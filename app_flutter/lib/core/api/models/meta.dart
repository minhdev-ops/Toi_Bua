import '../json.dart';
import 'data_quality.dart';

/// `meta` dùng chung mọi response (docs/02 §1.3, §4.3, §4.4, §4.5).
/// `latency_ms` là int ở `/places/urgent` và object ở `/matches` ⇒ cả hai field.
class ResponseMeta {
  const ResponseMeta({
    this.dataQuality = DataQuality.fresh,
    this.personalizationUsed,
    this.experimentArms = const {},
    this.providersUsed = const [],
    this.formulaVersion,
    this.candidateCount,
    this.returned,
    this.latencyMs,
    this.latency,
    this.cacheAgeS,
    this.generatedAt,
  });

  final DataQuality dataQuality;
  final bool? personalizationUsed;
  final Map<String, String> experimentArms;
  final List<String> providersUsed;
  final String? formulaVersion;
  final int? candidateCount;
  final int? returned;
  final int? latencyMs;
  final LatencyBreakdown? latency;
  final int? cacheAgeS;
  final DateTime? generatedAt;

  static const ResponseMeta fresh = ResponseMeta();

  /// Header `X-Data-Quality` là bản chỉnh sửa cuối của `meta.data_quality`.
  ResponseMeta copyWith({DataQuality? dataQuality}) => ResponseMeta(
        dataQuality: dataQuality ?? this.dataQuality,
        personalizationUsed: personalizationUsed,
        experimentArms: experimentArms,
        providersUsed: providersUsed,
        formulaVersion: formulaVersion,
        candidateCount: candidateCount,
        returned: returned,
        latencyMs: latencyMs,
        latency: latency,
        cacheAgeS: cacheAgeS,
        generatedAt: generatedAt,
      );

  factory ResponseMeta.fromJson(Map<String, dynamic> json) {
    final rawLatency = json['latency_ms'];
    return ResponseMeta(
      dataQuality: DataQuality.parse(asString(json, 'data_quality')),
      personalizationUsed: json['personalization_used'] is bool ? json['personalization_used'] as bool : null,
      experimentArms: asStringMap(json, 'experiment_arms'),
      providersUsed: asStringList(json, 'providers_used'),
      formulaVersion: asString(json, 'formula_version'),
      candidateCount: asInt(json, 'candidate_count'),
      returned: asInt(json, 'returned'),
      latencyMs: rawLatency is int ? rawLatency : null,
      latency: rawLatency is Map<String, dynamic> ? LatencyBreakdown.fromJson(rawLatency) : null,
      cacheAgeS: asInt(json, 'cache_age_s'),
      generatedAt: asDate(json, 'generated_at'),
    );
  }

  Map<String, dynamic> toJson() => {
        'data_quality': dataQuality.wireValue,
        if (personalizationUsed != null) 'personalization_used': personalizationUsed,
        if (experimentArms.isNotEmpty) 'experiment_arms': experimentArms,
        if (providersUsed.isNotEmpty) 'providers_used': providersUsed,
        if (formulaVersion != null) 'formula_version': formulaVersion,
        if (candidateCount != null) 'candidate_count': candidateCount,
        if (returned != null) 'returned': returned,
        if (latencyMs != null) 'latency_ms': latencyMs,
        if (latency != null) 'latency_ms': latency!.toJson(),
        if (cacheAgeS != null) 'cache_age_s': cacheAgeS,
        if (generatedAt != null) 'generated_at': generatedAt!.toIso8601String(),
      };
}

class LatencyBreakdown {
  const LatencyBreakdown({this.total = 0, this.db = 0, this.provider = 0, this.scoring = 0});

  final int total;
  final int db;
  final int provider;
  final int scoring;

  factory LatencyBreakdown.fromJson(Map<String, dynamic> json) => LatencyBreakdown(
        total: asInt(json, 'total') ?? 0,
        db: asInt(json, 'db') ?? 0,
        provider: asInt(json, 'provider') ?? 0,
        scoring: asInt(json, 'scoring') ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'total': total,
        'db': db,
        'provider': provider,
        'scoring': scoring,
      };
}

/// `page` cho mọi response dạng list (docs/02 §1.3). Con trỏ opaque, server ký.
class Page {
  const Page({this.nextCursor, this.hasMore = false, this.totalEstimate});

  final String? nextCursor;
  final bool hasMore;
  final int? totalEstimate;

  factory Page.fromJson(Map<String, dynamic> json) => Page(
        nextCursor: asString(json, 'next_cursor'),
        hasMore: asBool(json, 'has_more'),
        totalEstimate: asInt(json, 'total_estimate'),
      );

  Map<String, dynamic> toJson() => {
        'next_cursor': nextCursor,
        'has_more': hasMore,
        if (totalEstimate != null) 'total_estimate': totalEstimate,
      };
}
