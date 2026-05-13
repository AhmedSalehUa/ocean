import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

/// Logs every API request, response, and error. Bodies are JSON-encoded when
/// possible; `FormData` is summarized (multipart bodies can be large/binary).
/// Authorization headers are redacted.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({this.maxBodyChars = 2000});

  /// Truncate logged bodies to this many characters.
  final int maxBodyChars;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final url = options.uri.toString();
    developer.log('→ ${options.method} $url', name: 'api');
    final headers = _redactHeaders(options.headers);
    if (headers.isNotEmpty) developer.log('  headers: $headers', name: 'api');
    final body = _formatBody(options.data);
    if (body != null) developer.log('  body: $body', name: 'api');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final url = response.requestOptions.uri.toString();
    final status = response.statusCode ?? 0;
    developer.log('← $status ${response.requestOptions.method} $url',
        name: 'api');
    final body = _formatBody(response.data);
    if (body != null) developer.log('  body: $body', name: 'api');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final url = err.requestOptions.uri.toString();
    final status = err.response?.statusCode ?? 0;
    developer.log(
        '✗ $status ${err.requestOptions.method} $url — ${err.message ?? err.type.name}',
        name: 'api');
    final body = _formatBody(err.response?.data);
    if (body != null) developer.log('  body: $body', name: 'api');
    handler.next(err);
  }

  String? _formatBody(Object? data) {
    if (data == null) return null;
    if (data is FormData) {
      final fields = data.fields.map((e) => '${e.key}=${e.value}').join(', ');
      final files = data.files
          .map((e) =>
              '${e.key}=<file ${e.value.filename ?? ''} ${e.value.length}B>')
          .join(', ');
      return '<multipart fields={$fields} files={$files}>';
    }
    String text;
    try {
      text = data is String ? data : jsonEncode(data);
    } catch (_) {
      text = data.toString();
    }
    if (text.length > maxBodyChars) {
      text = '${text.substring(0, maxBodyChars)}… (+${text.length - maxBodyChars} chars)';
    }
    return text;
  }

  Map<String, dynamic> _redactHeaders(Map<String, dynamic> headers) {
    final out = <String, dynamic>{};
    headers.forEach((k, v) {
      out[k] = k.toLowerCase() == 'authorization' ? '<redacted>' : v;
    });
    return out;
  }
}
