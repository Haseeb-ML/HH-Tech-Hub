import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<String> kDefaultExpenseCategories = [
  'Electricity & Utilities',
  'Internet & Telecom',
  'Rent & Occupancy',
  'Bills',
  'Supplies',
  'Refreshments',
  'Travel & Transport',
  'Office Inventory',
  'Assets Management',
  'Marketing & Advertising',
  'Office & Admin Expenses',
  'Repairs & Maintenance',
  'Salaries & Payroll',
  'Salary Advances',
  'Depreciation',
  'Bank Charges & Fees',
  'Other',
];

class ExpenseCategoriesNotifier extends Notifier<List<String>> {
  static const _storageKey = 'custom_expense_categories_list';

  @override
  List<String> build() {
    _loadFromStorage();
    return kDefaultExpenseCategories;
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString(_storageKey);
      if (storedJson != null) {
        final List<dynamic> decoded = json.decode(storedJson);
        final list = decoded
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (list.isNotEmpty) {
          state = list;
          return;
        }
      }
    } catch (_) {}
  }

  Future<void> _saveToStorage(List<String> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json.encode(list));
    } catch (_) {}
  }

  Future<bool> addCategory(String category) async {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return false;
    final exists = state.any((c) => c.toLowerCase() == trimmed.toLowerCase());
    if (exists) return false;

    final updated = [...state, trimmed];
    state = updated;
    await _saveToStorage(updated);
    return true;
  }

  Future<bool> updateCategory(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;
    if (oldName == trimmed) return true;

    final exists = state.any(
      (c) =>
          c.toLowerCase() == trimmed.toLowerCase() &&
          c.toLowerCase() != oldName.toLowerCase(),
    );
    if (exists) return false;

    final updated = state.map((c) => c == oldName ? trimmed : c).toList();
    state = updated;
    await _saveToStorage(updated);
    return true;
  }

  Future<void> deleteCategory(String category) async {
    final updated = state.where((c) => c != category).toList();
    state = updated;
    await _saveToStorage(updated);
  }
}

final expenseCategoriesProvider =
    NotifierProvider<ExpenseCategoriesNotifier, List<String>>(() {
  return ExpenseCategoriesNotifier();
});
