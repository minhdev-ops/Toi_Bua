import 'package:dio/dio.dart';

import 'error_mapper.dart';
import 'models/data_quality.dart';
import 'models/meta.dart';
import 'request_id.dart';

/// Header bắt buộc ở mọi request (`docs/01` §4.2).
abstract final class AngiHeaders {
  static const String requestId = 'X-Request-Id';
  static const String deviceId = 'X-Device-Id';
  static const String platform = 'X-Platform';
  static const String appVersion = 'X-App-Version';
  static const String locale = 'X-Locale';
  static const String idempotencyKey = 'X-Idempotency-Key';
  static const String geoPrecision = 'X-Geo-Precision';
  static const String dataQuality = 'X-Data-Quality';

  /// Keys trong `Options.extra`, do interceptor đọc.
  static const String extraIdempotencyOp = 'angi_idempotency_op';
  static const String extraNoAuth = 'angi_no_auth';
}

/// Thông tin install-scoped, không phải ID người dùng.
class ClientIdentity {
  ClientIdentity({
    required this.deviceId,
    required this.platform,
    required this.appVersion,
    this.locale = 'vi',

    /// `exact` chỉ khi user chủ động bật; mặc định `coarse` (SRS 11).
    this.geoPrecision = 'coarse',
  });

  final String deviceId;
  final String platform;
  final String appVersion;
  String locale;
  String geoPrecision;
}

/// Một phản hồi thành công: body đã parse + những gì chỉ có ở header.
class ApiOk {
  const ApiOk({
    required this.json,
    required this.status,
    this.dataQuality,
    this.requestId,
    this.etag,
  });

  final Map<String, dynamic> json;
  final int status;

  /// `X-Data-Quality` **dẫn đầu** `meta.data_quality`: header là chỗ server nói kết quả
  /// này lấy từ đâu; body có thể bị cache ở CDN làm lệch. Vắng header ⇒ tin `meta`.
  final DataQuality? dataQuality;
  final String? requestId;
  final String? etag;
}

/// Wrapper `Dio`: ném `ApiError` cho **mọi** thất bại, trả `ApiOk` cho mọi thành công.
/// Interceptor lo header định danh + token + idempotency; class này chỉ lo hợp đồng call.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Dio get raw => _dio;

  Future<ApiOk> get(String path, {Map<String, dynamic>? query, bool auth = true}) =>
      _send('GET', path, query: query, auth: auth);

  Future<ApiOk> post(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,

    /// `null` ⇒ request **không** ghi (vd `POST /v1/spins`: mỗi lần quay là sự kiện mới,
    /// cấm key — `docs/02` §3.3). Có tên operation ⇒ one key stable qua mọi lần retry.
    String? idempotencyOperation,
  }) =>
      _send('POST', path, body: body, query: query, auth: auth, idempotencyOperation: idempotencyOperation);

  Future<ApiOk> put(String path, {Object? body, Map<String, dynamic>? query, String? idempotencyOperation}) =>
      _send('PUT', path, body: body, query: query, idempotencyOperation: idempotencyOperation);

  Future<ApiOk> patch(String path, {Object? body, Map<String, dynamic>? query, String? idempotencyOperation}) =>
      _send('PATCH', path, body: body, query: query, idempotencyOperation: idempotencyOperation);

  Future<ApiOk> delete(String path, {Map<String, dynamic>? query, String? idempotencyOperation}) =>
      _send('DELETE', path, query: query, idempotencyOperation: idempotencyOperation);

  Future<ApiOk> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
    String? idempotencyOperation,
  }) async {
    final options = Options(
      method: method,
      headers: {AngiHeaders.requestId: Ulid.generate()},
      extra: {
        AngiHeaders.extraIdempotencyOp: ?idempotencyOperation,
        if (!auth) AngiHeaders.extraNoAuth: true,
      },
      responseType: ResponseType.json,
      validateStatus: (code) => code != null && code >= 200 && code < 300,
    );

    DioException? failure;
    try {
      final response = await _dio.request<dynamic>(path, data: body, queryParameters: query, options: options);
      return _toOk(response);
    } on DioException catch (error) {
      failure = error;
      throw mapDioError(error);
    } finally {
      // `retry_policy` gửi lại ngay trong chuỗi interceptor của Dio ⇒ giữ nguyên key
      // cho tới khi thao tác có kết quả cuối cùng; lỗi transport thì không giải phóng key.
      if (idempotencyOperation != null && !_isTransportRetry(failure)) {
        IdempotencyKeys.release(idempotencyOperation);
      }
    }
  }

  bool _isTransportRetry(DioException? error) =>
      error != null &&
      (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError);

  ApiOk _toOk(Response<dynamic> response) {
    final data = response.data;
    final json = data is Map<String, dynamic>
        ? data
        : data is Map
            ? data.map((key, value) => MapEntry('$key', value))
            : <String, dynamic>{};
    return ApiOk(
      json: json,
      status: response.statusCode ?? 200,
      dataQuality: DataQuality.parseOrNull(response.headers.value(AngiHeaders.dataQuality)),
      requestId: response.headers.value(AngiHeaders.requestId),
      etag: response.headers.value('ETag'),
    );
  }
}

/// Body model luôn có `meta`; header là bản chỉnh sửa cuối ⇒ merge tại 1 chỗ duy nhất.
extension MetaFromHeader on ResponseMeta {
  ResponseMeta withHeader(ApiOk ok) => ok.dataQuality == null ? this : copyWith(dataQuality: ok.dataQuality!);
}

/// Gắn 5 header nhận diện install + phiên. `X-Request-Id` đã ở `Options.headers`
/// (mỗi lần gọi một id, server log và trả về để user dán vào ticket).
class ClientHeadersInterceptor extends Interceptor {
  ClientHeadersInterceptor(this.identity);

  final ClientIdentity identity;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[AngiHeaders.deviceId] = identity.deviceId;
    options.headers[AngiHeaders.platform] = identity.platform;
    options.headers[AngiHeaders.appVersion] = identity.appVersion;
    options.headers[AngiHeaders.locale] = identity.locale;
    options.headers[AngiHeaders.geoPrecision] = identity.geoPrecision;
    handler.next(options);
  }
}
