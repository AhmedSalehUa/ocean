class WorkflowStep {
  final String id;
  final String nameEn;
  final String nameAr;
  final int sortOrder;
  final bool requiresShipmentPhoto;
  final bool requiresItemPhoto;
  final bool isFinalStep;

  // Live counters from the API
  final int shipmentLogCount;
  final int itemLogCount;
  final int totalItems;
  final bool shipmentCompleted;
  final int itemCompletedCount;

  const WorkflowStep({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.sortOrder,
    required this.requiresShipmentPhoto,
    required this.requiresItemPhoto,
    required this.isFinalStep,
    this.shipmentLogCount = 0,
    this.itemLogCount = 0,
    this.totalItems = 0,
    this.shipmentCompleted = false,
    this.itemCompletedCount = 0,
  });

  String nameFor(String localeCode) => localeCode.startsWith('ar') ? nameAr : nameEn;

  bool get isComplete {
    final shipmentOk = !requiresShipmentPhoto || shipmentCompleted;
    final itemsOk = !requiresItemPhoto || (totalItems > 0 && itemCompletedCount >= totalItems);
    return shipmentOk && itemsOk;
  }

  WorkflowStep copyWith({
    int? shipmentLogCount,
    int? itemLogCount,
    int? totalItems,
    bool? shipmentCompleted,
    int? itemCompletedCount,
  }) =>
      WorkflowStep(
        id: id,
        nameEn: nameEn,
        nameAr: nameAr,
        sortOrder: sortOrder,
        requiresShipmentPhoto: requiresShipmentPhoto,
        requiresItemPhoto: requiresItemPhoto,
        isFinalStep: isFinalStep,
        shipmentLogCount: shipmentLogCount ?? this.shipmentLogCount,
        itemLogCount: itemLogCount ?? this.itemLogCount,
        totalItems: totalItems ?? this.totalItems,
        shipmentCompleted: shipmentCompleted ?? this.shipmentCompleted,
        itemCompletedCount: itemCompletedCount ?? this.itemCompletedCount,
      );

  factory WorkflowStep.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic v) =>
        v is int ? v : (v is String ? int.tryParse(v) ?? 0 : (v as num?)?.toInt() ?? 0);

    return WorkflowStep(
      id: json['id'] as String,
      nameEn: json['name_en'] as String,
      nameAr: json['name_ar'] as String,
      sortOrder: _asInt(json['sort_order']),
      requiresShipmentPhoto: json['requires_shipment_photo'] as bool? ?? false,
      requiresItemPhoto: json['requires_item_photo'] as bool? ?? false,
      isFinalStep: json['is_final_step'] as bool? ?? false,
      shipmentLogCount: _asInt(json['shipment_log_count']),
      itemLogCount: _asInt(json['item_log_count']),
      totalItems: _asInt(json['total_items']),
      shipmentCompleted: json['shipment_completed'] as bool? ?? false,
      itemCompletedCount: _asInt(json['item_completed_count']),
    );
  }
}
