import '../../../core/api/dio_client.dart';
import '../../../core/api/models/matches.dart';
import '../../../core/api/models/spin.dart';

/// Bước 2 của UC-01: gọi **đúng** `next.path` + `next.suggested_body` server gửi
/// (spec §Step 1). Client chỉ được chèn thêm vị trí, không tự assemble `dish_id`/`limit`.
class MatchesRepository {
  const MatchesRepository(this._api);

  final ApiClient _api;

  /// `POST /v1/matches` có `Idemp` = ✖ trong docs/02 §8 ⇒ không truyền
  /// `idempotencyOperation`: mỗi lần mở lại sheet là một lần đọc mới.
  Future<MatchResponse> follow(
    NextAction next, {
    GeoSource geo = const GeoSource.none(),
    RelaxationStep? relax,
  }) async {
    final body = _applyRelax(next.suggestedBody, relax)..addAll(geo.toJson());
    final ok = await _api.post(next.path, body: body);
    final parsed = MatchResponse.fromJson(ok.json);
    return MatchResponse(
      dish: parsed.dish,
      items: parsed.items,
      relaxation: parsed.relaxation,
      substituteDishes: parsed.substituteDishes,
      contextUsed: parsed.contextUsed,
      meta: parsed.meta.withHeader(ok),
    );
  }

  /// Dimension phải rơi đúng chỗ trên wire: `radius_m` là field top-level, mọi dimension
  /// khác thuộc `filters` (docs/02 §4.4). Dùng `toValue` để không gửi số dạng chuỗi.
  static Map<String, dynamic> _applyRelax(Map<String, dynamic> suggested, RelaxationStep? relax) {
    final body = Map<String, dynamic>.of(suggested);
    final step = relax;
    final value = step?.toValue;
    if (step == null || value == null) return body;
    if (step.dimension == 'radius_m') {
      body['radius_m'] = value;
      return body;
    }
    final raw = body['filters'];
    final filters = raw is Map ? Map<String, dynamic>.of(raw.cast<String, dynamic>()) : <String, dynamic>{};
    filters[step.dimension] = value;
    body['filters'] = filters;
    return body;
  }
}
