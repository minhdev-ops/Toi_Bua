import '../json.dart';

/// `ScoreBreakdown` (docs/02 §1.4, FR-REC-02).
/// App chỉ vẽ, **không** tự tính: mọi con số ở đây là của server.
class ScoreBreakdown {
  const ScoreBreakdown({
    required this.formulaVersion,
    required this.weights,
    required this.scoreTotal,
    required this.components,
    this.penalty,
    this.topComponent,
  });

  final String formulaVersion;
  final Map<String, double> weights;
  final double scoreTotal;
  final List<ScoreComponent> components;
  final Penalty? penalty;
  final String? topComponent;

  Iterable<ScoreComponent> get topComponents => components.where((c) => c.top);

  /// `TC-REC-02-A2`: Σ contribution − penalty.total == score_total, ±0.01.
  bool get arithmeticHolds {
    final sum = components.fold<double>(0, (acc, c) => acc + c.contribution);
    final expected = sum - (penalty?.total ?? 0.0);
    return (expected - scoreTotal).abs() <= 0.01;
  }

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) => ScoreBreakdown(
        formulaVersion: stringOr(json, 'formula_version'),
        weights: asDoubleMap(json, 'weights'),
        scoreTotal: asDouble(json, 'score_total') ?? 0.0,
        components: asMapList(json, 'components').map(ScoreComponent.fromJson).toList(growable: false),
        penalty: json['penalty'] is Map<String, dynamic> ? Penalty.fromJson(asMap(json, 'penalty')) : null,
        topComponent: asString(json, 'top_component'),
      );

  Map<String, dynamic> toJson() => {
        'formula_version': formulaVersion,
        'weights': weights,
        'score_total': scoreTotal,
        'components': components.map((c) => c.toJson()).toList(),
        if (penalty != null) 'penalty': penalty!.toJson(),
        if (topComponent != null) 'top_component': topComponent,
      };
}

class ScoreComponent {
  const ScoreComponent({
    required this.key,
    required this.label,
    required this.valueNorm,
    required this.contribution,
    this.top = false,
    this.facts = const {},
    this.whyKey,
    this.whyParams = const {},
  });

  /// `Q | D | P | O | U`
  final String key;

  /// Chuỗi server gửi cho log/debug; UI hiển thị qua `why_key` + ARB.
  final String label;
  final double valueNorm;
  final double contribution;
  final bool top;
  final Map<String, Object?> facts;
  final String? whyKey;
  final Map<String, String> whyParams;

  factory ScoreComponent.fromJson(Map<String, dynamic> json) => ScoreComponent(
        key: stringOr(json, 'key'),
        label: stringOr(json, 'label'),
        valueNorm: asDouble(json, 'value_norm') ?? 0.0,
        contribution: asDouble(json, 'contribution') ?? 0.0,
        top: asBool(json, 'top'),
        facts: json['facts'] is Map ? Map<String, Object?>.from(json['facts'] as Map) : const {},
        whyKey: asString(json, 'why_key'),
        whyParams: asStringMap(json, 'why_params'),
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'value_norm': valueNorm,
        'contribution': contribution,
        'top': top,
        if (facts.isNotEmpty) 'facts': facts,
        if (whyKey != null) 'why_key': whyKey,
        'why_params': whyParams,
      };
}

class Penalty {
  const Penalty({required this.total, this.items = const []});

  final double total;
  final List<PenaltyItem> items;

  factory Penalty.fromJson(Map<String, dynamic> json) => Penalty(
        total: asDouble(json, 'total') ?? 0.0,
        items: asMapList(json, 'items').map(PenaltyItem.fromJson).toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'total': total,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

class PenaltyItem {
  const PenaltyItem({required this.reason, this.days, required this.value});

  /// `stale_verification | low_data_confidence | reported`
  final String reason;
  final int? days;
  final double value;

  factory PenaltyItem.fromJson(Map<String, dynamic> json) => PenaltyItem(
        reason: stringOr(json, 'reason'),
        days: asInt(json, 'days'),
        value: asDouble(json, 'value') ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        'reason': reason,
        if (days != null) 'days': days,
        'value': value,
      };
}

/// `why{headline, bullets[], key, params}` (FR-REC-02).
/// Có `key` ⇒ render qua ARB, **không** hiển thị `headline` raw của server.
class WhyPayload {
  const WhyPayload({
    required this.headline,
    this.bullets = const [],
    this.key,
    this.params = const {},
  });

  final String headline;
  final List<String> bullets;
  final String? key;
  final Map<String, String> params;

  factory WhyPayload.fromJson(Map<String, dynamic> json) => WhyPayload(
        headline: stringOr(json, 'headline'),
        bullets: asStringList(json, 'bullets'),
        key: asString(json, 'key'),
        params: asStringMap(json, 'params'),
      );

  Map<String, dynamic> toJson() => {
        'headline': headline,
        'bullets': bullets,
        if (key != null) 'key': key,
        'params': params,
      };
}
