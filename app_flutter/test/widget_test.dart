import 'package:angi_day/core/api/models/score.dart';
import 'package:angi_day/core/i18n/app_localizations.dart';
import 'package:angi_day/core/theme/angi_theme.dart';
import 'package:angi_day/features/discover/presentation/why_sheet.dart';
import 'package:angi_day/shared/widgets/stamp_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('vi'),
    supportedLocales: S.supportedLocales,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: AngiTheme.light(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  testWidgets('StampButton đọc nhãn từ ARB và bấm được', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(StampButton(label: (s) => s.ctaSpin, onPressed: () => taps++)));
    expect(find.text('QUAY'), findsOneWidget);

    await tester.tap(find.text('QUAY'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('WhySheet vẽ đúng score_total và 5 thành phần', (tester) async {
    const breakdown = ScoreBreakdown(
      formulaVersion: '2026.10',
      weights: {'Q': 0.35, 'D': 0.25, 'P': 0.15, 'O': 0.15, 'U': 0.10},
      scoreTotal: 68.85,
      components: [
        ScoreComponent(key: 'Q', label: 'Chất lượng', valueNorm: 0.71, contribution: 24.85, top: true, whyKey: 'why.q.top', whyParams: {'rating': '4.3', 'count': '182'}),
        ScoreComponent(key: 'D', label: 'Gần bạn', valueNorm: 0.5, contribution: 12.5, whyKey: 'why.d.top', whyParams: {'distance': '420'}),
        ScoreComponent(key: 'P', label: 'Hợp túi tiền', valueNorm: 1, contribution: 15),
        ScoreComponent(key: 'O', label: 'Đang mở', valueNorm: 1, contribution: 15),
        ScoreComponent(key: 'U', label: 'Hợp khẩu vị', valueNorm: 0.55, contribution: 5.5),
      ],
    );

    await tester.pumpWidget(_app(const WhySheet(breakdown: breakdown)));
    await tester.pumpAndSettle();

    expect(find.text('68.85'), findsOneWidget);
    expect(find.text('Vì sao gợi ý quán này?'), findsOneWidget);
    expect(find.textContaining('Điểm cao nhờ'), findsWidgets);
    expect(find.textContaining('+24.85'), findsOneWidget);
  });
}
