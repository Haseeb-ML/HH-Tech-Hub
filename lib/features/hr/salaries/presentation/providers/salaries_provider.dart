import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/salary_record.dart';
import '../../domain/repositories/salaries_repository.dart';
import '../../data/repositories/salaries_repository_impl.dart';
import '../../../advances/presentation/providers/advances_provider.dart';


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

  double get totalPayoutsThisMonth => salaries
      .where((s) => s.payPeriod == 'May 2026')
      .fold<double>(0, (sum, s) => sum + s.netPaid);
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
    state = state.copyWith(isLoading: true);
    await _repository.addSalary(record);
    
    // INTEGRATION: If there is a deduction applied, check if we need to apply it as repayment for active advance
    if (record.deductions > 0) {
      await ref.read(advancesProvider.notifier).makeRepayment(record.employeeId, record.deductions);
    }

    final updated = await _repository.getSalaries();
    state = state.copyWith(salaries: updated, isLoading: false);
  }

  Future<void> updateSalary(SalaryRecord record) async {
    state = state.copyWith(isLoading: true);
    await _repository.updateSalary(record);
    final updated = await _repository.getSalaries();
    state = state.copyWith(salaries: updated, isLoading: false);
  }

  Future<void> deleteSalary(String id) async {
    state = state.copyWith(isLoading: true);
    await _repository.deleteSalary(id);
    final updated = await _repository.getSalaries();
    state = state.copyWith(salaries: updated, isLoading: false);
  }
}

final salariesProvider = NotifierProvider<SalariesNotifier, SalariesState>(() {
  return SalariesNotifier();
});
