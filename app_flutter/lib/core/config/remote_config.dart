import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/dio_client.dart';
import '../api/models/config.dart';
import '../api/models/misc.dart';
import '../telemetry/analytics.dart';

/// `Cache-Control: public, max-age=120` của `GET /v1/config` (docs/02 §5.1).
const Duration kConfigTtl = Duration(seconds: 120);

/// Ảnh chụp config + lúc lấy, để UI biết mình đang hiển thị dữ liệu cũ đến mức nào.
class ConfigSnapshot {
  const ConfigSnapshot({required this.config, this.fetchedAt});

  final AppConfig config;
  final DateTime? fetchedAt;

  bool get isLive => fetchedAt != null && !config.isSafeDefaults;

  Duration get age => fetchedAt == null ? const Duration(days: 3650) : DateTime.now().difference(fetchedAt!);

  bool get isStale => age > kConfigTtl;
}

/// Cache + refresh `GET /v1/config` — nơi duy nhất app lấy hằng số nghiệp vụ.
///
/// Bất biến (spec UC-01 §6): safe defaults **chỉ** dùng khi chưa từng tải được config.
/// Một lần refresh lỗi không bao giờ được ghi đè config đang sống.
class ConfigService extends ChangeNotifier {
  ConfigService({
    required ApiClient api,
    required SharedPreferences prefs,
    required ClientIdentity identity,
    Analytics? analytics,
    this.country = 'VN',
  })  : _api = api,
        _prefs = prefs,
        _identity = identity,
        _analytics = analytics,
        _snapshot = const ConfigSnapshot(config: AppConfig.safeDefaults) {
    _restore();
  }

  static const String _kBody = 'angi.config.body';
  static const String _kFetchedAt = 'angi.config.fetched_at';

  final ApiClient _api;
  final SharedPreferences _prefs;
  final ClientIdentity _identity;
  final Analytics? _analytics;

  /// `?country=` của docs/02 §5.1; P1 chỉ phục vụ VN.
  final String country;

  ConfigSnapshot _snapshot;
  Future<AppConfig>? _inFlight;
  bool _defaultsAnnounced = false;

  AppConfig get config => _snapshot.config;
  ConfigSnapshot get snapshot => _snapshot;
  bool get usingSafeDefaults => _snapshot.config.isSafeDefaults;

  /// Bản đã persist từ lần chạy trước: đọc đồng bộ, hub render ngay khi mở app.
  void _restore() {
    final raw = _prefs.getString(_kBody);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      _snapshot = ConfigSnapshot(
        config: AppConfig.fromJson(decoded),
        fetchedAt: DateTime.tryParse(_prefs.getString(_kFetchedAt) ?? ''),
      );
    } on FormatException catch (_) {
      _prefs.remove(_kBody);
      _prefs.remove(_kFetchedAt);
    }
  }

  /// Gọi ở bootstrap: trả bản cache ngay, chỉ gọi mạng khi cache quá TTL.
  Future<AppConfig> ensureFresh({bool force = false}) {
    if (!force && !_snapshot.isStale) return SynchronousFuture(_snapshot.config);
    return refresh();
  }

  /// One-flight: 3 màn hình cùng cần config lúc mở app ⇒ đúng 1 request.
  Future<AppConfig> refresh() => _inFlight ??= _fetch().whenComplete(() => _inFlight = null);

  Future<AppConfig> _fetch() async {
    final previous = _snapshot;
    try {
      final ok = await _api.get(
        '/v1/config',
        auth: false,
        query: {
          'platform': _identity.platform,
          'app_version': _identity.appVersion,
          'country': country,
        },
      );
      _snapshot = ConfigSnapshot(config: AppConfig.fromJson(ok.json), fetchedAt: DateTime.now());
      await _persist(ok.json);
      _defaultsAnnounced = false;
      notifyListeners();
      return _snapshot.config;
    } on ApiError catch (error) {
      // Không có `else` ghi đè: config cũ vẫn thắng, app vẫn chạy tiếp.
      if (!previous.isLive) _announceDefaults(error);
      return previous.config;
    }
  }

  void _announceDefaults(ApiError error) {
    if (_defaultsAnnounced) return;
    _defaultsAnnounced = true;
    _analytics?.log(AnalyticsEvents.configDefaultsUsed, properties: {
      'code': codeToWire(error.code),
      'http_status': error.httpStatus,
    });
  }

  Future<void> _persist(Map<String, dynamic> body) async {
    await _prefs.setString(_kBody, jsonEncode(body));
    await _prefs.setString(_kFetchedAt, DateTime.now().toUtc().toIso8601String());
  }

  /// User xóa dữ liệu (SRS 11) ⇒ xóa cache, lần chạy sau quay về safe defaults.
  Future<void> clearCache() async {
    await _prefs.remove(_kBody);
    await _prefs.remove(_kFetchedAt);
    _snapshot = const ConfigSnapshot(config: AppConfig.safeDefaults);
    _defaultsAnnounced = false;
    notifyListeners();
  }
}
