class Asset {
  final String id;
  final String name;
  final String type; // 'Hardware', 'Software', 'Other'
  final String purchaseAssetType; // 'Company', 'Personal'
  final String serialNumber;
  final String purchaseDate;
  final double cost;
  final String status; // 'Available', 'Assigned', 'Under Maintenance', 'Retired'
  final String condition; // 'None', 'New', 'Good', 'Fair', 'Damaged'
  final String? assignedToId; // ID of Employee if assigned
  final String? assignedToName; // Name of Employee if assigned

  const Asset({
    required this.id,
    required this.name,
    required this.type,
    this.purchaseAssetType = 'Company',
    required this.serialNumber,
    required this.purchaseDate,
    required this.cost,
    required this.status,
    required this.condition,
    this.assignedToId,
    this.assignedToName,
  });

  Asset copyWith({
    String? id,
    String? name,
    String? type,
    String? purchaseAssetType,
    String? serialNumber,
    String? purchaseDate,
    double? cost,
    String? status,
    String? condition,
    String? assignedToId,
    String? assignedToName,
  }) {
    return Asset(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      purchaseAssetType: purchaseAssetType ?? this.purchaseAssetType,
      serialNumber: serialNumber ?? this.serialNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      cost: cost ?? this.cost,
      status: status ?? this.status,
      condition: condition ?? this.condition,
      assignedToId: assignedToId, // Note: We allow clearing it by explicitly passing null or keeping track of it
      assignedToName: assignedToName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'purchaseAssetType': purchaseAssetType,
      'serialNumber': serialNumber,
      'purchaseDate': purchaseDate,
      'cost': cost,
      'status': status,
      'condition': condition,
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
    };
  }

  factory Asset.fromMap(Map<String, dynamic> map) {
    return Asset(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'Hardware',
      purchaseAssetType: map['purchaseAssetType'] ?? 'Company',
      serialNumber: map['serialNumber'] ?? '',
      purchaseDate: map['purchaseDate'] ?? '',
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Available',
      condition: map['condition'] ?? 'None',
      assignedToId: map['assignedToId'],
      assignedToName: map['assignedToName'],
    );
  }
}
