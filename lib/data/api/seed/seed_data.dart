import '../../models/enums.dart';
import '../../models/master_po.dart';
import '../../models/vendor_po.dart';
import '../../models/vendor_po_item.dart';
import '../../models/workflow_step.dart';

/// In-memory seed for [MockDeliveryApi].
/// Ported from /home/claude/repo/project/data.jsx — keep field names verbatim
/// so the mutations behave identically to the Claude Design prototype.
class Seed {
  Seed._();

  static const seedUser = (
    id: 'rep_arjun',
    fullName: 'Arjun Mehta',
    username: 'rep1',
    phone: '+254 712 008 441',
    region: 'Nairobi Yard · Region 02',
  );

  static List<WorkflowStep> steps({Map<String, ({bool ship, int items, int total})>? overrides}) {
    final defs = [
      (id: 'load',    en: 'Shipment Loading', ar: 'تحميل الشحنة',   ship: true,  item: false, fin: false),
      (id: 'transit', en: 'In Transit',       ar: 'في الطريق',      ship: false, item: false, fin: false),
      (id: 'unload',  en: 'Site Unloading',   ar: 'تفريغ الموقع',    ship: true,  item: false, fin: false),
      (id: 'verify',  en: 'Item Verification',ar: 'التحقق من الأصناف', ship: false, item: true,  fin: true),
    ];
    final out = <WorkflowStep>[];
    for (var i = 0; i < defs.length; i++) {
      final d = defs[i];
      final o = overrides?[d.id];
      out.add(WorkflowStep(
        id: d.id,
        nameEn: d.en,
        nameAr: d.ar,
        sortOrder: i,
        requiresShipmentPhoto: d.ship,
        requiresItemPhoto: d.item,
        isFinalStep: d.fin,
        shipmentCompleted: o?.ship ?? false,
        itemCompletedCount: o?.items ?? 0,
        totalItems: o?.total ?? 0,
      ));
    }
    return out;
  }

  static List<MasterPo> masters() {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    return [
      MasterPo(
        id: 'mpo_241187',
        masterPoNumber: 'MPO-2026-1187',
        operationDate: today,
        status: MasterStatus.inProgress,
        createdAt: today.subtract(const Duration(hours: 18)),
        vendorPoCount: 3,
        deliveredVendorPoCount: 1,
        site: 'Yard A · Bay 04',
        siteLat: -1.2921,
        siteLng: 36.8219,
        priorityLabel: 'Due 14:00',
        urgent: true,
      ),
      MasterPo(
        id: 'mpo_241192',
        masterPoNumber: 'MPO-2026-1192',
        operationDate: today,
        status: MasterStatus.inProgress,
        createdAt: today.subtract(const Duration(hours: 5)),
        vendorPoCount: 2,
        deliveredVendorPoCount: 0,
        site: 'Yard B · Bay 11',
        siteLat: -1.2944,
        siteLng: 36.8201,
        priorityLabel: 'Standard',
        urgent: false,
      ),
      MasterPo(
        id: 'mpo_241175',
        masterPoNumber: 'MPO-2026-1175',
        operationDate: yesterday,
        status: MasterStatus.inProgress,
        createdAt: yesterday.subtract(const Duration(hours: 9)),
        vendorPoCount: 4,
        deliveredVendorPoCount: 3,
        site: 'Yard A · Bay 02',
        siteLat: -1.2921,
        siteLng: 36.8219,
        priorityLabel: 'Batch sign-off',
        urgent: false,
      ),
    ];
  }

  static Map<String, List<VendorPo>> vendorPos() {
    final today = DateTime.now();
    DateTime atHm(int h, int m, {int dayOffset = 0}) =>
        DateTime(today.year, today.month, today.day, h, m).subtract(Duration(days: dayOffset));

    VendorPoItem item({
      required String id,
      required String vendorPoId,
      required String code,
      required String name,
      required String serial,
      required num qty,
      required String unit,
      required num unitPrice,
      ItemStatus status = ItemStatus.pending,
    }) =>
        VendorPoItem(
          id: id,
          vendorPoId: vendorPoId,
          itemCode: code,
          itemName: name,
          serial: serial,
          quantity: qty,
          unit: unit,
          unitPrice: unitPrice,
          totalPrice: qty * unitPrice,
          status: status,
        );

    return {
      'mpo_241187': [
        VendorPo(
          id: 'vpo_a',
          masterPoId: 'mpo_241187',
          masterPoNumber: 'MPO-2026-1187',
          supplierName: 'Kibo Steelworks Ltd.',
          vendorRef: 'KSW-INV-9921',
          status: PoStatus.newPo,
          totalAmount: 18420,
          assignedAt: atHm(8, 42),
          currentStepId: 'unload',
          itemCount: 5,
          resolvedItemCount: 0,
          steps: steps(overrides: {
            'load':    (ship: true,  items: 0, total: 5),
            'transit': (ship: true,  items: 0, total: 5),
            'unload':  (ship: false, items: 0, total: 5),
            'verify':  (ship: false, items: 0, total: 5),
          }),
          items: [
            item(id: 'it_a1', vendorPoId: 'vpo_a', code: 'BR-32-A',  name: 'Reinforcement bar · Ø32mm', serial: 'SN-001182', qty: 60,  unit: 'lengths', unitPrice: 142.00),
            item(id: 'it_a2', vendorPoId: 'vpo_a', code: 'BR-25-A',  name: 'Reinforcement bar · Ø25mm', serial: 'SN-001183', qty: 40,  unit: 'lengths', unitPrice: 98.00),
            item(id: 'it_a3', vendorPoId: 'vpo_a', code: 'TIE-1.5',  name: 'Binding wire 1.5mm',        serial: 'SN-001184', qty: 12,  unit: 'rolls',   unitPrice: 64.00),
            item(id: 'it_a4', vendorPoId: 'vpo_a', code: 'CHAIR-50', name: 'Bar chair spacers 50mm',     serial: 'SN-001185', qty: 200, unit: 'Piece',   unitPrice: 0.85),
            item(id: 'it_a5', vendorPoId: 'vpo_a', code: 'CTNG-4',   name: 'Cutting discs 4" diamond',   serial: 'SN-001186', qty: 24,  unit: 'Piece',   unitPrice: 6.00),
          ],
        ),
        VendorPo(
          id: 'vpo_b',
          masterPoId: 'mpo_241187',
          masterPoNumber: 'MPO-2026-1187',
          supplierName: 'Brightline Electrical',
          vendorRef: 'BL-2284',
          status: PoStatus.newPo,
          totalAmount: 3210,
          assignedAt: atHm(8, 42),
          currentStepId: 'load',
          itemCount: 2,
          resolvedItemCount: 0,
          steps: steps(overrides: {
            'load':    (ship: false, items: 0, total: 2),
            'transit': (ship: false, items: 0, total: 2),
            'unload':  (ship: false, items: 0, total: 2),
            'verify':  (ship: false, items: 0, total: 2),
          }),
          items: [
            item(id: 'it_b1', vendorPoId: 'vpo_b', code: 'CBL-4mm', name: 'Single-core cable 4mm²', serial: 'SN-002001', qty: 6,  unit: 'rolls', unitPrice: 215.00),
            item(id: 'it_b2', vendorPoId: 'vpo_b', code: 'BRK-32A', name: 'MCB 32A single pole',    serial: 'SN-002002', qty: 10, unit: 'Piece', unitPrice: 192.00),
          ],
        ),
        VendorPo(
          id: 'vpo_c',
          masterPoId: 'mpo_241187',
          masterPoNumber: 'MPO-2026-1187',
          supplierName: 'Acme Hydraulics',
          vendorRef: 'AH-DLN-4471',
          status: PoStatus.fullyDelivered,
          totalAmount: 9650,
          assignedAt: atHm(8, 42),
          finalizedAt: atHm(9, 8),
          currentStepId: 'verify',
          itemCount: 3,
          resolvedItemCount: 3,
          steps: steps(overrides: {
            'load':    (ship: true, items: 3, total: 3),
            'transit': (ship: true, items: 3, total: 3),
            'unload':  (ship: true, items: 3, total: 3),
            'verify':  (ship: true, items: 3, total: 3),
          }),
          items: [
            item(id: 'it_c1', vendorPoId: 'vpo_c', code: 'HOSE-3/4', name: 'Hydraulic hose 3/4"',     serial: 'SN-003101', qty: 8,  unit: 'lengths', unitPrice: 580.00, status: ItemStatus.delivered),
            item(id: 'it_c2', vendorPoId: 'vpo_c', code: 'FIT-NPT',  name: 'NPT fittings assorted',   serial: 'SN-003102', qty: 32, unit: 'Piece',   unitPrice: 110.00, status: ItemStatus.delivered),
            item(id: 'it_c3', vendorPoId: 'vpo_c', code: 'SEAL-V',   name: 'Viton seal kit',          serial: 'SN-003103', qty: 4,  unit: 'Box',     unitPrice: 372.50, status: ItemStatus.delivered),
          ],
        ),
      ],
      'mpo_241192': [
        VendorPo(
          id: 'vpo_d',
          masterPoId: 'mpo_241192',
          masterPoNumber: 'MPO-2026-1192',
          supplierName: 'Northwind Fasteners',
          vendorRef: 'NW-DL-882',
          status: PoStatus.newPo,
          totalAmount: 4220,
          assignedAt: atHm(11, 0),
          currentStepId: 'load',
          itemCount: 3,
          resolvedItemCount: 0,
          steps: steps(overrides: {
            'load':    (ship: false, items: 0, total: 3),
            'transit': (ship: false, items: 0, total: 3),
            'unload':  (ship: false, items: 0, total: 3),
            'verify':  (ship: false, items: 0, total: 3),
          }),
          items: [
            item(id: 'it_d1', vendorPoId: 'vpo_d', code: 'BOLT-M16', name: 'Bolt M16 × 80',  serial: 'SN-004001', qty: 200, unit: 'Piece', unitPrice: 4.20),
            item(id: 'it_d2', vendorPoId: 'vpo_d', code: 'NUT-M16',  name: 'Hex nut M16',     serial: 'SN-004002', qty: 200, unit: 'Piece', unitPrice: 1.40),
            item(id: 'it_d3', vendorPoId: 'vpo_d', code: 'WSH-M16',  name: 'Washer flat M16', serial: 'SN-004003', qty: 400, unit: 'Piece', unitPrice: 0.80),
          ],
        ),
        VendorPo(
          id: 'vpo_e',
          masterPoId: 'mpo_241192',
          masterPoNumber: 'MPO-2026-1192',
          supplierName: 'Sahara Insulation Co.',
          vendorRef: 'SI-9921',
          status: PoStatus.newPo,
          totalAmount: 5430,
          assignedAt: atHm(11, 0),
          currentStepId: 'load',
          itemCount: 2,
          resolvedItemCount: 0,
          steps: steps(overrides: {
            'load':    (ship: false, items: 0, total: 2),
            'transit': (ship: false, items: 0, total: 2),
            'unload':  (ship: false, items: 0, total: 2),
            'verify':  (ship: false, items: 0, total: 2),
          }),
          items: [
            item(id: 'it_e1', vendorPoId: 'vpo_e', code: 'INS-50R', name: 'Insulation roll 50mm', serial: 'SN-005001', qty: 18, unit: 'rolls', unitPrice: 220.00),
            item(id: 'it_e2', vendorPoId: 'vpo_e', code: 'TAPE-FR', name: 'Foil tape FR',         serial: 'SN-005002', qty: 24, unit: 'rolls', unitPrice: 61.25),
          ],
        ),
      ],
      'mpo_241175': [
        VendorPo(
          id: 'vpo_f',
          masterPoId: 'mpo_241175',
          masterPoNumber: 'MPO-2026-1175',
          supplierName: 'Ridgepoint Concrete',
          vendorRef: 'RC-7712',
          status: PoStatus.fullyDelivered,
          totalAmount: 12400,
          assignedAt: atHm(8, 0, dayOffset: 1),
          finalizedAt: atHm(17, 2, dayOffset: 1),
          currentStepId: 'verify',
          itemCount: 4,
          resolvedItemCount: 4,
          steps: steps(overrides: {'verify': (ship: true, items: 4, total: 4)}),
          items: const [],
        ),
        VendorPo(
          id: 'vpo_g',
          masterPoId: 'mpo_241175',
          masterPoNumber: 'MPO-2026-1175',
          supplierName: 'Helix Power Tools',
          vendorRef: 'HP-2208',
          status: PoStatus.partiallyDelivered,
          totalAmount: 2890,
          assignedAt: atHm(8, 0, dayOffset: 1),
          finalizedAt: atHm(17, 24, dayOffset: 1),
          currentStepId: 'verify',
          itemCount: 3,
          resolvedItemCount: 3,
          steps: steps(overrides: {'verify': (ship: true, items: 3, total: 3)}),
          items: const [],
        ),
        VendorPo(
          id: 'vpo_h',
          masterPoId: 'mpo_241175',
          masterPoNumber: 'MPO-2026-1175',
          supplierName: 'Tarmac Supplies',
          vendorRef: 'TS-5512',
          status: PoStatus.fullyDelivered,
          totalAmount: 6210,
          assignedAt: atHm(8, 0, dayOffset: 1),
          finalizedAt: atHm(17, 55, dayOffset: 1),
          currentStepId: 'verify',
          itemCount: 5,
          resolvedItemCount: 5,
          steps: steps(overrides: {'verify': (ship: true, items: 5, total: 5)}),
          items: const [],
        ),
        VendorPo(
          id: 'vpo_i',
          masterPoId: 'mpo_241175',
          masterPoNumber: 'MPO-2026-1175',
          supplierName: 'BlueArc Welding',
          vendorRef: 'BW-1188',
          status: PoStatus.inProgress,
          totalAmount: 1840,
          assignedAt: atHm(8, 0, dayOffset: 1),
          currentStepId: 'verify',
          itemCount: 3,
          resolvedItemCount: 1,
          steps: steps(overrides: {'verify': (ship: true, items: 1, total: 3)}),
          items: const [],
        ),
      ],
    };
  }
}
