import 'enums.dart';

class VendorPoItem {
  final String id;
  final String vendorPoId;
  final String itemCode;
  final String itemName;
  final String? serial;
  final num quantity;
  final String unit;
  final num unitPrice;
  final num totalPrice;
  final ItemStatus status;

  const VendorPoItem({
    required this.id,
    required this.vendorPoId,
    required this.itemCode,
    required this.itemName,
    this.serial,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    required this.status,
  });

  VendorPoItem copyWith({ItemStatus? status}) => VendorPoItem(
        id: id,
        vendorPoId: vendorPoId,
        itemCode: itemCode,
        itemName: itemName,
        serial: serial,
        quantity: quantity,
        unit: unit,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        status: status ?? this.status,
      );

  factory VendorPoItem.fromJson(Map<String, dynamic> json) => VendorPoItem(
        id: json['id'] as String,
        vendorPoId: json['vendor_po_id'] as String,
        itemCode: json['item_code'] as String,
        itemName: json['item_name'] as String,
        serial: json['serial'] as String?,
        quantity: json['quantity'] as num,
        unit: json['unit'] as String,
        unitPrice: json['unit_price'] as num,
        totalPrice: json['total_price'] as num,
        status: ItemStatusX.parse(json['status'] as String?),
      );
}
