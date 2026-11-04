import 'dart:math' as math;

import 'package:angi_day/bootstrap.dart';
import 'package:angi_day/features/app/presentation/angi_app.dart';
import 'package:angi_day/features/spin/presentation/result_stamp.dart';
import 'package:angi_day/features/spin/presentation/wheel_face.dart';
import 'package:angi_day/features/spin/presentation/wheel_spinner.dart';
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

  /// Chặn tái phát: build() từng đọc _progress mà không có gì lắng nghe controller,
  /// nên vòng quay đứng im suốt duration rồi nhảy thẳng ra tem kết quả.
  testWidgets('vòng quay xoay thật, dừng lại rồi hiện tem kết quả', (tester) async {
    await _boot(tester);

    final spin = find.text('QUAY');
    expect(spin, findsOneWidget);
    await tester.ensureVisible(spin);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(spin);

    // Chờ response về và WheelSpinner (không phải _IdleWheel) được mount.
    for (var i = 0; i < 60 && find.byType(WheelSpinner).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(WheelSpinner), findsOneWidget, reason: 'WheelSpinner không được mount');

    final face = tester.widget<WheelFace>(find.descendant(
      of: find.byType(WheelSpinner),
      matching: find.byType(WheelFace),
    ));
    final animation = face.rotationAnimation;
    expect(animation, isNotNull, reason: 'không có animation ⇒ vòng quay sẽ đứng im');

    final a1 = animation!.value;
    await tester.pump(const Duration(milliseconds: 200));
    final a2 = animation.value;
    await tester.pump(const Duration(milliseconds: 200));
    final a3 = animation.value;

    expect(a2, greaterThan(a1), reason: 'góc không tăng sau 200ms ⇒ vòng quay đứng im');
    expect(a3, greaterThan(a2), reason: 'góc không tăng sau 400ms');

    // Quay đủ nhiều để nhìn thấy, không phải nhích vài độ.
    var sawStamp = false;
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(ResultStamp).evaluate().isNotEmpty) sawStamp = true;
      if (find.byType(WheelSpinner).evaluate().isEmpty && sawStamp) break;
    }

    expect(a3, greaterThan(2 * math.pi), reason: 'phải quay hơn một vòng');
    expect(tester.takeException(), isNull, reason: 'quay xong');
    expect(sawStamp, isTrue, reason: 'quay xong phải hiện tem kết quả');
    expect(find.byType(WheelSpinner), findsNothing, reason: 'animation phải dừng sau khi settle');
  });
}
