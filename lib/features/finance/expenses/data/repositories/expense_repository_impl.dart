import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/expense_record.dart';
import '../../domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final DriftDatabaseService _dbService;
  static const String _metaKey = 'expense_records_metadata_v1';

  ExpenseRepositoryImpl(this._dbService);

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

  Future<void> _saveMeta(String expenseId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await _getMetaMap();
      current[expenseId] = data;
      await prefs.setString(_metaKey, jsonEncode(current));
    } catch (_) {}
  }

  Future<void> _deleteMeta(String expenseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await _getMetaMap();
      if (current.containsKey(expenseId)) {
        current.remove(expenseId);
        await prefs.setString(_metaKey, jsonEncode(current));
      }
    } catch (_) {}
  }

  @override
  Future<List<ExpenseRecord>> getExpenses() async {
    final list = await _dbService.db.getAll(_dbService.db.expenseRecordsTable);
    final meta = await _getMetaMap();
    return list.map((e) {
      final m = (meta[e.id] as Map<String, dynamic>?) ?? {};
      return ExpenseRecord(
        id: e.id,
        date: e.date,
        amount: e.amount,
        accountId: e.accountId,
        category: e.category,
        vendorName: e.vendorName,
        description: e.description,
        isPersonalExpense: (m['isPersonalExpense'] as bool?) ?? false,
      );
    }).toList();
  }

  @override
  Future<void> addExpense(ExpenseRecord expense) async {
    await _saveMeta(expense.id, {
      'isPersonalExpense': expense.isPersonalExpense,
    });
    await _dbService.db.upsert(
      _dbService.db.expenseRecordsTable,
      ExpenseRecordsTableCompanion.insert(
        id: expense.id,
        date: expense.date,
        amount: expense.amount,
        accountId: expense.accountId,
        category: expense.category,
        vendorName: expense.vendorName,
        description: expense.description,
      ),
    );
  }

  @override
  Future<void> updateExpense(ExpenseRecord expense) async {
    await addExpense(expense);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _deleteMeta(id);
    await _dbService.db.deleteById(_dbService.db.expenseRecordsTable, id);
  }
}

