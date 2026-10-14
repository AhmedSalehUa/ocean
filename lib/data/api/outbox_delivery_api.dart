import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/errors/api_exception.dart';
import '../../services/connectivity_service.dart';
import '../models/assistant_task.dart';
import '../models/delivery_note.dart';
import '../models/master_po.dart';
import '../models/proof_log.dart';
import '../models/sub_logistics.dart';
import '../models/user.dart';
import '../models/vendor_po.dart';
import '../models/workflow_step.dart';
import '../offline/outbox_op.dart';
import '../offline/outbox_store.dart';
import 'delivery_api.dart';

/// Decorates a real [DeliveryApi]: reads pass straight through (the Dio cache
/// handles offline reads), while writes are sent normally when online and
/// **queued to the outbox** when the device can't reach the server — returning
/// an optimistic result so the UI advances. The [SyncEngine] replays the queue.
class OutboxDeliveryApi implements DeliveryApi {
  OutboxDeliveryApi({
    required DeliveryApi inner,
    required OutboxStore outbox,
    required ConnectivityService connectivity,
  })  : _inner = inner,
        _outbox = outbox,
        _conn = connectivity;

  final DeliveryApi _inner;
  final OutboxStore _outbox;
  final ConnectivityService _conn;

  int _seq = 0;
  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  bool _isConnectivity(Object e) =>
      (e is ApiException && e.statusCode == null) ||
      e is SocketException ||
      e.toString().contains('SocketException');

  Future<String?> _persistFile(String? path) async {
    if (path == null) return null;
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory('${base.path}/outbox');
      if (!await dir.exists()) await dir.create(recursive: true);
      final name = path.split(Platform.pathSeparator).last;
      final dest = '${dir.path}/${DateTime.now().microsecondsSinceEpoch}-$name';
      await File(path).copy(dest);
      return dest;
    } catch (_) {
      return path; // fall back to the original path
    }
  }

  Future<void> _enqueue(OutboxType type, Map<String, dynamic> args, {String? filePath}) async {
    final stored = await _persistFile(filePath);
    await _outbox.add(OutboxOp(
      id: _newId(),
      type: type,
      args: args,
      filePath: stored,
      createdAt: DateTime.now(),
    ));
  }

  /// Send when online; on a connectivity failure, queue + return optimistic.
  Future<T> _run<T>({
    required OutboxType type,
    required Map<String, dynamic> args,
    String? filePath,
    required Future<T> Function() send,
    required Future<T> Function() optimistic,
  }) async {
    if (_conn.offline) {
      await _enqueue(type, args, filePath: filePath);
      return optimistic();
    }
    try {
      return await send();
    } catch (e) {
      if (_isConnectivity(e)) {
        await _enqueue(type, args, filePath: filePath);
        return optimistic();
      }
      rethrow;
    }
  }

  ProofLog _proof(String vendorPoId, String stepId, ProofKind kind, {String? itemId}) => ProofLog(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        vendorPoId: vendorPoId,
        vendorPoItemId: itemId,
        workflowStepId: stepId,
        stepNameEn: '',
        stepNameAr: '',
        actionType: 'PHOTO',
        loggedAt: DateTime.now(),
        kind: kind,
      );

  // ───────────────────────── reads / auth (pass-through) ─────────────────────
  @override
  Future<AuthResult> login({required String username, required String password}) =>
      _inner.login(username: username, password: password);
  @override
  Future<User> me() => _inner.me();
  @override
  Future<void> logout() => _inner.logout();
  @override
  Future<List<MasterPo>> listMasterPos() => _inner.listMasterPos();
  @override
  Future<({List<VendorPo> vendors, String masterPoNumber})> listVendorPos(String masterPoId) =>
      _inner.listVendorPos(masterPoId);
  @override
  Future<List<AssistantTask>> listAssistantTasks() => _inner.listAssistantTasks();
  @override
  Future<List<SubLogisticsOfficer>> listSubLogisticsOfficers() => _inner.listSubLogisticsOfficers();
  @override
  Future<SubLogisticsAssignment> getSubLogisticsAssignment(String vendorPoId) =>
      _inner.getSubLogisticsAssignment(vendorPoId);
  @override
  Future<VendorPo> getVendorPo(String vendorPoId) => _inner.getVendorPo(vendorPoId);
  @override
  Future<List<WorkflowStep>> getSteps(String vendorPoId) => _inner.getSteps(vendorPoId);
  @override
  Future<ProofHistory> getProofs(String vendorPoId) => _inner.getProofs(vendorPoId);
  @override
  Future<File> downloadDeliveryNote(String masterPoId, {DeliveryNote? note}) =>
      _inner.downloadDeliveryNote(masterPoId, note: note);
  @override
  String attachmentUrl(String attachmentId) => _inner.attachmentUrl(attachmentId);
  @override
  String resolveFileUrl(String fileUrl) => _inner.resolveFileUrl(fileUrl);
  @override
  Map<String, String> get authHeaders => _inner.authHeaders;
  @override
  Future<void> primeAuth() => _inner.primeAuth();

  // ───────────────────────── writes (queued offline) ─────────────────────────
  @override
  Future<void> putSubLogisticsAssignment({
    required String vendorPoId,
    required String? subLogisticsUserId,
    required List<String> workflowStepIds,
  }) =>
      _run<void>(
        type: OutboxType.assignSubLogistics,
        args: {
          'vendorPoId': vendorPoId,
          'subLogisticsUserId': subLogisticsUserId,
          'workflowStepIds': workflowStepIds,
        },
        send: () => _inner.putSubLogisticsAssignment(
          vendorPoId: vendorPoId,
          subLogisticsUserId: subLogisticsUserId,
          workflowStepIds: workflowStepIds,
        ),
        optimistic: () async {},
      );

  @override
  Future<VendorPo> startVendorPo(String vendorPoId) => _run<VendorPo>(
        type: OutboxType.startVendor,
        args: {'vendorPoId': vendorPoId},
        send: () => _inner.startVendorPo(vendorPoId),
        optimistic: () => _inner.getVendorPo(vendorPoId),
      );

  @override
  Future<ProofLog> uploadShipmentPhoto({
    required String vendorPoId,
    required String stepId,
    required File file,
    double? lat,
    double? lng,
    double? accuracyMeters,
  }) =>
      _run<ProofLog>(
        type: OutboxType.vendorStepPhoto,
        args: {'vendorPoId': vendorPoId, 'stepId': stepId, 'lat': lat, 'lng': lng, 'acc': accuracyMeters},
        filePath: file.path,
        send: () => _inner.uploadShipmentPhoto(
            vendorPoId: vendorPoId, stepId: stepId, file: file, lat: lat, lng: lng, accuracyMeters: accuracyMeters),
        optimistic: () async => _proof(vendorPoId, stepId, ProofKind.shipment),
      );

  @override
  Future<ProofLog> uploadLpoPhoto({
    required String masterPoId,
    required String stepId,
    required File file,
    double? lat,
    double? lng,
    double? accuracyMeters,
  }) =>
      _run<ProofLog>(
        type: OutboxType.lpoStepPhoto,
        args: {'masterPoId': masterPoId, 'stepId': stepId, 'lat': lat, 'lng': lng, 'acc': accuracyMeters},
        filePath: file.path,
        send: () => _inner.uploadLpoPhoto(
            masterPoId: masterPoId, stepId: stepId, file: file, lat: lat, lng: lng, accuracyMeters: accuracyMeters),
        optimistic: () async => _proof('', stepId, ProofKind.shipment),
      );

  @override
  Future<ProofLog> uploadItemPhoto({
    required String vendorPoId,
    required String itemId,
    required String stepId,
    required File file,
    double? lat,
    double? lng,
    double? accuracyMeters,
  }) =>
      _run<ProofLog>(
        type: OutboxType.itemStepPhoto,
        args: {'vendorPoId': vendorPoId, 'itemId': itemId, 'stepId': stepId, 'lat': lat, 'lng': lng, 'acc': accuracyMeters},
        filePath: file.path,
        send: () => _inner.uploadItemPhoto(
            vendorPoId: vendorPoId, itemId: itemId, stepId: stepId, file: file, lat: lat, lng: lng, accuracyMeters: accuracyMeters),
        optimistic: () async => _proof(vendorPoId, stepId, ProofKind.item, itemId: itemId),
      );

  @override
  Future<void> markItemMissing({required String vendorPoId, required String itemId}) => _run<void>(
        type: OutboxType.itemMissing,
        args: {'vendorPoId': vendorPoId, 'itemId': itemId},
        send: () => _inner.markItemMissing(vendorPoId: vendorPoId, itemId: itemId),
        optimistic: () async {},
      );

  @override
  Future<void> markItemRejected({
    required String vendorPoId,
    required String itemId,
    required String stepId,
  }) =>
      _run<void>(
        type: OutboxType.itemRejected,
        args: {'vendorPoId': vendorPoId, 'itemId': itemId, 'stepId': stepId},
        send: () => _inner.markItemRejected(vendorPoId: vendorPoId, itemId: itemId, stepId: stepId),
        optimistic: () async {},
      );

  @override
  Future<VendorPo> finalizeVendorPo(String vendorPoId) => _run<VendorPo>(
        type: OutboxType.finalizeVendor,
        args: {'vendorPoId': vendorPoId},
        send: () => _inner.finalizeVendorPo(vendorPoId),
        optimistic: () async => (await _inner.getVendorPo(vendorPoId)).copyWith(finalizedAt: DateTime.now()),
      );

  @override
  Future<void> finalizeMaster(String masterPoId) => _run<void>(
        type: OutboxType.finalizeMaster,
        args: {'masterPoId': masterPoId},
        send: () => _inner.finalizeMaster(masterPoId),
        optimistic: () async {},
      );

  @override
  Future<DeliveryNote> uploadDeliveryNote({required String masterPoId, required File file}) =>
      _run<DeliveryNote>(
        type: OutboxType.deliveryNote,
        args: {'masterPoId': masterPoId},
        filePath: file.path,
        send: () => _inner.uploadDeliveryNote(masterPoId: masterPoId, file: file),
        optimistic: () async => DeliveryNote(
          fileName: file.path.split(Platform.pathSeparator).last,
          mimeType: 'application/pdf',
          fileSize: 0,
          status: DeliveryNoteStatus.completed,
          updatedAt: DateTime.now(),
          downloadUrl: '',
        ),
      );
}
