import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/repositories/accounts_repository.dart';

class AccountsRepositoryImpl implements AccountsRepository {
  final DriftDatabaseService _dbService;
  static const String metaKey = 'bank_accounts_metadata_v1';

  AccountsRepositoryImpl(this._dbService);

  static Future<Map<String, dynamic>> getGlobalMetaMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(metaKey);
      if (str != null) {
        final decoded = jsonDecode(str);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (_) {}
    return {};
  }

  static Future<void> saveGlobalMetaMap(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(metaKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _getMetaMap() async {
    return getGlobalMetaMap();
  }

  Future<void> _saveMeta(String accountId, Map<String, dynamic> data) async {
    try {
      final current = await getGlobalMetaMap();
      current[accountId] = data;
      await saveGlobalMetaMap(current);
    } catch (_) {}
  }

  Future<void> _deleteMeta(String accountId) async {
    try {
      final current = await getGlobalMetaMap();
      if (current.containsKey(accountId)) {
        current.remove(accountId);
        await saveGlobalMetaMap(current);
      }
    } catch (_) {}
  }

  @override
  Future<List<BankAccount>> getAccounts() async {
    final list = await _dbService.db.getAll(_dbService.db.bankAccountsTable);
    final meta = await _getMetaMap();
    final allLedgers = await _dbService.db.getAll(_dbService.db.ledgerEntriesTable);
    final openingLedgerMap = <String, LedgerEntriesTableData>{};
    for (final l in allLedgers) {
      if (l.category == 'Opening Balance' || l.id.startsWith('led_opening_')) {
        openingLedgerMap[l.accountId] = l;
      }
    }

    return list.map((a) {
      final m = (meta[a.id] as Map<String, dynamic>?) ?? {};
      final isPersonal = (m['accountScope']?.toString().toLowerCase() == 'personal') ||
          a.id.toLowerCase().contains('personal') ||
          a.name.toLowerCase().contains('personal');
      final ledgerOpening = openingLedgerMap[a.id];
      final rawOpening = (m['openingBalance'] as num?)?.toDouble() ??
          (ledgerOpening != null ? ledgerOpening.amount : 0.0);
      final openingBal = rawOpening > 0 ? rawOpening : (ledgerOpening?.amount ?? 0.0);
      final rawOwner = m['ownerName'] as String? ?? '';
      final owner = rawOwner.isNotEmpty
          ? rawOwner
          : (isPersonal ? a.name.replaceAll(RegExp(r'Personal\s*Account', caseSensitive: false), '').trim() : '');
      final rawDate = m['openingBalanceDate'] as String? ?? '';
      final openingDate = rawDate.isNotEmpty ? rawDate : (ledgerOpening?.date ?? '');

      return BankAccount(
        id: a.id,
        name: a.name,
        type: a.type,
        accountNumber: a.accountNumber,
        bankName: a.bankName,
        balance: a.balance,
        status: a.status,
        openingBalance: openingBal,
        openingBalanceDate: openingDate,
        accountScope: isPersonal ? 'Personal' : 'Company',
        ownerName: owner,
      );
    }).toList();
  }

  @override
  Future<void> addAccount(BankAccount account) async {
    await _saveMeta(account.id, {
      'openingBalance': account.openingBalance,
      'openingBalanceDate': account.openingBalanceDate,
      'accountScope': account.accountScope,
      'ownerName': account.ownerName,
    });
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
      ),
    );
  }

  @override
  Future<void> updateAccount(BankAccount account) async {
    await addAccount(account);
  }

  @override
  Future<void> deleteAccount(String id) async {
    await _deleteMeta(id);
    await _dbService.db.deleteById(_dbService.db.bankAccountsTable, id);
  }
}

