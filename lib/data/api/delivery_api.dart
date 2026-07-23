import 'dart:io';

import '../models/delivery_note.dart';
import '../models/master_po.dart';
import '../models/proof_log.dart';
import '../models/user.dart';
import '../models/vendor_po.dart';
import '../models/workflow_step.dart';

/// Single seam between feature code and either the live HTTP backend
/// or the seeded mock. Methods mirror the docs in /api/delivery/*.
abstract class DeliveryApi {
  // Auth
  Future<AuthResult> login({required String username, required String password});
  Future<User> me();
  Future<void> logout();

  // Master / vendor lists
  Future<List<MasterPo>> listMasterPos();
  Future<({List<VendorPo> vendors, String masterPoNumber})> listVendorPos(String masterPoId);

  // Vendor PO detail
  Future<VendorPo> getVendorPo(String vendorPoId);
  Future<List<WorkflowStep>> getSteps(String vendorPoId);
  Future<ProofHistory> getProofs(String vendorPoId);

  // Mutations
  Future<VendorPo> startVendorPo(String vendorPoId);
  Future<ProofLog> uploadShipmentPhoto({
    required String vendorPoId,
    required String stepId,
    required File file,
    double? lat,
    double? lng,
    double? accuracyMeters,
  });
  Future<ProofLog> uploadItemPhoto({
    required String vendorPoId,
    required String itemId,
    required String stepId,
    required File file,
    double? lat,
    double? lng,
    double? accuracyMeters,
  });
  Future<void> markItemMissing({required String vendorPoId, required String itemId});
  Future<void> markItemRejected({
    required String vendorPoId,
    required String itemId,
    required String stepId,
  });
  Future<VendorPo> finalizeVendorPo(String vendorPoId);

  /// Downloads the current delivery-note file for the given Master PO into
  /// the app's temporary directory and returns the saved [File]. The rep
  /// must be assigned to at least one Vendor PO under the master. Throws
  /// [ApiException] with statusCode 404 if no file has been uploaded yet.
  Future<File> downloadDeliveryNote(String masterPoId, {DeliveryNote? note});

  /// Replaces the current delivery-note file with the completed version
  /// picked by the representative. Allowed types on the wire: PDF, Excel
  /// (xls, xlsx), Word (doc, docx), images (jpg, jpeg, png, webp).
  Future<DeliveryNote> uploadDeliveryNote({
    required String masterPoId,
    required File file,
  });

  /// For [HttpDeliveryApi] this returns the auth-aware URL the UI should
  /// hand to a Network image widget. For the mock it returns a local seed url.
  String attachmentUrl(String attachmentId);

  /// Resolve a (possibly relative) file URL returned by the API into an
  /// absolute URL the UI can hand to a Network image widget. Mock returns
  /// the local seed scheme unchanged.
  String resolveFileUrl(String fileUrl);

  /// Headers to attach when fetching authenticated binary assets (e.g.
  /// CachedNetworkImage). Returns an empty map when there is no token
  /// cached. Call [primeAuth] once at app start to populate the cache so
  /// the first image request after cold start carries the token.
  Map<String, String> get authHeaders;

  /// Loads the persisted auth token into memory so [authHeaders] returns
  /// it without needing a prior Dio call. Safe to await before showing
  /// any authenticated resource.
  Future<void> primeAuth();
}
