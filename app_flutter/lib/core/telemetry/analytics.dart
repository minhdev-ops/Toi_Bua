import 'package:flutter/foundation.dart';

/// Ràng buộc privacy (docs/04 TC-PRIV-04/08): event không mang PII, không tọa độ thô
/// (chỉ bucket hash), không diet/allergen. Chặn ngay ở cửa `log` thay vì tin call site.
abstract interface class AnalyticsSink {
  void emit(String event, Map<String, Object?> properties);
}

class LoggingAnalyticsSink implements AnalyticsSink {
  const LoggingAnalyticsSink();

  @override
  void emit(String event, Map<String, Object?> properties) {
    if (!kDebugMode) return;
    debugPrint('[angi] $event${properties.isEmpty ? '' : ' $properties'}');
  }
}

/// Tên event của UC-01 (`.ulpi/design/uc01-quay-den-chi-duong.md` §Analytics).
abstract final class AnalyticsEvents {
  static const String spinStarted = 'spin_started';
  static const String spinResultShown = 'spin_result_shown';
  static const String placesShown = 'places_shown';
  static const String placeChosen = 'place_chosen';
  static const String navOpened = 'nav_opened';
  static const String visitMarked = 'visit_marked';
  static const String errorShown = 'error_shown';

  /// Spec §6: admin cần thấy app đang chạy bằng hằng số tự chốt.
  static const String configDefaultsUsed = 'config_defaults_used';

  /// FR-AUTH-01 fail: app vẫn chạy, nhưng phải biết khách không xin được phiên.
  static const String authGuestFailed = 'auth_guest_failed';

  /// Spec §Edge cases: `animation.duration_ms` vượt trần ⇒ app clamp, admin phải thấy.
  static const String configAnomaly = 'config_anomaly';

  /// Error boundary (docs/01 §3.3). Chỉ type + library, không message (TC-PRIV-04).
  static const String appError = 'app_error';
}

class Analytics {
  Analytics({
    required List<AnalyticsSink> sinks,
    String? deviceId,
    this.enabled = true,
  })  : _sinks = List.unmodifiable(sinks),
        _deviceBucket = deviceId == null ? null : bucketHash(deviceId);

  final List<AnalyticsSink> _sinks;
  final String? _deviceBucket;

  /// Opt-out trong `PUT /v1/me/settings` ⇒ mọi event bị bỏ, không buffer lại.
  bool enabled;

  void log(String event, {Map<String, Object?>? properties}) {
    if (!enabled) return;
    final props = <String, Object?>{
      if (_deviceBucket != null) 'device_bucket': _deviceBucket,
      ...scrub(properties ?? const {}),
    };
    for (final sink in _sinks) {
      sink.emit(event, props);
    }
  }

  static const Set<String> _forbiddenKeys = {
    'user_id',
    'lat',
    'lng',
    'latitude',
    'longitude',
    'geo',
    'address',
    'email',
    'phone',
    'diet',
    'allergen',
    'allergens',
    'constraints',
    'location',
  };

  @visibleForTesting
  static Map<String, Object?> scrub(Map<String, Object?> properties) {
    final out = <String, Object?>{};
    properties.forEach((key, value) {
      if (_forbiddenKeys.contains(key.toLowerCase())) return;
      if (value is Map) {
        final nested = scrub(value.map((k, v) => MapEntry('$k', v)));
        if (nested.isNotEmpty) out[key] = nested;
      } else if (value is String && _looksLikeCoords(value)) {
        return;
      } else {
        out[key] = value;
      }
    });
    return out;
  }

  static bool _looksLikeCoords(String value) {
    final parts = value.split(',');
    return parts.length == 2 && double.tryParse(parts[0]) != null && double.tryParse(parts[1]) != null;
  }
}

/// 32-bit mixing hash (chỉ cộng/xoay/xor để chính xác tuyệt đối cả trên web).
@visibleForTesting
String bucketHash(String input) {
  var h = 0x811C9DC5;
  for (final unit in input.codeUnits) {
    h = (h + unit) & 0xFFFFFFFF;
    h = (h ^ (h << 5)) & 0xFFFFFFFF;
    h = (h ^ (h >> 15)) & 0xFFFFFFFF;
    h = (h + unit * 7) & 0xFFFFFFFF;
    h = (h ^ (h << 7)) & 0xFFFFFFFF;
  }
  return h.toRadixString(16).padLeft(8, '0');
}
