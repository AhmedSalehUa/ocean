import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/errors/api_exception.dart';
import '../models/delivery_note.dart';
import '../models/master_po.dart';
import '../models/proof_log.dart';
import '../models/user.dart';
import '../models/vendor_po.dart';
import '../models/workflow_step.dart';
import 'delivery_api.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/envelope_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

class HttpDeliveryApi implements DeliveryApi {
  HttpDeliveryApi({required this.baseUrl, FlutterSecureStorage? storage})
      : _auth = AuthInterceptor(storage ?? const FlutterSecureStorage()) {
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

  Map<String, dynamic> _unwrap(Response r) {
    final body = r.data;
    if (body is! Map<String, dynamic>) {
      throw ApiException('Malformed response', statusCode: r.statusCode);
    }
    if (body['success'] != true) {
      throw ApiException(body['message']?.toString() ?? 'Request failed', statusCode: r.statusCode);
    }
    return body;
  }

  // ─────────────────────────── Auth ───────────────────────────

  @override
  Future<AuthResult> login({required String username, required String password}) async {
    final r = await _dio
        .post('/api/delivery/auth/login', data: {'username': username, 'password': password});
    final body = _unwrap(r);
    final result = AuthResult.fromJson(body['data'] as Map<String, dynamic>);
    if (!result.user.isRepresentative) {
      throw const ApiException('Only REPRESENTATIVE users can use this app', statusCode: 403);
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

  // ─────────────────────────── Lists ───────────────────────────

  @override
  Future<List<MasterPo>> listMasterPos() async {
    final r = await _dio.get('/api/delivery/mobile/master-pos');
    final body = _unwrap(r);
    final list = (body['data'] as List).cast<Map<String, dynamic>>();
    return list.map(MasterPo.fromJson).toList();
  }

  @override
  Future<({List<VendorPo> vendors, String masterPoNumber})> listVendorPos(String masterPoId) async {
    final r = await _dio.get('/api/delivery/mobile/master-pos/$masterPoId/vendor-pos');
    final body = _unwrap(r);
    final list = (body['data'] as List).cast<Map<String, dynamic>>();
    final meta = body['meta'] as Map<String, dynamic>? ?? const {};
    return (
      vendors: list.map(VendorPo.fromJson).toList(),
      masterPoNumber: meta['master_po_number']?.toString() ?? '',
    );
  }

  @override
  Future<VendorPo> getVendorPo(String vendorPoId) async {
    final r = await _dio.get('/api/delivery/mobile/vendor-pos/$vendorPoId');
    final body = _unwrap(r);
    return VendorPo.fromJson(body['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<WorkflowStep>> getSteps(String vendorPoId) async {
    final r = await _dio.get('/api/delivery/mobile/vendor-pos/$vendorPoId/steps');
    final body = _unwrap(r);
    final list = (body['data'] as List).cast<Map<String, dynamic>>();
    return list.map(WorkflowStep.fromJson).toList();
  }

  @override
  Future<ProofHistory> getProofs(String vendorPoId) async {
    final r = await _dio.get('/api/delivery/mobile/vendor-pos/$vendorPoId/proofs');
    final body = _unwrap(r);
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
    double? accuracyMeters,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      if (lat != null) 'location_latitude': lat,
      if (lng != null) 'location_longitude': lng,
      if (accuracyMeters != null) 'location_accuracy_meters': accuracyMeters,
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
    double? accuracyMeters,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
      if (lat != null) 'location_latitude': lat,
      if (lng != null) 'location_longitude': lng,
      if (accuracyMeters != null) 'location_accuracy_meters': accuracyMeters,
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
  Future<void> markItemRejected({
    required String vendorPoId,
    required String itemId,
    required String stepId,
  }) async {
    final r = await _dio.post(
      '/api/delivery/mobile/vendor-pos/$vendorPoId/items/$itemId/steps/$stepId/rejected',
    );
    _unwrap(r);
  }

  @override
  Future<VendorPo> finalizeVendorPo(String vendorPoId) async {
    final r = await _dio.post('/api/delivery/mobile/vendor-pos/$vendorPoId/finalize');
    final body = _unwrap(r);
    return VendorPo.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Directory> _deliveryNoteDir() async {
    Directory base;
    if (Platform.isAndroid) {
      base = (await getExternalStorageDirectory()) ?? (await getApplicationDocumentsDirectory());
    } else {
      base = await getApplicationDocumentsDirectory();
    }
    final subdir = Directory('${base.path}/delivery-notes');
    if (!await subdir.exists()) await subdir.create(recursive: true);
    return subdir;
  }

  // ─────────────────────── Delivery note ───────────────────────
  @override
  @override
  Future<File> downloadDeliveryNote(String masterPoId, {DeliveryNote? note}) async {
    final subdir = await _deliveryNoteDir();

    if (!await subdir.exists()) await subdir.create(recursive: true);
    final tempPath = '${subdir.path}/master-$masterPoId.download';
    try {
      final prev = File(tempPath);
      if (await prev.exists()) await prev.delete();
    } catch (_) {}

    Response response;
    try {
      response = await _dio.download(
        '/api/delivery/mobile/master-pos/$masterPoId/delivery-note',
        tempPath,
        options: Options(
          // Do NOT override responseType — Dio's download() streams to disk
          // and needs the default stream response type.
          validateStatus: (code) => code != null && code < 500,
        ),
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404) {
        throw const ApiException('No delivery note uploaded yet', statusCode: 404);
      }
      rethrow;
    }

    final status = response.statusCode ?? 0;
    if (status == 404) {
      throw const ApiException('No delivery note uploaded yet', statusCode: 404);
    }
    if (status >= 400) {
      throw ApiException('Download failed', statusCode: status);
    }

    final contentType = response.headers.value('content-type')?.toLowerCase() ?? '';

    if (contentType.startsWith('application/json')) {
      String message = 'Server returned an error envelope instead of a file';
      try {
        final raw = await File(tempPath).readAsString();
        message = raw.length > 400 ? raw.substring(0, 400) : raw;
      } catch (_) {}
      try {
        await File(tempPath).delete();
      } catch (_) {}
      throw ApiException(message, statusCode: status);
    }

    final tempFile = File(tempPath);
    final size = await tempFile.length();
    if (size == 0) {
      try {
        await tempFile.delete();
      } catch (_) {}
      throw ApiException('Server returned an empty file', statusCode: status);
    }

    final disposition = response.headers.value('content-disposition') ?? '';
    final metaName = note?.fileName;

    final ctExt = _extensionFromContentType(contentType);
    final rfc5987 = _rfc5987FilenameFrom(disposition);
    final plainName = _plainFilenameFrom(disposition);
    final finalName = (metaName != null && metaName.contains('.'))
        ? metaName
        : rfc5987 ?? plainName ?? 'delivery-note-$masterPoId${ctExt.isEmpty ? '' : '.$ctExt'}';
    final finalPath = '${subdir.path}/$finalName';
    if (finalPath != tempPath) {
      try {
        await tempFile.rename(finalPath);
      } catch (_) {
        await tempFile.copy(finalPath);
        try {
          await tempFile.delete();
        } catch (_) {}
      }
    }
    return File(finalPath);
  }

  String _extensionFromContentType(String contentType) {
    final ct = contentType.split(';').first.trim();
    switch (ct) {
      case 'application/pdf':
        return 'pdf';
      case 'application/msword':
        return 'doc';
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return 'docx';
      case 'application/vnd.ms-excel':
        return 'xls';
      case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        return 'xlsx';
      case 'image/png':
        return 'png';
      case 'image/jpeg':
      case 'image/jpg':
        return 'jpg';
      case 'image/webp':
        return 'webp';
      default:
        return '';
    }
  }

  @override
  Future<DeliveryNote> uploadDeliveryNote({
    required String masterPoId,
    required File file,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final r = await _dio.patch(
      '/api/delivery/mobile/master-pos/$masterPoId/delivery-note',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    final body = _unwrap(r);
    final data = body['data'] as Map<String, dynamic>;
    return DeliveryNote.fromJson(data['delivery_note'] as Map<String, dynamic>);
  }

  /// Parses `attachment; filename="foo.pdf"` (with optional filename*=UTF-8''…)
  /// out of a Content-Disposition header. Returns null when the header is
  /// absent or malformed.
  String? _rfc5987FilenameFrom(String disposition) {
    if (disposition.isEmpty) return null;
    final rx = RegExp(r"filename\*\s*=\s*[^']*''([^;]+)", caseSensitive: false);
    final m = rx.firstMatch(disposition);
    if (m == null) return null;
    try {
      return Uri.decodeComponent(m.group(1)!.trim());
    } catch (_) {
      return null;
    }
  }

  /// Parses the plain `filename="foo.pdf"` form. HTTP headers officially
  /// carry ISO-8859-1, so non-ASCII bytes here are unreliable — only trust
  /// this form when the value is pure ASCII.
  String? _plainFilenameFrom(String disposition) {
    if (disposition.isEmpty) return null;
    final rx = RegExp(r'filename\s*=\s*"?([^";]+)"?', caseSensitive: false);
    final m = rx.firstMatch(disposition);
    final raw = m?.group(1)?.trim();
    if (raw == null || raw.isEmpty) return null;
    // Reject values that carry non-ASCII bytes — those are almost always
    // mojibake at the transport level.
    for (final r in raw.runes) {
      if (r > 0x7E) return null;
    }
    return raw;
  }

  @override
  String attachmentUrl(String attachmentId) =>
      '$baseUrl/api/delivery/mobile/attachments/$attachmentId/file';

  @override
  String resolveFileUrl(String fileUrl) {
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return fileUrl;
    }
    return '$baseUrl${fileUrl.startsWith('/') ? fileUrl : '/$fileUrl'}';
  }

  @override
  Map<String, String> get authHeaders {
    final t = _auth.currentToken;
    return t == null ? const {} : {'Authorization': 'Bearer $t'};
  }

  @override
  Future<void> primeAuth() async {
    await _auth.ensureLoaded();
  }
}
