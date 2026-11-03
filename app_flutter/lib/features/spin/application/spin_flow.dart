import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../bootstrap.dart';
import '../../../core/api/models/matches.dart';
import '../../../core/api/models/misc.dart';
import '../../../core/api/models/spin.dart';
import '../../../core/telemetry/analytics.dart';
import '../../../core/theme/angi_tokens.dart';
import '../../app/application/app_providers.dart';
import '../../discover/data/matches_repository.dart';
import '../data/dish_catalog.dart';
import '../data/spin_repository.dart';

enum SpinPhase { idle, requesting, animating, resolving, ready, failed }

class SpinFlow {
  const SpinFlow({
    this.phase = SpinPhase.idle,
    this.request = const SpinRequest(),
    this.spin,
    this.matches,
    this.error,
    this.countdownSeconds,
  });

  final SpinPhase phase;

  /// Bộ lọc đang áp dụng. Giữ ở state để mở lại sheet thấy đúng thứ đã chọn.
  final SpinRequest request;

  final SpinResult? spin;
  final MatchResponse? matches;

  /// App layer giữ ApiError thô. UiError chứa chuỗi ARB nên phải dựng ở presentation,
  /// nơi có S.of(context) (TC-I18N-01).
  final ApiError? error;

  /// 429: nút Quay bị ẩn và đếm ngược đúng retry_after_s server gửi.
  final int? countdownSeconds;

  bool get isWheelRunning => phase == SpinPhase.animating;

  bool get isBusy =>
      phase == SpinPhase.requesting || phase == SpinPhase.animating || phase == SpinPhase.resolving;

  bool get canSpin => !isBusy && (countdownSeconds ?? 0) <= 0;

  bool get hasResult => spin != null;

  List<RelaxationStep> get relaxSteps => matches?.relaxation?.stepsAvailable ?? const [];

  int get activeFilterCount {
    final f = request.filters;
    if (f == null) return 0;
    var count = 0;
    if (f.meal != null && f.meal!.isNotEmpty) count++;
    if (f.budgetVnd != null) count++;
    if (f.priceLevelMax != null) count++;
    if (f.type != null && f.type!.isNotEmpty) count++;
    if (f.region != null && f.region!.isNotEmpty) count++;
    if (f.temp != null && f.temp != 'any') count++;
    if (f.mood != null && f.mood!.isNotEmpty) count++;
    if (f.partySize != null && f.partySize! > 1) count++;
    if (request.locked?.isNotEmpty ?? false) count++;
    return count;
  }

  /// copyWith luôn thay error bằng giá trị truyền vào: rời khỏi failed là xoá lỗi cũ,
  /// kể cả khi caller không nhắc tới nó.
  SpinFlow copyWith({
    SpinPhase? phase,
    SpinRequest? request,
    SpinResult? spin,
    MatchResponse? matches,
    ApiError? error,
    int? countdownSeconds,
  }) =>
      SpinFlow(
        phase: phase ?? this.phase,
        request: request ?? this.request,
        spin: spin ?? this.spin,
        matches: matches ?? this.matches,
        error: error,
        countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      );
}

final spinRepositoryProvider = Provider<SpinRepository>((ref) => SpinRepository(sl()));

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) => MatchesRepository(sl()));

/// Tên + hue cho animation.wheel_items[]. Bundle lỗi thì catalog rỗng: vòng quay vẫn chạy,
/// nhãn là id, không có đường nào để renderer tự đặt tên món.
final dishCatalogProvider = FutureProvider<DishCatalog>((ref) => DishCatalogRepository(sl()).load());

final spinFlowProvider = NotifierProvider<SpinFlowNotifier, SpinFlow>(SpinFlowNotifier.new);

/// Máy trạng thái một lượt UC-01: Quay, wheel, 3 quán.
///
/// Bất biến giữ ở đây chứ không ở widget: kết quả đã chốt server-side trước khi
/// animation chạy (FR-ROU-07), nên app không đổi result_index, không sort lại items.
class SpinFlowNotifier extends Notifier<SpinFlow> {
  static const Duration _debounce = Duration(milliseconds: 300);

  Timer? _tick;
  DateTime? _lastTap;
  SpinRequest _lastRequest = const SpinRequest();

  @override
  SpinFlow build() {
    ref.onDispose(() => _tick?.cancel());
    // Onboarding ghi budget + diet vào máy; lượt quay đầu dùng ngay, không cần đợi API.
    final prefs = sl<SharedPreferences>();
    final budget = prefs.getInt('angi.budget');
    final diet = prefs.getStringList('angi.diet') ?? const <String>[];
    return SpinFlow(
      request: SpinRequest(
        filters: budget == null ? null : SpinFilters(budgetVnd: budget),
        diet: diet.isEmpty ? null : SpinDiet(overrideStrict: diet),
      ),
    );
  }

  void updateRequest(SpinRequest request) {
    state = state.copyWith(request: request);
  }

  Future<void> spinNow({SpinRequest? request}) async {
    if (!state.canSpin) return;
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!) < _debounce) return;
    _lastTap = now;
    final effective = request ?? state.request;
    _lastRequest = effective;

    final analytics = ref.read(analyticsProvider);
    analytics.log(
      AnalyticsEvents.spinStarted,
      properties: {
        'has_filters': !(effective.filters?.isEmpty ?? true),
        'locked': effective.locked != null,
        'network_state': effective.networkState,
      },
    );

    state = state.copyWith(phase: SpinPhase.requesting, request: effective);
    try {
      final result = await ref.read(spinRepositoryProvider).spin(effective);
      final animation = result.animation;
      if (animation.durationMs > AngiScale.wheelMaxDurationMs) {
        analytics.log(
          AnalyticsEvents.configAnomaly,
          properties: {'field': 'animation.duration_ms', 'value': animation.durationMs},
        );
      }
      if (!animation.isConsistent) {
        _fail(
          const ApiError(
            code: ErrorCode.serverError,
            httpStatus: 500,
            message: 'animation_inconsistent',
            retryable: true,
          ),
          'spins',
        );
        return;
      }
      state = state.copyWith(spin: result, phase: SpinPhase.animating);
    } on ApiError catch (error) {
      _fail(error, 'spins');
    }
  }

  /// Wheel dừng (hoặc kết quả render tức thì khi reduce-motion) thì xin 3 quán.
  Future<void> onWheelSettled() async {
    final spin = state.spin;
    if (spin == null || state.phase != SpinPhase.animating) return;
    ref.read(analyticsProvider).log(
          AnalyticsEvents.spinResultShown,
          properties: {
            'spin_id': spin.spinId,
            'dish_type': spin.dish.type?.name ?? 'unknown',
            'duration_ms': spin.animation.durationMs,
            'reduce_motion': spin.animation.reduceMotion,
          },
        );
    await _resolve(spin);
  }

  /// Bước nới lỏng user chạm trong RelaxEmptyState (FR-REC-05).
  Future<void> applyRelaxation(RelaxationStep step) async {
    final spin = state.spin;
    if (spin == null || state.isBusy) return;
    await _resolve(spin, relax: step);
  }

  Future<void> retry() async {
    final spin = state.spin;
    if (spin == null) {
      await spinNow(request: _lastRequest);
      return;
    }
    await _resolve(spin);
  }

  /// Về trạng thái chờ, giữ bộ lọc để lần quay sau không phải chọn lại.
  void reset() {
    _tick?.cancel();
    state = SpinFlow(request: state.request);
  }

  Future<void> _resolve(SpinResult spin, {RelaxationStep? relax}) async {
    state = state.copyWith(phase: SpinPhase.resolving);
    try {
      final matches = await ref
          .read(matchesRepositoryProvider)
          .follow(spin.next, geo: ref.read(anchorProvider).source, relax: relax);
      // items rỗng vẫn là 200 và phải mở RelaxEmptyState (FR-REC-05), không phải lỗi.
      state = state.copyWith(matches: matches, phase: SpinPhase.ready);
      ref.read(analyticsProvider).log(
            AnalyticsEvents.placesShown,
            properties: {
              'count': matches.items.length,
              'data_quality': matches.meta.dataQuality.wireValue,
              'latency_ms_total': matches.meta.latency?.total ?? matches.meta.latencyMs ?? 0,
              'relaxation_applied': matches.relaxation?.applied ?? false,
            },
          );
    } on ApiError catch (error) {
      _fail(error, 'matches');
    }
  }

  void _startCountdown(int seconds) {
    _tick?.cancel();
    state = state.copyWith(countdownSeconds: seconds);
    _tick = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = (state.countdownSeconds ?? 1) - 1;
      if (left <= 0) {
        timer.cancel();
        state = state.copyWith(countdownSeconds: 0);
        return;
      }
      state = state.copyWith(countdownSeconds: left);
    });
  }

  void _fail(ApiError error, String endpoint) {
    if (error.code == ErrorCode.rateLimited) _startCountdown(error.retryAfterS ?? 30);
    state = SpinFlow(
      phase: SpinPhase.failed,
      request: state.request,
      spin: state.spin,
      matches: state.matches,
      error: error,
      countdownSeconds: state.countdownSeconds,
    );
    ref.read(analyticsProvider).log(
          AnalyticsEvents.errorShown,
          properties: {'code': codeToWire(error.code), 'endpoint': endpoint, 'retryable': error.retryable},
        );
  }
}
