import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import '../../../../finance/expenses/domain/entities/expense_record.dart';
import '../../../../finance/expenses/presentation/providers/expenses_provider.dart';
import '../../../advances/presentation/providers/advances_provider.dart';
import '../../data/repositories/salaries_repository_impl.dart';
import '../../domain/entities/salary_record.dart';
import '../../domain/repositories/salaries_repository.dart';


class SalariesState {
  final List<SalaryRecord> salaries;
  final bool isLoading;
  final String periodFilter; // e.g. 'All', 'May 2026'

  const SalariesState({
    required this.salaries,
    required this.isLoading,
    required this.periodFilter,
  });

  SalariesState copyWith({
    List<SalaryRecord>? salaries,
    bool? isLoading,
    String? periodFilter,
  }) {
    return SalariesState(
      salaries: salaries ?? this.salaries,
      isLoading: isLoading ?? this.isLoading,
      periodFilter: periodFilter ?? this.periodFilter,
    );
  }

  List<SalaryRecord> get filteredSalaries {
    if (periodFilter == 'All') return salaries;
    return salaries.where((s) => s.payPeriod == periodFilter).toList();
  }

  double get totalPayoutsThisMonth {
    if (salaries.isEmpty) return 0.0;
    final latestPeriod = salaries.first.payPeriod;
    return salaries
        .where((s) => s.payPeriod == latestPeriod)
        .fold<double>(0, (sum, s) => sum + s.netPaid);
  }
}

final salariesRepositoryProvider = Provider<SalariesRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return SalariesRepositoryImpl(dbService);
});

class SalariesNotifier extends Notifier<SalariesState> {
  SalariesRepository get _repository => ref.read(salariesRepositoryProvider);

  @override
  SalariesState build() {
    _loadSalaries();
    return const SalariesState(
      salaries: [],
      isLoading: true,
      periodFilter: 'All',
    );
  }

  Future<void> _loadSalaries() async {
    try {
      final list = await _repository.getSalaries();
      state = state.copyWith(salaries: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setPeriodFilter(String filter) {
    state = state.copyWith(periodFilter: filter);
  }

  Future<void> addSalary(SalaryRecord record) async {
    final canCreate = ref.read(adminProvider).hasPermission(AppModule.payroll, PermissionAction.create);
    if (!canCreate) {
      throw Exception('Access Denied: You do not have permission to process or create payroll records.');
    }

    state = state.copyWith(isLoading: true);
    await _repository.addSalary(record);
    
    // INTEGRATION: If there is a deduction applied, check if we need to apply it as repayment for active advance
    if (record.deductions > 0) {
      await ref.read(advancesProvider.notifier).makeRepayment(record.employeeId, record.deductions);
    }

    // INTEGRATION: Record Salary Payment in Accounts, Expenses & General Ledger
    if (record.accountId.isNotEmpty && record.netPaid > 0) {
      final expenseRecord = ExpenseRecord(
        id: 'exp_sal_${record.id}',
        date: record.paymentDate,
        category: 'Salaries & Payroll',
        amount: record.netPaid,
        description: 'Salary Payment for ${record.employeeName} (${record.payPeriod})',
        vendorName: record.employeeName,
        accountId: record.accountId,
        isPersonalExpense: false,
      );
      await ref.read(expensesProvider.notifier).addExpense(expenseRecord);
    }

    final updated = await _repository.getSalaries();
    ref.read(adminProvider.notifier).logAction(
      action: 'Processed payroll for ${record.employeeName} (Net: ${record.netPaid}, Period: ${record.payPeriod})',
      module: 'Payroll',
    );
    state = state.copyWith(salaries: updated, isLoading: false);
  }

  Future<void> updateSalary(SalaryRecord record) async {
    final canEdit = ref.read(adminProvider).hasPermission(AppModule.payroll, PermissionAction.edit);
    if (!canEdit) {
      throw Exception('Access Denied: You do not have permission to update payroll records.');
    }

    state = state.copyWith(isLoading: true);
    await _repository.updateSalary(record);
    ref.read(adminProvider.notifier).logAction(
      action: 'Updated payroll record for ${record.employeeName}',
      module: 'Payroll',
    );
    final updated = await _repository.getSalaries();
    state = state.copyWith(salaries: updated, isLoading: false);
  }

  Future<void> deleteSalary(String id) async {
    final canDelete = ref.read(adminProvider).hasPermission(AppModule.payroll, PermissionAction.delete);
    if (!canDelete) {
      throw Exception('Access Denied: You do not have permission to delete payroll records.');
    }

    final list = List<SalaryRecord>.from(state.salaries);
    final record = list.where((s) => s.id == id).firstOrNull;

    state = state.copyWith(isLoading: true);

    if (record != null && record.accountId.isNotEmpty) {
      await ref.read(expensesProvider.notifier).deleteExpense('exp_sal_${record.id}');
    }

    await _repository.deleteSalary(id);
    ref.read(adminProvider.notifier).logAction(
      action: 'Deleted payroll record for ${record?.employeeName ?? id}',
      module: 'Payroll',
    );
    final updated = await _repository.getSalaries();
    state = state.copyWith(salaries: updated, isLoading: false);
  }
}

final salariesProvider = NotifierProvider<SalariesNotifier, SalariesState>(() {
  return SalariesNotifier();
});
