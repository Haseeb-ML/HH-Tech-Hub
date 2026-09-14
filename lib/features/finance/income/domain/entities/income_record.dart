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
}
