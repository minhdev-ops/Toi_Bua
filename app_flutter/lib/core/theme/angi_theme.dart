import 'package:flutter/material.dart';

import 'angi_tokens.dart';

/// Theme Material 3 được tô bằng token đã khoá. Không viết lại widget Material.
abstract final class AngiTheme {
  static ThemeData light() => _build(AngiTokens.light, Brightness.light);
  static ThemeData dark() => _build(AngiTokens.dark, Brightness.dark);

  static ThemeData _build(AngiTokens t, Brightness brightness) {
    final roles = AngiRoles.build();
    final scheme = ColorScheme(
      brightness: brightness,
      primary: t.accent,
      onPrimary: t.onAccent,
      primaryContainer: t.accent,
      onPrimaryContainer: t.onAccent,
      secondary: t.infoFill,
      onSecondary: t.onFill,
      secondaryContainer: t.sunken,
      onSecondaryContainer: t.ink,
      tertiary: t.successFill,
      onTertiary: t.onFill,
      error: t.dangerText,
      onError: t.surface,
      errorContainer: t.dangerFill,
      onErrorContainer: t.onFill,
      surface: t.surface,
      onSurface: t.ink,
      onSurfaceVariant: t.muted,
      surfaceContainerLowest: t.background,
      surfaceContainerLow: t.surface,
      surfaceContainer: t.surface,
      surfaceContainerHigh: t.sunken,
      surfaceContainerHighest: t.sunken,
      surfaceBright: t.sunken,
      surfaceDim: t.background,
      inverseSurface: t.ink,
      onInverseSurface: t.background,
      inversePrimary: t.accent,
      outline: t.line,
      outlineVariant: t.line,
      shadow: t.ink,
      scrim: t.ink,
    );

    final textTheme = TextTheme(
      displaySmall: roles.display.copyWith(color: t.ink),
      headlineMedium: roles.title.copyWith(color: t.ink),
      titleSmall: roles.sectionLabel.copyWith(color: t.muted),
      bodyMedium: roles.body.copyWith(color: t.ink),
      bodySmall: roles.micro.copyWith(color: t.muted),
      labelLarge: roles.label.copyWith(color: t.ink),
      labelMedium: roles.stampLabel.copyWith(color: t.onAccent),
    );

    final border = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AngiScale.radiusMd),
      side: BorderSide(color: t.ink, width: AngiScale.outline),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.background,
      canvasColor: t.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      disabledColor: t.muted,
      focusColor: t.focus,
      textTheme: textTheme,
      fontFamily: AngiRoles.bodyFamily,
      extensions: [t, roles],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: t.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: roles.title.copyWith(color: t.ink),
        iconTheme: IconThemeData(color: t.ink, weight: 600),
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: border,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AngiScale.radiusLg)),
          side: BorderSide(color: t.ink, width: AngiScale.outline),
        ),
        showDragHandle: true,
        dragHandleColor: t.muted,
        modalBackgroundColor: t.surface,
        constraints: const BoxConstraints(minHeight: 200),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: border,
        titleTextStyle: roles.title.copyWith(color: t.ink),
        contentTextStyle: roles.body.copyWith(color: t.ink),
      ),
      dividerTheme: DividerThemeData(
        color: t.line,
        thickness: AngiScale.divider,
        space: AngiScale.divider,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: t.ink,
        textColor: t.ink,
        titleTextStyle: roles.label.copyWith(color: t.ink),
        subtitleTextStyle: roles.micro.copyWith(color: t.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AngiScale.s5,
          vertical: AngiScale.s3,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.ink,
        contentTextStyle: roles.label.copyWith(color: t.background),
        actionTextColor: t.accent,
        behavior: SnackBarBehavior.floating,
        elevation: AngiScale.zToast,
        shape: border,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.ink,
          minimumSize: const Size(AngiScale.touchMin, AngiScale.touchMin),
          padding: const EdgeInsets.symmetric(horizontal: AngiScale.s4),
          shape: const StadiumBorder(),
          textStyle: roles.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.ink,
          minimumSize: const Size(AngiScale.touchMin, AngiScale.touchMin),
          side: BorderSide(color: t.ink, width: AngiScale.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AngiScale.radiusMd),
          ),
          textStyle: roles.label,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: t.ink,
          minimumSize: const Size(AngiScale.touchMin, AngiScale.touchMin),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: t.accent,
        inactiveTrackColor: t.sunken,
        thumbColor: t.ink,
        overlayColor: t.focus.withValues(alpha: 0.18),
        valueIndicatorColor: t.ink,
        valueIndicatorTextStyle: roles.label.copyWith(color: t.background),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? t.onAccent : t.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? t.accent : t.sunken,
        ),
        trackOutlineColor: WidgetStateProperty.all(t.ink),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? t.accent : t.surface,
        ),
        checkColor: WidgetStateProperty.all(t.onAccent),
        side: BorderSide(color: t.ink, width: AngiScale.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AngiScale.radiusXs)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? t.onAccent : t.muted,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.surface,
        selectedColor: t.accent,
        side: BorderSide(color: t.ink, width: AngiScale.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AngiScale.radiusSm),
        ),
        labelStyle: roles.label.copyWith(color: t.ink),
        secondaryLabelStyle: roles.label.copyWith(color: t.onAccent),
        padding: const EdgeInsets.symmetric(
          horizontal: AngiScale.s3,
          vertical: AngiScale.s2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: t.accent,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? roles.label.copyWith(color: t.onAccent)
              : roles.label.copyWith(color: t.muted),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? t.onAccent : t.ink,
            size: 24,
            weight: 600,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.accent,
        linearTrackColor: t.sunken,
        circularTrackColor: t.sunken,
      ),
      dividerColor: t.line,
      iconTheme: IconThemeData(color: t.ink, weight: 600),
    );
  }
}
