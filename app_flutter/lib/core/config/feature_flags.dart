import '../api/models/config.dart';

/// Đọc feature flag từ `GET /v1/config` (docs/02 §5.1).
///
/// Server đã resolve rollout ở `flag_assignment` (docs/01 §5) nên app **chỉ** thấy
/// `on` / `off`. Fail-closed: mọi giá trị lạ (thiếu flag, `"50"`, `null`) ⇒ tắt.
class FeatureFlags {
  const FeatureFlags(this._config);

  final AppConfig _config;

  bool isEnabled(String flag) => _config.isFlagOn(flag);

  bool get groupRooms => isEnabled('group_rooms');
  bool get journal => isEnabled('journal');
  bool get reviews => isEnabled('reviews');
  bool get weatherContext => isEnabled('weather_context');
  bool get rouletteV2 => isEnabled('roulette_v2');

  /// `feature_gates.requires_consent_location` — capability nào cần đồng ý vị trí.
  bool needsLocationConsent(String capability) => _config.requiresConsentLocation.contains(capability);

  /// `feature_gates.requires_account` — capability nào cần tài khoản, khách không được.
  bool needsAccount(String capability) => _config.requiresAccount.contains(capability);

  /// Renderer vòng quay: `animation.style` của spin phải có trong danh sách server khai
  /// báo, ngoài list ⇒ `wheel` (spec UC-01 §3).
  String resolveAnimationStyle(String? style) =>
      style != null && _config.animationStyles.contains(style) ? style : 'wheel';

  /// Danh sách cho màn hình cài đặt; luôn có `wheel` làm lựa chọn an toàn.
  List<String> get animationStyles =>
      _config.animationStyles.isEmpty ? const ['wheel'] : _config.animationStyles;

  bool blocksUpgrade(String platform, String appVersion) => _config.forceUpgrade && _config.needsUpgrade(platform, appVersion);
}
