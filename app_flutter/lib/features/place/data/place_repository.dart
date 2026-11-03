import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/models/matches.dart';
import '../../../core/api/models/misc.dart';
import '../../../core/api/models/place.dart';
import '../../../core/api/models/urgent.dart';
import '../../app/application/app_providers.dart';

/// Ba endpoint đọc quán + hai thao tác ghi (báo sai, đã đến). Không có field nào
/// được app tự thêm vào response: mọi thứ parse từ docs/02 §4.
class PlaceRepository {
  const PlaceRepository(this._api);

  final ApiClient _api;

  Future<Place> detail(String placeId) async {
    final ok = await _api.get('/v1/places/$placeId');
    return Place.fromJson(ok.json);
  }

  Future<NearbyResponse> nearby({
    required GeoSource geo,
    required int radiusM,
    int limit = 20,
    String travelMode = 'walk',
    bool openNow = true,
  }) async {
    final ok = await _api.get('/v1/places/nearby', query: {
      ...geo.toQuery(),
      'radius_m': '$radiusM',
      'limit': '$limit',
      'travel_mode': travelMode,
      'open_now': '$openNow',
      'view': 'list',
      'sort': 'score',
    });
    return NearbyResponse.fromJson(ok.json);
  }

  Future<UrgentResponse> urgent({
    required GeoSource geo,
    String travelMode = 'bike',
    int? budgetVnd,
  }) async {
    final ok = await _api.get('/v1/places/urgent', query: {
      ...geo.toQuery(),
      'travel_mode': travelMode,
      if (budgetVnd != null) 'budget_vnd': '$budgetVnd',
    });
    return UrgentResponse.fromJson(ok.json);
  }

  /// POST ghi ⇒ idempotency bắt buộc (docs/02 §4.7). Operation mang timestamp để
  /// retry trong cùng một lần gửi dùng lại key, còn lần báo mới thì có key mới.
  Future<ReportResult> report(
    String placeId, {
    required String kind,
    String? detail,
  }) async {
    final ok = await _api.post(
      '/v1/places/$placeId/reports',
      body: {
        'kind': kind,
        if (detail != null && detail.trim().isNotEmpty) 'detail': detail.trim(),
      },
      idempotencyOperation: 'report-$placeId-${DateTime.now().microsecondsSinceEpoch}',
    );
    return ReportResult.fromJson(ok.json);
  }

  Future<VisitResult> visit({
    required String placeId,
    String? dishId,
    String? spinId,
    String status = 'arrived',
    String source = 'manual',
  }) async {
    final ok = await _api.post(
      '/v1/journal/visits',
      body: {
        'place_id': placeId,
        'status': status,
        'source': source,
        // ignore: use_null_aware_elements
        if (dishId != null) 'dish_id': dishId,
        // ignore: use_null_aware_elements
        if (spinId != null) 'spin_id': spinId,
      },
      idempotencyOperation: 'visit-$placeId-${dishId ?? 'none'}',
    );
    return VisitResult.fromJson(ok.json);
  }
}

final placeRepositoryProvider = Provider<PlaceRepository>((ref) => PlaceRepository(sl()));

/// Chi tiết quán. autoDispose để rời màn là bỏ cache, lần sau mở lại thấy dữ liệu mới.
final placeDetailProvider = FutureProvider.autoDispose.family<Place, String>(
  (ref, placeId) => ref.watch(placeRepositoryProvider).detail(placeId),
);

/// Đói gấp: một chạm, server tự nới bán kính. Không chờ provider (docs/02 §4.5).
final urgentProvider = FutureProvider.autoDispose<UrgentResponse>((ref) {
  final anchor = ref.watch(anchorProvider);
  return ref.watch(placeRepositoryProvider).urgent(geo: anchor.source);
});

/// Danh sách quán quanh bạn theo bán kính đang chọn.
final nearbyProvider = FutureProvider.autoDispose.family<NearbyResponse, int>((ref, radiusM) {
  final anchor = ref.watch(anchorProvider);
  return ref.watch(placeRepositoryProvider).nearby(geo: anchor.source, radiusM: radiusM);
});
