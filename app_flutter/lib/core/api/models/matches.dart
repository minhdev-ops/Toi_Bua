import '../json.dart';
import 'dish.dart';
import 'meta.dart';
import 'place.dart';
import 'spin.dart';

/// Một trong ba nguồn vị trí: `geo` | `user_location_id` | `address` (docs/02 §4.3).
/// App **không** bao giờ gửi cả ba cùng lúc.
class GeoSource {
  const GeoSource.geo(this.point)
      : userId = null,
        address = null;
  const GeoSource.locationId(this.userId)
      : point = null,
        address = null;
  const GeoSource.named(this.address)
      : point = null,
        userId = null;

  const GeoSource.none()
      : point = null,
        userId = null,
        address = null;

  final GeoPoint? point;
  final String? userId;
  final String? address;

  bool get isPresent => point != null || userId != null || address != null;

  /// Body dạng JSON (`POST /v1/matches`).
  Map<String, dynamic> toJson() => {
        'geo': ?point?.wireValue,
        'user_location_id': ?userId,
        'address': ?address,
      };

  /// Query string (`GET /v1/places/nearby`, `/urgent`).
  Map<String, String> toQuery() => {
        'geo': ?point?.wireValue,
        'user_location_id': ?userId,
        'address': ?address,
      };
}

/// Input `POST /v1/matches` (docs/02 §4.4). App gọi bằng `next.suggested_body`
/// của spin, **không** tự assemble khi server đã gửi body.
class MatchRequest {
  const MatchRequest({
    this.dishId,
    this.dishIds = const [],
    this.spinId,
    this.geo = const GeoSource.none(),
    this.radiusM,
    this.limit,
    this.filters,
    this.diet,
    this.travelMode,
    this.excludePlaceIds = const [],
    this.includeClosed = false,
    this.personalization = true,
  });

  final String? dishId;
  final List<String> dishIds;
  final String? spinId;
  final GeoSource geo;
  final int? radiusM;
  final int? limit;
  final SpinFilters? filters;
  final SpinDiet? diet;

  /// `walk | bike | car`
  final String? travelMode;
  final List<String> excludePlaceIds;
  final bool includeClosed;

  /// `false` = tắt thành phần U (FR-REC-06) — server bỏ, app không tự tính.
  final bool personalization;

  Map<String, dynamic> toJson() => {
        if (dishId != null) 'dish_id': dishId,
        if (dishIds.isNotEmpty) 'dish_ids': dishIds,
        if (spinId != null) 'spin_id': spinId,
        ...geo.toJson(),
        if (radiusM != null) 'radius_m': radiusM,
        if (limit != null) 'limit': limit,
        if (filters != null && !filters!.isEmpty) 'filters': filters!.toJson(),
        if (diet != null && diet!.isNotEmpty) 'diet': diet!.toJson(),
        if (travelMode != null) 'travel_mode': travelMode,
        if (excludePlaceIds.isNotEmpty) 'exclude_place_ids': excludePlaceIds,
        'include_closed': includeClosed,
        'personalization': personalization,
      };

  factory MatchRequest.fromJson(Map<String, dynamic> json) => MatchRequest(
        dishId: asString(json, 'dish_id'),
        dishIds: asStringList(json, 'dish_ids'),
        spinId: asString(json, 'spin_id'),
        geo: json['geo'] is String
            ? GeoSource.geo(GeoPoint.parse(json['geo'] as String))
            : json['user_location_id'] != null
                ? GeoSource.locationId(stringOr(json, 'user_location_id'))
                : GeoSource.named(asString(json, 'address')),
        radiusM: asInt(json, 'radius_m'),
        limit: asInt(json, 'limit'),
        filters: json['filters'] is Map<String, dynamic> ? SpinFilters.fromJson(json['filters'] as Map<String, dynamic>) : null,
        diet: json['diet'] is Map<String, dynamic> ? SpinDiet.fromJson(json['diet'] as Map<String, dynamic>) : null,
        travelMode: asString(json, 'travel_mode'),
        excludePlaceIds: asStringList(json, 'exclude_place_ids'),
        includeClosed: asBool(json, 'include_closed'),
        personalization: asBool(json, 'personalization', true),
      );
}

/// `relaxation.steps_available[]` — mỗi bước là một `StampChip` bấm được.
class RelaxationStep {
  const RelaxationStep({
    required this.dimension,
    required this.from,
    required this.to,
    required this.expectedExtra,
    this.whyKey,
    this.toValue,
  });

  final String dimension;
  final String from;
  final String to;
  final int expectedExtra;

  /// `relax.radius`, `relax.price`… ⇒ render qua ARB, không hiển thị chuỗi thô.
  final String? whyKey;

  /// `to` trên wire, giữ nguyên kiểu (int/double/List). `to`/`from` chỉ để hiển thị —
  /// gửi lại `radius_m: "2500"` là sai kiểu ở docs/02 §4.4 nên body phải dùng field này.
  final Object? toValue;

  factory RelaxationStep.fromJson(Map<String, dynamic> json) => RelaxationStep(
        dimension: stringOr(json, 'dimension'),
        from: scalarText(json, 'from', '—'),
        to: scalarText(json, 'to', '—'),
        expectedExtra: asInt(json, 'expected_extra') ?? 0,
        whyKey: asString(json, 'why_key'),
        toValue: json['to'],
      );

  Map<String, dynamic> toJson() => {
        'dimension': dimension,
        'from': from,
        'to': toValue ?? to,
        'expected_extra': expectedExtra,
        if (whyKey != null) 'why_key': whyKey,
      };
}

class Relaxation {
  const Relaxation({this.applied = false, this.stepsAvailable = const []});

  final bool applied;
  final List<RelaxationStep> stepsAvailable;

  /// `items == []` ⇒ `steps_available` **không được rỗng** (FR-REC-05).
  bool get canOfferMore => stepsAvailable.isNotEmpty;

  factory Relaxation.fromJson(Map<String, dynamic> json) => Relaxation(
        applied: asBool(json, 'applied'),
        stepsAvailable: asMapList(json, 'steps_available').map(RelaxationStep.fromJson).toList(growable: false),
      );
}

class SubstituteDish {
  const SubstituteDish({required this.id, required this.name, required this.similarity, this.reasonKey});

  final String id;
  final String name;
  final double similarity;
  final String? reasonKey;

  factory SubstituteDish.fromJson(Map<String, dynamic> json) => SubstituteDish(
        id: stringOr(json, 'id'),
        name: stringOr(json, 'name'),
        similarity: asDouble(json, 'similarity') ?? 0.0,
        reasonKey: asString(json, 'reason_key'),
      );
}

/// `context_used` — P2, ẩn ở P1 (spec UC-01 §2).
class ContextUsed {
  const ContextUsed({
    this.localTime,
    this.dow,
    this.weather,
    this.monthEnd = false,
    this.weightOverrides = const {},
  });

  final String? localTime;
  final String? dow;
  final String? weather;
  final bool monthEnd;
  final Map<String, double> weightOverrides;

  factory ContextUsed.fromJson(Map<String, dynamic> json) => ContextUsed(
        localTime: asString(json, 'local_time'),
        dow: asString(json, 'dow'),
        weather: asString(json, 'weather'),
        monthEnd: asBool(json, 'month_end'),
        weightOverrides: asDoubleMap(json, 'weight_overrides'),
      );
}

/// Output `POST /v1/matches`. `items` giữ **đúng thứ tự server trả** — cấm sort lại.
class MatchResponse {
  const MatchResponse({
    required this.dish,
    required this.items,
    this.relaxation,
    this.substituteDishes = const [],
    this.contextUsed,
    this.meta = ResponseMeta.fresh,
  });

  final Dish dish;
  final List<Place> items;
  final Relaxation? relaxation;
  final List<SubstituteDish> substituteDishes;
  final ContextUsed? contextUsed;
  final ResponseMeta meta;

  bool get isEmpty => items.isEmpty;

  factory MatchResponse.fromJson(Map<String, dynamic> json) => MatchResponse(
        dish: Dish.fromJson(asMap(json, 'dish')),
        items: asMapList(json, 'items').map(Place.fromJson).toList(growable: false),
        relaxation: json['relaxation'] is Map<String, dynamic> ? Relaxation.fromJson(json['relaxation'] as Map<String, dynamic>) : null,
        substituteDishes: asMapList(json, 'substitute_dishes').map(SubstituteDish.fromJson).toList(growable: false),
        contextUsed: json['context_used'] is Map<String, dynamic> ? ContextUsed.fromJson(json['context_used'] as Map<String, dynamic>) : null,
        meta: ResponseMeta.fromJson(asMap(json, 'meta')),
      );
}

/// `context` của `GET /v1/places/nearby` (docs/02 §4.3): anchor server đã dùng.
class ListContext {
  const ListContext({
    this.anchorLabel,
    this.anchorGeo,
    this.radiusM,
    this.requestedDishIds = const [],
    this.now,
  });

  final String? anchorLabel;
  final GeoPoint? anchorGeo;
  final int? radiusM;
  final List<String> requestedDishIds;
  final DateTime? now;

  factory ListContext.fromJson(Map<String, dynamic> json) {
    final anchor = asMap(json, 'anchor');
    return ListContext(
      anchorLabel: asString(anchor, 'label'),
      anchorGeo: anchor['geo'] is Map<String, dynamic> ? GeoPoint.fromJson(anchor['geo'] as Map<String, dynamic>) : null,
      radiusM: asInt(json, 'radius_m'),
      requestedDishIds: asStringList(json, 'requested_dish_ids'),
      now: asDate(json, 'now'),
    );
  }
}

/// Cluster pin cho `view=map` — app **không** tự tính clustering.
class PlaceCluster {
  const PlaceCluster({
    required this.geohash,
    required this.count,
    required this.centerGeo,
    this.topItemIds = const [],
    this.expandCursor,
  });

  final String geohash;
  final int count;
  final GeoPoint centerGeo;
  final List<String> topItemIds;
  final String? expandCursor;

  factory PlaceCluster.fromJson(Map<String, dynamic> json) => PlaceCluster(
        geohash: stringOr(json, 'geohash'),
        count: asInt(json, 'count') ?? 0,
        centerGeo: GeoPoint.fromJson(asMap(json, 'center_geo')),
        topItemIds: asStringList(json, 'top_item_ids'),
        expandCursor: asString(json, 'expand_cursor'),
      );
}

/// Output `GET /v1/places/nearby` (S9 `DiscoverListScreen`).
class NearbyResponse {
  const NearbyResponse({
    required this.items,
    this.page,
    this.context,
    this.clusters = const [],
    this.relaxation,
    this.meta = ResponseMeta.fresh,
  });

  final List<Place> items;
  final Page? page;
  final ListContext? context;
  final List<PlaceCluster> clusters;
  final Relaxation? relaxation;
  final ResponseMeta meta;

  bool get hasMore => page?.hasMore ?? false;

  factory NearbyResponse.fromJson(Map<String, dynamic> json) => NearbyResponse(
        items: asMapList(json, 'items').map(Place.fromJson).toList(growable: false),
        page: json['page'] is Map<String, dynamic> ? Page.fromJson(json['page'] as Map<String, dynamic>) : null,
        context: json['context'] is Map<String, dynamic> ? ListContext.fromJson(json['context'] as Map<String, dynamic>) : null,
        clusters: asMapList(json, 'clusters').map(PlaceCluster.fromJson).toList(growable: false),
        relaxation: json['relaxation'] is Map<String, dynamic> ? Relaxation.fromJson(json['relaxation'] as Map<String, dynamic>) : null,
        meta: ResponseMeta.fromJson(asMap(json, 'meta')),
      );
}
