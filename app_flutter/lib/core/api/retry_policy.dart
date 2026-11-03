import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import 'dio_client.dart';

/// Backoff cho request **an toàn khi lặp lại**:
/// GET/HEAD, hoặc ghi có `X-Idempotency-Key` (TC-API-04: retry yếu mạng ⇒ 0 record trùng).
/// Không retry `429`: spec bắt app **ẩn** nút + đếm ngược `retry_after_s`, retry ngầm sẽ
/// khiến user thấy nút chết không lý do.
class RetryPolicyInterceptor extends Interceptor {
  RetryPolicyInterceptor({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 300),
    this.maxDelay = const Duration(seconds: 4),
    Dio? retryDio,
    Random? random,
  })  : _random = random ?? Random(),
        _retryDio = retryDio;

  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final Random _random;

  /// Dio không gắn chính interceptor này ⇒ vòng retry không nhân đôi chuỗi interceptor.
  Dio? _retryDio;

  set retryDio(Dio value) => _retryDio = value;

  static const String _attemptKey = 'angi_retry_attempt';

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (_retryDio == null || !_shouldRetry(err) || !_isSafeToRepeat(options)) {
      return handler.next(err);
    }

    final attempt = (options.extra[_attemptKey] as int? ?? 0) + 1;
    if (attempt > maxAttempts) return handler.next(err);

    final wait = _backoff(err, attempt);
    if (wait != Duration.zero) await Future<void>.delayed(wait);

    options.extra[_attemptKey] = attempt;
    try {
      final response = await _retryDio!.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  bool _isSafeToRepeat(RequestOptions options) {
    final method = options.method.toUpperCase();
    if (method == 'GET' || method == 'HEAD') return true;
    return options.headers.containsKey(AngiHeaders.idempotencyKey);
  }

  bool _shouldRetry(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        return status == 503 || status == 504 || status >= 500;
      default:
        return false;
    }
  }

  /// `Retry-After` thắng; không có thì exponential 300 → 900 → 2700ms + jitter ≤ 200ms.
  Duration _backoff(DioException err, int attempt) {
    final header = int.tryParse(err.response?.headers.value('Retry-After') ?? '');
    if (header != null && header > 0) {
      return Duration(seconds: min(header, maxDelay.inSeconds));
    }
    final scaled = baseDelay.inMilliseconds * (1 << (attempt - 1));
    return Duration(milliseconds: min(scaled + _random.nextInt(200), maxDelay.inMilliseconds));
  }
}
