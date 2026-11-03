import '../json.dart';

/// `spin` block của `GET /v1/config` (docs/02 §5.1).
class SpinConfig {
  const SpinConfig({
    this.antiRepeatDaysDefault = 3,
    this.tauDays = 3.0,
    this.minPool = 3,
    this.rateLimitPerMin = 60,
  });

  final int antiRepeatDaysDefault;
  final double tauDays;
  final int minPool;
  final int rateLimitPerMin;

  factory SpinConfig.fromJson(Map<String, dynamic> json) => SpinConfig(
        antiRepeatDaysDefault: asInt(json, 'anti_repeat_days_default') ?? 3,
        tauDays: asDouble(json, 'tau_days') ?? 3.0,
        minPool: asInt(json, 'min_pool') ?? 3,
        rateLimitPerMin: asInt(json, 'rate_limit_per_min') ?? 60,
      );
}

/// `place` block. App **cấm** hard-code các số này (DESIGN.md §Hằng số nghiệp vụ).
class PlaceConfig {
  const PlaceConfig({
    this.radiusDefaultM = 1500,
    this.radiusMaxM = 5000,
    this.closingSoonMin = 30,
    this.openMinLeftToScore1 = 45,
    this.urgentRadiusSteps = const [1500, 2500, 4000],
  });

  final int radiusDefaultM;
  final int radiusMaxM;
  final int closingSoonMin;
  final int openMinLeftToScore1;
  final List<int> urgentRadiusSteps;

  int get maxUrgentRadiusM => urgentRadiusSteps.isEmpty ? radiusMaxM : urgentRadiusSteps.last;

  factory PlaceConfig.fromJson(Map<String, dynamic> json) {
    final raw = json['urgent_radius_steps'];
    final steps = raw is List ? raw.whereType<num>().map((e) => e.round()).toList(growable: false) : const <int>[];
    return PlaceConfig(
      radiusDefaultM: asInt(json, 'radius_default_m') ?? 1500,
      radiusMaxM: asInt(json, 'radius_max_m') ?? 5000,
      closingSoonMin: asInt(json, 'closing_soon_min') ?? 30,
      openMinLeftToScore1: asInt(json, 'open_min_left_to_score_1') ?? 45,
      urgentRadiusSteps: steps.isEmpty ? const [1500, 2500, 4000] : steps,
    );
  }
}

/// Output `GET /v1/config`. Nguồn duy nhất của hằng số nghiệp vụ phía app.
class AppConfig {
  const AppConfig({
    this.configVersion = 'safe-defaults',
    this.policyVersion = '',
    this.minAppVersion = const {'ios': '1.2.0', 'android': '1.2.0'},
    this.forceUpgrade = false,
    this.flags = const {},
    this.rankingWeights = const {'Q': 0.35, 'D': 0.25, 'P': 0.15, 'O': 0.15, 'U': 0.10},
    this.rankingWeightsVersion = '2026.10',
    this.spin = const SpinConfig(),
    this.place = const PlaceConfig(),
    this.animationStyles = const ['wheel'],
    this.localeSupported = const ['vi', 'en'],
    this.dishBundleVersion = 0,
    this.requiresConsentLocation = const [],
    this.requiresAccount = const [],
    this.experiments = const {},
    this.isSafeDefaults = false,
  });

  /// Chế độ safe defaults khi config **chưa từng** tải được (spec UC-01 §6).
  /// `animation_styles` chỉ `["wheel"]`: không mạo hiểm renderer chưa kiểm chứng.
  /// `min_app_version` rỗng: defaults không được phép chặn màn hình nâng cấp.
  static const AppConfig safeDefaults = AppConfig(isSafeDefaults: true, minAppVersion: {});

  final String configVersion;
  final String policyVersion;
  final Map<String, String> minAppVersion;
  final bool forceUpgrade;

  /// `on` / `off` / `rollout:xx`.
  final Map<String, String> flags;
  final Map<String, double> rankingWeights;
  final String rankingWeightsVersion;
  final SpinConfig spin;
  final PlaceConfig place;
  final List<String> animationStyles;
  final List<String> localeSupported;
  final int dishBundleVersion;
  final List<String> requiresConsentLocation;
  final List<String> requiresAccount;
  final Map<String, String> experiments;
  final bool isSafeDefaults;

  bool isFlagOn(String name) => flags[name] == 'on';

  bool needsUpgrade(String platform, String appVersion) {
    final min = minAppVersion[platform];
    return min != null && compareVersions(appVersion, min) < 0;
  }

  bool supportsLocale(String locale) => localeSupported.contains(locale);

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final weights = Map<String, double>.fromEntries(
      asDoubleMap(json, 'ranking_weights').entries.where((e) => e.key != 'version'),
    );
    final gates = asMap(json, 'feature_gates');
    return AppConfig(
      configVersion: stringOr(json, 'config_version', 'unknown'),
      policyVersion: stringOr(json, 'policy_version'),
      minAppVersion: asStringMap(json, 'min_app_version'),
      forceUpgrade: asBool(json, 'force_upgrade'),
      flags: asStringMap(json, 'flags'),
      rankingWeights: weights.isEmpty ? const {'Q': 0.35, 'D': 0.25, 'P': 0.15, 'O': 0.15, 'U': 0.10} : weights,
      rankingWeightsVersion: stringOr(asMap(json, 'ranking_weights'), 'version', '2026.10'),
      spin: SpinConfig.fromJson(asMap(json, 'spin')),
      place: PlaceConfig.fromJson(asMap(json, 'place')),
      animationStyles: asStringList(json, 'animation_styles').isEmpty ? const ['wheel'] : asStringList(json, 'animation_styles'),
      localeSupported: asStringList(json, 'locale_supported').isEmpty ? const ['vi', 'en'] : asStringList(json, 'locale_supported'),
      dishBundleVersion: asInt(json, 'dish_bundle_version') ?? 0,
      requiresConsentLocation: asStringList(gates, 'requires_consent_location'),
      requiresAccount: asStringList(gates, 'requires_account'),
      experiments: asStringMap(json, 'experiments'),
    );
  }

  /// `2026.11.01.3` vs `1.2.0`: so theo từng segment số, phần tử thiếu tính là 0.
  static int compareVersions(String a, String b) {
    final left = a.split('.').map(int.tryParse).toList();
    final right = b.split('.').map(int.tryParse).toList();
    final count = left.length > right.length ? left.length : right.length;
    for (var i = 0; i < count; i++) {
      final l = i < left.length ? (left[i] ?? 0) : 0;
      final r = i < right.length ? (right[i] ?? 0) : 0;
      if (l != r) return l.compareTo(r);
    }
    return 0;
  }
}
