import 'delivery_note.dart';
import 'enums.dart';

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
      site: json['site'] as String?,
      siteLat: (json['site_lat'] as num?)?.toDouble(),
      siteLng: (json['site_lng'] as num?)?.toDouble(),
      priorityLabel: json['priority_label'] as String?,
      urgent: json['urgent'] as bool? ?? false,
    );
  }
}
