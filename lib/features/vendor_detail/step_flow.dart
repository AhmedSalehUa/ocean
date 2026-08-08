import '../../data/models/vendor_po.dart';
import '../../routing/routes.dart';

/// Given a freshly-hydrated vendor, returns the route the workflow should move
/// to next: the current step's capture screen, or finalize when every
/// required step + item is done. Shared by the capture screens so completing
/// a step jumps straight to the next one.
String nextStepRoute(VendorPo v) {
  if (v.readyToFinalize) return Routes.finalizePath(v.id);
  final next = v.currentStep;
  if (next == null ||
      next.isFinalStep ||
      (!next.requiresShipmentPhoto && !next.requiresItemPhoto)) {
    return Routes.finalizePath(v.id);
  }
  if (next.requiresShipmentPhoto && !next.shipmentCompleted) {
    return Routes.shipmentPath(v.id);
  }
  if (next.requiresItemPhoto) return Routes.guidedItemsPath(v.id);
  return Routes.finalizePath(v.id);
}
