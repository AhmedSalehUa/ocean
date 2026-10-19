import 'dart:convert';

import 'package:dio/dio.dart';

import '../offline_cache_store.dart';

/// Transparent read cache. On every successful GET it stores the raw
/// `{success, message, data, meta}` envelope; when a later GET fails because
/// the network is unreachable (no HTTP response came back) it replays the
/// last-stored envelope so the app shows last-synced data offline.
///
/// Must be registered BEFORE [EnvelopeInterceptor] so its [onError] runs first
/// and can resolve from cache before the envelope interceptor rejects.
class OfflineCacheInterceptor extends Interceptor {
  OfflineCacheInterceptor(this._cache);
  final OfflineCacheStore _cache;

  bool _isGet(RequestOptions o) => o.method.toUpperCase() == 'GET';
  String _key(RequestOptions o) => o.uri.toString();

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final o = response.requestOptions;
    final code = response.statusCode ?? 0;
    if (_isGet(o) && code >= 200 && code < 300 && response.data is Map) {
      // Fire-and-forget; caching must never block or fail the real response.
      _cache.put(_key(o), jsonEncode(response.data));
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final o = err.requestOptions;
    // Only fall back to cache for genuine connectivity failures — i.e. no HTTP
    // response arrived. A real 4xx/5xx (err.response != null) is a server
    // answer and must surface, never be masked by stale cache.
    if (_isGet(o) && err.response == null) {
      final cached = _cache.get(_key(o));
      if (cached != null) {
        try {
          handler.resolve(Response(
            requestOptions: o,
            data: jsonDecode(cached),
            statusCode: 200,
            extra: const {'fromCache': true},
          ));
          return;
        } catch (_) {
          // Corrupt cache entry — fall through to the real error.
        }
      }
    }
    handler.next(err);
  }
}
