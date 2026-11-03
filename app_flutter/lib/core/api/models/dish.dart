import '../../../core/theme/angi_tokens.dart';
import '../json.dart';

/// Tag trong `Dish.tags` / `taxonomy.tags` (docs/02 §1.4).
class DishTag {
  const DishTag({required this.id, required this.kind, required this.label, this.labelEn});

  final String id;

  /// `cuisine | diet | allergen | attribute`
  final String kind;
  final String label;
  final String? labelEn;

  factory DishTag.fromJson(Map<String, dynamic> json) => DishTag(
        id: stringOr(json, 'id'),
        kind: stringOr(json, 'kind'),
        label: stringOr(json, 'label'),
        labelEn: asString(json, 'label_en'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'label': label,
        if (labelEn != null) 'label_en': labelEn,
      };
}

/// `Dish` DTO, dùng cho `POST /v1/spins.dish` và `DishHighlight`.
class Dish {
  const Dish({
    required this.id,
    required this.name,
    this.nameEn,
    this.categoryPath = const [],
    this.categoryId,
    this.region,
    this.temp,
    this.meal = const [],
    this.tags = const [],
    this.tagIds = const [],
    this.priceLevel,
    this.imageUrl,
    this.isExcluded = false,
    this.baseWeight = 1.0,
  });

  final String id;
  final String name;
  final String? nameEn;
  final List<String> categoryPath;
  final String? categoryId;

  /// `north | central | south | all`
  final String? region;

  /// `hot | warm | cold | any`
  final String? temp;
  final List<String> meal;
  final List<DishTag> tags;

  /// `dish_bundle` (§3.2) trả `tags` là **id chuỗi**, còn `Dish` DTO (§1.4) trả object.
  /// `tagIds` luôn đúng ở cả hai ⇒ bộ lọc kiêng cứng và `RouletteEngine` offline đọc field này.
  final List<String> tagIds;
  final int? priceLevel;
  final String? imageUrl;
  final bool isExcluded;

  /// Chỉ có trong `dish_bundle` (docs/02 §3.2) ⇒ đường đi offline.
  final double baseWeight;

  /// Hue của vòng quay: suy từ `category_id` qua taxonomy, fallback theo tên.
  DishType? get type => TaxonomyTypeIndex.of(categoryId, categoryPath: categoryPath, name: name);

  bool hasTag(String tagId) => tagIds.contains(tagId);

  String get displayLabel {
    final cleaned = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isEmpty ? id : cleaned;
  }

  /// `image_url == null` ⇒ tem hue + 2 ký tự đầu (DESIGN.md §Iconography).
  String get stampInitials {
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return _upperTake(id, 2);
    final letters = words.take(2).map((w) => String.fromCharCode(w.runes.first)).join();
    return _upperTake(letters, 2);
  }

  static String _upperTake(String input, int count) {
    final upper = input.toUpperCase();
    return upper.length <= count ? upper : upper.substring(0, count);
  }

  static List<String> _tagIdsOf(Map<String, dynamic> json, List<DishTag> parsed) {
    final raw = json['tags'];
    if (raw is! List) return parsed.map((t) => t.id).toList(growable: false);
    final ids = <String>[];
    for (final element in raw) {
      if (element is String) {
        ids.add(element);
      } else if (element is Map && element['id'] != null) {
        ids.add('${element['id']}');
      }
    }
    return ids;
  }

  factory Dish.fromJson(Map<String, dynamic> json) {
    final tags = asMapList(json, 'tags').map(DishTag.fromJson).toList(growable: false);
    return Dish(
      id: stringOr(json, 'id'),
      name: stringOr(json, 'name'),
      nameEn: asString(json, 'name_en'),
      categoryPath: asStringList(json, 'category_path'),
      categoryId: asString(json, 'category_id'),
      region: asString(json, 'region'),
      temp: asString(json, 'temp'),
      meal: asStringList(json, 'meal'),
      tags: tags,
      tagIds: _tagIdsOf(json, tags),
      priceLevel: asInt(json, 'price_level'),
      imageUrl: asString(json, 'image_url'),
      isExcluded: asBool(json, 'is_excluded'),
      baseWeight: asDouble(json, 'base_weight') ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (nameEn != null) 'name_en': nameEn,
        'category_path': categoryPath,
        if (categoryId != null) 'category_id': categoryId,
        if (region != null) 'region': region,
        if (temp != null) 'temp': temp,
        'meal': meal,
        'tags': tags.isNotEmpty ? tags.map((t) => t.toJson()).toList() : tagIds,
        if (priceLevel != null) 'price_level': priceLevel,
        'image_url': imageUrl,
        'is_excluded': isExcluded,
        'base_weight': baseWeight,
      };
}

/// `dish_highlights[]` trong Place DTO.
class DishHighlight {
  const DishHighlight({required this.dishId, required this.name, this.confidence, this.priceVnd});

  final String dishId;
  final String name;
  final double? confidence;
  final int? priceVnd;

  factory DishHighlight.fromJson(Map<String, dynamic> json) => DishHighlight(
        dishId: stringOr(json, 'dish_id'),
        name: stringOr(json, 'name'),
        confidence: asDouble(json, 'confidence'),
        priceVnd: asInt(json, 'price_vnd'),
      );

  Map<String, dynamic> toJson() => {
        'dish_id': dishId,
        'name': name,
        if (confidence != null) 'confidence': confidence,
        if (priceVnd != null) 'price_vnd': priceVnd,
      };
}

/// Tra `type` (enum `filters.type`) từ `category_id` của taxonomy.
/// App không tự đặt tên hue: ánh xạ 1-1 theo `docs/02` §3.1.
abstract final class TaxonomyTypeIndex {
  static final Map<String, DishType> _byCategorySlug = {
    'mon-nuoc': DishType.noodle,
    'bun': DishType.noodle,
    'bun-bo': DishType.noodle,
    'pho': DishType.noodle,
    'pho-bo': DishType.noodle,
    'com': DishType.rice,
    'com-tam': DishType.rice,
    'com-ga': DishType.rice,
    'banh': DishType.bread,
    'banh-mi': DishType.bread,
    'banh-cuon': DishType.bread,
    'ngot': DishType.sweet,
    'che': DishType.sweet,
    'nuong': DishType.grill,
    'hai-san-nuong': DishType.grill,
    'rau': DishType.salad,
    'goi': DishType.salad,
    'do-uong': DishType.drink,
    'cafe': DishType.drink,
    'an-vat': DishType.snack,
    'nom': DishType.snack,
  };

  static final Map<String, DishType> _byCategoryId = {};

  static void register(String categoryId, DishType type) {
    _byCategoryId[categoryId] = type;
  }

  static void clearIndex() => _byCategoryId.clear();

  static DishType? of(String? categoryId, {List<String> categoryPath = const [], String name = ''}) {
    if (categoryId != null && _byCategoryId.containsKey(categoryId)) {
      return _byCategoryId[categoryId];
    }
    for (final segment in categoryPath) {
      final slug = _slugify(segment);
      if (_byCategorySlug.containsKey(slug)) return _byCategorySlug[slug];
    }
    final slug = _slugify(categoryId ?? '');
    if (_byCategorySlug.containsKey(slug)) return _byCategorySlug[slug];
    return _fromName(name);
  }

  static DishType? _fromName(String name) {
    final lower = _slugify(name);
    if (lower.isEmpty) return null;
    if (lower.contains('bun') || lower.contains('pho') || lower.contains('mien')) return DishType.noodle;
    if (lower.contains('com')) return DishType.rice;
    if (lower.contains('banh')) return DishType.bread;
    if (lower.contains('che') || lower.contains('sua-chua') || lower.contains('kem')) return DishType.sweet;
    if (lower.contains('nuong')) return DishType.grill;
    if (lower.contains('goi') || lower.contains('salad') || lower.contains('rau')) return DishType.salad;
    if (lower.contains('cafe') || lower.contains('tra') || lower.contains('nuoc')) return DishType.drink;
    if (lower.contains('nem') || lower.contains('kha') || lower.contains('vat')) return DishType.snack;
    return null;
  }

  /// Dart `String` không có `normalize('NFD')` ⇒ gấp dấu theo bảng tay.
  /// Chỉ cần cho heuristic nhận diện `type` khi món **không** có `category_id`
  /// (đường offline: `dish_bundle` đôi khi thiếu taxonomy).
  static const Map<String, String> _fold = {
    'á': 'a', 'à': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
    'ă': 'a', 'ắ': 'a', 'ằ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
    'â': 'a', 'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
    'é': 'e', 'è': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
    'ê': 'e', 'ế': 'e', 'ề': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
    'í': 'i', 'ì': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
    'ó': 'o', 'ò': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
    'ô': 'o', 'ố': 'o', 'ồ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
    'ơ': 'o', 'ớ': 'o', 'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
    'ú': 'u', 'ù': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
    'ư': 'u', 'ứ': 'u', 'ừ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
    'ý': 'y', 'ỳ': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
    'đ': 'd',
  };

  static String _slugify(String input) {
    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_fold[char] ?? char);
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp('^-|-\$'), '');
  }
}
