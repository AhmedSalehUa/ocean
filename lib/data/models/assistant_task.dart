import 'workflow_step.dart';

/// One line item a SUB_LOGISTICS_OFFICER must photograph for an ITEM-level
/// assigned step. Only present when the step is ITEM level; prices are never
/// included in assistant payloads.
class AssistantTaskTarget {
  final String id;
  final String itemCode;
  final String itemName;
  final String? serial;
  final String status;

  const AssistantTaskTarget({
    required this.id,
    required this.itemCode,
    required this.itemName,
    this.serial,
    required this.status,
  });

  factory AssistantTaskTarget.fromJson(Map<String, dynamic> json) => AssistantTaskTarget(
        id: json['id'] as String,
        itemCode: (json['item_code'] as String?) ?? '',
        itemName: (json['item_name'] as String?) ?? '',
        serial: json['serial']?.toString(),
        status: (json['status'] as String?) ?? 'PENDING',
      );
}

/// A single assigned step surfaced on the assistant's home screen, from
/// `GET /api/delivery/mobile/assistant/tasks`. Each row is one workflow step
/// the assistant is allowed to execute inside a specific Vendor PO.
class AssistantTask {
  final String assignmentId;
  final String masterPoId;
  final String vendorPoId;
  final String masterPoNumber;
  final String supplierName;
  final String? vesselName;
  final String? portName;
  final DateTime? etaDate;
  final String? representativeName;

  final String workflowStepId;
  final String stepNameEn;
  final String stepNameAr;
  final StepLevel stepLevel;

  /// Items to photograph — populated only for ITEM-level steps.
  final List<AssistantTaskTarget> targets;

  const AssistantTask({
    required this.assignmentId,
    required this.masterPoId,
    required this.vendorPoId,
    required this.masterPoNumber,
    required this.supplierName,
    this.vesselName,
    this.portName,
    this.etaDate,
    this.representativeName,
    required this.workflowStepId,
    required this.stepNameEn,
    required this.stepNameAr,
    required this.stepLevel,
    this.targets = const [],
  });

  String stepNameFor(String localeCode) => localeCode.startsWith('ar') ? stepNameAr : stepNameEn;

  factory AssistantTask.fromJson(Map<String, dynamic> json) {
    DateTime? date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
    final rawTargets = (json['targets'] as List?) ?? const [];
    return AssistantTask(
      assignmentId: (json['assignment_id'] as String?) ?? '',
      masterPoId: (json['master_po_id'] as String?) ?? '',
      vendorPoId: (json['vendor_po_id'] as String?) ?? '',
      masterPoNumber: (json['master_po_number'] as String?) ?? '',
      supplierName: (json['supplier_name'] as String?) ?? '',
      vesselName: (json['vessel_name'] ?? json['vessel_number']) as String?,
      portName: json['port_name'] as String?,
      etaDate: date(json['eta_date']),
      representativeName: (json['representative_name'] ??
          json['primary_representative_name'] ??
          json['rep_name']) as String?,
      workflowStepId: (json['workflow_step_id'] as String?) ?? '',
      stepNameEn: (json['step_name_en'] as String?) ?? '',
      stepNameAr: (json['step_name_ar'] as String?) ?? '',
      stepLevel: StepLevelX.parse(json['step_level'] as String?),
      targets: rawTargets
          .whereType<Map<String, dynamic>>()
          .map(AssistantTaskTarget.fromJson)
          .toList(),
    );
  }
}
