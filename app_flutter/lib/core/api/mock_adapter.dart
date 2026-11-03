import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Adapter **không mạng**: mọi endpoint trả fixture ở `assets/fixtures/`, đúng hình
/// `docs/02` từng field. Đây là đường chạy P1 khi backend chưa dựng (và là bộ dữ liệu
/// cho contract test), không phải chỗ để tự bịa response.
///
/// Kèm 2 công tắc phục vụ test kịch bản xấu:
/// - `?mock=<tên-không-có-.json>` ⇒ endpoint trả fixture khác (vd `?mock=error_rate_limited`).
/// - `forceOffline = true` ⇒ mọi request fail như mất mạng (FR-ROU-10, TC-ROU-10-A1).
class FixtureAdapter implements HttpClientAdapter {
  FixtureAdapter({this.fixtureDir = 'assets/fixtures', this.latency = Duration.zero});

  final String fixtureDir;
  final Duration latency;

  bool forceOffline = false;

  final Map<String, Map<String, dynamic>> _cache = {};

  /// Bảng path → file. Path có `{id}` khớp theo prefix.
  static const Map<String, String> _routes = {
    'POST /v1/auth/guest': 'auth_guest',
    'POST /v1/spins': 'spins',
    'POST /v1/matches': 'matches',
    'GET /v1/places/urgent': 'urgent',
    'GET /v1/places/nearby': 'nearby',
    'GET /v1/places/': 'place_detail',
    'POST /v1/places/': 'place_report',
    'GET /v1/dishes/taxonomy': 'taxonomy',
    'GET /v1/dishes/bundle': 'dish_bundle',
    'GET /v1/config': 'config',
    'POST /v1/journal/visits': 'journal_visit',
  };

  static const Map<String, String> _assetByFixture = {'dish_bundle': 'assets/bundle/dish_bundle'};

  @override
  void close({bool force = false}) => _cache.clear();

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelToken) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);

    if (forceOffline) {
      throw DioException.connectionError(requestOptions: options, reason: 'mock offline');
    }

    final name = _fixtureName(options);
    if (name == null) {
      return _json({'error': {'code': 'NOT_FOUND', 'message': 'no fixture for ${options.method} ${options.path}', 'request_id': '', 'retryable': false, 'details': []}}, 404);
    }

    final asset = _assetByFixture[name] ?? name;
    final body = await _load(asset);
    if (body == null) {
      return _json({'error': {'code': 'NOT_FOUND', 'message': 'missing fixture $asset', 'retryable': false, 'details': []}}, 404);
    }

    // `place_detail` / `report` có id thật trong path, fixture dùng id mock ⇒ ghi đè để
    // app never sees an id it did not ask for.
    final served = _echoId(options, body);
    final status = name.startsWith('error_') ? _statusFor(served) : 200;
    final quality = _dataQualityOf(served);
    return _json(served, status, quality: quality);
  }

  String? _fixtureName(RequestOptions options) {
    final forced = options.queryParameters['mock'];
    if (forced is String && forced.isNotEmpty) return forced;

    final method = options.method.toUpperCase();
    final path = options.path.replaceAll(RegExp(r'/[a-z]{3}_[0-9A-Za-z]+'), '/{id}');
    final exact = _routes['$method ${options.path}'];
    if (exact != null) return exact;

    for (final entry in _routes.entries) {
      if (entry.key.startsWith('$method ') && path.startsWith(entry.key.substring(entry.key.indexOf(' ') + 1))) return entry.value;
    }
    return null;
  }

  Map<String, dynamic> _echoId(RequestOptions options, Map<String, dynamic> body) {
    final match = RegExp(r'/([a-z]{3}_[0-9A-Za-z]+)$').firstMatch(options.path);
    final requestedId = match?.group(1);
    if (requestedId == null) return body;
    final copy = Map<String, dynamic>.from(body);
    if (copy['id'] is String) copy['id'] = requestedId;
    if (copy['place'] is Map<String, dynamic>) {
      final place = Map<String, dynamic>.from(copy['place'] as Map<String, dynamic>)..['id'] = requestedId;
      copy['place'] = place;
    }
    return copy;
  }

  int _statusFor(Map<String, dynamic> body) {
    final code = (body['error'] as Map<String, dynamic>?)?['code'];
    switch (code) {
      case 'VALIDATION_FAILED':
        return 400;
      case 'POOL_TOO_SMALL':
      case 'IDEMPOTENCY_REPLAY':
        return 409;
      case 'DIET_FILTER_EMPTY':
      case 'FILTER_CONTRADICTION':
        return 422;
      case 'RATE_LIMITED':
        return 429;
      case 'PROVIDER_UNAVAILABLE':
        return 424;
      case 'DEGRADED_NO_RESULT':
        return 503;
      default:
        return 500;
    }
  }

  String? _dataQualityOf(Map<String, dynamic> body) {
    final meta = body['meta'];
    if (meta is Map && meta['data_quality'] is String) return meta['data_quality'] as String;
    return null;
  }

  Future<Map<String, dynamic>?> _load(String asset) async {
    if (_cache.containsKey(asset)) return _cache[asset];
    try {
      final path = asset.startsWith('assets/') ? '$asset.json' : '$fixtureDir/$asset.json';
      final text = await rootBundle.loadString(path);
      final decoded = jsonDecode(text);
      final map = decoded is Map<String, dynamic> ? decoded : Map<String, dynamic>.from(decoded as Map);
      _cache[asset] = map;
      return map;
    } catch (_) {
      return null;
    }
  }

  ResponseBody _json(Map<String, dynamic> body, int status, {String? quality}) {
    return ResponseBody(
      Stream<Uint8List>.value(Uint8List.fromList(utf8.encode(jsonEncode(body)))),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        'X-Data-Quality': [if (quality != null) quality else 'fresh'],
        'X-Request-Id': ['MOCK${body['error'] != null ? '' : 'OK'}'],
        'Cache-Control': ['private, max-age=0, must-revalidate'],
      },
    );
  }
}
