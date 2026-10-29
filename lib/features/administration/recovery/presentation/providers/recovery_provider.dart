import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:software_house_erp/features/administration/recovery/data/models/recycle_bin_item.dart';
import '../../../../hr/employees/domain/entities/employee.dart';
import '../../../../hr/employees/presentation/providers/employees_provider.dart';
import '../../../../clients/clients/domain/entities/client.dart';
import '../../../../clients/clients/presentation/providers/clients_provider.dart';
import '../../../../finance/expenses/domain/entities/expense_record.dart';
import '../../../../finance/expenses/presentation/providers/expenses_provider.dart';
import '../../../../finance/income/domain/entities/income_record.dart';
import '../../../../finance/income/presentation/providers/income_provider.dart';
import '../../../../projects/projects/domain/entities/project.dart';
import '../../../../projects/projects/presentation/providers/projects_provider.dart';
import '../../../../projects/tasks/domain/entities/project_task.dart';
import '../../../../projects/tasks/presentation/providers/tasks_provider.dart';
import '../../../../sales/sales/domain/entities/product.dart';
import '../../../../sales/sales/presentation/providers/products_provider.dart';
import '../../../../sales/sales/domain/entities/sales_invoice.dart';
import '../../../../sales/sales/presentation/providers/sales_invoices_provider.dart';
import '../../../../inventory/assets/domain/entities/asset.dart';
import '../../../../inventory/assets/presentation/providers/assets_provider.dart';
import '../../../../finance/loans/domain/entities/loan_record.dart';
import '../../../../finance/loans/presentation/providers/loans_provider.dart';
import '../../../../finance/ledger/domain/entities/ledger_entry.dart';
import '../../../../finance/ledger/presentation/providers/ledger_provider.dart';
import '../../../../finance/accounts/domain/entities/bank_account.dart';
import '../../../../finance/accounts/presentation/providers/accounts_provider.dart';
import 'package:software_house_erp/core/auth/data/auth_local_repository.dart';
import 'package:software_house_erp/core/services/database_service.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class RecoveryNotifier extends Notifier<List<RecycleBinItem>> {

  @override
  List<RecycleBinItem> build() {
    _loadItems();
    return [];
  }

  Future<void> _loadItems() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final records = await db.select(db.recycleBinTable).get();
      final items = records.map((r) => RecycleBinItem(
        id: r.id,
        itemType: r.itemType,
        title: r.title,
        subtitle: r.subtitle,
        deletedAt: r.deletedAt,
        deletedBy: r.deletedBy,
        jsonData: r.jsonData,
      )).toList();

      items.sort((a, b) {
        final dtA = DateTime.tryParse(a.deletedAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dtB = DateTime.tryParse(b.deletedAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dtB.compareTo(dtA);
      });

      state = items;
    } catch (e) {
      debugPrint('Error loading recycle bin items from DB: $e');
    }
  }

  Future<void> _saveItems() async {
    // Database insert/delete is handled synchronously in the individual methods.
  }

  String _getModuleForItemType(String itemType) {
    switch (itemType) {
      case 'Account':
      case 'Expense':
      case 'Income':
      case 'Ledger':
      case 'LedgerEntry':
      case 'Loan':
        return 'Finance';
      case 'Employee':
      case 'Salary':
      case 'Advance':
      case 'Attendance':
        return 'HR Management';
      case 'Client':
        return 'Client Management';
      case 'Project':
      case 'Task':
      case 'Timesheet':
        return 'Project Management';
      case 'Inventory':
      case 'Asset':
      case 'Office Inventory':
        return 'Inventory & Assets';
      case 'Invoice':
      case 'Product':
      case 'Purchase Order':
        return 'Sales & Purchases';
      default:
        return 'Administration';
    }
  }

  Future<void> addDeletedItem({
    required String id,
    required String itemType,
    required String title,
    required String subtitle,
    required Map<String, dynamic> jsonData,
    String deletedBy = 'Admin',
  }) async {
    final item = RecycleBinItem(
      id: id,
      itemType: itemType,
      title: title,
      subtitle: subtitle,
      deletedAt: DateTime.now().toIso8601String(),
      deletedBy: deletedBy,
      jsonData: jsonData,
    );

    try {
      final db = ref.read(appDatabaseProvider);
      await db.into(db.recycleBinTable).insert(RecycleBinTableCompanion.insert(
        id: id,
        itemType: itemType,
        title: title,
        subtitle: subtitle,
        deletedAt: item.deletedAt,
        deletedBy: deletedBy,
        jsonData: jsonData,
      ));
    } catch (e) {
      debugPrint('Error inserting recycle bin item into DB: $e');
    }

    // Automatically log audit trail entry for ANY deletion
    try {
      final adminState = ref.read(adminProvider);
      final currentUser = adminState.currentUser;
      String actor = deletedBy;
      if (currentUser != null && currentUser.name.isNotEmpty) {
        final name = currentUser.name.trim();
        final role = currentUser.role.trim();
        if (role.isNotEmpty && role.toLowerCase() != name.toLowerCase()) {
          actor = '$name ($role)';
        } else {
          actor = name;
        }
      }
      ref.read(adminProvider.notifier).logAction(
        user: actor,
        action: 'Deleted $itemType Record: "$title"',
        module: _getModuleForItemType(itemType),
      );
    } catch (e) {
      debugPrint('Error logging audit log for deletion: $e');
    }

    final currentList = state;
    final filtered = currentList.where((e) => !(e.id == id && e.itemType == itemType)).toList();
    state = [item, ...filtered];
  }

  Future<bool> restoreItem(RecycleBinItem item) async {
    try {
      final data = item.jsonData;
      switch (item.itemType) {
        case 'Account':
          final account = BankAccount.fromMap(data);
          await ref.read(accountsRepositoryProvider).addAccount(account);
          ref.invalidate(accountsProvider);
          break;
        case 'Employee':
          final emp = Employee.fromMap(data).copyWith(status: 'Active');
          await ref.read(employeesRepositoryProvider).addEmployee(emp);
          ref.invalidate(employeesProvider);
          break;
        case 'Client':
          final client = Client.fromMap(data);
          await ref.read(clientsRepositoryProvider).addClient(client);
          ref.invalidate(clientsProvider);
          break;
        case 'Expense':
          final expense = ExpenseRecord.fromMap(data);
          await ref.read(expenseRepositoryProvider).addExpense(expense);
          ref.invalidate(expensesProvider);
          break;
        case 'Income':
          final income = IncomeRecord.fromMap(data);
          await ref.read(incomeRepositoryProvider).addIncome(income);
          ref.invalidate(incomeProvider);
          break;
        case 'Project':
          final proj = Project.fromMap(data);
          await ref.read(projectsRepositoryProvider).addProject(proj);
          ref.invalidate(projectsProvider);
          break;
        case 'Task':
          final task = ProjectTask.fromMap(data);
          await ref.read(tasksRepositoryProvider).addTask(task);
          ref.invalidate(tasksProvider);
          break;
        case 'Product':
          final prod = Product.fromMap(data);
          await ref.read(productsRepositoryProvider).addProduct(prod);
          ref.invalidate(productsProvider);
          break;
        case 'Invoice':
          final inv = SalesInvoice.fromMap(data);
          await ref.read(salesInvoicesRepositoryProvider).addInvoice(inv);
          ref.invalidate(salesInvoicesProvider);
          break;
        case 'Asset':
          final asset = Asset.fromMap(data);
          await ref.read(assetsRepositoryProvider).addAsset(asset);
          ref.invalidate(assetsProvider);
          break;
        case 'Loan':
          final loan = LoanRecord.fromMap(data);
          await ref.read(loansRepositoryProvider).addLoan(loan);
          ref.invalidate(loansProvider);
          break;
        case 'LedgerEntry':
          final entry = LedgerEntry.fromMap(data);
          await ref.read(ledgerRepositoryProvider).addLedgerEntry(entry);
          ref.invalidate(ledgerProvider);
          break;
        case 'Audit Log':
          final log = AuditLog.fromMap(data);
          await ref.read(authLocalRepositoryProvider).saveAuditLog(
            id: log.id,
            timestamp: log.timestamp,
            user: log.user,
            action: log.action,
            module: log.module,
            ipAddress: log.ipAddress,
          );
          await ref.read(adminProvider.notifier).reloadData();
          break;
      }

      final db = ref.read(appDatabaseProvider);
      await (db.delete(db.recycleBinTable)..where((tbl) => tbl.id.equals(item.id))).go();

      ref.read(adminProvider.notifier).logAction(
        action: 'Restored ${item.itemType} Record: "${item.title}"',
        module: _getModuleForItemType(item.itemType),
      );

      state = state.where((e) => !(e.id == item.id && e.itemType == item.itemType)).toList();
      return true;
    } catch (e) {
      debugPrint('Error restoring item: $e');
      return false;
    }
  }

  Future<void> permanentlyDeleteItem(RecycleBinItem item) async {
    final db = ref.read(appDatabaseProvider);
    await (db.delete(db.recycleBinTable)..where((tbl) => tbl.id.equals(item.id))).go();

    ref.read(adminProvider.notifier).logAction(
      action: 'Permanently Deleted ${item.itemType} Record: "${item.title}"',
      module: _getModuleForItemType(item.itemType),
    );

    state = state.where((e) => !(e.id == item.id && e.itemType == item.itemType)).toList();
  }

  Future<void> clearAll() async {
    final db = ref.read(appDatabaseProvider);
    await db.delete(db.recycleBinTable).go();

    ref.read(adminProvider.notifier).logAction(
      action: 'Cleared All Items from Data Recovery Recycle Bin',
      module: 'Administration',
    );

    state = [];
  }
}

final recoveryProvider = NotifierProvider<RecoveryNotifier, List<RecycleBinItem>>(RecoveryNotifier.new);
