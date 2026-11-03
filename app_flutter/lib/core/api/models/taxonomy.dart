import '../../../core/theme/angi_tokens.dart';
import '../json.dart';
import 'dish.dart';

DishType? dishTypeFromApi(String? raw) {
  if (raw == null) return null;
  for (final type in DishType.values) {
    if (type.name == raw) return type;
  }
  return null;
}

/// Node trong `GET /v1/dishes/taxonomy` (docs/02 §3.1). Level 1 ↔ 8 hue của DESIGN.md.
class TaxonomyCategory {
  const TaxonomyCategory({
    required this.id,
    required this.slug,
    required this.name,
    required this.level,
    this.type,
    this.children = const [],
  });

  final String id;
  final String slug;
  final String name;
  final int level;
  final DishType? type;
  final List<TaxonomyCategory> children;

  TaxonomyCategory? findById(String id) {
    if (this.id == id) return this;
    for (final child in children) {
      final found = child.findById(id);
      if (found != null) return found;
    }
    return null;
  }

  factory TaxonomyCategory.fromJson(Map<String, dynamic> json) => TaxonomyCategory(
        id: stringOr(json, 'id'),
        slug: stringOr(json, 'slug'),
        name: stringOr(json, 'name'),
        level: asInt(json, 'level') ?? 1,
        type: dishTypeFromApi(asString(json, 'type')),
        children: asMapList(json, 'children').map(TaxonomyCategory.fromJson).toList(growable: false),
      );
}

/// Output `GET /v1/dishes/taxonomy`. Khi parse, mọi `category_id` được nạp vào
/// `TaxonomyTypeIndex` ⇒ `Dish.type` (hue vòng quay) không cần suy đoán.
class Taxonomy {
  const Taxonomy({
    this.version = 0,
    this.roots = const [],
    this.filterDimensions = const {},
    this.tags = const [],
    this.counts = const {},
  });

  final int version;
  final List<TaxonomyCategory> roots;

  /// `meal`, `temp`, `type`, `price_level`, `party_size`, `diet`… giá trị dạng chuỗi gốc.
  final Map<String, List<String>> filterDimensions;
  final List<DishTag> tags;
  final Map<String, int> counts;

  int get dishCount => counts['dishes'] ?? 0;

  List<String> dimension(String key) => filterDimensions[key] ?? const [];

  TaxonomyCategory? byId(String id) {
    for (final root in roots) {
      final found = root.findById(id);
      if (found != null) return found;
    }
    return null;
  }

  /// Nhãn nhóm món cho `StampChip`/vòng quay; `null` ⇒ caller tự fallback.
  String? labelOf(String? categoryId) => categoryId == null ? null : byId(categoryId)?.name;

  factory Taxonomy.fromJson(Map<String, dynamic> json) {
    final roots = asMapList(json, 'categories').map(TaxonomyCategory.fromJson).toList(growable: false);
    final dimensions = <String, List<String>>{};
    asMap(json, 'filter_dimensions').forEach((key, value) {
      if (value is List) dimensions[key] = scalarsToStrings(value);
    });
    final taxonomy = Taxonomy(
      version: asInt(json, 'version') ?? 0,
      roots: roots,
      filterDimensions: dimensions,
      tags: asMapList(json, 'tags').map(DishTag.fromJson).toList(growable: false),
      counts: asIntMap(json, 'counts'),
    );
    taxonomy._registerTypes();
    return taxonomy;
  }

  void _registerTypes() {
    void walk(TaxonomyCategory node) {
      if (node.type != null) TaxonomyTypeIndex.register(node.id, node.type!);
      node.children.forEach(walk);
    }

    roots.forEach(walk);
  }
}
