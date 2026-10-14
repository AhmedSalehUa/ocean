import 'package:dio/dio.dart';

import '../offline_cache_store.dart';

/// Caches successful GET responses and, when the device can't reach the
/// server (network error / timeout), replays the last cached response so the
/// app stays browsable offline. Writes and real HTTP errors are untouched.
///
/// Must sit FIRST in the interceptor chain so its `onError` runs before the
/// envelope interceptor converts/rejects the error.
class OfflineCacheInterceptor extends Interceptor {
  OfflineCacheInterceptor(this._store);
  final OfflineCacheStore _store;

  bool _isGet(RequestOptions o) => o.method.toUpperCase() == 'GET';

  String _key(RequestOptions o) {
    final u = o.uri;
    return u.query.isEmpty ? u.path : '${u.path}?${u.query}';
  }

  bool _isConnectivityError(DioException err) =>
      err.type == DioExceptionType.connectionError ||
      err.type == DioExceptionType.connectionTimeout ||
      err.type == DioExceptionType.receiveTimeout ||
      err.type == DioExceptionType.sendTimeout ||
      (err.type == DioExceptionType.unknown && err.response == null);

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final o = response.requestOptions;
    final code = response.statusCode ?? 0;
    if (_isGet(o) && code >= 200 && code < 300) {
      final data = response.data;
      if (data is Map || data is List) {
        // Fire-and-forget; never block the live response on a disk write.
        _store.put(_key(o), data);
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final o = err.requestOptions;
    if (_isGet(o) && _isConnectivityError(err)) {
      final cached = _store.get(_key(o));
      if (cached != null && cached.data != null) {
        handler.resolve(Response(
          requestOptions: o,
          data: cached.data,
          statusCode: 200,
          extra: {'fromCache': true, 'cachedAt': cached.at?.toIso8601String()},
        ));
        return;
      }
    }
    handler.next(err);
  }
}
