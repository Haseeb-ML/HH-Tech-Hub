import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/repositories/accounts_repository.dart';

class AccountsRepositoryImpl implements AccountsRepository {
  final DriftDatabaseService _dbService;

  AccountsRepositoryImpl(this._dbService);


  /// Performs a one-time automatic migration of any legacy SharedPreferences
  /// bank account metadata into SQLite, consolidating SQLite as the SINGLE source of truth.
  Future<void> _migrateLegacyPrefsMeta() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const metaKey = 'bank_accounts_metadata_v1';
      final str = prefs.getString(metaKey);
      if (str != null && str.isNotEmpty) {
        final decoded = jsonDecode(str);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            final accId = entry.key;
            final m = entry.value as Map<String, dynamic>?;
            if (m != null) {
              final openingBalance = (m['openingBalance'] as num?)?.toDouble() ?? 0.0;
              final openingBalanceDate = m['openingBalanceDate']?.toString() ?? '';
              final accountScope = m['accountScope']?.toString() ?? 'Company';
              final ownerName = m['ownerName']?.toString() ?? '';

              await _dbService.db.customStatement('''
                UPDATE bank_accounts_table
                SET opening_balance = ?, opening_balance_date = ?, account_scope = ?, owner_name = ?
                WHERE id = ?
              ''', [openingBalance, openingBalanceDate, accountScope, ownerName, accId]);
            }
          }
        }
        await prefs.remove(metaKey);
      }
    } catch (_) {}
  }

  @override
  Future<List<BankAccount>> getAccounts() async {
    await _migrateLegacyPrefsMeta();

    final list = await _dbService.db.getAll(_dbService.db.bankAccountsTable);
    final allLedgers = await _dbService.db.getAll(_dbService.db.ledgerEntriesTable);
    final openingLedgerMap = <String, LedgerEntriesTableData>{};
    for (final l in allLedgers) {
      if (l.category == 'Opening Balance' || l.id.startsWith('led_opening_')) {
        openingLedgerMap[l.accountId] = l;
      }
    }

    return list.map((a) {
      final isPersonal = (a.accountScope.toLowerCase() == 'personal') ||
          a.id.toLowerCase().contains('personal') ||
          a.name.toLowerCase().contains('personal');

      final ledgerOpening = openingLedgerMap[a.id];
      final rawOpening = a.openingBalance > 0 ? a.openingBalance : (ledgerOpening?.amount ?? 0.0);
      final openingDate = a.openingBalanceDate.isNotEmpty ? a.openingBalanceDate : (ledgerOpening?.date ?? '');
      final owner = a.ownerName.isNotEmpty
          ? a.ownerName
          : (isPersonal ? a.name.replaceAll(RegExp(r'Personal\s*Account', caseSensitive: false), '').trim() : '');

      return BankAccount(
        id: a.id,
        name: a.name,
        type: a.type,
        accountNumber: a.accountNumber,
        bankName: a.bankName,
        balance: a.balance,
        status: a.status,
        openingBalance: rawOpening,
        openingBalanceDate: openingDate,
        accountScope: isPersonal ? 'Personal' : 'Company',
        ownerName: owner,
      );
    }).toList();
  }

  @override
  Future<void> addAccount(BankAccount account) async {
    await _dbService.db.upsert(
      _dbService.db.bankAccountsTable,
      BankAccountsTableCompanion.insert(
        id: account.id,
        name: account.name,
        type: account.type,
        accountNumber: account.accountNumber,
        bankName: account.bankName,
        balance: account.balance,
        status: account.status,
        openingBalance: Value(account.openingBalance),
        openingBalanceDate: Value(account.openingBalanceDate),
        accountScope: Value(account.accountScope),
        ownerName: Value(account.ownerName),
      ),
    );
  }

  @override
  Future<void> updateAccount(BankAccount account) async {
    await addAccount(account);
  }

  @override
  Future<void> deleteAccount(String id) async {
    await _dbService.db.deleteById(_dbService.db.bankAccountsTable, id);
  }
}
