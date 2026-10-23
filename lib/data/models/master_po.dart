import 'enums.dart';

class MasterPo {
  final String id;
  final String masterPoNumber;
  final DateTime? operationDate;
  final MasterStatus status;
  final DateTime createdAt;
  final int vendorPoCount;
  final int deliveredVendorPoCount;

  // Mock-only convenience fields (carried alongside the wire data)
  final String? site;
  final double? siteLat;
  final double? siteLng;
  final String? priorityLabel;
  final bool urgent;

  // Soft copy (e.g. the LPO PDF) attached to the master PO, if any.
  final String? softCopyFileName;
  final String? softCopyUrl;

  const MasterPo({
    required this.id,
    required this.masterPoNumber,
    this.operationDate,
    required this.status,
    required this.createdAt,
    required this.vendorPoCount,
    required this.deliveredVendorPoCount,
    this.site,
    this.siteLat,
    this.siteLng,
    this.priorityLabel,
    this.urgent = false,
    this.softCopyFileName,
    this.softCopyUrl,
  });

  bool get hasSoftCopy => (softCopyUrl ?? '').isNotEmpty;

  double get progress => vendorPoCount == 0 ? 0 : deliveredVendorPoCount / vendorPoCount;
  bool get isClosed => deliveredVendorPoCount >= vendorPoCount && vendorPoCount > 0;

  MasterPo copyWith({
    int? deliveredVendorPoCount,
    MasterStatus? status,
  }) =>
      MasterPo(
        id: id,
        masterPoNumber: masterPoNumber,
        operationDate: operationDate,
        status: status ?? this.status,
        createdAt: createdAt,
        vendorPoCount: vendorPoCount,
        deliveredVendorPoCount: deliveredVendorPoCount ?? this.deliveredVendorPoCount,
        site: site,
        siteLat: siteLat,
        siteLng: siteLng,
        priorityLabel: priorityLabel,
        urgent: urgent,
        softCopyFileName: softCopyFileName,
        softCopyUrl: softCopyUrl,
      );

  factory MasterPo.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic v) =>
        v is int ? v : (v is String ? int.tryParse(v) ?? 0 : (v as num?)?.toInt() ?? 0);
    DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

    final soft = json['soft_copy'];
    final softMap = soft is Map ? soft.cast<String, dynamic>() : const <String, dynamic>{};

    return MasterPo(
      id: json['id'] as String,
      masterPoNumber: json['master_po_number'] as String,
      operationDate: _date(json['operation_date']),
      status: MasterStatusX.parse(json['status'] as String?),
      createdAt: _date(json['created_at']) ?? DateTime.now(),
      vendorPoCount: _asInt(json['vendor_po_count']),
      deliveredVendorPoCount: _asInt(json['delivered_vendor_po_count']),
      site: json['site'] as String?,
      siteLat: (json['site_lat'] as num?)?.toDouble(),
      siteLng: (json['site_lng'] as num?)?.toDouble(),
      priorityLabel: json['priority_label'] as String?,
      urgent: json['urgent'] as bool? ?? false,
      softCopyFileName: softMap['file_name']?.toString(),
      softCopyUrl: softMap['download_url']?.toString(),
    );
  }
}
