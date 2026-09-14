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
    return BankAccount(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'Bank',
      accountNumber: map['accountNumber'] ?? '',
      bankName: map['bankName'] ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      openingBalance: (map['openingBalance'] as num?)?.toDouble() ?? 0.0,
      openingBalanceDate: map['openingBalanceDate'] ?? '',
      accountScope: map['accountScope'] ?? 'Company',
      ownerName: map['ownerName'] ?? '',
      status: map['status'] ?? 'Active',
    );
  }
}
