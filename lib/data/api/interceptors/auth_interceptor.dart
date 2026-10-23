import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  static const tokenKey = 'trail.jwt';
  final FlutterSecureStorage _storage;
  String? _cachedToken;

  String? get currentToken => _cachedToken;

  Future<String?> _token() async {
    try {
      _cachedToken ??= await _storage.read(key: tokenKey);
    } catch (_) {
      // Secure storage can throw on some devices (locked keystore, etc.) —
      // treat as "no token" rather than crashing session restore at startup.
    }
    return _cachedToken;
  }

  /// Eagerly populates [_cachedToken] from secure storage so synchronous
  /// readers (e.g. CachedNetworkImage's http headers) get a value even on
  /// the first network call after a cold start.
  Future<String?> ensureLoaded() => _token();

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
