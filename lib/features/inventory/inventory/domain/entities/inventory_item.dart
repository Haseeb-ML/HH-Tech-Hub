class InventoryItem {
  final String id;
  final String name;
  final String category; // 'Stationery', 'Pantry', 'Merchandise', 'Office Supplies'
  final int quantity;
  final int minQuantity;
  final String unit; // 'pcs', 'boxes', 'rims', 'packs'
  final double pricePerUnit;
  final String lastRestockedDate;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.minQuantity,
    required this.unit,
    required this.pricePerUnit,
    required this.lastRestockedDate,
  });

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    int? quantity,
    int? minQuantity,
    String? unit,
    double? pricePerUnit,
    String? lastRestockedDate,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      minQuantity: minQuantity ?? this.minQuantity,
      unit: unit ?? this.unit,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      lastRestockedDate: lastRestockedDate ?? this.lastRestockedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'minQuantity': minQuantity,
      'unit': unit,
      'pricePerUnit': pricePerUnit,
      'lastRestockedDate': lastRestockedDate,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? 'Office Supplies',
      quantity: map['quantity'] as int? ?? 0,
      minQuantity: map['minQuantity'] as int? ?? 0,
      unit: map['unit'] ?? 'pcs',
      pricePerUnit: (map['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
      lastRestockedDate: map['lastRestockedDate'] ?? '',
    );
  }
}
