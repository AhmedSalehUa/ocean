/// Whether a workflow step is captured once for the whole PO (`vendor`) or
/// once per line item (`item`). Drives which capture screen the workflow
/// routes to.
enum StepLevel { vendor, item, unknown }

extension StepLevelX on StepLevel {
  static StepLevel parse(String? value) {
    return switch (value?.toUpperCase()) {
      'VENDOR' => StepLevel.vendor,
      'ITEM' => StepLevel.item,
      _ => StepLevel.unknown,
    };
  }
}

class WorkflowStep {
  final String id;
  final String nameEn;
  final String nameAr;
  final int sortOrder;
  final bool requiresShipmentPhoto;
  final bool requiresItemPhoto;
  final bool isFinalStep;

  /// VENDOR → one shipment photo for the whole PO; ITEM → a photo per item.
  final StepLevel stepLevel;

  /// Optional steps (`is_required:false`) don't block finalize.
  final bool isRequired;

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
    this.stepLevel = StepLevel.unknown,
    this.isRequired = true,
    this.shipmentLogCount = 0,
    this.itemLogCount = 0,
    this.totalItems = 0,
    this.shipmentCompleted = false,
    this.itemCompletedCount = 0,
  });

  String nameFor(String localeCode) => localeCode.startsWith('ar') ? nameAr : nameEn;

  /// Per-item capture step: the user photographs every line item.
  bool get isItemStep => stepLevel == StepLevel.item || (requiresItemPhoto && !requiresShipmentPhoto);

  /// Vendor-level capture step: one shipment photo covers the whole PO.
  bool get isVendorStep =>
      stepLevel == StepLevel.vendor || (requiresShipmentPhoto && !requiresItemPhoto);

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
        stepLevel: stepLevel,
        isRequired: isRequired,
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
        stepLevel: stepLevel != StepLevel.unknown ? stepLevel : other.stepLevel,
        isRequired: isRequired || other.isRequired,
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
  /// newer `/steps` object shape.
  ///
  /// `step_level` (VENDOR | ITEM) is authoritative for the capture mode:
  /// a VENDOR step needs one shipment photo, an ITEM step needs a photo per
  /// line item. When present it drives the requires-photo flags so routing
  /// can't disagree with the backend. Falls back to the raw flags for the
  /// legacy/mock shape that has no step_level.
  factory WorkflowStep.fromJson(Map<String, dynamic> json, {int? fallbackTotalItems}) {
    int asInt(dynamic v) =>
        v is int ? v : (v is String ? int.tryParse(v) ?? 0 : (v as num?)?.toInt() ?? 0);
    bool? asBool(dynamic v) => v is bool ? v : null;

    final level = StepLevelX.parse(json['step_level'] as String?);

    final rawShipment = json['requires_shipment_photo'] as bool? ?? false;
    final rawItem = json['requires_item_photo'] as bool? ?? false;
    // Derive the capture mode from step_level when the backend supplies it.
    final requiresShipment = switch (level) {
      StepLevel.vendor => true,
      StepLevel.item => false,
      StepLevel.unknown => rawShipment,
    };
    final requiresItem = switch (level) {
      StepLevel.item => true,
      StepLevel.vendor => false,
      StepLevel.unknown => rawItem,
    };

    final perStepTotal = asInt(json['total_items']);
    final total = perStepTotal > 0 ? perStepTotal : (fallbackTotalItems ?? 0);

    final shipmentDone =
        asBool(json['shipment_completed']) ?? asBool(json['vendor_completed']) ?? false;

    // Item completion count (per-item steps). `item_completed_count` is the
    // canonical key; the boolean fallbacks cover any variant shape.
    var itemCompleted = asInt(json['item_completed_count']);
    if (itemCompleted == 0) {
      final itemDone = asBool(json['item_completed']) ??
          asBool(json['items_completed']) ??
          asBool(json['completed']);
      if (itemDone == true) itemCompleted = total;
    }

    return WorkflowStep(
      id: json['id'] as String,
      nameEn: (json['name_en'] as String?) ?? '',
      nameAr: (json['name_ar'] as String?) ?? '',
      sortOrder: asInt(json['sort_order']),
      requiresShipmentPhoto: requiresShipment,
      requiresItemPhoto: requiresItem,
      isFinalStep: json['is_final_step'] as bool? ?? false,
      stepLevel: level,
      isRequired: json['is_required'] as bool? ?? true,
      shipmentLogCount: asInt(json['shipment_log_count']),
      itemLogCount: asInt(json['item_log_count']),
      totalItems: total,
      shipmentCompleted: shipmentDone,
      itemCompletedCount: itemCompleted,
    );
  }
}
