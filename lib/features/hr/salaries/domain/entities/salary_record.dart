class SalaryRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final String payPeriod; // 'May 2026'
  final double baseSalary;
  final double allowances;
  final double deductions;
  final double netPaid;
  final String paymentDate; // 'YYYY-MM-DD'
  final String status; // 'Paid', 'Pending'
  final String paymentMethod; // 'Bank Transfer', 'Cash', 'Cheque'
  final String accountId;
  final String accountName;

  const SalaryRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.payPeriod,
    required this.baseSalary,
    required this.allowances,
    required this.deductions,
    required this.netPaid,
    required this.paymentDate,
    required this.status,
    required this.paymentMethod,
    this.accountId = '',
    this.accountName = '',
  });

  SalaryRecord copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? payPeriod,
    double? baseSalary,
    double? allowances,
    double? deductions,
    double? netPaid,
    String? paymentDate,
    String? status,
    String? paymentMethod,
    String? accountId,
    String? accountName,
  }) {
    return SalaryRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      payPeriod: payPeriod ?? this.payPeriod,
      baseSalary: baseSalary ?? this.baseSalary,
      allowances: allowances ?? this.allowances,
      deductions: deductions ?? this.deductions,
      netPaid: netPaid ?? this.netPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'payPeriod': payPeriod,
      'baseSalary': baseSalary,
      'allowances': allowances,
      'deductions': deductions,
      'netPaid': netPaid,
      'paymentDate': paymentDate,
      'status': status,
      'paymentMethod': paymentMethod,
      'accountId': accountId,
      'accountName': accountName,
    };
  }

  factory SalaryRecord.fromMap(Map<String, dynamic> map) {
    return SalaryRecord(
      id: map['id'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      payPeriod: map['payPeriod'] ?? '',
      baseSalary: (map['baseSalary'] as num?)?.toDouble() ?? 0.0,
      allowances: (map['allowances'] as num?)?.toDouble() ?? 0.0,
      deductions: (map['deductions'] as num?)?.toDouble() ?? 0.0,
      netPaid: (map['netPaid'] as num?)?.toDouble() ?? 0.0,
      paymentDate: map['paymentDate'] ?? '',
      status: map['status'] ?? 'Paid',
      paymentMethod: map['paymentMethod'] ?? 'Bank Transfer',
      accountId: map['accountId'] ?? '',
      accountName: map['accountName'] ?? '',
    );
  }
}
