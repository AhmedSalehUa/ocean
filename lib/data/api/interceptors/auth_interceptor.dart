import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  static const tokenKey = 'trail.jwt';
  final FlutterSecureStorage _storage;
  String? _cachedToken;

  Future<String?> _token() async {
    _cachedToken ??= await _storage.read(key: tokenKey);
    return _cachedToken;
  }

  /// Read the saved token into memory (if any) so it is ready for the next
  /// request, and report whether one exists. Used at startup to decide if a
  /// session can be restored offline.
  Future<bool> primeToken() async => (await _token()) != null;

  Future<void> setToken(String? token) async {
    _cachedToken = token;
    if (token == null) {
      await _storage.delete(key: tokenKey);
    } else {
      await _storage.write(key: tokenKey, value: token);
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final t = await _token();
    if (t != null) options.headers['Authorization'] = 'Bearer $t';
    handler.next(options);
  }
}
