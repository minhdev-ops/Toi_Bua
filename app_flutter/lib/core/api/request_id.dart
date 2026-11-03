import 'dart:math';

/// `X-Request-Id`: ULID 26 ký tự Crockford base32 — client sinh, server log và trả về
/// để user dán vào ticket (`docs/01` §4.2). Không phải UUID: ULID sắp xếp theo thời gian.
abstract final class Ulid {
  static const String _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  static final Random _random = Random.secure();

  static String generate() {
    final now = DateTime.now().toUtc().microsecondsSinceEpoch;
    final buffer = StringBuffer();
    for (var shift = 9; shift >= 0; shift--) {
      buffer.write(_alphabet[(now >> (shift * 6)) & 0x1f]);
    }
    for (var i = 0; i < 16; i++) {
      buffer.write(_alphabet[_random.nextInt(32)]);
    }
    return buffer.toString();
  }
}

/// `install_id` UUID v4 (docs/02 §2.1): sinh một lần, lưu keystore, gửi ở `X-Device-Id`.
/// Không phải device fingerprint và không định danh con người.
String uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}'
      '-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Idempotency key: **mỗi một** POST/PUT/PATCH/DELETE có ghi dùng một key, giữ nguyên
/// khi retry cùng thao tác ⇒ server trả `409 IDEMPOTENCY_REPLAY` thay vì ghi trùng
/// (TC-API-04, TC-MOB-02).
abstract final class IdempotencyKeys {
  static final Map<String, String> _inFlight = {};

  /// Trả key ổn định cho `operation` đang chờ; sinh mới khi operation cũ đã xong.
  static String forOperation(String operation) {
    return _inFlight.putIfAbsent(operation, Ulid.generate);
  }

  static void release(String operation) => _inFlight.remove(operation);

  static void clear() => _inFlight.clear();
}
