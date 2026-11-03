import '../../../core/api/dio_client.dart';
import '../../../core/api/models/spin.dart';

/// `POST /v1/spins` (docs/02 §3.3). App không tự sinh kết quả — mọi thứ từ response.
class SpinRepository {
  const SpinRepository(this._api);

  final ApiClient _api;

  /// **Không** có `idempotencyOperation`: spin là sự kiện mới, key sẽ khiến server trả
  /// `IDEMPOTENCY_REPLAY` và user quay mãi ra một món (TC-API-05, docs/02 §3.3).
  Future<SpinResult> spin(SpinRequest request) async {
    final ok = await _api.post('/v1/spins', body: request.toJson());
    final result = SpinResult.fromJson(ok.json);
    return SpinResult(
      spinId: result.spinId,
      createdAt: result.createdAt,
      dish: result.dish,
      proof: result.proof,
      pool: result.pool,
      antiRepeat: result.antiRepeat,
      appliedFilters: result.appliedFilters,
      animation: result.animation,
      next: result.next,
      meta: result.meta.withHeader(ok),
    );
  }
}
