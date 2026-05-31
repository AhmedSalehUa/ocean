import 'dart:io';

import '../api/delivery_api.dart';
import '../models/master_po.dart';
import '../models/proof_log.dart';
import '../models/vendor_po.dart';
import '../models/workflow_step.dart';

class DeliveryRepository {
  DeliveryRepository(this._api);
  final DeliveryApi _api;

  DeliveryApi get api => _api;

  Future<List<MasterPo>> listMasters() => _api.listMasterPos();
  Future<({List<VendorPo> vendors, String masterPoNumber})> listVendors(String masterId) =>
      _api.listVendorPos(masterId);

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

  String attachmentUrl(String id) => _api.attachmentUrl(id);

  /// Returns an absolute URL the UI can hand to a Network image widget.
  /// Prefers the per-attachment `file_url` returned by the server so future
  /// changes to the file-serving route don't require code updates.
  String fileUrl(String relativeOrAbsolute) =>
      _api.resolveFileUrl(relativeOrAbsolute);
}
