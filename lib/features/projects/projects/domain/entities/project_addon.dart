class ProjectAddon {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final double amount;
  final double amountPaid;
  final String status; // 'Pending', 'In Progress', 'Completed'
  final String paymentStatus; // 'Unpaid', 'Partially Paid', 'Paid'
  final String createdAt;
  final String estimatedDelivery;
  final String bankAccountId;
  final String bankAccountName;
  final String paymentMethod; // 'Bank', 'Cash', 'Online'

  const ProjectAddon({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    required this.amount,
    this.amountPaid = 0.0,
    this.status = 'Pending',
    this.paymentStatus = 'Unpaid',
    required this.createdAt,
    this.estimatedDelivery = '',
    this.bankAccountId = '',
    this.bankAccountName = '',
    this.paymentMethod = 'Bank',
  });

  double get remainingAmount => (amount - amountPaid).clamp(0.0, double.infinity);
  bool get isFullyPaid => amountPaid >= amount && amount > 0;

  ProjectAddon copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    double? amount,
    double? amountPaid,
    String? status,
    String? paymentStatus,
    String? createdAt,
    String? estimatedDelivery,
    String? bankAccountId,
    String? bankAccountName,
    String? paymentMethod,
  }) {
    return ProjectAddon(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      amountPaid: amountPaid ?? this.amountPaid,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'description': description,
      'amount': amount,
      'amountPaid': amountPaid,
      'status': status,
      'paymentStatus': paymentStatus,
      'createdAt': createdAt,
      'estimatedDelivery': estimatedDelivery,
      'bankAccountId': bankAccountId,
      'bankAccountName': bankAccountName,
      'paymentMethod': paymentMethod,
    };
  }

  factory ProjectAddon.fromJson(Map<String, dynamic> json) {
    return ProjectAddon(
      id: json['id'] ?? '',
      projectId: json['projectId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Pending',
      paymentStatus: json['paymentStatus'] ?? 'Unpaid',
      createdAt: json['createdAt'] ?? '',
      estimatedDelivery: json['estimatedDelivery'] ?? '',
      bankAccountId: json['bankAccountId'] ?? '',
      bankAccountName: json['bankAccountName'] ?? '',
      paymentMethod: json['paymentMethod'] ?? 'Bank',
    );
  }
}
