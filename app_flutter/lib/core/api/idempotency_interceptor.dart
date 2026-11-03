import 'package:dio/dio.dart';

import 'dio_client.dart';
import 'request_id.dart';

/// Đính `X-Idempotency-Key` cho thao tác ghi **theo đúng bảng §8 của docs/02** —
/// không phải "mọi POST". Ghi mà thiếu key ⇒ TC-API-04 fail; ghi ở endpoint bị cấm
/// key ⇒ server trả `IDEMPOTENCY_REPLAY` và nuốt luôn sự kiện mới (TC-API-05).
///
/// Key là hàm của `operation` ⇒ 3 lần retry yếu mạng vẫn là một record (TC-MOB-02).
class IdempotencyInterceptor extends Interceptor {
  /// docs/02 §8, cột `Idemp` = ✔.
  static const List<String> _requireKeyPrefixes = [
    '/v1/auth/guest',
    '/v1/auth/oauth',
    '/v1/auth/otp',
    '/v1/me', // PUT settings/preferences/diet/onboarding, DELETE me
    '/v1/devices/push-token',
    '/v1/exclusions',
    '/v1/user-locations',
    '/v1/journal/visits',
    '/v1/uploads/policy',
    '/v1/admin',
  ];

  static const List<String> _requireKeySuffixes = [
    '/reports', // POST /v1/places/{id}/reports
  ];

  /// Ghi **cấm** key: mỗi lần gọi là một sự kiện mới, hoặc token cũ đã bị thu hồi.
  static const List<String> _forbidKeyPrefixes = [
    '/v1/spins',
    '/v1/auth/refresh',
    '/v1/auth/logout',
    '/v1/matches',
    '/v1/geocode',
    '/v1/rooms', // phòng dùng `expected_version` (optimistic lock), không dùng key
  ];

  static bool _isWrite(String method) {
    switch (method.toUpperCase()) {
      case 'POST':
      case 'PUT':
      case 'PATCH':
      case 'DELETE':
        return true;
      default:
        return false;
    }
  }

  static bool _requiresKey(String path) =>
      _requireKeyPrefixes.any(path.startsWith) || _requireKeySuffixes.any(path.endsWith);

  static bool _forbidsKey(String path) => _forbidKeyPrefixes.any((prefix) => path.startsWith(prefix));

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final operation = options.extra[AngiHeaders.extraIdempotencyOp];
    final hasKey = operation is String && operation.isNotEmpty;
    final path = options.path;

    assert(
      !_isWrite(options.method) || !_requiresKey(path) || hasKey,
      '$path cần X-Idempotency-Key (docs/02 §8) — truyền idempotencyOperation vào ApiClient.',
    );
    assert(
      !_forbidsKey(path) || !hasKey,
      '$path cấm X-Idempotency-Key (docs/02 §8) — key sẽ biến lần gọi sau thành IDEMPOTENCY_REPLAY.',
    );

    if (hasKey) options.headers[AngiHeaders.idempotencyKey] = IdempotencyKeys.forOperation(operation);
    handler.next(options);
  }
}
