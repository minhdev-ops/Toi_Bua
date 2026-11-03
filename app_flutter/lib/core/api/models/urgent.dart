import '../json.dart';
import 'dish.dart';
import 'meta.dart';
import 'place.dart';

/// `decision.one_tap_action` — `navigate` ⇒ **nút duy nhất** trên StampCard là `Chỉ đường`.
enum OneTapAction { navigate, browse, none }

OneTapAction oneTapFromApi(String? raw) {
  switch (raw) {
    case 'navigate':
      return OneTapAction.navigate;
    case 'browse':
      return OneTapAction.browse;
    default:
      return OneTapAction.none;
  }
}

class UrgentDecision {
  const UrgentDecision({
    required this.radiusMUsed,
    required this.expanded,
    required this.candidatesConsidered,
    required this.oneTapAction,
    this.fallbackDish,
    this.notifyKey,
  });

  final int radiusMUsed;

  /// `true` ⇒ server đã tự nới theo `config.place.urgent_radius_steps`.
  final bool expanded;
  final int candidatesConsidered;
  final OneTapAction oneTapAction;

  /// Tem phụ "Hợp món bạn vừa quay".
  final Dish? fallbackDish;

  /// `urgent.none_open` khi `place == null`.
  final String? notifyKey;

  factory UrgentDecision.fromJson(Map<String, dynamic> json) {
    final fallback = asMap(json, 'fallback_dish');
    return UrgentDecision(
      radiusMUsed: asInt(json, 'radius_m_used') ?? 0,
      expanded: asBool(json, 'expanded'),
      candidatesConsidered: asInt(json, 'candidates_considered') ?? 0,
      oneTapAction: oneTapFromApi(asString(json, 'one_tap_action')),
      fallbackDish: fallback.isEmpty ? null : Dish.fromJson(fallback),
      notifyKey: asString(json, 'notify_key'),
    );
  }
}

/// `alternatives[]` — render từ `why_key` + `why_params`, không hiển thị chuỗi thô.
class UrgentAlternative {
  const UrgentAlternative({
    required this.id,
    required this.name,
    required this.whyKey,
    this.whyParams = const {},
  });

  final String id;
  final String name;
  final String whyKey;
  final Map<String, String> whyParams;

  factory UrgentAlternative.fromJson(Map<String, dynamic> json) => UrgentAlternative(
        id: stringOr(json, 'id'),
        name: stringOr(json, 'name'),
        whyKey: stringOr(json, 'why_key'),
        whyParams: asStringMap(json, 'why_params'),
      );
}

/// Output `GET /v1/places/urgent` (docs/02 §4.5).
/// `place == null` **vẫn là 200**: không phải lỗi, luồng một chạm không được chết.
class UrgentResponse {
  const UrgentResponse({
    this.place,
    required this.decision,
    this.alternatives = const [],
    this.openStatus,
    this.meta = ResponseMeta.fresh,
  });

  final Place? place;
  final UrgentDecision decision;
  final List<UrgentAlternative> alternatives;

  /// Server gửi riêng để app đọc được trạng thái mở cả khi `place == null`.
  final OpenStatus? openStatus;
  final ResponseMeta meta;

  bool get hasPlace => place != null;

  factory UrgentResponse.fromJson(Map<String, dynamic> json) {
    final placeJson = json['place'];
    final statusJson = json['open_status'];
    return UrgentResponse(
      place: placeJson is Map<String, dynamic> ? Place.fromJson(placeJson) : null,
      decision: UrgentDecision.fromJson(asMap(json, 'decision')),
      alternatives: asMapList(json, 'alternatives').map(UrgentAlternative.fromJson).toList(growable: false),
      openStatus: statusJson is Map<String, dynamic> ? OpenStatus.fromJson(statusJson) : null,
      meta: ResponseMeta.fromJson(asMap(json, 'meta')),
    );
  }
}
