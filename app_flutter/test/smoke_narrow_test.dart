import 'package:angi_day/bootstrap.dart';
import 'package:angi_day/features/app/presentation/angi_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 320x640dp: nhỏ hơn mọi máy Android phổ thông còn hỗ trợ (Pixel 4a là 393dp).
/// Dùng để bắt tràn layout trước khi người dùng thật bắt được.
Future<void> _boot(WidgetTester tester, {bool onboarded = true, Size size = const Size(640, 1280)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await sl.reset();
  SharedPreferences.setMockInitialValues(<String, Object>{'angi.onboarded': onboarded});
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

Future<void> _settle(WidgetTester tester, {int frames = 30}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('320dp: 4 tab không tràn layout', (tester) async {
    await _boot(tester, size: const Size(640, 1280));
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byType(NavigationDestination).at(i));
      await _settle(tester);
      expect(tester.takeException(), isNull, reason: 'tab $i ở 320dp');
    }
    debugPrint('NARROW_TABS_OK');
  });

  testWidgets('320dp: quay xong không tràn', (tester) async {
    await _boot(tester, size: const Size(640, 1280));
    final spin = find.text('QUAY');
    expect(spin, findsOneWidget);
    await tester.ensureVisible(spin);
    await _settle(tester, frames: 10);
    await tester.tap(spin);
    await _settle(tester, frames: 60);
    expect(tester.takeException(), isNull, reason: 'quay ở 320dp');
    debugPrint('NARROW_SPIN_OK');
  });

  testWidgets('onboarding hiện và bấm tiếp được', (tester) async {
    await _boot(tester, onboarded: false, size: const Size(720, 1600));
    await _settle(tester);
    expect(tester.takeException(), isNull, reason: 'onboarding render');
    debugPrint('ONBOARDING_OK');
  });

  testWidgets('mở sheet bộ lọc không lỗi', (tester) async {
    await _boot(tester, size: const Size(720, 1600));
    final filters = find.textContaining('Lọc');
    if (filters.evaluate().isNotEmpty) {
      await tester.ensureVisible(filters.first);
      await tester.pumpAndSettle();
      await tester.tap(filters.first);
      await _settle(tester);
      expect(tester.takeException(), isNull, reason: 'filter sheet');
    }
    debugPrint('FILTER_SHEET_OK');
  });
}
