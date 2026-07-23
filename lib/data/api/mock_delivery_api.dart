import 'dart:io';

import '../models/attachment.dart';
import '../models/delivery_note.dart';
import '../models/enums.dart';
import '../models/master_po.dart';
import '../models/proof_log.dart';
import '../models/user.dart';
import '../models/vendor_po.dart';
import '../models/vendor_po_item.dart';
import '../models/workflow_step.dart';
import '../../core/errors/api_exception.dart';
import 'delivery_api.dart';
import 'seed/seed_data.dart';

/// In-memory backend used during development. Mirrors the mutation rules
/// from the Claude Design prototype's `app.jsx`.
class MockDeliveryApi implements DeliveryApi {
  MockDeliveryApi() {
    _masters = List.of(Seed.masters());
    _vendors = {for (final e in Seed.vendorPos().entries) e.key: List.of(e.value)};
    _proofs = {
      'vpo_c': [
        _seedProof('plog_c1', 'vpo_c', 'verify', 'Item · HOSE-3/4', 'it_c1',
            auto: true, atHm: (8, 56), file: 'hose_0856.jpg'),
        _seedProof('plog_c2', 'vpo_c', 'verify', 'Item · FIT-NPT', 'it_c2',
            auto: true, atHm: (8, 58), file: 'fit_0858.jpg'),
        _seedProof('plog_c3', 'vpo_c', 'verify', 'Item · SEAL-V', 'it_c3',
            auto: true, atHm: (9, 1), file: 'seal_0901.jpg'),
      ],
      'vpo_a': [
        _seedProof('plog_a1', 'vpo_a', 'load', 'Shipment loading', null,
            atHm: (6, 30), file: 'load_0630.jpg'),
        _seedProof('plog_a2', 'vpo_a', 'transit', 'Transit checkpoint', null,
            atHm: (8, 42), file: 'trans_0842.jpg'),
      ],
    };
  }

  late List<MasterPo> _masters;
  late Map<String, List<VendorPo>> _vendors;
  late Map<String, List<ProofLog>> _proofs;

  String? _token;
  User? _user;

  ProofLog _seedProof(
    String id,
    String vendorPoId,
    String stepId,
    String label,
    String? itemId, {
    required (int, int) atHm,
    required String file,
    bool auto = false,
  }) {
    final now = DateTime.now();
    return ProofLog(
      id: id,
      vendorPoId: vendorPoId,
      vendorPoItemId: itemId,
      workflowStepId: stepId,
      stepNameEn: _stepName(stepId).en,
      stepNameAr: _stepName(stepId).ar,
      itemName: label,
      itemCode: null,
      actionType: 'PHOTO',
      isAutoCompleted: auto,
      loggedAt: DateTime(now.year, now.month, now.day, atHm.$1, atHm.$2),
      kind: itemId == null ? ProofKind.shipment : ProofKind.item,
      attachment: Attachment(
        id: 'att_$id',
        fileName: file,
        mimeType: 'image/jpeg',
        fileSize: 2200000,
        fileUrl: 'mock://attachments/att_$id',
      ),
    );
  }

  ({String en, String ar}) _stepName(String stepId) {
    return switch (stepId) {
      'load' => (en: 'Shipment Loading', ar: 'تحميل الشحنة'),
      'transit' => (en: 'In Transit', ar: 'في الطريق'),
      'unload' => (en: 'Site Unloading', ar: 'تفريغ الموقع'),
      'verify' => (en: 'Item Verification', ar: 'التحقق من الأصناف'),
      _ => (en: stepId, ar: stepId),
    };
  }

  Future<void> _latency([int min = 180, int max = 380]) => Future<void>.delayed(
      Duration(milliseconds: min + (DateTime.now().microsecond % (max - min))));

  VendorPo _findVendor(String id) {
    for (final list in _vendors.values) {
      for (final v in list) {
        if (v.id == id) return v;
      }
    }
    throw const ApiException('Vendor PO not found', statusCode: 404);
  }

  void _replaceVendor(VendorPo v) {
    final list = _vendors[v.masterPoId];
    if (list == null) return;
    final i = list.indexWhere((x) => x.id == v.id);
    if (i >= 0) list[i] = v;
  }

  // ─────────────────────────── Auth ───────────────────────────

  @override
  Future<AuthResult> login({required String username, required String password}) async {
    await _latency(450, 750);
    if (username.trim().isEmpty || password.isEmpty) {
      throw const ApiException('Invalid credentials', statusCode: 401);
    }
    _token = 'mock-jwt-${DateTime.now().millisecondsSinceEpoch}';
    _user = User(
      id: Seed.seedUser.id,
      fullName: Seed.seedUser.fullName,
      username: Seed.seedUser.username,
      role: 'REPRESENTATIVE',
      phone: Seed.seedUser.phone,
      isActive: true,
    );
    return AuthResult(token: _token!, user: _user!);
  }

  @override
  Future<User> me() async {
    await _latency();
    if (_user == null) throw const ApiException('Unauthorized', statusCode: 401);
    return _user!;
  }

  @override
  Future<void> logout() async {
    await _latency(80, 120);
    _token = null;
    _user = null;
  }

  // ─────────────────────────── Lists ───────────────────────────

  @override
  Future<List<MasterPo>> listMasterPos() async {
    await _latency();
    return List.of(_masters);
  }

  @override
  Future<({List<VendorPo> vendors, String masterPoNumber})> listVendorPos(String masterPoId) async {
    await _latency();
    final m = _masters.firstWhere(
      (m) => m.id == masterPoId,
      orElse: () => throw const ApiException('Master PO not found', statusCode: 404),
    );
    final list = _vendors[masterPoId] ?? const <VendorPo>[];
    return (vendors: List.of(list), masterPoNumber: m.masterPoNumber);
  }

  @override
  Future<VendorPo> getVendorPo(String vendorPoId) async {
    await _latency();
    return _findVendor(vendorPoId);
  }

  @override
  Future<List<WorkflowStep>> getSteps(String vendorPoId) async {
    await _latency();
    return List.of(_findVendor(vendorPoId).steps);
  }

  @override
  Future<ProofHistory> getProofs(String vendorPoId) async {
    await _latency();
    final v = _findVendor(vendorPoId);
    final logs = _proofs[vendorPoId] ?? const <ProofLog>[];
    return ProofHistory(
      vendorPoId: vendorPoId,
      supplierName: v.supplierName,
      shipmentProofs: logs.where((p) => p.kind == ProofKind.shipment).toList(),
      itemProofs: logs.where((p) => p.kind == ProofKind.item).toList(),
    );
  }

  // ─────────────────────────── Mutations ───────────────────────────

  @override
  Future<VendorPo> startVendorPo(String vendorPoId) async {
    await _latency();
    final v = _findVendor(vendorPoId);
    if (v.status != PoStatus.newPo && v.status != PoStatus.inProgress) {
      throw const ApiException('Vendor PO already finalized', statusCode: 409);
    }
    final updated = v.copyWith(
      status: PoStatus.inProgress,
      items: v.items
          .map(
              (i) => i.status == ItemStatus.pending ? i.copyWith(status: ItemStatus.inProgress) : i)
          .toList(),
    );
    _replaceVendor(updated);
    _recomputeMaster(updated.masterPoId);
    return updated;
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
    await _latency(550, 900);
    final v = _findVendor(vendorPoId);
    final stepIdx = v.steps.indexWhere((s) => s.id == stepId);
    if (stepIdx < 0) throw const ApiException('Step not found', statusCode: 404);
    final step = v.steps[stepIdx];
    if (!step.requiresShipmentPhoto) {
      throw const ApiException('Step does not require shipment photo', statusCode: 422);
    }

    final newSteps = List<WorkflowStep>.from(v.steps);
    newSteps[stepIdx] = step.copyWith(shipmentCompleted: true);
    // advance current_step_id to the next, if any
    final nextStep = stepIdx + 1 < newSteps.length ? newSteps[stepIdx + 1] : null;
    final updated = v.copyWith(
      steps: newSteps,
      currentStepId: nextStep?.id ?? v.currentStepId,
    );
    _replaceVendor(updated);

    final log = _addLog(
      vendorPoId: vendorPoId,
      stepId: stepId,
      itemId: null,
      label: 'Shipment proof · ${step.nameEn}',
      kind: ProofKind.shipment,
    );
    return log;
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
    await _latency(550, 900);
    final v = _findVendor(vendorPoId);
    final stepIdx = v.steps.indexWhere((s) => s.id == stepId);
    if (stepIdx < 0) throw const ApiException('Step not found', statusCode: 404);
    final step = v.steps[stepIdx];
    if (!step.requiresItemPhoto) {
      throw const ApiException('Step does not require item photo', statusCode: 422);
    }
    final itemIdx = v.items.indexWhere((i) => i.id == itemId);
    if (itemIdx < 0) throw const ApiException('Item not in vendor PO', statusCode: 404);

    final items = List<VendorPoItem>.from(v.items);
    final wasUnresolved = !items[itemIdx].status.isResolved;
    if (step.isFinalStep) {
      items[itemIdx] = items[itemIdx].copyWith(status: ItemStatus.delivered);
    }

    final newSteps = List<WorkflowStep>.from(v.steps);
    newSteps[stepIdx] = step.copyWith(
      itemCompletedCount: step.itemCompletedCount + 1,
      totalItems: step.totalItems == 0 ? items.length : step.totalItems,
    );

    final updated = v.copyWith(
      items: items,
      steps: newSteps,
      resolvedItemCount:
          wasUnresolved && step.isFinalStep ? v.resolvedItemCount + 1 : v.resolvedItemCount,
    );
    _replaceVendor(updated);

    final log = _addLog(
      vendorPoId: vendorPoId,
      stepId: stepId,
      itemId: itemId,
      label: 'Item · ${items[itemIdx].itemCode}',
      itemCode: items[itemIdx].itemCode,
      itemName: items[itemIdx].itemName,
      kind: ProofKind.item,
      autoCompleted: step.isFinalStep,
    );
    return log;
  }

  @override
  Future<void> markItemMissing({required String vendorPoId, required String itemId}) async {
    await _latency();
    final v = _findVendor(vendorPoId);
    final idx = v.items.indexWhere((i) => i.id == itemId);
    if (idx < 0) throw const ApiException('Item not found', statusCode: 404);
    final items = List<VendorPoItem>.from(v.items);
    final wasUnresolved = !items[idx].status.isResolved;
    items[idx] = items[idx].copyWith(status: ItemStatus.missing);
    final updated = v.copyWith(
      items: items,
      resolvedItemCount: wasUnresolved ? v.resolvedItemCount + 1 : v.resolvedItemCount,
    );
    _replaceVendor(updated);
    _recomputeMaster(updated.masterPoId);
  }

  @override
  Future<void> markItemRejected({
    required String vendorPoId,
    required String itemId,
    required String stepId,
  }) async {
    await _latency();
    final v = _findVendor(vendorPoId);
    final idx = v.items.indexWhere((i) => i.id == itemId);
    if (idx < 0) throw const ApiException('Item not found', statusCode: 404);
    final items = List<VendorPoItem>.from(v.items);
    final wasUnresolved = !items[idx].status.isResolved;
    items[idx] = items[idx].copyWith(status: ItemStatus.rejected);
    final updated = v.copyWith(
      items: items,
      resolvedItemCount: wasUnresolved ? v.resolvedItemCount + 1 : v.resolvedItemCount,
    );
    _replaceVendor(updated);
    _recomputeMaster(updated.masterPoId);
  }

  @override
  Future<VendorPo> finalizeVendorPo(String vendorPoId) async {
    await _latency(400, 700);
    final v = _findVendor(vendorPoId);
    if (!v.allItemsResolved && v.items.isNotEmpty) {
      throw const ApiException('Resolve all items before finalizing', statusCode: 409);
    }
    final hasMissing = v.items.any((i) => i.status == ItemStatus.missing);
    final newStatus = hasMissing ? PoStatus.partiallyDelivered : PoStatus.fullyDelivered;
    final updated = v.copyWith(
      status: newStatus,
      finalizedAt: DateTime.now(),
    );
    _replaceVendor(updated);
    _recomputeMaster(updated.masterPoId);
    return updated;
  }

  @override
  @override
  Future<File> downloadDeliveryNote(String masterPoId, {DeliveryNote? note}) {
    // Mock mode has no real files on disk; feature only makes sense against
    // the live backend. Surface a friendly 404 so the UI shows the empty
    // state instead of a runtime crash.
    throw const ApiException('No delivery note uploaded yet', statusCode: 404);
  }

  @override
  Future<DeliveryNote> uploadDeliveryNote({
    required String masterPoId,
    required File file,
  }) async {
    return DeliveryNote(
      fileName: file.uri.pathSegments.last,
      mimeType: 'application/octet-stream',
      fileSize: await file.length(),
      status: DeliveryNoteStatus.completed,
      updatedAt: DateTime.now(),
      downloadUrl: '/api/delivery/mobile/master-pos/$masterPoId/delivery-note',
    );
  }

  @override
  String attachmentUrl(String attachmentId) => 'mock://attachments/$attachmentId';

  @override
  String resolveFileUrl(String fileUrl) => fileUrl;

  @override
  Map<String, String> get authHeaders => const {};

  @override
  Future<void> primeAuth() async {}

  // ─────────────────────────── Helpers ───────────────────────────

  ProofLog _addLog({
    required String vendorPoId,
    required String stepId,
    String? itemId,
    required String label,
    String? itemCode,
    String? itemName,
    required ProofKind kind,
    bool autoCompleted = false,
  }) {
    final id = 'plog_${DateTime.now().microsecondsSinceEpoch}';
    final names = _stepName(stepId);
    final log = ProofLog(
      id: id,
      vendorPoId: vendorPoId,
      vendorPoItemId: itemId,
      workflowStepId: stepId,
      stepNameEn: names.en,
      stepNameAr: names.ar,
      itemName: itemName ?? label,
      itemCode: itemCode,
      actionType: 'PHOTO',
      isAutoCompleted: autoCompleted,
      loggedAt: DateTime.now(),
      kind: kind,
      attachment: Attachment(
        id: 'att_$id',
        fileName: '$id.jpg',
        mimeType: 'image/jpeg',
        fileSize: 1800000,
        fileUrl: 'mock://attachments/att_$id',
      ),
    );
    final bucket = _proofs.putIfAbsent(vendorPoId, () => <ProofLog>[]);
    bucket.add(log);
    return log;
  }

  void _recomputeMaster(String masterId) {
    final mi = _masters.indexWhere((m) => m.id == masterId);
    if (mi < 0) return;
    final list = _vendors[masterId] ?? const <VendorPo>[];
    final delivered = list
        .where(
            (v) => v.status == PoStatus.fullyDelivered || v.status == PoStatus.partiallyDelivered)
        .length;
    _masters[mi] = _masters[mi].copyWith(
      deliveredVendorPoCount: delivered,
      status: delivered == list.length && list.isNotEmpty
          ? MasterStatus.fullyDelivered
          : MasterStatus.inProgress,
    );
  }
}
