import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/models/place.dart';
import '../api/models/matches.dart';

/// Vị trí app đang dùng làm anchor cho mọi query quán.
/// Ba dạng đúng như docs/02 §4.3: `geo` | `user_location_id` | `address` — **một trong ba**.
class Anchor {
  const Anchor({this.address, this.userLocationId, this.point, this.label});

  final String? address;
  final String? userLocationId;
  final GeoPoint? point;
  final String? label;

  bool get isEmpty => address == null && userLocationId == null && point == null;

  GeoSource get source {
    if (point != null) return GeoSource.geo(point!);
    if (userLocationId != null) return GeoSource.locationId(userLocationId!);
    if (address != null) return GeoSource.named(address!);
    return const GeoSource.none();
  }

  /// Nhãn ngắn cho UI ("Nhà", "Cơ quan", hoặc chính địa chỉ).
  String get displayLabel => label ?? address ?? '';

  Map<String, dynamic> toJson() => {
        'address': ?address,
        'user_location_id': ?userLocationId,
        'label': ?label,
        'point': ?point?.toJson(),
      };

  factory Anchor.fromJson(Map<String, dynamic> json) {
    final rawPoint = json['point'];
    return Anchor(
      address: json['address'] as String?,
      userLocationId: json['user_location_id'] as String?,
      label: json['label'] as String?,
      point: rawPoint is Map<String, dynamic> ? GeoPoint.fromJson(rawPoint) : null,
    );
  }
}

/// Anchor hiện hành, persist máy-local (GPS/permission là việc của `LocationService`;
/// store này chỉ giữ cái mà user đã chọn hoặc đã nhập).
class AnchorStore {
  AnchorStore(this._prefs);

  static const String _kAnchor = 'angi.anchor.current';

  final SharedPreferences _prefs;

  Anchor read() {
    final raw = _prefs.getString(_kAnchor);
    if (raw == null || raw.isEmpty) return const Anchor();
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? Anchor.fromJson(decoded) : const Anchor();
    } on FormatException catch (_) {
      _prefs.remove(_kAnchor);
      return const Anchor();
    }
  }

  Future<void> write(Anchor anchor) async {
    if (anchor.isEmpty) {
      await _prefs.remove(_kAnchor);
      return;
    }
    await _prefs.setString(_kAnchor, jsonEncode(anchor.toJson()));
  }
}
