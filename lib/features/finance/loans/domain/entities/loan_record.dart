class LoanRepayment {
  final String id;
  final String date;
  final double amount;
  final String accountId;
  final String accountName;

  const LoanRepayment({
    required this.id,
    required this.date,
    required this.amount,
    required this.accountId,
    required this.accountName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'amount': amount,
      'accountId': accountId,
      'accountName': accountName,
    };
  }
}

class LoanRecord {
  final String id;
  final String borrowerName; // Person or Bank name
  final String type; // 'Lent' or 'Borrowed'
  final double amount;
  final double remainingBalance;
  final String startDate;
  final String endDate;
  final String status; // 'Active', 'Repaid'
  final String description;
  final String accountId;
  final String accountName;
  final List<LoanRepayment> repayments;

  const LoanRecord({
    required this.id,
    required this.borrowerName,
    required this.type,
    required this.amount,
    required this.remainingBalance,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.description,
    this.accountId = '',
    this.accountName = '',
    required this.repayments,
  });

  /// Extracts clean description without internal account metadata tags
  String get cleanDescription {
    return description
        .replaceAll(RegExp(r'\s*\[Account:.*?\]'), '')
        .replaceAll(RegExp(r'\s*\[PersonalAccount:.*?\]'), '')
        .trim();
  }

  /// Extracts account ID from field or embedded tag in description
  String get resolvedAccountId {
    if (accountId.isNotEmpty) return accountId;
    final match = RegExp(r'\[Account:(.*?)\|(.*?)\]').firstMatch(description);
    if (match != null) {
      return match.group(1) ?? '';
    }
    return '';
  }

  /// Extracts account Name from field or embedded tag in description
  String get resolvedAccountName {
    if (accountName.isNotEmpty) return accountName;
    final match = RegExp(r'\[Account:(.*?)\|(.*?)\]').firstMatch(description);
    if (match != null) {
      return match.group(2) ?? '';
    }
    return '';
  }

  /// Extracts personal account ID from embedded tag in description
  String get personalAccountId {
    final match = RegExp(r'\[PersonalAccount:(.*?)\|(.*?)\]').firstMatch(description);
    if (match != null) {
      return match.group(1) ?? '';
    }
    return '';
  }

  /// Extracts personal account Name from embedded tag in description
  String get personalAccountName {
    final match = RegExp(r'\[PersonalAccount:(.*?)\|(.*?)\]').firstMatch(description);
    if (match != null) {
      return match.group(2) ?? '';
    }
    return '';
  }

  /// True if this loan is linked with an Owner / Partner personal account
  bool get isPersonalLoan => personalAccountId.isNotEmpty;

  LoanRecord copyWith({
    String? id,
    String? borrowerName,
    String? type,
    double? amount,
    double? remainingBalance,
    String? startDate,
    String? endDate,
    String? status,
    String? description,
    String? accountId,
    String? accountName,
    List<LoanRepayment>? repayments,
  }) {
    return LoanRecord(
      id: id ?? this.id,
      borrowerName: borrowerName ?? this.borrowerName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      description: description ?? this.description,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      repayments: repayments ?? this.repayments,
    );
  }
}
