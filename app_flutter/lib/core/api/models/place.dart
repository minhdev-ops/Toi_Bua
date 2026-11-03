import '../json.dart';
import 'dish.dart';
import 'score.dart';

class GeoPoint {
  const GeoPoint({required this.lat, required this.lng});

  final double lat;
  final double lng;

  /// Định dạng query `geo` của API: 6 chữ số thập phân (docs/02 §4.3).
  String get wireValue => '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
        lat: asDouble(json, 'lat') ?? 0.0,
        lng: asDouble(json, 'lng') ?? 0.0,
      );

  factory GeoPoint.parse(String raw) {
    final parts = raw.split(',');
    if (parts.length != 2) return const GeoPoint(lat: 0, lng: 0);
    return GeoPoint(
      lat: double.tryParse(parts[0]) ?? 0.0,
      lng: double.tryParse(parts[1]) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class PriceRange {
  const PriceRange({required this.min, required this.max});

  final int min;
  final int max;

  factory PriceRange.fromJson(Map<String, dynamic> json) => PriceRange(
        min: asInt(json, 'min') ?? 0,
        max: asInt(json, 'max') ?? 0,
      );

  Map<String, dynamic> toJson() => {'min': min, 'max': max};
}

/// `OpenStatus` (docs/02 §1.4, FR-PLC-06).
/// App **không** tự tính `o_score`/`closing_soon`: đồng hồ máy sai là đổi xếp hạng.
class OpenStatus {
  const OpenStatus({
    required this.isOpen,
    this.opensAt,
    this.closesAt,
    this.closesInMin,
    required this.closingSoon,
    required this.oScore,
    this.tz,
    this.isExceptionDay = false,
    this.noteKey,
  });

  final bool isOpen;
  final DateTime? opensAt;
  final DateTime? closesAt;
  final int? closesInMin;
  final bool closingSoon;
  final double oScore;
  final String? tz;
  final bool isExceptionDay;
  final String? noteKey;

  factory OpenStatus.fromJson(Map<String, dynamic> json) => OpenStatus(
        isOpen: asBool(json, 'is_open'),
        opensAt: asDate(json, 'opens_at'),
        closesAt: asDate(json, 'closes_at'),
        closesInMin: asInt(json, 'closes_in_min'),
        closingSoon: asBool(json, 'closing_soon'),
        oScore: asDouble(json, 'o_score') ?? 0.0,
        tz: asString(json, 'tz'),
        isExceptionDay: asBool(json, 'is_exception_day'),
        noteKey: asString(json, 'note_key'),
      );

  Map<String, dynamic> toJson() => {
        'is_open': isOpen,
        if (opensAt != null) 'opens_at': opensAt!.toIso8601String(),
        if (closesAt != null) 'closes_at': closesAt!.toIso8601String(),
        if (closesInMin != null) 'closes_in_min': closesInMin,
        'closing_soon': closingSoon,
        'o_score': oScore,
        if (tz != null) 'tz': tz,
        'is_exception_day': isExceptionDay,
        'note_key': noteKey,
      };
}

class SourceInfo {
  const SourceInfo({
    required this.provider,
    this.externalId,
    this.verifiedAt,
    this.dataConfidence,
  });

  final String provider;
  final String? externalId;
  final DateTime? verifiedAt;
  final double? dataConfidence;

  factory SourceInfo.fromJson(Map<String, dynamic> json) => SourceInfo(
        provider: stringOr(json, 'provider'),
        externalId: asString(json, 'external_id'),
        verifiedAt: asDate(json, 'verified_at'),
        dataConfidence: asDouble(json, 'data_confidence'),
      );

  Map<String, dynamic> toJson() => {
        'provider': provider,
        if (externalId != null) 'external_id': externalId,
        if (verifiedAt != null) 'verified_at': verifiedAt!.toIso8601String(),
        if (dataConfidence != null) 'data_confidence': dataConfidence,
      };
}

class Amenities {
  const Amenities({
    this.parking = false,
    this.ac = false,
    this.groupFriendly = false,
    this.takeaway = false,
    this.wifi = false,
  });

  final bool parking;
  final bool ac;
  final bool groupFriendly;
  final bool takeaway;
  final bool wifi;

  factory Amenities.fromJson(Map<String, dynamic> json) => Amenities(
        parking: asBool(json, 'parking'),
        ac: asBool(json, 'ac'),
        groupFriendly: asBool(json, 'group_friendly'),
        takeaway: asBool(json, 'takeaway'),
        wifi: asBool(json, 'wifi'),
      );

  Map<String, dynamic> toJson() => {
        'parking': parking,
        'ac': ac,
        'group_friendly': groupFriendly,
        'takeaway': takeaway,
        'wifi': wifi,
      };
}

/// `images[]` — `credit` bắt buộc render (điều khoản nhà cung cấp, SRS 1.4).
class PlaceImage {
  const PlaceImage({
    required this.url,
    required this.credit,
    required this.source,
    required this.isUserSubmitted,
  });

  final String url;
  final String credit;
  final String source;
  final bool isUserSubmitted;

  factory PlaceImage.fromJson(Map<String, dynamic> json) => PlaceImage(
        url: stringOr(json, 'url'),
        credit: stringOr(json, 'credit'),
        source: stringOr(json, 'source'),
        isUserSubmitted: asBool(json, 'is_user_submitted'),
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'credit': credit,
        'source': source,
        'is_user_submitted': isUserSubmitted,
      };
}

class PlaceHour {
  const PlaceHour({required this.dow, this.opensAt, this.closesAt, this.isClosed = false});

  /// 1 = thứ hai … 7 = chủ nhật.
  final int dow;
  final String? opensAt;
  final String? closesAt;
  final bool isClosed;

  factory PlaceHour.fromJson(Map<String, dynamic> json) => PlaceHour(
        dow: asInt(json, 'dow') ?? 1,
        opensAt: asString(json, 'opens_at'),
        closesAt: asString(json, 'closes_at'),
        isClosed: asBool(json, 'is_closed'),
      );

  Map<String, dynamic> toJson() => {
        'dow': dow,
        if (opensAt != null) 'opens_at': opensAt,
        if (closesAt != null) 'closes_at': closesAt,
        'is_closed': isClosed,
      };
}

class MenuEntry {
  const MenuEntry({
    required this.dishId,
    required this.name,
    required this.priceVnd,
    this.confidence,
    this.popular = false,
  });

  final String dishId;
  final String name;
  final int priceVnd;
  final double? confidence;
  final bool popular;

  factory MenuEntry.fromJson(Map<String, dynamic> json) => MenuEntry(
        dishId: stringOr(json, 'dish_id'),
        name: stringOr(json, 'name'),
        priceVnd: asInt(json, 'price_vnd') ?? 0,
        confidence: asDouble(json, 'confidence'),
        popular: asBool(json, 'popular'),
      );

  Map<String, dynamic> toJson() => {
        'dish_id': dishId,
        'name': name,
        'price_vnd': priceVnd,
        if (confidence != null) 'confidence': confidence,
        'popular': popular,
      };
}

class Menu {
  const Menu({this.dishes = const [], this.source = '', this.updatedAt});

  final List<MenuEntry> dishes;
  final String source;
  final DateTime? updatedAt;

  factory Menu.fromJson(Map<String, dynamic> json) => Menu(
        dishes: asMapList(json, 'dishes').map(MenuEntry.fromJson).toList(growable: false),
        source: stringOr(json, 'source'),
        updatedAt: asDate(json, 'updated_at'),
      );

  Map<String, dynamic> toJson() => {
        'dishes': dishes.map((d) => d.toJson()).toList(),
        'source': source,
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };
}

/// `report_summary` (FR-PLC-07).
class ReportSummary {
  const ReportSummary({
    required this.count30d,
    this.lastKind,
    required this.pending,
    this.canReport = true,
    this.cooldownS = 0,
  });

  final int count30d;
  final String? lastKind;
  final int pending;
  final bool canReport;
  final int cooldownS;

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
        count30d: asInt(json, 'count_30d') ?? 0,
        lastKind: asString(json, 'last_kind'),
        pending: asInt(json, 'pending') ?? 0,
        canReport: asBool(json, 'can_report', true),
        cooldownS: asInt(json, 'cooldown_s') ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'count_30d': count30d,
        if (lastKind != null) 'last_kind': lastKind,
        'pending': pending,
        'can_report': canReport,
        'cooldown_s': cooldownS,
      };
}

class ReviewVerdictSplit {
  const ReviewVerdictSplit({this.good = 0, this.ok = 0, this.bad = 0});

  final int good;
  final int ok;
  final int bad;

  factory ReviewVerdictSplit.fromJson(Map<String, dynamic> json) => ReviewVerdictSplit(
        good: asInt(json, 'good') ?? 0,
        ok: asInt(json, 'ok') ?? 0,
        bad: asInt(json, 'bad') ?? 0,
      );

  Map<String, dynamic> toJson() => {'good': good, 'ok': ok, 'bad': bad};
}

class ReviewsSummary {
  const ReviewsSummary({this.avg = 0, this.count = 0, this.verdictSplit});

  final double avg;
  final int count;
  final ReviewVerdictSplit? verdictSplit;

  factory ReviewsSummary.fromJson(Map<String, dynamic> json) => ReviewsSummary(
        avg: asDouble(json, 'avg') ?? 0,
        count: asInt(json, 'count') ?? 0,
        verdictSplit: json['verdict_split'] is Map<String, dynamic>
            ? ReviewVerdictSplit.fromJson(asMap(json, 'verdict_split'))
            : null,
      );

  Map<String, dynamic> toJson() => {
        'avg': avg,
        'count': count,
        if (verdictSplit != null) 'verdict_split': verdictSplit!.toJson(),
      };
}

class SimilarPlace {
  const SimilarPlace({required this.id, required this.name, required this.distanceM});

  final String id;
  final String name;
  final int distanceM;

  factory SimilarPlace.fromJson(Map<String, dynamic> json) => SimilarPlace(
        id: stringOr(json, 'id'),
        name: stringOr(json, 'name'),
        distanceM: asInt(json, 'distance_m') ?? 0,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'distance_m': distanceM};
}

/// `Place` DTO — một class cho cả list shape và detail shape (docs/02 §1.4).
/// Field chỉ có ở detail mang `null` khi response là list.
class Place {
  const Place({
    required this.id,
    required this.name,
    this.nameEn,
    required this.address,
    required this.geo,
    this.travelMode,
    required this.distanceM,
    this.walkMinutes,
    this.priceLevel,
    this.priceRangeVnd,
    required this.avgPriceVnd,
    required this.ratingRaw,
    required this.ratingBayesian,
    required this.reviewCount,
    this.openStatus,
    this.cuisineTags = const [],
    this.dishHighlights = const [],
    this.source,
    this.badges = const [],
    this.isSponsored = false,
    this.naturalRank,
    this.scoreBreakdown,
    this.why,
    this.amenities,
    this.phoneE164,
    this.bookingUrl,
    this.deliveryUrl,
    this.images = const [],
    this.hoursByDow = const [],
    this.hoursExceptions = const [],
    this.menu,
    this.reviews,
    this.reportSummary,
    this.similarPlaces = const [],
  });

  final String id;
  final String name;
  final String? nameEn;
  final String address;
  final GeoPoint geo;
  final String? travelMode;
  final int distanceM;
  final int? walkMinutes;
  final int? priceLevel;
  final PriceRange? priceRangeVnd;
  final int avgPriceVnd;

  /// Trung bình thô — chỉ hiện trong tooltip (FR-REC-03).
  final double ratingRaw;

  /// Số hiển thị trong UI.
  final double ratingBayesian;
  final int reviewCount;
  final OpenStatus? openStatus;
  final List<String> cuisineTags;
  final List<DishHighlight> dishHighlights;
  final SourceInfo? source;
  final List<String> badges;

  /// P3, luôn `false` ở P1. `true` ⇒ tem `QUẢNG CÁO` + `naturalRank`, **không** đổi thứ tự.
  final bool isSponsored;
  final int? naturalRank;
  final ScoreBreakdown? scoreBreakdown;
  final WhyPayload? why;
  final Amenities? amenities;
  final String? phoneE164;
  final String? bookingUrl;
  final String? deliveryUrl;
  final List<PlaceImage> images;
  final List<PlaceHour> hoursByDow;
  final List<Map<String, dynamic>> hoursExceptions;
  final Menu? menu;
  final ReviewsSummary? reviews;
  final ReportSummary? reportSummary;
  final List<SimilarPlace> similarPlaces;

  bool get hasDetail => menu != null || hoursByDow.isNotEmpty || images.isNotEmpty;

  /// `dish_highlights[0]` cho hue tem khi ảnh vắng (DESIGN.md §Iconography).
  String? get highlightTypeSeed => dishHighlights.isEmpty ? null : dishHighlights.first.name;

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: stringOr(json, 'id'),
        name: stringOr(json, 'name'),
        nameEn: asString(json, 'name_en'),
        address: stringOr(json, 'address'),
        geo: json['geo'] is Map<String, dynamic> ? GeoPoint.fromJson(asMap(json, 'geo')) : const GeoPoint(lat: 0, lng: 0),
        travelMode: asString(json, 'travel_mode'),
        distanceM: asInt(json, 'distance_m') ?? 0,
        walkMinutes: asInt(json, 'walk_minutes'),
        priceLevel: asInt(json, 'price_level'),
        priceRangeVnd: json['price_range_vnd'] is Map<String, dynamic>
            ? PriceRange.fromJson(asMap(json, 'price_range_vnd'))
            : null,
        avgPriceVnd: asInt(json, 'avg_price_vnd') ?? 0,
        ratingRaw: asDouble(json, 'rating_raw') ?? 0.0,
        ratingBayesian: asDouble(json, 'rating_bayesian') ?? 0.0,
        reviewCount: asInt(json, 'review_count') ?? 0,
        openStatus: json['open_status'] is Map<String, dynamic>
            ? OpenStatus.fromJson(asMap(json, 'open_status'))
            : null,
        cuisineTags: asStringList(json, 'cuisine_tags'),
        dishHighlights: asMapList(json, 'dish_highlights').map(DishHighlight.fromJson).toList(growable: false),
        source: json['source'] is Map<String, dynamic> ? SourceInfo.fromJson(asMap(json, 'source')) : null,
        badges: asStringList(json, 'badges'),
        isSponsored: asBool(json, 'is_sponsored'),
        naturalRank: asInt(json, 'natural_rank'),
        scoreBreakdown: json['score_breakdown'] is Map<String, dynamic>
            ? ScoreBreakdown.fromJson(asMap(json, 'score_breakdown'))
            : null,
        why: json['why'] is Map<String, dynamic> ? WhyPayload.fromJson(asMap(json, 'why')) : null,
        amenities: json['amenities'] is Map<String, dynamic> ? Amenities.fromJson(asMap(json, 'amenities')) : null,
        phoneE164: asString(json, 'phone_e164') ?? asString(asMap(json, 'contact'), 'phone_e164'),
        bookingUrl: asString(json, 'booking_url') ?? asString(asMap(json, 'contact'), 'booking_url'),
        deliveryUrl: asString(json, 'delivery_url') ?? asString(asMap(json, 'contact'), 'delivery_url'),
        images: asMapList(json, 'images').map(PlaceImage.fromJson).toList(growable: false),
        hoursByDow: asMapList(json, 'hours_by_dow').map(PlaceHour.fromJson).toList(growable: false),
        hoursExceptions: asMapList(json, 'hours_exceptions'),
        menu: json['menu'] is Map<String, dynamic> ? Menu.fromJson(asMap(json, 'menu')) : null,
        reviews: json['reviews'] is Map<String, dynamic>
            ? ReviewsSummary.fromJson(asMap(asMap(json, 'reviews'), 'summary'))
            : null,
        reportSummary: json['report_summary'] is Map<String, dynamic>
            ? ReportSummary.fromJson(asMap(json, 'report_summary'))
            : null,
        similarPlaces: asMapList(json, 'similar_places').map(SimilarPlace.fromJson).toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (nameEn != null) 'name_en': nameEn,
        'address': address,
        'geo': geo.toJson(),
        if (travelMode != null) 'travel_mode': travelMode,
        'distance_m': distanceM,
        'walk_minutes': walkMinutes,
        if (priceLevel != null) 'price_level': priceLevel,
        if (priceRangeVnd != null) 'price_range_vnd': priceRangeVnd!.toJson(),
        'avg_price_vnd': avgPriceVnd,
        'rating_raw': ratingRaw,
        'rating_bayesian': ratingBayesian,
        'review_count': reviewCount,
        if (openStatus != null) 'open_status': openStatus!.toJson(),
        'cuisine_tags': cuisineTags,
        'dish_highlights': dishHighlights.map((d) => d.toJson()).toList(),
        if (source != null) 'source': source!.toJson(),
        'badges': badges,
        'is_sponsored': isSponsored,
        if (naturalRank != null) 'natural_rank': naturalRank,
        if (scoreBreakdown != null) 'score_breakdown': scoreBreakdown!.toJson(),
        if (why != null) 'why': why!.toJson(),
        if (amenities != null) 'amenities': amenities!.toJson(),
        'phone_e164': phoneE164,
        'booking_url': bookingUrl,
        'delivery_url': deliveryUrl,
        'images': images.map((i) => i.toJson()).toList(),
        'hours_by_dow': hoursByDow.map((h) => h.toJson()).toList(),
        'hours_exceptions': hoursExceptions,
        if (menu != null) 'menu': menu!.toJson(),
        if (reviews != null) 'reviews': {'summary': reviews!.toJson()},
        if (reportSummary != null) 'report_summary': reportSummary!.toJson(),
        'similar_places': similarPlaces.map((s) => s.toJson()).toList(),
      };
}
