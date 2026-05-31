import 'dart:io';

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
