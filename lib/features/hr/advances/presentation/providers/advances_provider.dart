import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/advance_record.dart';
import '../../domain/repositories/advances_repository.dart';
import '../../data/repositories/advances_repository_impl.dart';
import '../../../../finance/accounts/presentation/providers/accounts_provider.dart';
import '../../../../finance/ledger/presentation/providers/ledger_provider.dart';
import '../../../../finance/ledger/domain/entities/ledger_entry.dart';


class AdvancesState {
  final List<AdvanceRecord> advances;
  final bool isLoading;
  final String statusFilter;

  const AdvancesState({
    required this.advances,
    required this.isLoading,
    required this.statusFilter,
  });

  AdvancesState copyWith({
    List<AdvanceRecord>? advances,
    bool? isLoading,
    String? statusFilter,
  }) {
    return AdvancesState(
      advances: advances ?? this.advances,
      isLoading: isLoading ?? this.isLoading,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  List<AdvanceRecord> get filteredAdvances {
    if (statusFilter == 'All') return advances;
    return advances.where((adv) => adv.status == statusFilter).toList();
  }

  double get totalApprovedAmount => advances
      .where((adv) => adv.status == 'Approved' || adv.status == 'Fully Paid')
      .fold<double>(0, (sum, adv) => sum + adv.amount);

  double get remainingRepaymentAmount => advances
      .where((adv) => adv.status == 'Approved')
      .fold<double>(0, (sum, adv) => sum + adv.remainingAmount);

  int get pendingApprovalsCount => advances.where((adv) => adv.status == 'Pending').length;
}

final advancesRepositoryProvider = Provider<AdvancesRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return AdvancesRepositoryImpl(dbService);
});

class AdvancesNotifier extends Notifier<AdvancesState> {
  AdvancesRepository get _repository => ref.read(advancesRepositoryProvider);

  @override
  AdvancesState build() {
    _loadAdvances();
    return const AdvancesState(
      advances: [],
      isLoading: true,
      statusFilter: 'All',
    );
  }

  Future<void> _loadAdvances() async {
    try {
      final list = await _repository.getAdvances();
      state = state.copyWith(advances: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setStatusFilter(String filter) {
    state = state.copyWith(statusFilter: filter);
  }

  Future<void> addAdvance(AdvanceRecord record) async {
    state = state.copyWith(isLoading: true);
    await _repository.addAdvance(record);
    final updated = await _repository.getAdvances();
    state = state.copyWith(advances: updated, isLoading: false);
  }

  Future<void> approveAdvance(String id) async {
    state = state.copyWith(isLoading: true);
    final adv = state.advances.firstWhere((a) => a.id == id);
    await _repository.updateAdvance(adv.copyWith(status: 'Approved'));
    final updated = await _repository.getAdvances();
    state = state.copyWith(advances: updated, isLoading: false);
  }

  Future<void> disburseAdvance({
    required AdvanceRecord record,
    required String accountId,
    required String accountName,
  }) async {
    state = state.copyWith(isLoading: true);
    await _repository.updateAdvance(record.copyWith(status: 'Approved'));

    // Deduct selected account balance
    await ref.read(accountsProvider.notifier).adjustBalance(accountId, -record.amount);

    // Record Outflow ledger entry
    final entry = LedgerEntry(
      id: 'led_adv_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now().toIso8601String(),
      accountId: accountId,
      accountName: accountName,
      type: 'Credit',
      category: 'Salary Advance',
      amount: record.amount,
      reference: 'ADV-${record.id}',
      description: 'Salary Advance disbursed to ${record.employeeName}',
    );
    await ref.read(ledgerProvider.notifier).addLedgerEntry(entry);

    final updated = await _repository.getAdvances();
    state = state.copyWith(advances: updated, isLoading: false);
  }

  Future<void> rejectAdvance(String id) async {
    state = state.copyWith(isLoading: true);
    final adv = state.advances.firstWhere((a) => a.id == id);
    await _repository.updateAdvance(adv.copyWith(status: 'Rejected'));
    final updated = await _repository.getAdvances();
    state = state.copyWith(advances: updated, isLoading: false);
  }

  Future<void> makeRepayment(String employeeId, double repaymentValue) async {
    // Find active approved advance for this employee
    state = state.copyWith(isLoading: true);
    final activeAdvances = state.advances.where((adv) => adv.employeeId == employeeId && adv.status == 'Approved').toList();
    if (activeAdvances.isNotEmpty) {
      final active = activeAdvances.first;
      final newRepaid = active.amountRepaid + repaymentValue;
      final newStatus = newRepaid >= active.amount ? 'Fully Paid' : 'Approved';
      await _repository.updateAdvance(active.copyWith(
        amountRepaid: newRepaid >= active.amount ? active.amount : newRepaid,
        status: newStatus,
      ));
    }
    final updated = await _repository.getAdvances();
    state = state.copyWith(advances: updated, isLoading: false);
  }

  Future<void> updateAdvance(AdvanceRecord record) async {
    state = state.copyWith(isLoading: true);
    await _repository.updateAdvance(record);
    final updated = await _repository.getAdvances();
    state = state.copyWith(advances: updated, isLoading: false);
  }

  Future<void> deleteAdvance(String id) async {
    state = state.copyWith(isLoading: true);
    await _repository.deleteAdvance(id);
    final updated = await _repository.getAdvances();
    state = state.copyWith(advances: updated, isLoading: false);
  }
}

final advancesProvider = NotifierProvider<AdvancesNotifier, AdvancesState>(() {
  return AdvancesNotifier();
});
