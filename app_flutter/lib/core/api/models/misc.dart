import '../json.dart';
import 'dish.dart';
import 'matches.dart';
import 'place.dart';

/// Mã lỗi trong bảng `docs/01` §4.6 + các code riêng của endpoint (`docs/02`).
/// Không có `unknown` rơi vào UI: mọi code đều ánh xạ được một ARB key chung.
enum ErrorCode {
  validationFailed,
  unauthenticated,
  tokenExpired,
  forbidden,
  consentRequired,
  locationNotAuthorized,
  locationRequired,
  outsideServiceArea,
  notFound,
  dishNotFound,
  gone,
  conflict,
  idempotencyReplay,
  reportAlreadyResolved,
  roomVersionStale,
  roomExpired,
  dietFilterEmpty,
  filterContradiction,
  poolTooSmall,
  policyVersionOutdated,
  providerUnavailable,
  rateLimited,
  reportLimit,
  degradedNoResult,
  serverError,
  unavailable,
}

/// Wire value (`"DIET_FILTER_EMPTY"`) ⇄ enum. Code lạ ⇒ `serverError` (banner retry, không crash).
String codeToWire(ErrorCode code) {
  switch (code) {
    case ErrorCode.validationFailed:
      return 'VALIDATION_FAILED';
    case ErrorCode.unauthenticated:
      return 'UNAUTHENTICATED';
    case ErrorCode.tokenExpired:
      return 'TOKEN_EXPIRED';
    case ErrorCode.forbidden:
      return 'FORBIDDEN';
    case ErrorCode.consentRequired:
      return 'CONSENT_REQUIRED';
    case ErrorCode.locationNotAuthorized:
      return 'LOCATION_NOT_AUTHORIZED';
    case ErrorCode.locationRequired:
      return 'LOCATION_REQUIRED';
    case ErrorCode.outsideServiceArea:
      return 'OUTSIDE_SERVICE_AREA';
    case ErrorCode.notFound:
      return 'NOT_FOUND';
    case ErrorCode.dishNotFound:
      return 'DISH_NOT_FOUND';
    case ErrorCode.gone:
      return 'GONE';
    case ErrorCode.conflict:
      return 'CONFLICT';
    case ErrorCode.idempotencyReplay:
      return 'IDEMPOTENCY_REPLAY';
    case ErrorCode.reportAlreadyResolved:
      return 'REPORT_ALREADY_RESOLVED';
    case ErrorCode.roomVersionStale:
      return 'ROOM_VERSION_STALE';
    case ErrorCode.roomExpired:
      return 'ROOM_EXPIRED';
    case ErrorCode.dietFilterEmpty:
      return 'DIET_FILTER_EMPTY';
    case ErrorCode.filterContradiction:
      return 'FILTER_CONTRADICTION';
    case ErrorCode.poolTooSmall:
      return 'POOL_TOO_SMALL';
    case ErrorCode.policyVersionOutdated:
      return 'POLICY_VERSION_OUTDATED';
    case ErrorCode.providerUnavailable:
      return 'PROVIDER_UNAVAILABLE';
    case ErrorCode.rateLimited:
      return 'RATE_LIMITED';
    case ErrorCode.reportLimit:
      return 'REPORT_LIMIT';
    case ErrorCode.degradedNoResult:
      return 'DEGRADED_NO_RESULT';
    case ErrorCode.serverError:
      return 'SERVER_ERROR';
    case ErrorCode.unavailable:
      return 'UNAVAILABLE';
  }
}

ErrorCode codeFromWire(String? raw) {
  for (final code in ErrorCode.values) {
    if (codeToWire(code) == raw) return code;
  }
  return ErrorCode.serverError;
}

/// `error.details[]` — field-level, có thể mang relaxation đề xuất.
class ErrorDetail {
  const ErrorDetail({
    this.field,
    this.rule,
    this.messageKey,
    this.allowed,
    this.received,
    this.value,
    this.tagId,
    this.conflictingWith,
    this.removedDishes,
    this.retryAfterS,
    this.suggestedRelaxations = const [],
  });

  /// Đường dẫn body gây lỗi (`budget_vnd`, `filters.type`) ⇒ app focus vào control đó.
  final String? field;

  /// `min | max | conflict | enum | per_minute`…
  final String? rule;

  /// ARB key duy nhất được phép hiển thị.
  final String? messageKey;
  final String? allowed;
  final String? received;
  final String? value;
  final String? tagId;

  /// `conflicting_with`: tag hoặc category thủ phạm (FR-ROU-03 sheet).
  final String? conflictingWith;
  final int? removedDishes;
  final int? retryAfterS;
  final List<RelaxationStep> suggestedRelaxations;

  bool get isFieldError => field != null && field!.isNotEmpty;

  factory ErrorDetail.fromJson(Map<String, dynamic> json) => ErrorDetail(
        field: asString(json, 'field'),
        rule: asString(json, 'rule'),
        messageKey: asString(json, 'message_key'),
        allowed: json['allowed'] == null ? null : scalarText(json, 'allowed'),
        received: json['received'] == null ? null : scalarText(json, 'received'),
        value: json['value'] == null ? null : scalarText(json, 'value'),
        tagId: asString(json, 'tag_id'),
        conflictingWith: asString(json, 'conflicting_with'),
        removedDishes: asInt(json, 'removed_dishes'),
        retryAfterS: asInt(json, 'retry_after_s'),
        suggestedRelaxations: asMapList(json, 'suggested_relaxations').map(RelaxationStep.fromJson).toList(growable: false),
      );
}

/// Envelope lỗi thống nhất (`docs/01` §4.6). `message` **không bao giờ** ra UI (TC-I18N-01).
class ApiError implements Exception {
  const ApiError({
    required this.code,
    required this.httpStatus,
    this.message = '',
    this.details = const [],
    this.requestId,
    this.retryable = false,
    this.docUrl,
    this.headerRetryAfter,
  });

  final ErrorCode code;
  final int httpStatus;

  /// Chỉ để log/debug drawer, không render.
  final String message;
  final List<ErrorDetail> details;
  final String? requestId;
  final bool retryable;
  final String? docUrl;

  /// `Retry-After` của HTTP, khi envelope không nói gì.
  final int? headerRetryAfter;

  /// ARB key ưu tiên: `message_key` đầu tiên có trong `details[]`.
  String? get messageKey {
    for (final detail in details) {
      if (detail.messageKey != null) return detail.messageKey;
    }
    return null;
  }

  int? get retryAfterS {
    for (final detail in details) {
      if (detail.retryAfterS != null) return detail.retryAfterS;
    }
    return headerRetryAfter;
  }

  List<RelaxationStep> get suggestedRelaxations => details.expand((d) => d.suggestedRelaxations).toList(growable: false);

  /// Xung đột kiêng: `details[].conflicting_with` không rỗng ⇒ sheet liệt kê đúng thủ phạm.
  List<ErrorDetail> get conflictDetails => details.where((d) => d.conflictingWith != null).toList(growable: false);

  bool get isAuth => code == ErrorCode.unauthenticated || code == ErrorCode.tokenExpired;

  factory ApiError.fromJson(Map<String, dynamic> body, int httpStatus, {int? retryAfterHeader}) {
    final error = body['error'];
    final json = error is Map<String, dynamic> ? error : body;
    final wireCode = asString(json, 'code');
    return ApiError(
      code: codeFromWire(wireCode),
      httpStatus: httpStatus,
      message: stringOr(json, 'message'),
      details: asMapList(json, 'details').map(ErrorDetail.fromJson).toList(growable: false),
      requestId: asString(json, 'request_id'),
      retryable: asBool(json, 'retryable'),
      docUrl: asString(json, 'doc_url'),
      headerRetryAfter: retryAfterHeader,
    );
  }

  /// Khi không có JSON lỗi (mạng chết, HTML 502, timeout) ⇒ cùng một kiểu để UI chỉ cần 1 nhánh.
  factory ApiError.transport({required int httpStatus, String message = '', int? retryAfterHeader}) => ApiError(
        code: httpStatus == 0 ? ErrorCode.unavailable : codeFromWire(null),
        httpStatus: httpStatus,
        message: message,
        retryable: true,
        headerRetryAfter: retryAfterHeader,
      );

  @override
  String toString() => 'ApiError(${codeToWire(code)} $httpStatus request_id=$requestId)';
}

/// `POST /v1/auth/guest` `201` (docs/02 §2.1).
class GuestSession {
  const GuestSession({
    required this.userId,
    required this.accessToken,
    required this.accessExpiresIn,
    required this.refreshToken,
    required this.refreshExpiresIn,
    this.displayName,
    this.kind = 'guest',
    this.onboardingCompleted = false,
    this.consentsRequired = const [],
    this.policyVersion = '',
  });

  final String userId;
  final String kind;
  final String? displayName;
  final bool onboardingCompleted;
  final String accessToken;
  final int accessExpiresIn;
  final String refreshToken;
  final int refreshExpiresIn;

  /// `["location"]` ⇒ app phải xin trước khi gọi `nearby`/`urgent` (FR-PLC-01).
  final List<String> consentsRequired;
  final String policyVersion;

  bool get isGuest => kind == 'guest';

  factory GuestSession.fromJson(Map<String, dynamic> json) {
    final user = asMap(json, 'user');
    return GuestSession(
      userId: stringOr(user, 'id'),
      kind: stringOr(user, 'kind', 'guest'),
      displayName: asString(user, 'display_name'),
      onboardingCompleted: asBool(user, 'onboarding_completed'),
      accessToken: stringOr(json, 'access_token'),
      accessExpiresIn: asInt(json, 'access_expires_in') ?? 900,
      refreshToken: stringOr(json, 'refresh_token'),
      refreshExpiresIn: asInt(json, 'refresh_expires_in') ?? 2592000,
      consentsRequired: asStringList(json, 'consents_required'),
      policyVersion: stringOr(json, 'policy_version'),
    );
  }
}

/// Bản `PUT /v1/me/settings` áp dụng ngay local (FR-PER-01), sync sau.
class UserSettings {
  const UserSettings({
    this.locale = 'vi',
    this.theme = 'system',
    this.fontScale = 1.0,
    this.reduceMotion = false,
    this.sound = true,
    this.haptics = true,
    this.animationStyle = 'wheel',
  });

  /// `system | light | dark`
  final String theme;
  final String locale;
  final double fontScale;
  final bool reduceMotion;
  final bool sound;
  final bool haptics;

  /// `wheel | chest | draw | none` — vẫn phải ∩ `config.animation_styles`.
  final String animationStyle;

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
        locale: stringOr(json, 'locale', 'vi'),
        theme: stringOr(json, 'theme', 'system'),
        fontScale: asDouble(json, 'font_scale') ?? 1.0,
        reduceMotion: asBool(json, 'reduce_motion'),
        sound: asBool(json, 'sound', true),
        haptics: asBool(json, 'haptics', true),
        animationStyle: stringOr(json, 'animation_style', 'wheel'),
      );

  Map<String, dynamic> toJson() => {
        'locale': locale,
        'theme': theme,
        'font_scale': fontScale,
        'reduce_motion': reduceMotion,
        'sound': sound,
        'haptics': haptics,
        'animation_style': animationStyle,
      };
}

/// Hồ sơ mặc định cho `POST /v1/spins`: app **chỉ** gửi field user động vào.
class UserPreferences {
  const UserPreferences({
    this.meals = const [],
    this.priceLevelMax,
    this.regions = const [],
    this.temp = 'any',
    this.moods = const [],
    this.partySizeDefault,
    this.travelMode = 'bike',
    this.radiusDefaultM,
    this.personalizationOptIn = true,
    this.dietStrict = const [],
    this.dietPreferred = const [],
    this.weeklyBudgetVnd,
    this.savedLocations = const [],
  });

  final List<String> meals;
  final int? priceLevelMax;
  final List<String> regions;
  final String temp;
  final List<String> moods;
  final int? partySizeDefault;
  final String travelMode;
  final int? radiusDefaultM;
  final bool personalizationOptIn;

  /// Lọc cứng, **không tắt được từ UI** (FR-ROU-03, TC-BIZ-11).
  final List<String> dietStrict;
  final List<String> dietPreferred;
  final int? weeklyBudgetVnd;
  final List<SavedLocation> savedLocations;

  SavedLocation? get defaultLocation => savedLocations.isEmpty ? null : savedLocations.first;

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    final prefs = asMap(json, 'preferences');
    final diet = asMap(json, 'diet');
    return UserPreferences(
      meals: asStringList(prefs, 'meals'),
      priceLevelMax: asInt(prefs, 'price_level_max'),
      regions: asStringList(prefs, 'regions'),
      temp: stringOr(prefs, 'temp', 'any'),
      moods: asStringList(prefs, 'moods'),
      partySizeDefault: asInt(prefs, 'party_size_default'),
      travelMode: stringOr(prefs, 'travel_mode', 'bike'),
      radiusDefaultM: asInt(prefs, 'radius_default_m'),
      personalizationOptIn: asBool(prefs, 'personalization_opt_in', true),
      dietStrict: asStringList(diet, 'strict'),
      dietPreferred: asStringList(diet, 'preferred'),
      weeklyBudgetVnd: asInt(asMap(json, 'budget'), 'weekly_vnd'),
      savedLocations: asMapList(json, 'locations').map(SavedLocation.fromJson).toList(growable: false),
    );
  }
}

/// `locations[]` của `GET /v1/me` ⇒ nguồn vị trí không cần GPS.
class SavedLocation {
  const SavedLocation({
    required this.id,
    required this.label,
    required this.name,
    required this.geo,
    this.address,
    this.isDefault = false,
  });

  final String id;

  /// `work | home | …` — nhãn nội bộ, không phải PII hiển thị.
  final String label;
  final String name;
  final GeoPoint geo;
  final String? address;
  final bool isDefault;

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
        id: stringOr(json, 'id'),
        label: stringOr(json, 'label'),
        name: stringOr(json, 'name'),
        geo: GeoPoint.fromJson(asMap(json, 'geo')),
        address: asString(json, 'address'),
        isDefault: asBool(json, 'is_default'),
      );

  GeoSource get asSource => GeoSource.locationId(id);
}

/// `PUT /v1/me/onboarding` `200` (docs/02 §2.7): 3 bước, không bước nào bắt buộc.
class OnboardingResult {
  const OnboardingResult({
    this.onboardingCompleted = false,
    this.stepsDone = const [],
    this.nextStep,
  });

  final bool onboardingCompleted;
  final List<String> stepsDone;
  final String? nextStep;

  int get stepsDoneCount => stepsDone.length;

  factory OnboardingResult.fromJson(Map<String, dynamic> json) => OnboardingResult(
        onboardingCompleted: asBool(json, 'onboarding_completed'),
        stepsDone: asStringList(json, 'steps_done'),
        nextStep: asString(json, 'next_step'),
      );
}

/// `POST /v1/journal/visits` `201` (docs/02 §6.1).
class VisitResult {
  const VisitResult({
    required this.id,
    required this.status,
    this.occurredAt,
    this.askReview = false,
    this.reviewPromptKey,
    this.budgetDeltaVnd,
  });

  final String id;
  final String status;
  final DateTime? occurredAt;

  /// Bật theo tần suất có kiểm soát ⇒ **một** prompt rời rạc, không modal (NFR-09).
  final bool askReview;
  final String? reviewPromptKey;
  final int? budgetDeltaVnd;

  factory VisitResult.fromJson(Map<String, dynamic> json) => VisitResult(
        id: stringOr(json, 'id'),
        status: stringOr(json, 'status'),
        occurredAt: asDate(json, 'occurred_at'),
        askReview: asBool(json, 'ask_review'),
        reviewPromptKey: asString(json, 'review_prompt_key'),
        budgetDeltaVnd: asInt(json, 'budget_delta_vnd'),
      );
}

/// `POST /v1/places/{id}/reports` `201` (docs/02 §4.7).
class ReportResult {
  const ReportResult({
    required this.reportId,
    required this.status,
    this.queuedForReview = false,
    this.credited = false,
    this.affectsRankingAfterReview = false,
    this.cooldownS = 0,
    this.duplicateOf,
  });

  final String reportId;
  final String status;
  final bool queuedForReview;
  final bool credited;
  final bool affectsRankingAfterReview;

  /// `> 0` ⇒ vô hiệu nút `Báo sai` hết khoảng này.
  final int cooldownS;

  /// `200 + duplicate_of` ⇒ "Bạn đã báo rồi", không phải lỗi.
  final String? duplicateOf;

  factory ReportResult.fromJson(Map<String, dynamic> json) => ReportResult(
        reportId: stringOr(json, 'report_id'),
        status: stringOr(json, 'status'),
        queuedForReview: asBool(json, 'queued_for_review'),
        credited: asBool(json, 'credited'),
        affectsRankingAfterReview: asBool(json, 'affects_ranking_after_review'),
        cooldownS: asInt(json, 'cooldown_s') ?? 0,
        duplicateOf: asString(json, 'duplicate_of'),
      );
}

/// Item trong `GET /v1/me/exclusions` / `Dish.is_excluded`.
class DishExclusion {
  const DishExclusion({required this.dishId, required this.name, this.scope = 'permanent', this.expiresAt});

  final String dishId;
  final String name;

  /// `permanent | session`
  final String scope;
  final DateTime? expiresAt;

  bool get isExpired => expiresAt != null && DateTime.now().toUtc().isAfter(expiresAt!);

  factory DishExclusion.fromJson(Map<String, dynamic> json) => DishExclusion(
        dishId: stringOr(json, 'dish_id'),
        name: stringOr(json, 'name'),
        scope: stringOr(json, 'scope', 'permanent'),
        expiresAt: asDate(json, 'expires_at'),
      );

  Map<String, dynamic> toJson() => {
        'dish_id': dishId,
        'name': name,
        'scope': scope,
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      };
}

/// `GET /v1/dishes/bundle` (docs/02 §3.2) — full hoặc delta.
class DishBundle {
  const DishBundle({
    required this.version,
    this.isDelta = false,
    this.baseVersion,
    this.etag,
    this.upsert = const [],
    this.deactivate = const [],
    this.signature = '',
  });

  final int version;
  final bool isDelta;
  final int? baseVersion;
  final String? etag;
  final List<Dish> upsert;
  final List<String> deactivate;

  /// `base64(Ed25519(...))` — app verify bằng public key trong bundle, chống bundle giả.
  final String signature;

  int get dishCount => upsert.length;

  factory DishBundle.fromJson(Map<String, dynamic> json) => DishBundle(
        version: asInt(json, 'version') ?? 0,
        isDelta: asBool(json, 'is_delta'),
        baseVersion: asInt(json, 'base_version'),
        etag: asString(json, 'etag'),
        upsert: asMapList(json, 'upsert').map(Dish.fromJson).toList(growable: false),
        deactivate: asStringList(json, 'deactivate'),
        signature: stringOr(json, 'signature'),
      );
}
