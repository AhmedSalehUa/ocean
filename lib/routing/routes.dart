class Routes {
  Routes._();
  static const login = '/login';
  static const dashboard = '/';
  static const vendorList = '/master/:masterId';
  static const vendorDetail = '/vendor/:vendorId';
  static const shipmentCapture = '/vendor/:vendorId/shipment';
  static const itemLoop = '/vendor/:vendorId/items';
  static const proofs = '/vendor/:vendorId/proofs';
  static const finalize = '/vendor/:vendorId/finalize';
  static const handoff = '/vendor/:vendorId/handoff';

  static String vendorListPath(String masterId) => '/master/$masterId';
  static String vendorDetailPath(String vendorId) => '/vendor/$vendorId';
  static String shipmentPath(String vendorId) => '/vendor/$vendorId/shipment';
  static String itemLoopPath(String vendorId) => '/vendor/$vendorId/items';
  static String proofsPath(String vendorId) => '/vendor/$vendorId/proofs';
  static String finalizePath(String vendorId) => '/vendor/$vendorId/finalize';
  static String handoffPath(String vendorId) => '/vendor/$vendorId/handoff';
}
