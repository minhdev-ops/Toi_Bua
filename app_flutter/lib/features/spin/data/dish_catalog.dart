import '../../../core/api/dio_client.dart';
import '../../../core/api/models/dish.dart';
import '../../../core/api/models/misc.dart';
import '../../../core/api/models/taxonomy.dart';
import '../../../core/theme/angi_tokens.dart';

/// Tra `dish_id` ⇒ nhãn + hue. `animation.wheel_items[]` và `dish_highlights[]` trên wire
/// **chỉ là id** (docs/02 §3.2, §3.3) ⇒ renderer vòng quay không có nguồn tên nào khác,
/// và cấm tự bịa nhãn.
class DishCatalog {
  const DishCatalog(this._byId);

  final Map<String, Dish> _byId;

  /// Bundle chưa về (hoặc fail): vẫn quay được, nhãn fallback về chính id.
  static const DishCatalog empty = DishCatalog({});

  int get length => _byId.length;

  Dish? of(String dishId) => _byId[dishId];

  String labelOf(String dishId) => _byId[dishId]?.displayLabel ?? dishId;

  DishType? typeOf(String dishId) => _byId[dishId]?.type;

  String? imageUrlOf(String dishId) => _byId[dishId]?.imageUrl;
}

/// `GET /v1/dishes/bundle` + `GET /v1/dishes/taxonomy` (docs/02 §3.1, §3.2).
class DishCatalogRepository {
  const DishCatalogRepository(this._api);

  final ApiClient _api;

  /// Hai request song song: bundle đặt tên cho id, taxonomy đăng ký `category_id → type`
  /// vào `TaxonomyTypeIndex` để hue không phải đoán. Thiếu taxonomy vẫn chạy —
  /// `Dish.type` còn fallback theo slug `category_path` rồi theo tên.
  Future<DishCatalog> load() async {
    final results = await Future.wait(<Future<Object?>>[_loadTaxonomy(), _loadBundle()]);
    final dishes = results[1] as List<Dish>;
    return DishCatalog({for (final dish in dishes) dish.id: dish});
  }

  Future<Object?> _loadTaxonomy() async {
    try {
      Taxonomy.fromJson((await _api.get('/v1/dishes/taxonomy')).json);
    } on ApiError {
      // Không chặn được luồng quay: ghi lỗi thuộc về telemetry, không thuộc về catalog.
    }
    return null;
  }

  Future<List<Dish>> _loadBundle() async {
    try {
      return DishBundle.fromJson((await _api.get('/v1/dishes/bundle')).json).upsert;
    } on ApiError {
      return const [];
    }
  }
}
