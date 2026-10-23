import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/errors/api_exception.dart';
import '../models/master_po.dart';
import '../models/proof_log.dart';
import '../models/user.dart';
import '../models/vendor_po.dart';
import '../models/workflow_step.dart';
import 'delivery_api.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/envelope_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'offline_cache_store.dart';

class HttpDeliveryApi implements DeliveryApi {
  HttpDeliveryApi({required this.baseUrl, FlutterSecureStorage? storage, OfflineCacheStore? cache})
      : _auth = AuthInterceptor(storage ?? const FlutterSecureStorage()),
        _cache = cache {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ));
    _dio.interceptors.addAll([_auth, LoggingInterceptor(), EnvelopeInterceptor()]);
  }

  final String baseUrl;
  late final Dio _dio;
  final AuthInterceptor _auth;
  final OfflineCacheStore? _cache;

  Map<String, dynamic> _unwrap(Response r) => _unwrapData(r.data, r.statusCode);

  Map<String, dynamic> _unwrapData(dynamic body, int? statusCode) {
    if (body is! Map<String, dynamic>) {
      throw ApiException('Malformed response', statusCode: statusCode);
    }
    if (body['success'] != true) {
      throw ApiException(body['message']?.toString() ?? 'Request failed',
          statusCode: statusCode);
    }
    return body;
  }

  /// GET with a transparent offline fallback: on success the raw envelope is
  /// cached and returned; if the network is unreachable (no HTTP response came
  /// back) the last-cached envelope for this path is replayed so the app shows
  /// last-synced data offline. A real server error (4xx/5xx) is never masked.
  Future<Map<String, dynamic>> _getJson(String path) async {
    try {
      final r = await _dio.get(path);
      final body = _unwrapData(r.data, r.statusCode);
      _cache?.put(path, jsonEncode(r.data));
      return body;
    } on DioException catch (e) {
      final cache = _cache;
      if (e.response == null && cache != null) {
        final cached = cache.get(path);
        if (cached != null) {
          try {
            return _unwrapData(jsonDecode(cached), 200);
          } catch (_) {/* corrupt entry — fall through to the real error */}
        }
      }
      rethrow;
    }
  }

  // ─────────────────────────── Auth ───────────────────────────

  @override
  Future<AuthResult> login({required String username, required String password}) async {
    final r = await _dio.post('/api/delivery/auth/login',
        data: {'username': username, 'password': password});
    final body = _unwrap(r);
    final result = AuthResult.fromJson(body['data'] as Map<String, dynamic>);
    if (!result.user.isRepresentative) {
      throw const ApiException('Only REPRESENTATIVE users can use this app',
          statusCode: 403);
    }
    await _auth.setToken(result.token);
    return result;
  }

  @override
  Future<User> me() async {
    final r = await _dio.get('/api/delivery/auth/me');
    final body = _unwrap(r);
    final data = body['data'] as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post('/api/delivery/auth/logout');
    } finally {
      await _auth.setToken(null);
    }
  }

  @override
  Future<bool> hasStoredToken() => _auth.primeToken();

  // ─────────────────────────── Lists ───────────────────────────

  @override
  Future<List<MasterPo>> listMasterPos() async {
    final body = await _getJson('/api/delivery/mobile/master-pos');
    final list = (body['data'] as List).cast<Map<String, dynamic>>();
    return list.map(MasterPo.fromJson).toList();
  }

  @override
  Future<({List<VendorPo> vendors, String masterPoNumber})> listVendorPos(
      String masterPoId) async {
    final body = await _getJson('/api/delivery/mobile/master-pos/$masterPoId/vendor-pos');
    final list = (body['data'] as List).cast<Map<String, dynamic>>();
    final meta = body['meta'] as Map<String, dynamic>? ?? const {};
    return (
      vendors: list.map(VendorPo.fromJson).toList(),
      masterPoNumber: meta['master_po_number']?.toString() ?? '',
    );
  }

  @override
  Future<VendorPo> getVendorPo(String vendorPoId) async {
    final body = await _getJson('/api/delivery/mobile/vendor-pos/$vendorPoId');
    return VendorPo.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<WorkflowStep>> getSteps(String vendorPoId) async {
    final body = await _getJson('/api/delivery/mobile/vendor-pos/$vendorPoId/steps');
    final list = (body['data'] as List).cast<Map<String, dynamic>>();
    return list.map(WorkflowStep.fromJson).toList();
  }

  @override
  Future<ProofHistory> getProofs(String vendorPoId) async {
    final body = await _getJson('/api/delivery/mobile/vendor-pos/$vendorPoId/proofs');
    return ProofHistory.fromJson(body['data'] as Map<String, dynamic>);
  }

  // ─────────────────────────── Mutations ───────────────────────────

  @override
  Future<VendorPo> startVendorPo(String vendorPoId) async {
    final r = await _dio.post('/api/delivery/mobile/vendor-pos/$vendorPoId/start');
    final body = _unwrap(r);
    return VendorPo.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<ProofLog> uploadShipmentPhoto({
    required String vendorPoId,
    required String stepId,
    required File file,
    double? lat,
    double? lng,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    });
    final r = await _dio.post(
      '/api/delivery/mobile/vendor-pos/$vendorPoId/shipment-steps/$stepId/photo',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    final body = _unwrap(r);
    return ProofLog.fromJson(body['data'] as Map<String, dynamic>, ProofKind.shipment);
  }

  @override
  Future<ProofLog> uploadItemPhoto({
    required String vendorPoId,
    required String itemId,
    required String stepId,
    required File file,
    double? lat,
    double? lng,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    });
    final r = await _dio.post(
      '/api/delivery/mobile/vendor-pos/$vendorPoId/items/$itemId/steps/$stepId/photo',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    final body = _unwrap(r);
    return ProofLog.fromJson(body['data'] as Map<String, dynamic>, ProofKind.item);
  }

  @override
  Future<void> markItemMissing({required String vendorPoId, required String itemId}) async {
    final r = await _dio.post('/api/delivery/mobile/vendor-pos/$vendorPoId/items/$itemId/missing');
    _unwrap(r);
  }

  @override
  Future<VendorPo> finalizeVendorPo(String vendorPoId) async {
    final r = await _dio.post('/api/delivery/mobile/vendor-pos/$vendorPoId/finalize');
    final body = _unwrap(r);
    return VendorPo.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  String attachmentUrl(String attachmentId) =>
      '$baseUrl/api/delivery/mobile/attachments/$attachmentId/file';

  @override
  String absoluteUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final sep = path.startsWith('/') ? '' : '/';
    return '$baseUrl$sep$path';
  }
}
