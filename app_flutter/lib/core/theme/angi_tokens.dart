import 'package:flutter/material.dart';

/// 8 hue dữ liệu, ánh xạ 1-1 vào enum `filters.type` của API (docs/02 §3.3).
enum DishType { noodle, rice, bread, sweet, grill, salad, drink, snack }

DishType? dishTypeFromApi(String? raw) {
  for (final value in DishType.values) {
    if (value.name == raw) return value;
  }
  return null;
}

/// Token màu đã khoá trong `.ulpi/design/DESIGN.md`.
/// Không có `Colors.` nào được dùng ngoài file này.
@immutable
class AngiTokens extends ThemeExtension<AngiTokens> {
  const AngiTokens({
    required this.background,
    required this.surface,
    required this.sunken,
    required this.ink,
    required this.muted,
    required this.subtle,
    required this.line,
    required this.accent,
    required this.onAccent,
    required this.onFill,
    required this.onData,
    required this.focus,
    required this.successFill,
    required this.warningFill,
    required this.dangerFill,
    required this.infoFill,
    required this.successText,
    required this.dangerText,
    required this.infoText,
    required this.accentText,
    required this.hues,
  });

  final Color background;
  final Color surface;
  final Color sunken;

  /// Chữ chính **và** mọi viền 2dp.
  final Color ink;
  final Color muted;

  /// Caption, số thứ cấp. Cấm trên [sunken] (4.19:1).
  final Color subtle;

  /// Chỉ divider 1dp, không dùng làm viền control.
  final Color line;
  final Color accent;
  final Color onAccent;
  final Color onFill;
  final Color onData;
  final Color focus;
  final Color successFill;
  final Color warningFill;
  final Color dangerFill;
  final Color infoFill;
  final Color successText;
  final Color dangerText;
  final Color infoText;
  final Color accentText;

  final Map<DishType, Color> hues;

  static AngiTokens of(BuildContext context) {
    final tokens = Theme.of(context).extension<AngiTokens>();
    assert(tokens != null, 'Thiếu AngiTokens trong ThemeData.extensions');
    return tokens!;
  }

  static const AngiTokens light = AngiTokens(
    background: Color(0xFFE8F7F3),
    surface: Color(0xFFFAFFFD),
    sunken: Color(0xFFD9EDE8),
    ink: Color(0xFF152725),
    muted: Color(0xFF4C615F),
    subtle: Color(0xFF5E7270),
    line: Color(0xFFBCCDC9),
    accent: Color(0xFFF2CD20),
    onAccent: Color(0xFF211E10),
    onFill: Color(0xFF211E10),
    onData: Color(0xFF211E10),
    focus: Color(0xFF125B84),
    successFill: Color(0xFF86D29B),
    warningFill: Color(0xFFF9B87F),
    dangerFill: Color(0xFFFC9D95),
    infoFill: Color(0xFF95C8ED),
    successText: Color(0xFF137D41),
    dangerText: Color(0xFFCD1F2A),
    infoText: Color(0xFF1B77AC),
    accentText: Color(0xFF654B07),
    hues: {
      DishType.noodle: Color(0xFF0698A4),
      DishType.rice: Color(0xFFB18C39),
      DishType.bread: Color(0xFFCF802E),
      DishType.sweet: Color(0xFFC33887),
      DishType.grill: Color(0xFFC83C25),
      DishType.salad: Color(0xFF42A357),
      DishType.drink: Color(0xFF297FBD),
      DishType.snack: Color(0xFFCE475C),
    },
  );

  static const AngiTokens dark = AngiTokens(
    background: Color(0xFF0C1C1E),
    surface: Color(0xFF182B2E),
    sunken: Color(0xFF061213),
    ink: Color(0xFFE8F3F0),
    muted: Color(0xFFA3B5B4),
    subtle: Color(0xFF899D9C),
    line: Color(0xFF314749),
    accent: Color(0xFFE3C023),
    onAccent: Color(0xFF201D0F),
    onFill: Color(0xFF201D0F),
    onData: Color(0xFF201D0F),
    focus: Color(0xFF5AAEE5),
    successFill: Color(0xFF86D29B),
    warningFill: Color(0xFFEFAE75),
    dangerFill: Color(0xFFEB827B),
    infoFill: Color(0xFF85B8DC),
    successText: Color(0xFF5EBC7B),
    dangerText: Color(0xFFF75D59),
    infoText: Color(0xFF4FA8E1),
    accentText: Color(0xFFD8BD51),
    hues: {
      DishType.noodle: Color(0xFF48BECA),
      DishType.rice: Color(0xFFD8B260),
      DishType.bread: Color(0xFFF8A558),
      DishType.sweet: Color(0xFFED60AC),
      DishType.grill: Color(0xFFF3654C),
      DishType.salad: Color(0xFF6ACA7B),
      DishType.drink: Color(0xFF52A4E5),
      DishType.snack: Color(0xFFF96E7F),
    },
  );

  /// Hue của `type`; fallback về [muted] khi id món không có trong taxonomy.
  Color hue(DishType? type) => hues[type] ?? muted;

  @override
  AngiTokens copyWith({
    Color? background,
    Color? surface,
    Color? sunken,
    Color? ink,
    Color? muted,
    Color? subtle,
    Color? line,
    Color? accent,
    Color? onAccent,
    Color? onFill,
    Color? onData,
    Color? focus,
    Color? successFill,
    Color? warningFill,
    Color? dangerFill,
    Color? infoFill,
    Color? successText,
    Color? dangerText,
    Color? infoText,
    Color? accentText,
    Map<DishType, Color>? hues,
  }) {
    return AngiTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      sunken: sunken ?? this.sunken,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      subtle: subtle ?? this.subtle,
      line: line ?? this.line,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      onFill: onFill ?? this.onFill,
      onData: onData ?? this.onData,
      focus: focus ?? this.focus,
      successFill: successFill ?? this.successFill,
      warningFill: warningFill ?? this.warningFill,
      dangerFill: dangerFill ?? this.dangerFill,
      infoFill: infoFill ?? this.infoFill,
      successText: successText ?? this.successText,
      dangerText: dangerText ?? this.dangerText,
      infoText: infoText ?? this.infoText,
      accentText: accentText ?? this.accentText,
      hues: hues ?? this.hues,
    );
  }

  static Color? _lerp(Color a, Color b, double t) => Color.lerp(a, b, t);

  @override
  AngiTokens lerp(ThemeExtension<AngiTokens>? other, double t) {
    if (other is! AngiTokens) return this;
    return AngiTokens(
      background: _lerp(background, other.background, t)!,
      surface: _lerp(surface, other.surface, t)!,
      sunken: _lerp(sunken, other.sunken, t)!,
      ink: _lerp(ink, other.ink, t)!,
      muted: _lerp(muted, other.muted, t)!,
      subtle: _lerp(subtle, other.subtle, t)!,
      line: _lerp(line, other.line, t)!,
      accent: _lerp(accent, other.accent, t)!,
      onAccent: _lerp(onAccent, other.onAccent, t)!,
      onFill: _lerp(onFill, other.onFill, t)!,
      onData: _lerp(onData, other.onData, t)!,
      focus: _lerp(focus, other.focus, t)!,
      successFill: _lerp(successFill, other.successFill, t)!,
      warningFill: _lerp(warningFill, other.warningFill, t)!,
      dangerFill: _lerp(dangerFill, other.dangerFill, t)!,
      infoFill: _lerp(infoFill, other.infoFill, t)!,
      successText: _lerp(successText, other.successText, t)!,
      dangerText: _lerp(dangerText, other.dangerText, t)!,
      infoText: _lerp(infoText, other.infoText, t)!,
      accentText: _lerp(accentText, other.accentText, t)!,
      hues: t < 0.5 ? hues : other.hues,
    );
  }
}

/// Các scale đã khoá: spacing / radius / shadow / z / motion / sizing.
/// Không đổi giữa light và dark nên đứng ngoài ThemeExtension.
abstract final class AngiScale {
  static const double s0 = 0;
  static const double s1 = 2;
  static const double s2 = 4;
  static const double s3 = 8;
  static const double s4 = 12;
  static const double s5 = 16;
  static const double s6 = 20;
  static const double s7 = 24;
  static const double s8 = 32;
  static const double s9 = 40;
  static const double s10 = 48;
  static const double s11 = 64;

  static const double screenPadding = s5;
  static const double screenPaddingSafe = s6;

  static const double radiusXs = 8;
  static const double radiusSm = 14;
  static const double radiusMd = 20;
  static const double radiusLg = 28;
  static const double radiusPill = 999;

  /// Shadow luôn blur 0. Bóng chỉ tồn tại trên stamp.
  static const double stamp1 = 2;
  static const double stamp2 = 4;
  static const double stamp3 = 6;
  static const double shadowBlur = 0;

  static const double zBase = 0;
  static const double zSticky = 10;
  static const double zSheet = 20;
  static const double zDialog = 30;
  static const double zToast = 40;

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration emphasis = Duration(milliseconds: 520);
  static const Duration exit = Duration(milliseconds: 200);
  static const Duration stampPress = Duration(milliseconds: 90);
  static const Duration staggerStep = Duration(milliseconds: 40);
  static const Duration barGrow = Duration(milliseconds: 400);
  static const Duration wheelSettle = Duration(milliseconds: 180);

  /// Easing duy nhất cho UI. Vòng quay dùng vật lý riêng.
  static const Curve curveStamp = Cubic(0.2, 0, 0, 1);

  static const double touchMin = 48;
  static const double touchMinIos = 44;
  static const double stampButtonH = 56;
  static const double rowMinH = 76;
  static const double rankOneScale = 1.4;
  static const double thumbFallback = 44;
  static const double badgeVisualMin = 32;
  static const double badgeTouchMin = 48;
  static const double focusRing = 3;
  static const double focusRingGap = 2;
  static const double outline = 2;
  static const double divider = 1;

  static const double disabledOpacity = 0.45;
  static const double stampTilt = -6 * 3.141592653589793 / 180;

  /// Clamp `animation.duration_ms` chống cấu hình sai (spec §1 edge cases).
  static const int wheelMaxDurationMs = 4000;
  static const double wheelSettleDegrees = 3;
  static const double wheelDecelerate = 0.05;

  static const double textScaleStepDown = 1.6;
}

/// Role chữ đã khoá. Tách khỏi `TextTheme` vì 3 role không có slot Material.
@immutable
class AngiRoles extends ThemeExtension<AngiRoles> {
  const AngiRoles({
    required this.display,
    required this.title,
    required this.sectionLabel,
    required this.body,
    required this.label,
    required this.micro,
    required this.stampLabel,
    required this.wheelLabel,
    required this.numeric,
    required this.numericLg,
    required this.mono,
  });

  final TextStyle display;
  final TextStyle title;
  final TextStyle sectionLabel;
  final TextStyle body;
  final TextStyle label;

  /// Cấm trên [AngiTokens.sunken].
  final TextStyle micro;
  final TextStyle stampLabel;

  /// Ngưỡng AA-large 3.0 đã đo theo đúng size này.
  final TextStyle wheelLabel;
  final TextStyle numeric;
  final TextStyle numericLg;
  final TextStyle mono;

  static const String bodyFamily = 'BeVietnamPro';
  static const String displayFamily = 'BricolageGrotesque';
  static const String monoFamily = 'JetBrainsMono';

  /// `textScaleFactor ≥ 1.6` ⇒ mỗi role số tụt về role kế tiếp có thật.
  static const Map<String, String> _stepDown = {
    'numericLg': 'numeric',
    'numeric': 'title',
    'display': 'title',
  };

  factory AngiRoles.build() {
    TextStyle display(double size, double height, FontWeight weight) {
      return TextStyle(
        fontFamily: displayFamily,
        fontFamilyFallback: const ['sans-serif-black'],
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
        fontWeight: weight,
        fontSize: size,
        height: height,
        letterSpacing: size >= 22 ? -0.02 * size : null,
      );
    }

    TextStyle body(double size, double height, FontWeight weight, {double? spacing}) {
      return TextStyle(
        fontFamily: bodyFamily,
        fontFamilyFallback: const ['sans-serif'],
        fontWeight: weight,
        fontSize: size,
        height: height,
        letterSpacing: spacing,
      );
    }

    return AngiRoles(
      display: display(34, 1.1, FontWeight.w700),
      title: display(22, 1.25, FontWeight.w600),
      sectionLabel: body(13, 1.2, FontWeight.w700, spacing: 13 * 0.06),
      body: body(16, 1.5, FontWeight.w400),
      label: body(13, 1.3, FontWeight.w600),
      micro: body(11, 1.3, FontWeight.w500),
      stampLabel: body(12, 1.1, FontWeight.w700, spacing: 12 * 0.04),
      wheelLabel: display(18, 1.0, FontWeight.w700),
      numeric: display(28, 1.0, FontWeight.w700),
      numericLg: display(40, 1.0, FontWeight.w700),
      mono: TextStyle(
        fontFamily: monoFamily,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        height: 1.3,
        fontVariations: const [FontVariation('wght', 500)],
      ),
    );
  }

  /// Trả role đã áp quy tắc tụt scale. `Text` tự nhân `MediaQuery.textScaler`
  /// lên `fontSize`, nên ở đây chỉ đổi role, không đổi size lần hai.
  static AngiRoles of(BuildContext context) {
    final roles = Theme.of(context).extension<AngiRoles>() ?? AngiRoles.build();
    final factor = MediaQuery.textScalerOf(context).scale(1).toDouble();
    if (factor < AngiScale.textScaleStepDown) return roles;
    TextStyle down(String name) => roles.byRole(_stepDown[name] ?? name);
    return AngiRoles(
      display: down('display'),
      title: roles.title,
      sectionLabel: roles.sectionLabel,
      body: roles.body,
      label: roles.label,
      micro: roles.micro,
      stampLabel: roles.stampLabel,
      wheelLabel: roles.wheelLabel,
      numeric: down('numeric'),
      numericLg: down('numericLg'),
      mono: roles.mono,
    );
  }

  TextStyle byRole(String role) {
    switch (role) {
      case 'display':
        return display;
      case 'title':
        return title;
      case 'sectionLabel':
        return sectionLabel;
      case 'body':
        return body;
      case 'label':
        return label;
      case 'micro':
        return micro;
      case 'stampLabel':
        return stampLabel;
      case 'wheelLabel':
        return wheelLabel;
      case 'numeric':
        return numeric;
      case 'numericLg':
        return numericLg;
      case 'mono':
        return mono;
      default:
        return body;
    }
  }

  @override
  AngiRoles copyWith({
    TextStyle? display,
    TextStyle? title,
    TextStyle? sectionLabel,
    TextStyle? body,
    TextStyle? label,
    TextStyle? micro,
    TextStyle? stampLabel,
    TextStyle? wheelLabel,
    TextStyle? numeric,
    TextStyle? numericLg,
    TextStyle? mono,
  }) {
    return AngiRoles(
      display: display ?? this.display,
      title: title ?? this.title,
      sectionLabel: sectionLabel ?? this.sectionLabel,
      body: body ?? this.body,
      label: label ?? this.label,
      micro: micro ?? this.micro,
      stampLabel: stampLabel ?? this.stampLabel,
      wheelLabel: wheelLabel ?? this.wheelLabel,
      numeric: numeric ?? this.numeric,
      numericLg: numericLg ?? this.numericLg,
      mono: mono ?? this.mono,
    );
  }

  @override
  AngiRoles lerp(ThemeExtension<AngiRoles>? other, double t) {
    if (other is! AngiRoles) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AngiRoles(
      display: l(display, other.display),
      title: l(title, other.title),
      sectionLabel: l(sectionLabel, other.sectionLabel),
      body: l(body, other.body),
      label: l(label, other.label),
      micro: l(micro, other.micro),
      stampLabel: l(stampLabel, other.stampLabel),
      wheelLabel: l(wheelLabel, other.wheelLabel),
      numeric: l(numeric, other.numeric),
      numericLg: l(numericLg, other.numericLg),
      mono: l(mono, other.mono),
    );
  }
}
