import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'employees_provider.dart';

const List<String> kDefaultDepartments = [
  'Mobile Apps',
  'Design',
  'Quality Assurance',
  'Management',
  'Web Development',
];

const String _kDepartmentsPrefKey = 'erp_hr_departments';

class DepartmentsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    _loadDepartments();
    ref.listen(employeesProvider, (previous, next) {
      syncFromEmployees();
    });
    return kDefaultDepartments;
  }

  Future<void> _loadDepartments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_kDepartmentsPrefKey);
      final List<String> loaded = [];

      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(savedJson);
        for (final item in decoded) {
          final str = item.toString().trim();
          if (str.isNotEmpty && !loaded.any((d) => d.toLowerCase() == str.toLowerCase())) {
            loaded.add(str);
          }
        }
      }

      // Ensure defaults are present
      for (final def in kDefaultDepartments) {
        if (!loaded.any((d) => d.toLowerCase() == def.toLowerCase())) {
          loaded.add(def);
        }
      }

      // Auto-merge any department already assigned to existing employees in DB
      final employees = ref.read(employeesProvider).employees;
      for (final emp in employees) {
        final dept = emp.department.trim();
        if (dept.isNotEmpty && !loaded.any((d) => d.toLowerCase() == dept.toLowerCase())) {
          loaded.add(dept);
        }
      }

      state = loaded;
      await _save(loaded);
    } catch (_) {
      state = kDefaultDepartments;
    }
  }

  Future<void> _save(List<String> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDepartmentsPrefKey, jsonEncode(list));
    } catch (_) {}
  }

  /// Adds a department if not already present (case-insensitive check).
  /// Returns the canonical name (existing or newly added).
  Future<String> addDepartment(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';

    final existing = state.firstWhere(
      (d) => d.toLowerCase() == trimmed.toLowerCase(),
      orElse: () => '',
    );

    if (existing.isNotEmpty) {
      return existing;
    }

    final updated = [...state, trimmed];
    state = updated;
    await _save(updated);
    return trimmed;
  }

  Future<void> deleteDepartment(String name) async {
    final trimmed = name.trim();
    final updated = state.where((d) => d.toLowerCase() != trimmed.toLowerCase()).toList();
    state = updated;
    await _save(updated);
  }

  /// Syncs departments against current employee list in case an employee was just loaded/created
  Future<void> syncFromEmployees() async {
    final employees = ref.read(employeesProvider).employees;
    bool hasNew = false;
    final List<String> current = List.from(state);

    for (final emp in employees) {
      final dept = emp.department.trim();
      if (dept.isNotEmpty && !current.any((d) => d.toLowerCase() == dept.toLowerCase())) {
        current.add(dept);
        hasNew = true;
      }
    }

    if (hasNew) {
      state = current;
      await _save(current);
    }
  }
}

final departmentsProvider = NotifierProvider<DepartmentsNotifier, List<String>>(() {
  return DepartmentsNotifier();
});
