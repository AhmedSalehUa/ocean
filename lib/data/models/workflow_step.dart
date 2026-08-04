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

  /// Combine two views of the same step (same [id]) that arrived in
  /// different arrays of the `/steps` payload — e.g. one carrying the
  /// shipment-completion flag and another carrying item counts. Takes the
  /// most-progressed value for each field.
  WorkflowStep mergedWith(WorkflowStep other) => WorkflowStep(
        id: id,
        nameEn: nameEn.isNotEmpty ? nameEn : other.nameEn,
        nameAr: nameAr.isNotEmpty ? nameAr : other.nameAr,
        sortOrder: sortOrder != 0 ? sortOrder : other.sortOrder,
        requiresShipmentPhoto: requiresShipmentPhoto || other.requiresShipmentPhoto,
        requiresItemPhoto: requiresItemPhoto || other.requiresItemPhoto,
        isFinalStep: isFinalStep || other.isFinalStep,
        shipmentLogCount:
            shipmentLogCount > other.shipmentLogCount ? shipmentLogCount : other.shipmentLogCount,
        itemLogCount: itemLogCount > other.itemLogCount ? itemLogCount : other.itemLogCount,
        totalItems: totalItems > other.totalItems ? totalItems : other.totalItems,
        shipmentCompleted: shipmentCompleted || other.shipmentCompleted,
        itemCompletedCount: itemCompletedCount > other.itemCompletedCount
            ? itemCompletedCount
            : other.itemCompletedCount,
      );

  /// Parses one step object. Tolerant of both the legacy flat shape and the
  /// newer `/steps` object shape:
  /// - completion may be booleans (`shipment_completed`, `vendor_completed`,
  ///   `item_completed`) or counters (`item_completed_count`).
  /// - `total_items` may live per-step or only at the payload root, in which
  ///   case [fallbackTotalItems] carries it down.
  factory WorkflowStep.fromJson(Map<String, dynamic> json, {int? fallbackTotalItems}) {
    int asInt(dynamic v) =>
        v is int ? v : (v is String ? int.tryParse(v) ?? 0 : (v as num?)?.toInt() ?? 0);
    bool? asBool(dynamic v) => v is bool ? v : null;

    final perStepTotal = asInt(json['total_items']);
    final total = perStepTotal > 0 ? perStepTotal : (fallbackTotalItems ?? 0);

    final shipmentDone =
        asBool(json['shipment_completed']) ?? asBool(json['vendor_completed']) ?? false;

    // Item completion: prefer an explicit count, else map a boolean to
    // "all items done" so a completed item step reads as complete.
    var itemCompleted = asInt(json['item_completed_count']);
    if (itemCompleted == 0) {
      final itemDone = asBool(json['item_completed']) ??
          asBool(json['items_completed']) ??
          asBool(json['item_step_completed']) ??
          asBool(json['completed']);
      if (itemDone == true) {
        itemCompleted = total;
      } else {
        itemCompleted = asInt(json['completed_item_count'] ?? json['item_completed_items']);
      }
    }

    return WorkflowStep(
      id: json['id'] as String,
      nameEn: (json['name_en'] as String?) ?? '',
      nameAr: (json['name_ar'] as String?) ?? '',
      sortOrder: asInt(json['sort_order']),
      requiresShipmentPhoto: json['requires_shipment_photo'] as bool? ?? false,
      requiresItemPhoto: json['requires_item_photo'] as bool? ?? false,
      isFinalStep: json['is_final_step'] as bool? ?? false,
      shipmentLogCount: asInt(json['shipment_log_count']),
      itemLogCount: asInt(json['item_log_count']),
      totalItems: total,
      shipmentCompleted: shipmentDone,
      itemCompletedCount: itemCompleted,
    );
  }
}
