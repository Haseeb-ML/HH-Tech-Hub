import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/bank_account.dart';
import '../../domain/repositories/accounts_repository.dart';

class AccountsRepositoryImpl implements AccountsRepository {
  final DriftDatabaseService _dbService;
  static const String _metaKey = 'bank_accounts_metadata_v1';

  AccountsRepositoryImpl(this._dbService);

  Future<Map<String, dynamic>> _getMetaMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_metaKey);
      if (str != null) {
        final decoded = jsonDecode(str);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (_) {}
    return {};
  }

  Future<void> _saveMeta(String accountId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await _getMetaMap();
      current[accountId] = data;
      await prefs.setString(_metaKey, jsonEncode(current));
    } catch (_) {}
  }

  Future<void> _deleteMeta(String accountId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await _getMetaMap();
      if (current.containsKey(accountId)) {
        current.remove(accountId);
        await prefs.setString(_metaKey, jsonEncode(current));
      }
    } catch (_) {}
  }

  @override
  Future<List<BankAccount>> getAccounts() async {
    final list = await _dbService.db.getAll(_dbService.db.bankAccountsTable);
    final meta = await _getMetaMap();
    return list.map((a) {
      final m = (meta[a.id] as Map<String, dynamic>?) ?? {};
      return BankAccount(
        id: a.id,
        name: a.name,
        type: a.type,
        accountNumber: a.accountNumber,
        bankName: a.bankName,
        balance: a.balance,
        status: a.status,
        openingBalance: (m['openingBalance'] as num?)?.toDouble() ?? 0.0,
        openingBalanceDate: m['openingBalanceDate'] as String? ?? '',
        accountScope: m['accountScope'] as String? ?? 'Company',
        ownerName: m['ownerName'] as String? ?? '',
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

