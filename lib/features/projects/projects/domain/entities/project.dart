class Project {
  final String id;
  final String name;
  final String description;
  final String clientId;
  final String clientName;
  final String startDate;
  final String endDate;
  final String status; // 'Planning', 'In Progress', 'On Hold', 'Completed'
  final double budget;
  final double advancedPayment;
  final double partialPayments;
  final double finalPayment;
  final String paymentStatus; // 'Pending', 'Partially Paid', 'Fully Paid'
  final String bankAccountId;
  final String bankAccountName;
  final String accountHolder;
  final List<String> teamMembers; // Employee IDs
  final String clientPaymentSource;

  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.clientId,
    required this.clientName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.budget,
    required this.advancedPayment,
    this.partialPayments = 0.0,
    this.finalPayment = 0.0,
    this.paymentStatus = 'Pending',
    required this.bankAccountId,
    required this.bankAccountName,
    required this.accountHolder,
    required this.teamMembers,
    required this.clientPaymentSource,
  });

  double get remainingPayment => budget - (advancedPayment + partialPayments + finalPayment);

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? clientId,
    String? clientName,
    String? startDate,
    String? endDate,
    String? status,
    double? budget,
    double? advancedPayment,
    double? partialPayments,
    double? finalPayment,
    String? paymentStatus,
    String? bankAccountId,
    String? bankAccountName,
    String? accountHolder,
    List<String>? teamMembers,
    String? clientPaymentSource,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      budget: budget ?? this.budget,
      advancedPayment: advancedPayment ?? this.advancedPayment,
      partialPayments: partialPayments ?? this.partialPayments,
      finalPayment: finalPayment ?? this.finalPayment,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      accountHolder: accountHolder ?? this.accountHolder,
      teamMembers: teamMembers ?? this.teamMembers,
      clientPaymentSource: clientPaymentSource ?? this.clientPaymentSource,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'clientId': clientId,
      'clientName': clientName,
      'startDate': startDate,
      'endDate': endDate,
      'status': status,
      'budget': budget,
      'advancedPayment': advancedPayment,
      'partialPayments': partialPayments,
      'finalPayment': finalPayment,
      'paymentStatus': paymentStatus,
      'bankAccountId': bankAccountId,
      'bankAccountName': bankAccountName,
      'accountHolder': accountHolder,
      'teamMembers': teamMembers,
      'clientPaymentSource': clientPaymentSource,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
      status: map['status'] ?? 'Planning',
      budget: (map['budget'] as num?)?.toDouble() ?? 0.0,
      advancedPayment: (map['advancedPayment'] as num?)?.toDouble() ?? 0.0,
      partialPayments: (map['partialPayments'] as num?)?.toDouble() ?? 0.0,
      finalPayment: (map['finalPayment'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: map['paymentStatus'] ?? 'Pending',
      bankAccountId: map['bankAccountId'] ?? '',
      bankAccountName: map['bankAccountName'] ?? '',
      accountHolder: map['accountHolder'] ?? '',
      teamMembers: List<String>.from(map['teamMembers'] ?? []),
      clientPaymentSource: map['clientPaymentSource'] ?? 'Cash',
    );
  }
}
