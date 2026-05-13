import 'attachment.dart';

class ProofLog {
  final String id;
  final String vendorPoId;
  final String? vendorPoItemId;
  final String workflowStepId;
  final String stepNameEn;
  final String stepNameAr;
  final String? itemName;
  final String? itemCode;
  final String actionType;
  final bool isAutoCompleted;
  final DateTime loggedAt;
  final Attachment attachment;
  final ProofKind kind;

  const ProofLog({
    required this.id,
    required this.vendorPoId,
    this.vendorPoItemId,
    required this.workflowStepId,
    required this.stepNameEn,
    required this.stepNameAr,
    this.itemName,
    this.itemCode,
    required this.actionType,
    this.isAutoCompleted = false,
    required this.loggedAt,
    required this.attachment,
    required this.kind,
  });

  String stepNameFor(String localeCode) => localeCode.startsWith('ar') ? stepNameAr : stepNameEn;

  factory ProofLog.fromJson(Map<String, dynamic> json, ProofKind kind) {
    return ProofLog(
      id: json['id'] as String,
      vendorPoId: json['vendor_po_id'] as String,
      vendorPoItemId: json['vendor_po_item_id'] as String?,
      workflowStepId: json['workflow_step_id'] as String,
      stepNameEn: json['step_name_en'] as String? ?? '',
      stepNameAr: json['step_name_ar'] as String? ?? '',
      itemName: json['item_name'] as String?,
      itemCode: json['item_code'] as String?,
      actionType: json['action_type'] as String? ?? 'PHOTO',
      isAutoCompleted: json['is_auto_completed'] as bool? ?? false,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      attachment: Attachment.fromJson(json['attachment'] as Map<String, dynamic>),
      kind: kind,
    );
  }
}

enum ProofKind { shipment, item }

class ProofHistory {
  final String vendorPoId;
  final String supplierName;
  final List<ProofLog> shipmentProofs;
  final List<ProofLog> itemProofs;

  const ProofHistory({
    required this.vendorPoId,
    required this.supplierName,
    this.shipmentProofs = const [],
    this.itemProofs = const [],
  });

  factory ProofHistory.fromJson(Map<String, dynamic> json) {
    final ship = (json['shipment_proofs'] as List? ?? const [])
        .map((e) => ProofLog.fromJson(e as Map<String, dynamic>, ProofKind.shipment))
        .toList();
    final items = (json['item_proofs'] as List? ?? const [])
        .map((e) => ProofLog.fromJson(e as Map<String, dynamic>, ProofKind.item))
        .toList();
    return ProofHistory(
      vendorPoId: json['vendor_po_id'] as String,
      supplierName: json['supplier_name'] as String? ?? '',
      shipmentProofs: ship,
      itemProofs: items,
    );
  }
}
