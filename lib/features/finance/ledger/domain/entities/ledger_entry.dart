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
  });

  static List<LedgerEntry> sortEntriesNewestFirst(List<LedgerEntry> entries) {
    final sorted = List<LedgerEntry>.from(entries);
    sorted.sort((a, b) {
      final dateA = _parseDateTime(a.date);
      final dateB = _parseDateTime(b.date);

      // 1. Minute-level date comparison (Year, Month, Day, Hour, Minute)
      final minA = DateTime(dateA.year, dateA.month, dateA.day, dateA.hour, dateA.minute);
      final minB = DateTime(dateB.year, dateB.month, dateB.day, dateB.hour, dateB.minute);
      final minCmp = minB.compareTo(minA);
      if (minCmp != 0) return minCmp;

      // 2. Asset / Inventory purchase prioritization if applicable
      final aIsAstOrInv = a.id.contains('AST') || a.id.contains('INV');
      final bIsAstOrInv = b.id.contains('AST') || b.id.contains('INV');
      if (aIsAstOrInv && !bIsAstOrInv) return -1;
      if (!aIsAstOrInv && bIsAstOrInv) return 1;

      // 3. For entries occurring in the same minute, sort by creation timestamp (Epoch in ID)
      // Newest created transaction appears on top (descending order)
      final aNum = _numericId(a.id);
      final bNum = _numericId(b.id);
      final numericCmp = bNum.compareTo(aNum);
      if (numericCmp != 0) return numericCmp;

      // 4. Exact date comparison (seconds & milliseconds)
      final dateCmp = dateB.compareTo(dateA);
      if (dateCmp != 0) return dateCmp;

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
    );
  }
}
