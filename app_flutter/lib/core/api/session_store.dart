import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_interceptor.dart';
import 'models/misc.dart';

/// TC-SEC-11 (docs/04): token và `install_id` nằm trong Keychain/Keystore,
/// **không** bao giờ trong SharedPreferences hay file plaintext.
abstract interface class TokenVault {
  Future<String?> read(String key);
  Future<void> write(String key, String? value);
  Future<void> clearAll();
}

class SecureTokenVault implements TokenVault {
  SecureTokenVault([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: value);
    }
  }

  @override
  Future<void> clearAll() => _storage.deleteAll();
}

/// Web preview + test: không có keystore ⇒ session chỉ sống trong RAM.
/// Mất token khi reload là chủ đích, không phải bug — bản đóng gói iOS/Android dùng `SecureTokenVault`.
class InMemoryTokenVault implements TokenVault {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }

  @override
  Future<void> clearAll() async => _values.clear();
}

/// iOS/Android/macOS có Keychain+Keystore. Web và Linux/Windows desktop thì không:
/// session chỉ sống trong RAM, vì ghi token xuống disk plaintext phạm TC-SEC-11.
TokenVault defaultTokenVault() {
  final hasKeystore = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.macOS);
  return hasKeystore ? SecureTokenVault() : InMemoryTokenVault();
}

/// Lưu/xóa phiên + `install_id` (docs/02 §2.1: install-scoped, không phải ID người dùng).
class SessionStore {
  SessionStore(this._vault);

  static const String _kAccess = 'angi.session.access';
  static const String _kRefresh = 'angi.session.refresh';
  static const String _kUserId = 'angi.session.user_id';
  static const String _kGuest = 'angi.session.is_guest';
  static const String _kAccessExp = 'angi.session.access_exp';
  static const String _kRefreshExp = 'angi.session.refresh_exp';
  static const String _kInstallId = 'angi.install_id';

  final TokenVault _vault;

  Future<Session?> restore() async {
    final access = await _vault.read(_kAccess);
    if (access == null || access.isEmpty) return null;
    return Session(
      userId: await _vault.read(_kUserId) ?? '',
      accessToken: access,
      refreshToken: await _vault.read(_kRefresh) ?? '',
      isGuest: (await _vault.read(_kGuest)) != 'false',
      accessExpiresAt: DateTime.tryParse(await _vault.read(_kAccessExp) ?? ''),
      refreshExpiresAt: DateTime.tryParse(await _vault.read(_kRefreshExp) ?? ''),
    );
  }

  Future<void> save(Session session) async {
    await _vault.write(_kAccess, session.accessToken);
    await _vault.write(_kRefresh, session.refreshToken);
    await _vault.write(_kUserId, session.userId);
    await _vault.write(_kGuest, session.isGuest ? 'true' : 'false');
    await _vault.write(_kAccessExp, session.accessExpiresAt.toUtc().toIso8601String());
    await _vault.write(_kRefreshExp, session.refreshExpiresAt.toUtc().toIso8601String());
  }

  Future<void> saveGuest(GuestSession guest) => save(sessionFrom(guest));

  Session sessionFrom(GuestSession guest) {
    final now = DateTime.now().toUtc();
    return Session(
      userId: guest.userId,
      accessToken: guest.accessToken,
      refreshToken: guest.refreshToken,
      isGuest: guest.isGuest,
      accessExpiresAt: now.add(Duration(seconds: guest.accessExpiresIn)),
      refreshExpiresAt: now.add(Duration(seconds: guest.refreshExpiresIn)),
    );
  }

  /// Xóa tài khoản / logout (docs/01 §4.5): token biến mất khỏi máy, install_id giữ nguyên
  /// vì nó là khóa của `X-Device-Id` và rate limit, không định danh con người.
  Future<void> wipeSession() async {
    for (final key in [_kAccess, _kRefresh, _kUserId, _kGuest, _kAccessExp, _kRefreshExp]) {
      await _vault.write(key, null);
    }
  }

  Future<void> wipeAll() => _vault.clearAll();

  /// `install_id` UUID v4 sinh một lần, lưu keystore; `X-Device-Id` gửi ở mọi request.
  Future<String> installId(String Function() generate) async {
    final existing = await _vault.read(_kInstallId);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = generate();
    await _vault.write(_kInstallId, created);
    return created;
  }
}
