import 'dart:async';

import 'package:dio/dio.dart';

import 'dio_client.dart';

/// Phiên hiện tại. Đổi giá trị ⇒ UI rebuild qua Riverpod, không qua interceptor.
class Session {
  Session({
    this.userId = '',
    this.accessToken = '',
    this.refreshToken = '',
    this.isGuest = true,
    DateTime? accessExpiresAt,
    DateTime? refreshExpiresAt,
  })  : accessExpiresAt = accessExpiresAt ?? DateTime.now().toUtc().add(const Duration(minutes: 15)),
        refreshExpiresAt = refreshExpiresAt ?? DateTime.now().toUtc().add(const Duration(days: 30));

  String userId;
  String accessToken;
  String refreshToken;
  bool isGuest;

  DateTime accessExpiresAt;
  DateTime refreshExpiresAt;

  bool get isSignedIn => accessToken.isNotEmpty;

  /// Nạp session khác vào **đúng object** mà `AuthInterceptor` đang giữ tham chiếu —
  /// interceptor không được đổi reference giữa chừng.
  void adopt(Session other) {
    userId = other.userId;
    accessToken = other.accessToken;
    refreshToken = other.refreshToken;
    isGuest = other.isGuest;
    accessExpiresAt = other.accessExpiresAt;
    refreshExpiresAt = other.refreshExpiresAt;
  }

  bool get accessExpired => DateTime.now().toUtc().isAfter(accessExpiresAt.subtract(const Duration(seconds: 30)));

  /// Hết cả refresh ⇒ không còn gì để xoay, app phải xin phiên guest mới.
  bool get refreshExpired => DateTime.now().toUtc().isAfter(refreshExpiresAt);

  /// `Bearer <jwt>` cho tài khoản đủ điều kiện, `Guest <token>` cho khách (docs/01 §4.2).
  String? get authorizationHeader => accessToken.isEmpty ? null : '${isGuest ? 'Guest' : 'Bearer'} $accessToken';

  void applyTokens({required String access, required String refresh, required int expiresIn, required int refreshIn}) {
    accessToken = access;
    refreshToken = refresh;
    accessExpiresAt = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
    refreshExpiresAt = DateTime.now().toUtc().add(Duration(seconds: refreshIn));
  }

  void clear() {
    accessToken = '';
    refreshToken = '';
  }
}

/// Trả access token mới, hoặc `null` khi refresh thất bại ⇒ app rơi về sheet guest.
typedef TokenRefresher = Future<String?> Function();

/// Header `Authorization` + xử lý 401 **một lần duy nhất** với mutex chống
/// thundering-herd (`docs/01` §4.4): N request cùng lúc chỉ gây 1 lần refresh.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.session,
    required this.refresher,
    required this.retryDio,
    this.onSignedOut,
  });

  final Session session;
  final TokenRefresher refresher;

  /// Dio **không** gắn interceptor này: retry bằng chính Dio sẽ đệ quy khi 401 lặp lại.
  final Dio retryDio;
  final void Function()? onSignedOut;

  Completer<String?>? _inFlight;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra[AngiHeaders.extraNoAuth] != true) {
      final header = session.authorizationHeader;
      if (header != null) options.headers[_authorizationHeader] = header;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final retriedAlready = err.requestOptions.extra[_retriedKey] == true;
    if (err.response?.statusCode != 401 || retriedAlready || session.refreshToken.isEmpty) {
      return handler.next(err);
    }

    final token = await _refreshOnce();
    if (token == null) {
      session.clear();
      onSignedOut?.call();
      return handler.next(err);
    }

    err.requestOptions.headers[_authorizationHeader] = session.authorizationHeader;
    err.requestOptions.extra[_retriedKey] = true;
    try {
      final response = await retryDio.fetch<dynamic>(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  Future<String?> _refreshOnce() {
    final pending = _inFlight;
    if (pending != null) return pending.future;
    final completer = Completer<String?>();
    _inFlight = completer;
    refresher().then((value) {
      _inFlight = null;
      completer.complete(value);
    }).catchError((Object _) {
      _inFlight = null;
      completer.complete(null);
    });
    return completer.future;
  }
}

/// `dart:io` không tồn tại trên web ⇒ dùng literal, app chạy được cả Chrome (TC-MOB build).
const String _authorizationHeader = 'Authorization';
const String _retriedKey = 'angi_refreshed_once';
