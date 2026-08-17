import 'delivery_note.dart';
import 'enums.dart';
import 'master_step.dart';
import 'workflow_step.dart';

/// The master PO's active step, as returned inline by the master-pos list.
/// Used to surface an LPO capture action directly on the card.
class MasterCurrentStep {
  final String id;
  final String nameEn;
  final String nameAr;
  final StepLevel stepLevel;

  const MasterCurrentStep({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.stepLevel,
  });

  String nameFor(String localeCode) => localeCode.startsWith('ar') ? nameAr : nameEn;
  bool get isLpo => stepLevel == StepLevel.lpo;

  factory MasterCurrentStep.fromJson(Map<String, dynamic> json) => MasterCurrentStep(
        id: (json['id'] ?? json['workflow_step_id'] ?? '') as String,
        nameEn: (json['name_en'] as String?) ?? '',
        nameAr: (json['name_ar'] as String?) ?? '',
        stepLevel: StepLevelX.parse(json['step_level'] as String?),
      );
}

class MasterPo {
  final String id;
  final String masterPoNumber;
  final DateTime? operationDate;
  final MasterStatus status;
  final DateTime createdAt;
  final int vendorPoCount;
  final int deliveredVendorPoCount;
  final String? vesselName;
  final DateTime? etaDate;
  final String? portName;
  final DeliveryNote? deliveryNote;
  final MasterCurrentStep? currentStep;

  /// Every visible workflow step on this master PO with its rolled-up status,
  /// from the master-pos response `steps` array (spec §5). Drives the
  /// per-master steps screen shown before the vendor list.
  final List<MasterStep> steps;

  /// Primary representative + assigned assistant (sub-logistics officer)
  /// names, when the API surfaces them. Rendered on the card only if present.
  final String? representativeName;
  final String? assistantName;

  // Mock-only convenience fields (carried alongside the wire data)
  final String? site;
  final double? siteLat;
  final double? siteLng;
  final String? priorityLabel;
  final bool urgent;

  const MasterPo({
    required this.id,
    required this.masterPoNumber,
    this.operationDate,
    required this.status,
    required this.createdAt,
    required this.vendorPoCount,
    required this.deliveredVendorPoCount,
    this.vesselName,
    this.etaDate,
    this.portName,
    this.deliveryNote,
    this.currentStep,
    this.steps = const [],
    this.representativeName,
    this.assistantName,
    this.site,
    this.siteLat,
    this.siteLng,
    this.priorityLabel,
    this.urgent = false,
  });

  double get progress => vendorPoCount == 0 ? 0 : deliveredVendorPoCount / vendorPoCount;
  bool get isClosed => deliveredVendorPoCount >= vendorPoCount && vendorPoCount > 0;

  /// The rep can upload their filled delivery note only when the master PO
  /// has moved past IN_PROGRESS — i.e. when the whole delivery has been
  /// resolved on the ground (fully or partially delivered, or closed).
  bool get canUploadDeliveryNote {
    return status == MasterStatus.fullyDelivered;
  }

  MasterPo copyWith({
    int? deliveredVendorPoCount,
    MasterStatus? status,
    DeliveryNote? deliveryNote,
  }) =>
      MasterPo(
        id: id,
        masterPoNumber: masterPoNumber,
        operationDate: operationDate,
        status: status ?? this.status,
        createdAt: createdAt,
        vendorPoCount: vendorPoCount,
        deliveredVendorPoCount: deliveredVendorPoCount ?? this.deliveredVendorPoCount,
        vesselName: vesselName,
        etaDate: etaDate,
        portName: portName,
        deliveryNote: deliveryNote ?? this.deliveryNote,
        currentStep: currentStep,
        steps: steps,
        representativeName: representativeName,
        assistantName: assistantName,
        site: site,
        siteLat: siteLat,
        siteLng: siteLng,
        priorityLabel: priorityLabel,
        urgent: urgent,
      );

  factory MasterPo.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) =>
        v is int ? v : (v is String ? int.tryParse(v) ?? 0 : (v as num?)?.toInt() ?? 0);
    DateTime? date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

    final noteJson = json['delivery_note'];
    final stepJson = json['current_step'];
    final stepsJson = json['steps'];

    // People names arrive under several possible keys depending on the
    // endpoint (flat name, or a nested {name} object). Read the first match
    // tolerantly so the card can surface them whenever they are present.
    String? nameFrom(List<String> flatKeys, List<String> objectKeys) {
      for (final k in flatKeys) {
        final v = json[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      for (final k in objectKeys) {
        final v = json[k];
        if (v is Map<String, dynamic>) {
          final n = v['name'] ?? v['full_name'] ?? v['display_name'];
          if (n is String && n.trim().isNotEmpty) return n.trim();
        }
      }
      return null;
    }

    return MasterPo(
      id: json['id'] as String,
      masterPoNumber: json['master_po_number'] as String,
      operationDate: date(json['operation_date']),
      status: MasterStatusX.parse(json['status'] as String?),
      createdAt: date(json['created_at']) ?? DateTime.now(),
      vendorPoCount: asInt(json['vendor_po_count']),
      deliveredVendorPoCount: asInt(json['delivered_vendor_po_count']),
      vesselName: json['vessel_name'] as String?,
      etaDate: date(json['eta_date']),
      portName: json['port_name'] as String?,
      deliveryNote: noteJson is Map<String, dynamic> ? DeliveryNote.fromJson(noteJson) : null,
      currentStep:
          stepJson is Map<String, dynamic> ? MasterCurrentStep.fromJson(stepJson) : null,
      steps: stepsJson is List
          ? (stepsJson
              .whereType<Map<String, dynamic>>()
              .map(MasterStep.fromJson)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
          : const [],
      representativeName: nameFrom(
        const [
          'representative_name',
          'primary_representative_name',
          'primary_representative',
          'rep_name',
        ],
        const ['representative', 'primary_representative'],
      ),
      assistantName: nameFrom(
        const [
          'assistant_name',
          'sub_logistics_officer_name',
          'sub_officer_name',
          'assistant_representative_name',
        ],
        const ['assistant', 'sub_logistics_officer', 'assistant_representative'],
      ),
      site: json['site'] as String?,
      siteLat: (json['site_lat'] as num?)?.toDouble(),
      siteLng: (json['site_lng'] as num?)?.toDouble(),
      priorityLabel: json['priority_label'] as String?,
      urgent: json['urgent'] as bool? ?? false,
    );
  }
}
