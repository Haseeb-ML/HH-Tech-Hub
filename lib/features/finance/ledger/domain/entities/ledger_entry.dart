class LedgerEntry {
  final String id;
  final String date; // ISO-8601 Date String
  final String accountId;
  final String accountName;
  final String type; // 'Debit' (Inflow/Income/Repayment Received) or 'Credit' (Outflow/Expense/Loan Lent)
  final String category; // 'Client Invoice', 'Service Fee', 'Salaries', 'Rent', 'Bills', 'Loan Lent', 'Loan Borrowed', etc.
  final double amount;
  final String reference; // e.g. check no, invoice no, loan borrower name, tx id
  final String description;
  final String installmentType;

  const LedgerEntry({
    required this.id,
    required this.date,
    required this.accountId,
    required this.accountName,
    required this.type,
    required this.category,
    required this.amount,
    required this.reference,
    required this.description,
    this.installmentType = '',
  });

  static List<LedgerEntry> sortEntriesNewestFirst(List<LedgerEntry> entries) {
    final sorted = List<LedgerEntry>.from(entries);
    sorted.sort((a, b) {
      final dateA = _parseDateTime(a.date);
      final dateB = _parseDateTime(b.date);

      // 1. Exact Date & Time comparison (Newest first -> descending order)
      final dateCmp = dateB.compareTo(dateA);
      if (dateCmp != 0) return dateCmp;

      // 2. For entries occurring at the exact same millisecond, sort by creation numeric ID (newest first)
      final aNum = _numericId(a.id);
      final bNum = _numericId(b.id);
      final numericCmp = bNum.compareTo(aNum);
      if (numericCmp != 0) return numericCmp;

      return b.id.compareTo(a.id);
    });
    return sorted;
  }

  static DateTime _parseDateTime(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      final normalized = value.replaceFirst(' ', 'T');
      try {
        return DateTime.parse(normalized);
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
  }

  static BigInt _numericId(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return BigInt.tryParse(digits) ?? BigInt.zero;
  }

  LedgerEntry copyWith({
    String? id,
    String? date,
    String? accountId,
    String? accountName,
    String? type,
    String? category,
    double? amount,
    String? reference,
    String? description,
    String? installmentType,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      reference: reference ?? this.reference,
      description: description ?? this.description,
      installmentType: installmentType ?? this.installmentType,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date,
        'accountId': accountId,
        'accountName': accountName,
        'type': type,
        'category': category,
        'amount': amount,
        'reference': reference,
        'description': description,
        'installmentType': installmentType,
      };

  factory LedgerEntry.fromMap(Map<String, dynamic> map) => LedgerEntry(
        id: map['id'] ?? '',
        date: map['date'] ?? '',
        accountId: map['accountId'] ?? '',
        accountName: map['accountName'] ?? '',
        type: map['type'] ?? 'Debit',
        category: map['category'] ?? 'General',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        reference: map['reference'] ?? '',
        description: map['description'] ?? '',
        installmentType: map['installmentType'] ?? '',
      );
  /// Formatted Invoice / Expense ID (e.g. inv_0001 or exp_0001)
  String get formattedInvoiceId {
    final isOutflow = type == 'Credit' || category.toLowerCase().contains('expense');
    final prefix = isOutflow ? 'exp_' : 'inv_';

    if (reference.isNotEmpty) {
      if (reference.startsWith('inv_') || reference.startsWith('exp_') || reference.startsWith('rec_')) {
        final sub = reference.substring(4);
        final numVal = int.tryParse(sub);
        if (numVal != null) return '$prefix${numVal.toString().padLeft(4, '0')}';
      }
      final digits = reference.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isNotEmpty && (reference.toLowerCase().contains('inv') || reference.toLowerCase().contains('exp') || reference.toLowerCase().contains('rec'))) {
        final numVal = int.tryParse(digits.length > 4 ? digits.substring(digits.length - 4) : digits) ?? 1;
        return '$prefix${numVal.toString().padLeft(4, '0')}';
      }
    }

    if (id.startsWith('inc_') || id.startsWith('rec_') || id.startsWith('led_inc_') || id.startsWith('inv_')) {
      final sub = id.replaceAll(RegExp(r'[^0-9]'), '');
      if (sub.isNotEmpty) {
        final numVal = int.tryParse(sub.length > 4 ? sub.substring(sub.length - 4) : sub) ?? 1;
        return 'inv_${numVal.toString().padLeft(4, '0')}';
      }
    } else if (id.startsWith('exp_') || id.startsWith('led_exp_')) {
      final sub = id.replaceAll(RegExp(r'[^0-9]'), '');
      if (sub.isNotEmpty) {
        final numVal = int.tryParse(sub.length > 4 ? sub.substring(sub.length - 4) : sub) ?? 1;
        return 'exp_${numVal.toString().padLeft(4, '0')}';
      }
    }

    final digits = id.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) {
      final numVal = int.tryParse(digits.length > 4 ? digits.substring(digits.length - 4) : digits) ?? 1;
      return '$prefix${numVal.toString().padLeft(4, '0')}';
    }
    return '${prefix}0001';
  }
}
