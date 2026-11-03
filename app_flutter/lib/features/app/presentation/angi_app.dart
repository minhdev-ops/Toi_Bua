import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bootstrap.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/angi_motion.dart';
import '../../../core/theme/angi_theme.dart';
import '../../../main.dart' show bindStrings;
import '../application/app_providers.dart';
import 'home_shell.dart';

class AngiApp extends ConsumerWidget {
  const AngiApp({required this.services, super.key});

  final AppServices services;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      onGenerateTitle: (context) => S.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AngiTheme.light(),
      darkTheme: AngiTheme.dark(),
      themeMode: settings.themeMode,
      // NFR-11: mặc định tiếng Việt, đổi được trong Của bạn.
      locale: settings.locale,
      supportedLocales: S.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        bindStrings(context);
        return AngiMotionPrefs(settings: settings.value, child: child ?? const SizedBox.shrink());
      },
      home: const HomeShell(),
    );
  }
}
