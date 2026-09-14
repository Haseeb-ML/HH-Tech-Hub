class AdvanceRecord {
  final String id;
  final String employeeId;
  final String employeeName;
  final double amount;
  final String requestDate; // 'YYYY-MM-DD'
  final String reason;
  final int repaymentMonths;
  final double amountRepaid;
  final String status; // 'Pending', 'Approved', 'Rejected', 'Fully Paid'

  const AdvanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    required this.requestDate,
    required this.reason,
    required this.repaymentMonths,
    required this.amountRepaid,
    required this.status,
  });

  double get monthlyDeduction => amount / repaymentMonths;
  double get remainingAmount => amount - amountRepaid;

  AdvanceRecord copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    double? amount,
    String? requestDate,
    String? reason,
    int? repaymentMonths,
    double? amountRepaid,
    String? status,
  }) {
    return AdvanceRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      amount: amount ?? this.amount,
      requestDate: requestDate ?? this.requestDate,
      reason: reason ?? this.reason,
      repaymentMonths: repaymentMonths ?? this.repaymentMonths,
      amountRepaid: amountRepaid ?? this.amountRepaid,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'amount': amount,
      'requestDate': requestDate,
      'reason': reason,
      'repaymentMonths': repaymentMonths,
      'amountRepaid': amountRepaid,
      'status': status,
    };
  }

  factory AdvanceRecord.fromMap(Map<String, dynamic> map) {
    return AdvanceRecord(
      id: map['id'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      requestDate: map['requestDate'] ?? '',
      reason: map['reason'] ?? '',
      repaymentMonths: map['repaymentMonths'] ?? 1,
      amountRepaid: (map['amountRepaid'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Pending',
    );
  }
}
