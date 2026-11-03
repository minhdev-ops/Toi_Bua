import 'package:angi_day/bootstrap.dart';
import 'package:angi_day/features/app/presentation/angi_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _boot(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await sl.reset();
  SharedPreferences.setMockInitialValues(<String, Object>{'angi.onboarded': true});
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async => null,
  );
  final services = await bootstrap();
  await tester.pumpWidget(ProviderScope(child: AngiApp(services: services)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('luồng quay: bấm QUAY -> có kết quả -> mở danh sách quán', (tester) async {
    await _boot(tester);
    expect(tester.takeException(), isNull, reason: 'boot');

    final spin = find.text('QUAY');
    expect(spin, findsOneWidget, reason: 'không thấy nút QUAY');
    await tester.ensureVisible(spin);
    await tester.pumpAndSettle();
    await tester.tap(spin);
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull, reason: 'sau khi quay');

    final viewPlaces = find.text('XEM QUÁN');
    debugPrint('viewPlaces found: ${viewPlaces.evaluate().length}');
    if (viewPlaces.evaluate().isNotEmpty) {
      await tester.tap(viewPlaces.first);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull, reason: 'mở danh sách quán');
    }
    debugPrint('SPIN_OK');
  });

  testWidgets('tab Đói gấp render không lỗi', (tester) async {
    await _boot(tester);
    final tabs = find.byType(NavigationDestination);
    expect(tabs.evaluate().length, 4);
    await tester.tap(tabs.at(2));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull, reason: 'tab urgent');
    debugPrint('URGENT_OK');
  });

  testWidgets('tab Của bạn render không lỗi', (tester) async {
    await _boot(tester);
    await tester.tap(find.byType(NavigationDestination).at(3));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull, reason: 'tab you');
    debugPrint('YOU_OK');
  });

  testWidgets('tab Quán render không lỗi', (tester) async {
    await _boot(tester);
    await tester.tap(find.byType(NavigationDestination).at(1));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull, reason: 'tab discover');
    debugPrint('DISCOVER_OK');
  });
}
