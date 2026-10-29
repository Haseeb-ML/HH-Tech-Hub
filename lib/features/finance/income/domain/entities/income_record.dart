class IncomeRecord {
  final String id;
  final String date; // ISO-8601 Date
  final String clientId; // Optional/Empty if not client-related
  final String clientName; // e.g. "Vertex Mobile"
  final double amount;
  final String accountId; // Credit target account
  final String invoiceNumber; // Optional
  final String description;
  final String status; // 'Received', 'Pending'
  final String? projectId;
  final String? projectName;
  final String? projectPaymentType; // 'Advance', 'Partial', 'Final'

  const IncomeRecord({
    required this.id,
    required this.date,
    required this.clientId,
    required this.clientName,
    required this.amount,
    required this.accountId,
    required this.invoiceNumber,
    required this.description,
    required this.status,
    this.projectId,
    this.projectName,
    this.projectPaymentType,
  });

  IncomeRecord copyWith({
    String? id,
    String? date,
    String? clientId,
    String? clientName,
    double? amount,
    String? accountId,
    String? invoiceNumber,
    String? description,
    String? status,
    String? projectId,
    String? projectName,
    String? projectPaymentType,
  }) {
    return IncomeRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      description: description ?? this.description,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      projectPaymentType: projectPaymentType ?? this.projectPaymentType,
    );
  }

  /// Orderly formatted Receipt ID (e.g. rec_0001, rec_0002)
  String get receiptId {
    if (id.startsWith('rec_')) {
      final sub = id.substring(4);
      final numVal = int.tryParse(sub);
      if (numVal != null) return 'rec_${numVal.toString().padLeft(4, '0')}';
      if (sub.length >= 4) {
        final last4 = int.tryParse(sub.substring(sub.length - 4));
        if (last4 != null) return 'rec_${last4.toString().padLeft(4, '0')}';
      }
    }
    final digits = id.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) {
      final numVal = int.tryParse(digits.length > 4 ? digits.substring(digits.length - 4) : digits) ?? 1;
      return 'rec_${numVal.toString().padLeft(4, '0')}';
    }
    return 'rec_0001';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'clientId': clientId,
      'clientName': clientName,
      'amount': amount,
      'accountId': accountId,
      'invoiceNumber': invoiceNumber,
      'description': description,
      'status': status,
      'projectId': projectId,
      'projectName': projectName,
      'projectPaymentType': projectPaymentType,
    };
  }

  factory IncomeRecord.fromMap(Map<String, dynamic> map) {
    return IncomeRecord(
      id: map['id'] ?? '',
      date: map['date'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      accountId: map['accountId'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'Received',
      projectId: map['projectId'],
      projectName: map['projectName'],
      projectPaymentType: map['projectPaymentType'],
    );
  }

  /// Categorized income type: 'Project Payment', 'Consulting Services',
  /// 'Maintenance & Support', 'Commission / Referral', or 'Other Income'
  String get incomeType {
    if (projectId != null && projectId!.isNotEmpty) {
      return 'Project Payment';
    }
    if (projectPaymentType != null && projectPaymentType!.isNotEmpty) {
      if (['Advance', 'Partial', 'Final', 'Full'].contains(projectPaymentType)) {
        return 'Project Payment';
      }
      return projectPaymentType!;
    }
    return 'Other Income';
  }

  /// Specific installment or sub-type if project payment
  String? get installmentType {
    if (['Advance', 'Partial', 'Final', 'Full'].contains(projectPaymentType)) {
      return projectPaymentType == 'Full' ? 'Final' : projectPaymentType;
    }
    return null;
  }
}
