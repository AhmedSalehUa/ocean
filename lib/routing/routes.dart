class Routes {
  Routes._();
  static const login = '/login';
  static const dashboard = '/';
  static const assistantHome = '/assistant';
  static const masterSteps = '/master/:masterId/steps';
  static const assignVendors = '/master/:masterId/assign-vendors';
  static const stepVendors = '/master/:masterId/step/:stepId/vendors';
  static const stepItems = '/vendor/:vendorId/step/:stepId/items';
  static const vendorList = '/master/:masterId';
  static const vendorDetail = '/vendor/:vendorId';
  static const shipmentCapture = '/vendor/:vendorId/shipment';
  static const itemLoop = '/vendor/:vendorId/items';
  static const guidedItems = '/vendor/:vendorId/guided-items';
  static const proofs = '/vendor/:vendorId/proofs';
  static const proofViewer = '/vendor/:vendorId/proofs/:proofId';
  static const finalize = '/vendor/:vendorId/finalize';
  static const handoff = '/vendor/:vendorId/handoff';
  static const stepDone = '/vendor/:vendorId/step-done/:stepId';
  static const assignAssistant = '/vendor/:vendorId/assign';

  static String masterStepsPath(String masterId) => '/master/$masterId/steps';
  static String assignVendorsPath(String masterId) => '/master/$masterId/assign-vendors';
  static String stepVendorsPath(String masterId, String stepId) =>
      '/master/$masterId/step/$stepId/vendors';
  static String stepItemsPath(String vendorId, String stepId) =>
      '/vendor/$vendorId/step/$stepId/items';
  static String vendorListPath(String masterId) => '/master/$masterId';
  static String vendorDetailPath(String vendorId) => '/vendor/$vendorId';
  static String shipmentPath(String vendorId) => '/vendor/$vendorId/shipment';
  static String itemLoopPath(String vendorId) => '/vendor/$vendorId/items';
  static String guidedItemsPath(String vendorId) =>
      '/vendor/$vendorId/guided-items';
  static String proofsPath(String vendorId) => '/vendor/$vendorId/proofs';
  static String proofViewerPath(String vendorId, String proofId) =>
      '/vendor/$vendorId/proofs/$proofId';
  static String finalizePath(String vendorId) => '/vendor/$vendorId/finalize';
  static String handoffPath(String vendorId) => '/vendor/$vendorId/handoff';
  static String stepDonePath(String vendorId, String stepId) =>
      '/vendor/$vendorId/step-done/$stepId';
  static String assignAssistantPath(String vendorId) => '/vendor/$vendorId/assign';
}
