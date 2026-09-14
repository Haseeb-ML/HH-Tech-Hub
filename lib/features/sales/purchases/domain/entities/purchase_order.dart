class PurchaseItem {
  final String itemId;
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const PurchaseItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  PurchaseItem copyWith({
    String? itemId,
    String? itemName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return PurchaseItem(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

class PurchaseOrder {
  final String id;
  final String vendorId;
  final String vendorName;
  final String date;
  final String deliveryDate;
  final List<PurchaseItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final String status; // 'Ordered', 'Received', 'Cancelled', 'Pending'

  const PurchaseOrder({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.date,
    required this.deliveryDate,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
  });

  PurchaseOrder copyWith({
    String? id,
    String? vendorId,
    String? vendorName,
    String? date,
    String? deliveryDate,
    List<PurchaseItem>? items,
    double? subtotal,
    double? tax,
    double? total,
    String? status,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      date: date ?? this.date,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
    );
  }
}
