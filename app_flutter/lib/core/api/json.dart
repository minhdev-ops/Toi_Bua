/// Helper đọc JSON yếu: server có thể vắng field ở một số endpoint
/// (`score_breakdown` chỉ có khi `sort=score`, `amenities` chỉ ở detail).
library;

String? asString(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is String ? value : null;
}

String stringOr(Map<String, dynamic> json, String key, [String fallback = '']) {
  return asString(json, key) ?? fallback;
}

int? asInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

double? asDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.'));
  return null;
}

bool asBool(Map<String, dynamic> json, String key, [bool fallback = false]) {
  final value = json[key];
  if (value is bool) return value;
  return fallback;
}

List<String> asStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is List) return value.whereType<String>().toList(growable: false);
  return const [];
}

List<Map<String, dynamic>> asMapList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is List) return value.whereType<Map<String, dynamic>>().toList(growable: false);
  return const [];
}

Map<String, dynamic> asMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) return value;
  return const {};
}

Map<String, String> asStringMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) return const {};
  return value.map((k, v) => MapEntry('$k', '$v'));
}

Map<String, double> asDoubleMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) return const {};
  final out = <String, double>{};
  value.forEach((k, v) {
    if (v is num) out['$k'] = v.toDouble();
  });
  return out;
}

/// `filter_dimensions` trộn string (`"hot"`) và int (`1500`) trong cùng một list.
List<String> scalarsToStrings(List value) => value.where((e) => e != null).map((e) {
      if (e is double) return e == e.roundToDouble() ? e.round().toString() : '$e';
      return '$e';
    }).toList(growable: false);

List<String> scalarList(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is List ? scalarsToStrings(value) : const [];
}

Map<String, int> asIntMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) return const {};
  final out = <String, int>{};
  value.forEach((k, v) {
    if (v is num) out['$k'] = v.round();
  });
  return out;
}

/// Scalar in thẳng ra UI: `relaxation.steps_available[].from/to` có thể là
/// int (`1500`) hoặc enum string (`"cold"`). Số nguyên không được in thành `1500.0`.
String scalarText(Map<String, dynamic> json, String key, [String fallback = '']) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is int) return '$value';
  if (value is double) return value == value.roundToDouble() ? value.round().toString() : '$value';
  return '$value';
}

DateTime? asDate(Map<String, dynamic> json, String key) {
  final raw = asString(json, key);
  if (raw == null) return null;
  return DateTime.tryParse(raw)?.toUtc();
}
