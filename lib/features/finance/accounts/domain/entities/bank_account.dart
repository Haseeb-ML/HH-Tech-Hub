class BankAccount {
  final String id;
  final String name;
  final String type; // 'Cash', 'Bank', 'Wallet'
  final String accountNumber; // Empty for Cash
  final String bankName; // Empty for Cash
  final double balance;
  final double openingBalance;
  final String openingBalanceDate;
  final String accountScope; // 'Company', 'Personal'
  final String ownerName; // Empty for 'Company' scope
  final String status; // 'Active', 'Inactive'

  const BankAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.accountNumber,
    required this.bankName,
    required this.balance,
    this.openingBalance = 0.0,
    this.openingBalanceDate = '',
    this.accountScope = 'Company',
    this.ownerName = '',
    required this.status,
  });

  bool get isPersonal =>
      accountScope.toLowerCase() == 'personal' ||
      id.toLowerCase().contains('personal') ||
      name.toLowerCase().contains('personal');

  bool get isCompany => !isPersonal;

  String get ledgerOpeningDate {
    if (openingBalanceDate.isNotEmpty) {
      return openingBalanceDate;
    }

    final match = RegExp(r'\d{12,14}').firstMatch(id);
    final timestamp = match == null ? null : int.tryParse(match.group(0)!);
    if (timestamp != null && timestamp > 0 && timestamp < 8640000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp).toIso8601String();
    }

    return DateTime.fromMillisecondsSinceEpoch(0).toIso8601String();
  }

  BankAccount copyWith({
    String? id,
    String? name,
    String? type,
    String? accountNumber,
    String? bankName,
    double? balance,
    double? openingBalance,
    String? openingBalanceDate,
    String? accountScope,
    String? ownerName,
    String? status,
  }) {
    return BankAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      balance: balance ?? this.balance,
      openingBalance: openingBalance ?? this.openingBalance,
      openingBalanceDate: openingBalanceDate ?? this.openingBalanceDate,
      accountScope: accountScope ?? this.accountScope,
      ownerName: ownerName ?? this.ownerName,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'balance': balance,
      'openingBalance': openingBalance,
      'openingBalanceDate': openingBalanceDate,
      'accountScope': accountScope,
      'ownerName': ownerName,
      'status': status,
    };
  }

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString() ?? '';
    final name = map['name']?.toString() ?? '';
    final rawScope = map['accountScope']?.toString().trim() ?? '';
    final isPersonal = rawScope.toLowerCase() == 'personal' ||
        id.toLowerCase().contains('personal') ||
        name.toLowerCase().contains('personal');
    final bal = (map['balance'] as num?)?.toDouble() ?? 0.0;
    final openingBal = (map['openingBalance'] as num?)?.toDouble() ?? 0.0;

    return BankAccount(
      id: id,
      name: name,
      type: map['type'] ?? 'Bank',
      accountNumber: map['accountNumber'] ?? '',
      bankName: map['bankName'] ?? '',
      balance: bal,
      openingBalance: openingBal > 0 ? openingBal : (bal > 0 ? bal : 0.0),
      openingBalanceDate: map['openingBalanceDate'] ?? '',
      accountScope: isPersonal ? 'Personal' : 'Company',
      ownerName: map['ownerName'] ??
          (isPersonal ? name.replaceAll(RegExp(r'Personal\s*Account', caseSensitive: false), '').trim() : ''),
      status: map['status'] ?? 'Active',
    );
  }
}
