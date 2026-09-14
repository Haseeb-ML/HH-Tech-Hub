class InvoiceItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const InvoiceItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  InvoiceItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
  }) {
    return InvoiceItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SalesInvoice {
  final String id;
  final String clientId;
  final String clientName;
  final String date;
  final String dueDate;
  final List<InvoiceItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final String status; // 'Paid', 'Pending', 'Overdue'

  const SalesInvoice({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.date,
    required this.dueDate,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
  });

  SalesInvoice copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? date,
    String? dueDate,
    List<InvoiceItem>? items,
    double? subtotal,
    double? tax,
    double? total,
    String? status,
  }) {
    return SalesInvoice(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'date': date,
      'dueDate': dueDate,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'status': status,
    };
  }

  factory SalesInvoice.fromMap(Map<String, dynamic> map) {
    return SalesInvoice(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      date: map['date'] ?? '',
      dueDate: map['dueDate'] ?? '',
      items: (map['items'] as List<dynamic>?)?.map((i) => InvoiceItem.fromMap(i)).toList() ?? [],
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Pending',
    );
  }
}
