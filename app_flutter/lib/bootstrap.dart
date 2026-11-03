import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api/auth_interceptor.dart';
import 'core/api/auth_service.dart';
import 'core/api/dio_client.dart';
import 'core/api/idempotency_interceptor.dart';
import 'core/api/mock_adapter.dart';
import 'core/api/models/misc.dart';
import 'core/api/request_id.dart';
import 'core/api/retry_policy.dart';
import 'core/api/session_store.dart';
import 'core/config/remote_config.dart';
import 'core/geo/anchor_store.dart';
import 'core/telemetry/analytics.dart';

final GetIt sl = GetIt.instance;

/// Backend chưa dựng (P1). Chạy fixture cho tới khi build với `--dart-define=ANGI_REAL_API=true`.
const bool _realApi = bool.fromEnvironment('ANGI_REAL_API', defaultValue: false);
const String _baseUrl = String.fromEnvironment('ANGI_API_BASE_URL', defaultValue: 'https://api.angi.example');
const String _appVersion = String.fromEnvironment('ANGI_APP_VERSION', defaultValue: '1.0.0+1');

String get _platformTag {
  if (kIsWeb) return 'web';
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.android:
      return 'android';
    default:
      return 'web';
  }
}

BaseOptions get _baseOptions => BaseOptions(
      baseUrl: _baseUrl,
      // docs/02 §8: SLA p95 cao nhất là 1,5 s. 8 s là trần chịu đựng cho mạng yếu —
      // vượt qua thì app hiện state offline, không treo màn hình.
      connectTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      responseType: ResponseType.json,
      contentType: Headers.jsonContentType,
    );

/// Hạ tầng dữ liệu đã nối xong, sẵn sàng cho `ProviderScope`.
class AppServices {
  AppServices({
    required this.identity,
    required this.session,
    required this.auth,
    required this.api,
    required this.config,
    required this.analytics,
    required this.fixtureAdapter,
  });

  final ClientIdentity identity;
  final Session session;
  final AuthService auth;
  final ApiClient api;
  final ConfigService config;
  final Analytics analytics;

  /// `null` khi chạy API thật. Giữ lại để test bật/tắt `forceOffline` giữa chừng.
  final FixtureAdapter? fixtureAdapter;
}

Future<AppServices> bootstrap({String locale = 'vi'}) async {
  WidgetsFlutterBinding.ensureInitialized();
  // DateFormat.EEEE cho bảng giờ mở: intl cần nạp dữ liệu locale trước khi dùng.
  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();

  final store = SessionStore(defaultTokenVault());
  final installId = await store.installId(uuidV4);
  final identity = ClientIdentity(
    deviceId: installId,
    platform: _platformTag,
    appVersion: _appVersion,
    locale: locale,
  );

  final analytics = Analytics(sinks: const [LoggingAnalyticsSink()], deviceId: installId);
  final session = Session();
  final adapter = _realApi ? null : FixtureAdapter();

  // Chuỗi 1: KHÔNG có AuthInterceptor. Vừa là đường cho guest/refresh (docs/01 §4.4
  // cấm refresh đi qua interceptor gây 401), vừa là đường retry của một request 401.
  final anonymousDio = Dio(_baseOptions);
  if (adapter != null) anonymousDio.httpClientAdapter = adapter;
  final anonymousRetry = RetryPolicyInterceptor();
  anonymousDio.interceptors.addAll([
    ClientHeadersInterceptor(identity),
    IdempotencyInterceptor(),
    anonymousRetry,
  ]);
  anonymousRetry.retryDio = anonymousDio;

  // Chuỗi 2: chuỗi thật sự dùng của app. `refresher` chỉ gắn được sau khi AuthService
  // tồn tại ⇒ closure đọc biến, không đọc giá trị chốt lúc khởi tạo.
  TokenRefresher? refresher;
  final mainDio = Dio(_baseOptions);
  if (adapter != null) mainDio.httpClientAdapter = adapter;
  final mainRetry = RetryPolicyInterceptor();
  mainDio.interceptors.addAll([
    ClientHeadersInterceptor(identity),
    AuthInterceptor(
      session: session,
      refresher: () async {
        final current = refresher;
        return current == null ? null : await current();
      },
      retryDio: anonymousDio,
    ),
    IdempotencyInterceptor(),
    mainRetry,
  ]);
  mainRetry.retryDio = anonymousDio;

  final anonymousApi = ApiClient(anonymousDio);
  final api = ApiClient(mainDio);
  final auth = AuthService(
    api: api,
    anonymousApi: anonymousApi,
    session: session,
    store: store,
    identity: identity,
  );
  refresher = auth.refresh;

  final config = ConfigService(
    api: anonymousApi,
    prefs: prefs,
    identity: identity,
    analytics: analytics,
  );

  sl
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerSingleton<ClientIdentity>(identity)
    ..registerSingleton<Session>(session)
    ..registerSingleton<SessionStore>(store)
    ..registerSingleton<AnchorStore>(AnchorStore(prefs))
    ..registerSingleton<Analytics>(analytics)
    ..registerSingleton<ApiClient>(api)
    ..registerSingleton<AuthService>(auth)
    ..registerSingleton<ConfigService>(config);

  // Mở app không chờ network: guest + config chạy nền, UI đã có cache/safe defaults
  // (FR "3 chạm đến kết quả", docs/02 §8 SLA chỉ đúng khi backend sống).
  unawaited(_startSession(auth, analytics));
  unawaited(config.ensureFresh());

  return AppServices(
    identity: identity,
    session: session,
    auth: auth,
    api: api,
    config: config,
    analytics: analytics,
    fixtureAdapter: adapter,
  );
}

/// Mở app không được chết vì auth: guest fail thì vẫn chạy bằng config cache +
/// safe defaults, request cần token sẽ xin lại qua `AuthInterceptor`.
Future<void> _startSession(AuthService auth, Analytics analytics) async {
  try {
    await auth.ensureSession();
  } on ApiError catch (error) {
    analytics.log(AnalyticsEvents.authGuestFailed, properties: {'code': codeToWire(error.code)});
  }
}
