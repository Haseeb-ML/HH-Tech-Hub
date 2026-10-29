import 'dart:convert';

class RecycleBinItem {
  final String id;
  final String itemType; // 'Account', 'Employee', 'Client', 'Expense', 'Income', 'Project', 'Task', 'Product', 'Asset', 'Invoice', 'Loan'
  final String title;
  final String subtitle;
  final String deletedAt;
  final String deletedBy;
  final Map<String, dynamic> jsonData;

  RecycleBinItem({
    required this.id,
    required this.itemType,
    required this.title,
    required this.subtitle,
    required this.deletedAt,
    required this.deletedBy,
    required this.jsonData,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'itemType': itemType,
        'title': title,
        'subtitle': subtitle,
        'deletedAt': deletedAt,
        'deletedBy': deletedBy,
        'jsonData': jsonData,
      };

  factory RecycleBinItem.fromMap(Map<String, dynamic> map) => RecycleBinItem(
        id: map['id'] ?? '',
        itemType: map['itemType'] ?? 'Record',
        title: map['title'] ?? '',
        subtitle: map['subtitle'] ?? '',
        deletedAt: map['deletedAt'] ?? '',
        deletedBy: map['deletedBy'] ?? 'Admin',
        jsonData: map['jsonData'] is Map ? Map<String, dynamic>.from(map['jsonData']) : {},
      );

  String toJson() => jsonEncode(toMap());

  factory RecycleBinItem.fromJson(String source) => RecycleBinItem.fromMap(jsonDecode(source));
}
