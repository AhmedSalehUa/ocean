import 'dart:io';

import '../api/delivery_api.dart';
import '../models/assistant_task.dart';
import '../models/master_po.dart';
import '../models/proof_log.dart';
import '../models/sub_logistics.dart';
import '../models/vendor_po.dart';
import '../models/workflow_step.dart';
import '../models/delivery_note.dart';

class DeliveryRepository {
  DeliveryRepository(this._api);
  final DeliveryApi _api;

  DeliveryApi get api => _api;

  Future<List<MasterPo>> listMasters() => _api.listMasterPos();
  Future<({List<VendorPo> vendors, String masterPoNumber})> listVendors(String masterId) =>
      _api.listVendorPos(masterId);

  Future<List<AssistantTask>> assistantTasks() => _api.listAssistantTasks();

  Future<List<SubLogisticsOfficer>> subLogisticsOfficers() => _api.listSubLogisticsOfficers();
  Future<SubLogisticsAssignment> subLogisticsAssignment(String vendorPoId) =>
      _api.getSubLogisticsAssignment(vendorPoId);
  Future<void> saveSubLogisticsAssignment({
    required String vendorPoId,
    required String? subLogisticsUserId,
    required List<String> workflowStepIds,
  }) =>
      _api.putSubLogisticsAssignment(
        vendorPoId: vendorPoId,
        subLogisticsUserId: subLogisticsUserId,
        workflowStepIds: workflowStepIds,
      );

  /// The assistant currently assigned to [stepId] anywhere under the master —
  /// assignment is per Vendor PO, so this returns the first vendor's assignee
  /// that covers this step (null when none). Used to show the step's assignee.
  Future<({String? officerId, String? officerName})> stepAssignee({
    required String masterId,
    required String stepId,
  }) async {
    final vendors = (await _api.listVendorPos(masterId)).vendors;
    for (final v in vendors) {
      try {
        final a = await _api.getSubLogisticsAssignment(v.id);
        if (a.officerId != null && a.stepIds.contains(stepId)) {
          return (officerId: a.officerId, officerName: a.officerName);
        }
      } catch (_) {
        // A vendor the rep can't read / has no assignment — skip it.
      }
    }
    return (officerId: null, officerName: null);
  }

  /// Assigns [stepId] to [assistantUserId] across every vendor PO under the
  /// master (no per-vendor selection). Pass a null id to unassign the step
  /// everywhere. Because the backend keeps one assistant per Vendor PO, a
  /// vendor already tied to a different assistant is switched to this one for
  /// this step. Returns how many vendors were updated.
  Future<({int applied, int total})> assignStepAcrossVendors({
    required String masterId,
    required String stepId,
    required String? assistantUserId,
  }) async {
    final vendors = (await _api.listVendorPos(masterId)).vendors;
    var applied = 0;
    for (final v in vendors) {
      try {
        final cur = await _api.getSubLogisticsAssignment(v.id);
        final steps = <String>{...cur.stepIds};
        String? officer;
        if (assistantUserId == null) {
          steps.remove(stepId);
          officer = steps.isEmpty ? null : cur.officerId;
        } else if (cur.officerId == assistantUserId) {
          steps.add(stepId);
          officer = assistantUserId;
        } else {
          // Different / no assistant → switch this vendor to the chosen one.
          steps
            ..clear()
            ..add(stepId);
          officer = assistantUserId;
        }
        await _api.putSubLogisticsAssignment(
          vendorPoId: v.id,
          subLogisticsUserId: officer,
          workflowStepIds: steps.toList(),
        );
        applied++;
      } catch (_) {
        // Skip vendors that reject the change (e.g. step not valid there).
      }
    }
    return (applied: applied, total: vendors.length);
  }

  Future<VendorPo> vendor(String id) => _api.getVendorPo(id);
  Future<List<WorkflowStep>> steps(String id) => _api.getSteps(id);
  Future<ProofHistory> proofs(String id) => _api.getProofs(id);

  Future<VendorPo> start(String id) => _api.startVendorPo(id);

  Future<ProofLog> shipmentPhoto({
    required String vendorPoId,
    required String stepId,
    required File file,
    double? lat,
    double? lng,
    double? accuracyMeters,
  }) =>
      _api.uploadShipmentPhoto(
        vendorPoId: vendorPoId,
        stepId: stepId,
        file: file,
        lat: lat,
        lng: lng,
        accuracyMeters: accuracyMeters,
      );

  Future<ProofLog> lpoPhoto({
    required String masterPoId,
    required String stepId,
    required File file,
    double? lat,
    double? lng,
    double? accuracyMeters,
  }) =>
      _api.uploadLpoPhoto(
        masterPoId: masterPoId,
        stepId: stepId,
        file: file,
        lat: lat,
        lng: lng,
        accuracyMeters: accuracyMeters,
      );

  Future<ProofLog> itemPhoto({
    required String vendorPoId,
    required String itemId,
    required String stepId,
    required File file,
    double? lat,
    double? lng,
    double? accuracyMeters,
  }) =>
      _api.uploadItemPhoto(
        vendorPoId: vendorPoId,
        itemId: itemId,
        stepId: stepId,
        file: file,
        lat: lat,
        lng: lng,
        accuracyMeters: accuracyMeters,
      );

  Future<void> markMissing({required String vendorPoId, required String itemId}) =>
      _api.markItemMissing(vendorPoId: vendorPoId, itemId: itemId);

  Future<void> markRejected({
    required String vendorPoId,
    required String itemId,
    required String stepId,
  }) =>
      _api.markItemRejected(
        vendorPoId: vendorPoId,
        itemId: itemId,
        stepId: stepId,
      );

  Future<VendorPo> finalize(String id) => _api.finalizeVendorPo(id);

  Future<File> downloadDeliveryNote(String masterPoId, {DeliveryNote? note}) =>
      _api.downloadDeliveryNote(masterPoId, note: note);

  Future<DeliveryNote> uploadDeliveryNote({
    required String masterPoId,
    required File file,
  }) =>
      _api.uploadDeliveryNote(masterPoId: masterPoId, file: file);
  String attachmentUrl(String id) => _api.attachmentUrl(id);

  /// Returns an absolute URL the UI can hand to a Network image widget.
  /// Prefers the per-attachment `file_url` returned by the server so future
  /// changes to the file-serving route don't require code updates.
  String fileUrl(String relativeOrAbsolute) => _api.resolveFileUrl(relativeOrAbsolute);

  /// Headers to attach when fetching authenticated assets (e.g. proof
  /// thumbnails / full-screen images via CachedNetworkImage).
  Map<String, String> get authHeaders => _api.authHeaders;

  /// Eagerly loads the persisted JWT into memory so [authHeaders] is
  /// non-empty by the time the first image request fires.
  Future<void> primeAuth() => _api.primeAuth();
}
