import 'enums.dart';
import 'vendor_po_item.dart';
import 'workflow_step.dart';

class VendorPo {
  final String id;
  final String masterPoId;
  final String masterPoNumber;
  final DateTime? operationDate;
  final String supplierName;
  final String? vendorRef;
  final PoStatus status;
  final num totalAmount;
  final String currency;
  final DateTime? assignedAt;
  final DateTime? finalizedAt;
  final DateTime? etaDate;
  final String? portName;
  final String? currentStepId;

  // Detail extras (populated by GET /vendor-pos/:id)
  final int itemCount;
  final int resolvedItemCount;
  final List<VendorPoItem> items;
  final List<WorkflowStep> steps;

  const VendorPo({
    required this.id,
    required this.masterPoId,
    required this.masterPoNumber,
    required this.supplierName,
    required this.status,
    required this.totalAmount,
    this.currency = 'USD',
    this.vendorRef,
    this.operationDate,
    this.assignedAt,
    this.finalizedAt,
    this.etaDate,
    this.portName,
    this.currentStepId,
    this.itemCount = 0,
    this.resolvedItemCount = 0,
    this.items = const [],
    this.steps = const [],
  });

  WorkflowStep? get currentStep {
    if (currentStepId == null) return null;
    for (final s in steps) {
      if (s.id == currentStepId) return s;
    }
    return null;
  }

  bool get allItemsResolved => items.isNotEmpty && items.every((i) => i.status.isResolved);

  /// True only when every non-final workflow step is locally complete.
  bool get allPriorStepsComplete {
    if (steps.isEmpty) return true;
    for (final s in steps) {
      if (s.isFinalStep) continue;
      if (!s.isComplete) return false;
    }
    return true;
  }

  /// True when /finalize is safe to call: every item resolved and every
  /// non-final step complete.
  bool get readyToFinalize => allItemsResolved && allPriorStepsComplete;

  VendorPo copyWith({
    PoStatus? status,
    DateTime? finalizedAt,
    String? currentStepId,
    List<VendorPoItem>? items,
    List<WorkflowStep>? steps,
    int? resolvedItemCount,
  }) =>
      VendorPo(
        id: id,
        masterPoId: masterPoId,
        masterPoNumber: masterPoNumber,
        supplierName: supplierName,
        status: status ?? this.status,
        totalAmount: totalAmount,
        currency: currency,
        vendorRef: vendorRef,
        operationDate: operationDate,
        assignedAt: assignedAt,
        finalizedAt: finalizedAt ?? this.finalizedAt,
        etaDate: etaDate,
        portName: portName,
        currentStepId: currentStepId ?? this.currentStepId,
        itemCount: itemCount,
        resolvedItemCount: resolvedItemCount ?? this.resolvedItemCount,
        items: items ?? this.items,
        steps: steps ?? this.steps,
      );

  factory VendorPo.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) =>
        v is int ? v : (v is String ? int.tryParse(v) ?? 0 : (v as num?)?.toInt() ?? 0);
    num asNum(dynamic v) => v is num ? v : (v is String ? num.tryParse(v) ?? 0 : 0);
    DateTime? date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

    final itemsRaw = (json['items'] as List?) ?? const [];
    final stepsRaw = (json['steps'] as List?) ?? const [];

    return VendorPo(
      id: json['id'] as String,
      masterPoId: (json['master_po_id'] ?? json['master_id']) as String,
      masterPoNumber: (json['master_po_number'] as String?) ?? '',
      supplierName: json['supplier_name'] as String,
      status: PoStatusX.parse(json['status'] as String?),
      totalAmount: asNum(json['total_amount']),
      currency: json['currency'] as String? ?? 'USD',
      vendorRef: json['vendor_ref'] as String?,
      operationDate: date(json['operation_date']),
      assignedAt: date(json['assigned_at']),
      finalizedAt: date(json['finalized_at']),
      etaDate:
          date(json['eta_date'] ?? json['eta'] ?? json['expected_arrival'] ?? json['arrival_date']),
      portName: (json['port_name'] ?? json['port']) as String?,
      currentStepId: json['current_step_id'] as String?,
      itemCount: asInt(json['item_count']),
      resolvedItemCount: asInt(json['resolved_item_count']),
      items: itemsRaw.map((e) => VendorPoItem.fromJson(e as Map<String, dynamic>)).toList(),
      steps: stepsRaw.map((e) => WorkflowStep.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
