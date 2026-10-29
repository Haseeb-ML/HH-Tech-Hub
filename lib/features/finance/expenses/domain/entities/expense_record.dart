class ExpenseRecord {
  static const List<String> validCategories = [
    'Rent',
    'Salaries',
    'Salary Advances',
    'Bills',
    'Internet',
    'Electricity',
    'Supplies',
    'Refreshments',
    'Travel',
    'Office Inventory',
    'Assets Management',
    'Other',
  ];

  final String id;
  final String date; // ISO-8601 Date
  final double amount;
  final String accountId; // Debit source account
  final String category; // 'Rent', 'Salaries', 'Bills', 'Internet', 'Electricity', 'Supplies', 'Refreshments', 'Travel', 'Office Inventory', 'Assets Management', 'Other'
  final String vendorName; // Optional
  final String description;
  final bool isPersonalExpense;

  const ExpenseRecord({
    required this.id,
    required this.date,
    required this.amount,
    required this.accountId,
    required this.category,
    required this.vendorName,
    required this.description,
    this.isPersonalExpense = false,
  });

  ExpenseRecord copyWith({
    String? id,
    String? date,
    double? amount,
    String? accountId,
    String? category,
    String? vendorName,
    String? description,
    bool? isPersonalExpense,
  }) {
    return ExpenseRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      category: category ?? this.category,
      vendorName: vendorName ?? this.vendorName,
      description: description ?? this.description,
      isPersonalExpense: isPersonalExpense ?? this.isPersonalExpense,
    );
  }

  /// Orderly formatted Expense ID (e.g. sal_0001 for salaries, exp_0001 for general expenses)
  String get expenseId {
    final isSalary = category.toLowerCase().contains('salary') ||
        category.toLowerCase().contains('payroll') ||
        id.toLowerCase().contains('sal_');
    final prefix = isSalary ? 'sal_' : 'exp_';

    final digits = id.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) {
      final numVal = int.tryParse(digits);
      if (numVal != null) {
        if (numVal <= 9999) {
          return '$prefix${numVal.toString().padLeft(4, '0')}';
        }
        final last4 = numVal % 10000;
        final seq = last4 == 0 ? 1 : last4;
        return '$prefix${seq.toString().padLeft(4, '0')}';
      }
    }
    return '${prefix}0001';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'amount': amount,
      'accountId': accountId,
      'category': category,
      'vendorName': vendorName,
      'description': description,
      'isPersonalExpense': isPersonalExpense,
    };
  }

  static String normalizeCategory(String category) {
    final normalized = category.trim();
    if (normalized.isEmpty) return 'Other';

    final lower = normalized.toLowerCase();
    if (lower.contains('electric') || lower.contains('utilit')) return 'Electricity & Utilities';
    if (lower.contains('advance')) return 'Salary Advances';
    if (lower.contains('salar') || lower.contains('payroll')) return 'Salaries & Payroll';
    if (lower.contains('internet') || lower.contains('telecom') || lower == 'wifi') return 'Internet & Telecom';
    if (lower.contains('rent')) return 'Rent & Occupancy';
    if (lower == 'misc' || lower == 'other' || lower == 'miscellaneous') return 'Other';
    if (lower == 'office inventory') return 'Office Inventory';
    if (lower == 'assets management' || lower == 'asset management') return 'Assets Management';

    final exactMatch = validCategories.firstWhere(
      (c) => c.toLowerCase() == lower,
      orElse: () => '',
    );

    return exactMatch.isNotEmpty ? exactMatch : 'Other';
  }

  static String inventoryCategory() => 'Office Inventory';
  static String assetCategory() => 'Assets Management';

  static DateTime resolveExpenseDateTime(ExpenseRecord e) {
    if (e.date.endsWith('T12:00:00.000') && (e.id.contains('AST') || e.id.contains('INV'))) {
      final base = DateTime.tryParse(e.date.substring(0, 10));
      if (base != null) return base;
    }

    final parsed = DateTime.tryParse(e.date);
    if (parsed == null) return DateTime.fromMillisecondsSinceEpoch(0);

    final hasExplicitTime = e.date.contains('T') || e.date.contains(' ');
    final isMidnight = parsed.hour == 0 && parsed.minute == 0 && parsed.second == 0;
    if (!hasExplicitTime || isMidnight) {
      final match13 = RegExp(r'\d{12,14}').firstMatch(e.id);
      if (match13 != null) {
        final ms = int.tryParse(match13.group(0)!);
        if (ms != null) {
          final idDt = DateTime.fromMillisecondsSinceEpoch(ms);
          if (idDt.year == parsed.year && idDt.month == parsed.month && idDt.day == parsed.day) {
            return idDt;
          }
        }
      }
    }

    return parsed;
  }

  static BigInt numericExpenseId(String id) {
    final m13 = RegExp(r'\d{12,14}').firstMatch(id);
    if (m13 != null) {
      return BigInt.tryParse(m13.group(0)!) ?? BigInt.zero;
    }
    final matches = RegExp(r'\d+').allMatches(id);
    String longest = '';
    for (final m in matches) {
      final s = m.group(0)!;
      if (s.length > longest.length) longest = s;
    }
    return BigInt.tryParse(longest) ?? BigInt.zero;
  }

  static List<ExpenseRecord> sortExpensesNewestFirst(List<ExpenseRecord> records) {
    final list = List<ExpenseRecord>.from(records);
    list.sort((a, b) {
      final dtA = resolveExpenseDateTime(a);
      final dtB = resolveExpenseDateTime(b);

      final dateCmp = dtB.compareTo(dtA);
      if (dateCmp != 0) return dateCmp;

      final aNum = numericExpenseId(a.id);
      final bNum = numericExpenseId(b.id);
      final numCmp = bNum.compareTo(aNum);
      if (numCmp != 0) return numCmp;

      return b.id.compareTo(a.id);
    });
    return list;
  }

  factory ExpenseRecord.fromMap(Map<String, dynamic> map) {
    return ExpenseRecord(
      id: map['id'] ?? '',
      date: map['date'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      accountId: map['accountId'] ?? '',
      category: normalizeCategory(map['category'] ?? 'Other'),
      vendorName: map['vendorName'] ?? '',
      description: map['description'] ?? '',
      isPersonalExpense: map['isPersonalExpense'] ?? false,
    );
  }
}
