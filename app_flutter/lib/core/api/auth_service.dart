import 'auth_interceptor.dart';
import 'dio_client.dart';
import 'json.dart';
import 'models/misc.dart';
import 'request_id.dart';
import 'session_store.dart';

/// FR-AUTH-01 (docs/02 §2.1): mở app là có phiên khách, không màn đăng ký.
///
/// Ba đường ra của một phiên: còn hạn ⇒ dùng; hết access mà còn refresh ⇒ `refresh()`
/// (do `AuthInterceptor` gọi khi gặp 401); hết sạch hoặc lỗi ⇒ xin guest mới.
class AuthService {
  AuthService({
    required ApiClient api,

    /// Dio **không** có `AuthInterceptor`: refresh mà đi qua interceptor thì gặp 401
    /// là đệ quy vô hạn (docs/01 §4.4).
    required ApiClient anonymousApi,
    required Session session,
    required SessionStore store,
    required ClientIdentity identity,
  })  : _api = api,
        _anonymousApi = anonymousApi,
        _session = session,
        _store = store,
        _identity = identity;

  final ApiClient _api;
  final ApiClient _anonymousApi;
  final Session _session;
  final SessionStore _store;
  final ClientIdentity _identity;

  Session get session => _session;
  bool get isSignedIn => _session.isSignedIn;

  Future<Session> ensureSession() async {
    if (_session.isSignedIn) return _session;
    final restored = await _store.restore();
    if (restored != null && !restored.refreshExpired) {
      _session.adopt(restored);
      return _session;
    }
    return signInAsGuest();
  }

  /// `POST /v1/auth/guest` — **có** `X-Idempotency-Key`: 2 lần gọi vì retry mạng
  /// phải ra cùng một guest user, không tạo 2 `user_account`.
  Future<Session> signInAsGuest({String? attestation}) async {
    final installId = await _store.installId(uuidV4);
    final ok = await _anonymousApi.post(
      '/v1/auth/guest',
      auth: false,
      idempotencyOperation: 'auth_guest',
      body: {
        'install_id': installId,
        'platform': _identity.platform,
        'app_version': _identity.appVersion,
        'locale': _identity.locale,
        'attestation': ?attestation,
      },
    );
    final guest = GuestSession.fromJson(ok.json);
    _session.userId = guest.userId;
    _session.isGuest = guest.isGuest;
    _session.applyTokens(
      access: guest.accessToken,
      refresh: guest.refreshToken,
      expiresIn: guest.accessExpiresIn,
      refreshIn: guest.refreshExpiresIn,
    );
    await _store.save(_session);
    return _session;
  }

  /// `POST /v1/auth/refresh` (docs/02 §2.4). Server thu hồi token cũ ngay ⇒ **cấm**
  /// idempotency key: replay qua key sẽ trả lại đúng token đã bị thu hồi.
  /// Trả access token mới, `null` khi không xoay được ⇒ caller xin guest.
  Future<String?> refresh() async {
    final old = _session.refreshToken;
    if (old.isEmpty) return null;
    try {
      final ok = await _anonymousApi.post(
        '/v1/auth/refresh',
        auth: false,
        body: {'refresh_token': old},
      );
      final body = ok.json;
      _session.applyTokens(
        access: stringOr(body, 'access_token'),
        refresh: stringOr(body, 'refresh_token', old),
        expiresIn: asInt(body, 'access_expires_in') ?? 900,
        refreshIn: asInt(body, 'refresh_expires_in') ?? 2592000,
      );
      await _store.save(_session);
      return _session.accessToken;
    } on ApiError catch (_) {
      // 401 REFRESH_REUSE_DETECTED: thu hồi toàn bộ phiên ⇒ quay về guest.
      await _store.wipeSession();
      _session.clear();
      return null;
    }
  }

  /// `POST /v1/auth/logout` → `204`. Server lỗi vẫn wipe: user đã bấm "đăng xuất" thì
  /// máy không được giữ token nữa (docs/01 §4.5, SRS 11).
  Future<void> signOut({bool allDevices = false}) async {
    final refresh = _session.refreshToken;
    try {
      if (refresh.isNotEmpty) {
        await _api.post(
          '/v1/auth/logout',
          body: {'refresh_token': refresh, 'sign_out_all_devices': allDevices},
        );
      }
    } on ApiError catch (_) {
      // Server lỗi cũng không được giữ token: finally luôn chạy.
    } finally {
      await _store.wipeSession();
      _session.clear();
    }
  }

  /// Xóa tài khoản (docs/02 §2.7 `DELETE /v1/me`): token + install_id đều đi,
  /// vì `install_id` là duy nhất còn lại định danh máy này.
  Future<void> wipeLocalIdentity() async {
    await _store.wipeAll();
    _session.clear();
  }
}
