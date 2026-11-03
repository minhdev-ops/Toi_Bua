import '../json.dart';
import 'data_quality.dart';
import 'dish.dart';
import 'meta.dart';

/// `animation.style` (FR-ROU-08). Ngoài list của `config.animation_styles` ⇒ fallback `wheel`.
enum WheelStyle { wheel, chest, draw }

WheelStyle styleFromApi(String? raw) {
  for (final style in WheelStyle.values) {
    if (style.name == raw) return style;
  }
  return WheelStyle.wheel;
}

/// Input `POST /v1/spins`. Only-sent-what-changed: field `null` **không** được serialize.
class SpinRequest {
  const SpinRequest({
    this.filters,
    this.locked,
    this.diet,
    this.excludeDishIds,
    this.antiRepeat,
    this.wheelId,
    this.travelMode,
    this.contextOverrides,
    this.clientSeed,
    this.networkState = 'online',
  });

  final SpinFilters? filters;
  final SpinLocked? locked;
  final SpinDiet? diet;
  final List<String>? excludeDishIds;
  final AntiRepeatRequest? antiRepeat;
  final String? wheelId;
  final String? travelMode;
  final Map<String, Object?>? contextOverrides;

  /// Chỉ staging/test. Prod server bỏ qua (docs/02 §3.3).
  final String? clientSeed;
  final String networkState;

  Map<String, dynamic> toJson() => {
        if (filters != null) 'filters': filters!.toJson(),
        if (locked != null && locked!.isNotEmpty) 'locked': locked!.toJson(),
        if (diet != null && diet!.isNotEmpty) 'diet': diet!.toJson(),
        if (excludeDishIds != null && excludeDishIds!.isNotEmpty) 'exclude_dish_ids': excludeDishIds,
        if (antiRepeat != null && antiRepeat!.isNotEmpty) 'anti_repeat': antiRepeat!.toJson(),
        if (wheelId != null) 'wheel_id': wheelId,
        if (travelMode != null) 'travel_mode': travelMode,
        if (contextOverrides != null && contextOverrides!.isNotEmpty) 'context': {
          'overrides': contextOverrides,
        },
        if (clientSeed != null) 'client_seed': clientSeed,
        'network_state': networkState,
      };
}

class SpinFilters {
  const SpinFilters({
    this.meal,
    this.priceLevelMin,
    this.priceLevelMax,
    this.budgetVnd,
    this.type,
    this.region,
    this.temp,
    this.mood,
    this.partySize,
  });

  final List<String>? meal;
  final int? priceLevelMin;
  final int? priceLevelMax;
  final int? budgetVnd;
  final List<String>? type;
  final List<String>? region;
  final String? temp;
  final List<String>? mood;
  final int? partySize;

  bool get isEmpty =>
      meal == null &&
      priceLevelMin == null &&
      priceLevelMax == null &&
      budgetVnd == null &&
      type == null &&
      region == null &&
      temp == null &&
      mood == null &&
      partySize == null;

  Map<String, dynamic> toJson() => {
        if (meal != null && meal!.isNotEmpty) 'meal': meal,
        if (priceLevelMin != null) 'price_level_min': priceLevelMin,
        if (priceLevelMax != null) 'price_level_max': priceLevelMax,
        if (budgetVnd != null) 'budget_vnd': budgetVnd,
        if (type != null && type!.isNotEmpty) 'type': type,
        if (region != null && region!.isNotEmpty) 'region': region,
        if (temp != null) 'temp': temp,
        if (mood != null && mood!.isNotEmpty) 'mood': mood,
        if (partySize != null) 'party_size': partySize,
      };

  factory SpinFilters.fromJson(Map<String, dynamic> json) => SpinFilters(
        meal: asStringList(json, 'meal'),
        priceLevelMin: asInt(json, 'price_level_min'),
        priceLevelMax: asInt(json, 'price_level_max'),
        budgetVnd: asInt(json, 'budget_vnd'),
        type: asStringList(json, 'type'),
        region: asStringList(json, 'region'),
        temp: asString(json, 'temp'),
        mood: asStringList(json, 'mood'),
        partySize: asInt(json, 'party_size'),
      );
}

class SpinLocked {
  const SpinLocked({this.categoryId, this.region, this.temp, this.type});

  final String? categoryId;
  final String? region;
  final String? temp;
  final String? type;

  bool get isNotEmpty => categoryId != null || region != null || temp != null || type != null;

  Map<String, dynamic> toJson() => {
        if (categoryId != null) 'category_id': categoryId,
        if (region != null) 'region': region,
        if (temp != null) 'temp': temp,
        if (type != null) 'type': type,
      };

  factory SpinLocked.fromJson(Map<String, dynamic> json) => SpinLocked(
        categoryId: asString(json, 'category_id'),
        region: asString(json, 'region'),
        temp: asString(json, 'temp'),
        type: asString(json, 'type'),
      );
}

/// `diet.override_strict`: **chỉ thêm**, không bao giờ xoá ràng buộc đã lưu (FR-ROU-03).
class SpinDiet {
  const SpinDiet({this.overrideStrict = const []});

  final List<String> overrideStrict;

  bool get isNotEmpty => overrideStrict.isNotEmpty;

  Map<String, dynamic> toJson() => {'override_strict': overrideStrict};

  factory SpinDiet.fromJson(Map<String, dynamic> json) =>
      SpinDiet(overrideStrict: asStringList(json, 'override_strict'));
}

class AntiRepeatRequest {
  const AntiRepeatRequest({this.days, this.scope});

  /// 0–30, mặc định từ `config.spin.anti_repeat_days_default`.
  final int? days;
  final String? scope;

  bool get isNotEmpty => days != null || scope != null;

  Map<String, dynamic> toJson() => {
        if (days != null) 'days': days,
        if (scope != null) 'scope': scope,
      };
}

/// Output `201` của `POST /v1/spins`.
class SpinResult {
  const SpinResult({
    required this.spinId,
    required this.dish,
    required this.animation,
    required this.next,
    this.createdAt,
    this.proof,
    this.pool,
    this.antiRepeat,
    this.appliedFilters = const {},
    this.meta = ResponseMeta.fresh,
  });

  final String spinId;
  final DateTime? createdAt;
  final Dish dish;
  final ProofInfo? proof;
  final PoolInfo? pool;
  final AntiRepeatInfo? antiRepeat;
  final Map<String, dynamic> appliedFilters;
  final AnimationDirective animation;
  final NextAction next;
  final ResponseMeta meta;

  factory SpinResult.fromJson(Map<String, dynamic> json) => SpinResult(
        spinId: stringOr(json, 'spin_id'),
        createdAt: asDate(json, 'created_at'),
        dish: Dish.fromJson(asMap(json, 'dish')),
        proof: json['proof'] is Map<String, dynamic> ? ProofInfo.fromJson(asMap(json, 'proof')) : null,
        pool: json['pool'] is Map<String, dynamic> ? PoolInfo.fromJson(asMap(json, 'pool')) : null,
        antiRepeat: json['anti_repeat'] is Map<String, dynamic>
            ? AntiRepeatInfo.fromJson(asMap(json, 'anti_repeat'))
            : null,
        appliedFilters: asMap(json, 'applied_filters'),
        animation: AnimationDirective.fromJson(asMap(json, 'animation')),
        next: NextAction.fromJson(asMap(json, 'next')),
        meta: ResponseMeta.fromJson(asMap(json, 'meta')),
      );

  Map<String, dynamic> toJson() => {
        'spin_id': spinId,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        'dish': dish.toJson(),
        if (proof != null) 'proof': proof!.toJson(),
        if (pool != null) 'pool': pool!.toJson(),
        if (antiRepeat != null) 'anti_repeat': antiRepeat!.toJson(),
        'applied_filters': appliedFilters,
        'animation': animation.toJson(),
        'next': next.toJson(),
        'meta': meta.toJson(),
      };
}

class ProofInfo {
  const ProofInfo({
    required this.seedB64,
    required this.sha256Result,
    required this.algorithm,
    required this.poolHash,
    required this.verifyUrl,
  });

  final String seedB64;
  final String sha256Result;
  final String algorithm;
  final String poolHash;
  final String verifyUrl;

  factory ProofInfo.fromJson(Map<String, dynamic> json) => ProofInfo(
        seedB64: stringOr(json, 'seed_b64'),
        sha256Result: stringOr(json, 'sha256_result'),
        algorithm: stringOr(json, 'algorithm'),
        poolHash: stringOr(json, 'pool_hash'),
        verifyUrl: stringOr(json, 'verify_url'),
      );

  Map<String, dynamic> toJson() => {
        'seed_b64': seedB64,
        'sha256_result': sha256Result,
        'algorithm': algorithm,
        'pool_hash': poolHash,
        'verify_url': verifyUrl,
      };
}

class PoolInfo {
  const PoolInfo({
    required this.sizeInitial,
    required this.sizeAfterHardFilters,
    required this.sizeFinal,
    required this.removed,
  });

  final int sizeInitial;
  final int sizeAfterHardFilters;
  final int sizeFinal;
  final PoolRemoved removed;

  factory PoolInfo.fromJson(Map<String, dynamic> json) => PoolInfo(
        sizeInitial: asInt(json, 'size_initial') ?? 0,
        sizeAfterHardFilters: asInt(json, 'size_after_hard_filters') ?? 0,
        sizeFinal: asInt(json, 'size_final') ?? 0,
        removed: PoolRemoved.fromJson(asMap(json, 'removed')),
      );

  Map<String, dynamic> toJson() => {
        'size_initial': sizeInitial,
        'size_after_hard_filters': sizeAfterHardFilters,
        'size_final': sizeFinal,
        'removed': removed.toJson(),
      };
}

class PoolRemoved {
  const PoolRemoved({
    this.dietHard = 0,
    this.excluded = 0,
    this.locked = 0,
    this.filters = 0,
    this.antiRepeat = 0,
  });

  final int dietHard;
  final int excluded;
  final int locked;
  final int filters;
  final int antiRepeat;

  factory PoolRemoved.fromJson(Map<String, dynamic> json) => PoolRemoved(
        dietHard: asInt(json, 'diet_hard') ?? 0,
        excluded: asInt(json, 'excluded') ?? 0,
        locked: asInt(json, 'locked') ?? 0,
        filters: asInt(json, 'filters') ?? 0,
        antiRepeat: asInt(json, 'anti_repeat') ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'diet_hard': dietHard,
        'excluded': excluded,
        'locked': locked,
        'filters': filters,
        'anti_repeat': antiRepeat,
      };
}

class AntiRepeatInfo {
  const AntiRepeatInfo({
    required this.daysWindow,
    required this.tauDays,
    this.applied = const [],
    required this.maxPenalty,
  });

  final int daysWindow;
  final double tauDays;
  final List<AntiRepeatApplied> applied;
  final double maxPenalty;

  factory AntiRepeatInfo.fromJson(Map<String, dynamic> json) => AntiRepeatInfo(
        daysWindow: asInt(json, 'days_window') ?? 0,
        tauDays: asDouble(json, 'tau_days') ?? 0.0,
        applied: asMapList(json, 'applied').map(AntiRepeatApplied.fromJson).toList(growable: false),
        maxPenalty: asDouble(json, 'max_penalty') ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'days_window': daysWindow,
        'tau_days': tauDays,
        'applied': applied.map((a) => a.toJson()).toList(),
        'max_penalty': maxPenalty,
      };
}

class AntiRepeatApplied {
  const AntiRepeatApplied({required this.dishId, required this.factor, required this.daysSince});

  final String dishId;
  final double factor;
  final int daysSince;

  factory AntiRepeatApplied.fromJson(Map<String, dynamic> json) => AntiRepeatApplied(
        dishId: stringOr(json, 'dish_id'),
        factor: asDouble(json, 'factor') ?? 1.0,
        daysSince: asInt(json, 'days_since') ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'dish_id': dishId,
        'factor': factor,
        'days_since': daysSince,
      };
}

/// Chỉ dẫn hoạt hình. Kết quả **đã chốt server-side** trước khi response về
/// (FR-ROU-07) ⇒ app cấm đổi index, cấm thêm/xoá item.
class AnimationDirective {
  const AnimationDirective({
    required this.style,
    required this.durationMs,
    required this.reduceMotion,
    required this.sound,
    required this.haptics,
    required this.targetPosition,
    required this.wheelItems,
    required this.resultIndex,
  });

  final WheelStyle style;
  final int durationMs;
  final bool reduceMotion;
  final bool sound;
  final bool haptics;
  final int targetPosition;

  /// `dish_id`, app resolve tên + hue qua taxonomy/bundle đã cache.
  final List<String> wheelItems;
  final int resultIndex;

  /// Bất biến server guarantee (docs/02 §3.3):
  /// `wheel_items[result_index]` là món thắng và
  /// `target_position % wheel_items.length == result_index`.
  bool get isConsistent {
    if (wheelItems.isEmpty || resultIndex < 0 || resultIndex >= wheelItems.length) return false;
    return targetPosition % wheelItems.length == resultIndex;
  }

  factory AnimationDirective.fromJson(Map<String, dynamic> json) => AnimationDirective(
        style: styleFromApi(asString(json, 'style')),
        durationMs: asInt(json, 'duration_ms') ?? 0,
        reduceMotion: asBool(json, 'reduce_motion'),
        sound: asBool(json, 'sound', true),
        haptics: asBool(json, 'haptics', true),
        targetPosition: asInt(json, 'target_position') ?? 0,
        wheelItems: asStringList(json, 'wheel_items'),
        resultIndex: asInt(json, 'result_index') ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'style': style.name,
        'duration_ms': durationMs,
        'reduce_motion': reduceMotion,
        'sound': sound,
        'haptics': haptics,
        'target_position': targetPosition,
        'wheel_items': wheelItems,
        'result_index': resultIndex,
      };
}

/// `next` — app gọi **đúng** `path` + `suggested_body` server gửi.
class NextAction {
  const NextAction({
    required this.action,
    required this.method,
    required this.path,
    required this.suggestedBody,
  });

  final String action;
  final String method;
  final String path;
  final Map<String, dynamic> suggestedBody;

  factory NextAction.fromJson(Map<String, dynamic> json) => NextAction(
        action: stringOr(json, 'action'),
        method: stringOr(json, 'method', 'POST'),
        path: stringOr(json, 'path'),
        suggestedBody: asMap(json, 'suggested_body'),
      );

  Map<String, dynamic> toJson() => {
        'action': action,
        'method': method,
        'path': path,
        'suggested_body': suggestedBody,
      };
}

/// `network_state` của request (FR-ROU-10).
abstract final class NetworkState {
  static const String online = 'online';
  static const String offlineBundle = 'offline_bundle';
}

/// Spin do `RouletteEngine` cục bộ sinh khi mất mạng: **không có** `places`,
/// `data_quality = offline_bundle`, enqueue để sync sau.
///
/// Không có `animation.duration_ms` từ server ⇒ caller truyền token `AngiScale.base`.
/// Thời lượng không được hard-code trong renderer (DESIGN.md §Motion).
SpinResult offlineSpin({
  required String spinId,
  required Dish dish,
  required List<String> wheelItems,
  required int resultIndex,
  required bool reduceMotion,
  required int durationMs,
}) {
  final items = wheelItems.isEmpty ? [dish.id] : wheelItems;
  final index = resultIndex.clamp(0, items.length - 1);
  return SpinResult(
    spinId: spinId,
    createdAt: DateTime.now().toUtc(),
    dish: dish,
    animation: AnimationDirective(
      style: WheelStyle.wheel,
      durationMs: reduceMotion ? 0 : durationMs,
      reduceMotion: reduceMotion,
      sound: !reduceMotion,
      haptics: !reduceMotion,
      targetPosition: index + items.length * 4,
      wheelItems: items,
      resultIndex: index,
    ),
    next: NextAction(
      action: 'match_places',
      method: 'POST',
      path: '/v1/matches',
      suggestedBody: {'dish_id': dish.id, 'limit': 3},
    ),
    meta: const ResponseMeta(dataQuality: DataQuality.offlineBundle),
  );
}
