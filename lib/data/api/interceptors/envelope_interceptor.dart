import 'package:dio/dio.dart';

import '../../../core/errors/api_exception.dart';

/// Translates HTTP errors into [ApiException] and lets handlers receive raw
/// `{success, message, data, meta}` envelopes.
class EnvelopeInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final res = err.response;
    String message = err.message ?? 'Network error';
    if (res?.data is Map && (res!.data as Map)['message'] is String) {
      message = (res.data as Map)['message'] as String;
    }
    handler.reject(DioException(
      requestOptions: err.requestOptions,
      response: res,
      type: err.type,
      error: ApiException(message, statusCode: res?.statusCode),
    ));
  }
}
