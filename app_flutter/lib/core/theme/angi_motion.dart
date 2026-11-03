import 'package:flutter/widgets.dart';

import '../api/models/misc.dart';
import 'angi_tokens.dart';

/// reduce-motion là **hợp đồng** (DESIGN.md §Motion, FR-ROU-08), không phải toggle trang trí.
/// Gộp 3 nguồn: hệ thống (reduceMotion/highContrast/disableAnimations), cài đặt user,
/// và danh sách renderer server cho phép.
@immutable
class AngiMotion {
  const AngiMotion({
    required this.reduceMotion,
    required this.haptics,
    required this.sound,
    required this.style,
  });

  final bool reduceMotion;

  /// 2 cờ **độc lập** với reduce-motion: tắt rung không hàm ý tắt animation.
  final bool haptics;
  final bool sound;

  /// `wheel | chest | draw | none`, đã giao với `config.animation_styles`.
  final String style;

  bool get animates => !reduceMotion && style != 'none';

  /// Wheel **không** có độ dài mặc định phía app: duration đến từ
  /// `animation.duration_ms` của spin; đây chỉ là trần chống cấu hình sai (spec §1).
  Duration wheelDuration(int durationMs) {
    if (!animates) return Duration.zero;
    final clamped = durationMs.clamp(1, AngiScale.wheelMaxDurationMs);
    return Duration(milliseconds: clamped);
  }

  static AngiMotion of(BuildContext context) {
    final settings = AngiMotionPrefs.maybeOf(context);
    final features = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    final systemReduce = MediaQuery.disableAnimationsOf(context) ||
        features.reduceMotion ||
        (MediaQuery.maybeOf(context)?.highContrast ?? false) ||
        features.highContrast;
    return AngiMotion(
      reduceMotion: systemReduce || (settings?.reduceMotion ?? false),
      haptics: settings?.haptics ?? true,
      sound: settings?.sound ?? true,
      style: settings?.animationStyle ?? 'wheel',
    );
  }
}

/// Bọc quanh app để màn Settings đổi motion/haptics/sound mà không dựng lại toàn bộ cây.
class AngiMotionPrefs extends StatelessWidget {
  const AngiMotionPrefs({required this.settings, required this.child, super.key});

  final UserSettings settings;
  final Widget child;

  static UserSettings? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AngiMotionPrefsScope>()?.settings;

  @override
  Widget build(BuildContext context) => _AngiMotionPrefsScope(settings: settings, child: child);
}

class _AngiMotionPrefsScope extends InheritedWidget {
  const _AngiMotionPrefsScope({required this.settings, required super.child});

  final UserSettings settings;

  @override
  bool updateShouldNotify(_AngiMotionPrefsScope oldWidget) =>
      !identical(settings, oldWidget.settings);
}
