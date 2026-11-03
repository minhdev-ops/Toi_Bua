import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap.dart';
import 'core/i18n/app_localizations.dart';
import 'core/telemetry/analytics.dart';
import 'core/theme/angi_icons.dart';
import 'core/theme/angi_tokens.dart';
import 'features/app/presentation/angi_app.dart';

/// `ErrorWidget` không nằm trong subtree `Localizations` ⇒ màn lỗi crash không tự lấy
/// được ARB. Giữ một bản `S` bắt từ build đầu tiên để không hard-code chuỗi (TC-I18N-01).
S? _capturedStrings;

void bindStrings(BuildContext context) {
  final strings = S.of(context);
  if (!identical(strings, _capturedStrings)) _capturedStrings = strings;
}

Future<void> main() async {
  final services = await bootstrap();
  _installErrorBoundary(services.analytics);
  runApp(ProviderScope(child: AngiApp(services: services)));
}

void _installErrorBoundary(Analytics analytics) {
  FlutterError.onError = (details) {
    // Chỉ type + library, không message/stack: chuỗi lỗi có thể chứa địa chỉ hay
    // tên quán mà user vừa nhập (TC-PRIV-04). Debug vẫn in đầy đủ ra console.
    analytics.log(
      AnalyticsEvents.appError,
      properties: {
        'library': details.library ?? 'unknown',
        'exception_type': details.exception.runtimeType.toString(),
      },
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    analytics.log(AnalyticsEvents.appError, properties: {'exception_type': error.runtimeType.toString()});
    return !kDebugMode;
  };

  if (kDebugMode) return;
  // Release: không để vỡ màn hình thành khối hồng — vẫn là một tem, vẫn có lối thoát.
  ErrorWidget.builder = (details) => const _CrashStamp();
}

class _CrashStamp extends StatelessWidget {
  const _CrashStamp();

  @override
  Widget build(BuildContext context) {
    final tokens = AngiTokens.light;
    return ColoredBox(
      color: tokens.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AngiScale.s7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AngiIcons.offline, color: tokens.ink, size: AngiIcons.sizeStamp),
              const SizedBox(height: AngiScale.s5),
              Text(
                _capturedStrings?.errUnknown ?? '',
                textAlign: TextAlign.center,
                style: AngiRoles.build().title.copyWith(color: tokens.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
