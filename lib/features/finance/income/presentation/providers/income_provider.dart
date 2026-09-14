import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/income_record.dart';
import '../../domain/repositories/income_repository.dart';
import '../../data/repositories/income_repository_impl.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../ledger/domain/entities/ledger_entry.dart';
import '../../../../projects/projects/presentation/providers/projects_provider.dart';
import '../../../../projects/projects/domain/entities/project.dart';


class IncomeState {
  final List<IncomeRecord> incomes;
  final bool isLoading;
  final String searchQuery;
  final String clientFilter; // 'All' or clientId

  const IncomeState({
    required this.incomes,
    required this.isLoading,
    required this.searchQuery,
    required this.clientFilter,
  });

  IncomeState copyWith({
    List<IncomeRecord>? incomes,
    bool? isLoading,
    String? searchQuery,
    String? clientFilter,
  }) {
    return IncomeState(
      incomes: incomes ?? this.incomes,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      clientFilter: clientFilter ?? this.clientFilter,
    );
  }

  List<IncomeRecord> get filteredIncomes {
    final list = List<IncomeRecord>.from(incomes);
    list.sort((a, b) {
      final dateCmp = b.date.compareTo(a.date);
      if (dateCmp != 0) return dateCmp;
      final aStr = a.id.replaceAll(RegExp(r'[^0-9]'), '');
      final bStr = b.id.replaceAll(RegExp(r'[^0-9]'), '');
      final aNum = BigInt.tryParse(aStr) ?? BigInt.zero;
      final bNum = BigInt.tryParse(bStr) ?? BigInt.zero;
      return bNum.compareTo(aNum);
    });

    return list.where((i) {
      final matchesSearch = i.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          i.clientName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          i.invoiceNumber.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesClient = clientFilter == 'All' || i.clientId == clientFilter;

      return matchesSearch && matchesClient;
    }).toList();
  }
}

final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return IncomeRepositoryImpl(dbService);
});

class IncomeNotifier extends Notifier<IncomeState> {
  IncomeRepository get _repository => ref.read(incomeRepositoryProvider);

  @override
  IncomeState build() {
    _loadIncomes();
    return const IncomeState(
      incomes: [],
      isLoading: true,
      searchQuery: '',
      clientFilter: 'All',
    );
  }

  Future<void> _loadIncomes() async {
    try {
      final list = await _repository.getIncomes();
      state = state.copyWith(incomes: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setClientFilter(String filter) {
    state = state.copyWith(clientFilter: filter);
  }

  Future<void> addIncome(IncomeRecord record) async {
    state = state.copyWith(isLoading: true);
    await _repository.addIncome(record);

    // Resolve Account Name
    final accounts = ref.read(accountsProvider).accounts;
    final account = accounts.where((a) => a.id == record.accountId).firstOrNull;
    final accountName = account?.name ?? 'Unknown Account';

    // 1. Adjust bank account balance (Add income amount)
    await ref.read(accountsProvider.notifier).adjustBalance(record.accountId, record.amount);

    // 2. Adjust project payment fields if selected
    if (record.projectId != null) {
      final projectsState = ref.read(projectsProvider);
      final project = projectsState.projects.where((p) => p.id == record.projectId).firstOrNull;
      if (project != null) {
        Project updatedProject = project;
        if (record.projectPaymentType == 'Advance') {
          final newAdv = project.advancedPayment + record.amount;
          final newTotal = newAdv + project.partialPayments + project.finalPayment;
          final newStatus = newTotal >= project.budget ? 'Fully Paid' : (newTotal > 0 ? 'Partially Paid' : 'Pending');
          updatedProject = project.copyWith(advancedPayment: newAdv, paymentStatus: newStatus);
        } else if (record.projectPaymentType == 'Partial') {
          final newPart = project.partialPayments + record.amount;
          final newTotal = project.advancedPayment + newPart + project.finalPayment;
          final newStatus = newTotal >= project.budget ? 'Fully Paid' : 'Partially Paid';
          updatedProject = project.copyWith(partialPayments: newPart, paymentStatus: newStatus);
        } else if (record.projectPaymentType == 'Final' || record.projectPaymentType == 'Full') {
          final newFin = project.finalPayment + record.amount;
          final newTotal = project.advancedPayment + project.partialPayments + newFin;
          final newStatus = newTotal >= project.budget ? 'Fully Paid' : 'Partially Paid';
          updatedProject = project.copyWith(finalPayment: newFin, paymentStatus: newStatus);
        } else {
          final newAdv = project.advancedPayment + record.amount;
          final newTotal = newAdv + project.partialPayments + project.finalPayment;
          final newStatus = newTotal >= project.budget ? 'Fully Paid' : (newTotal > 0 ? 'Partially Paid' : 'Pending');
          updatedProject = project.copyWith(advancedPayment: newAdv, paymentStatus: newStatus);
        }
        await ref.read(projectsProvider.notifier).updateProject(updatedProject);
      }
    }

    String isoDate = record.date;
    final idNumStr = record.id.replaceAll(RegExp(r'[^0-9]'), '');
    if (idNumStr.length > 10) {
      final ms = int.tryParse(idNumStr);
      if (ms != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(ms);
        if (isoDate.length == 10) {
          isoDate += dt.toIso8601String().substring(10);
        } else if (isoDate.endsWith('T00:00:00.000') || isoDate.endsWith('T00:00:00') || isoDate.endsWith(':00.000')) {
          final p = DateTime.tryParse(isoDate);
          if (p != null && p.second == 0 && p.millisecond == 0) {
            isoDate = DateTime(p.year, p.month, p.day, p.hour, p.minute, dt.second, dt.millisecond).toIso8601String();
          }
        }
      }
    }

    // 3. Add General Ledger entry (Debit / Inflow)
    String paymentTypeText = 'Advance Payment';
    if (record.projectPaymentType == 'Partial') {
      paymentTypeText = 'Partial Payment';
    } else if (record.projectPaymentType == 'Final' || record.projectPaymentType == 'Full') {
      paymentTypeText = 'Full Payment';
    }

    // For project payments, resolve proper description
    String ledgerDesc = record.description;
    if (record.projectId != null && record.projectName != null) {
      ledgerDesc = '${record.projectName} - ${record.clientName}';
    }

    String ledgerRef = record.invoiceNumber.isNotEmpty 
        ? record.invoiceNumber 
        : (record.projectId != null ? paymentTypeText : record.clientName);

    final ledgerEntry = LedgerEntry(
      id: 'led_inc_${record.id}',
      date: isoDate,
      accountId: record.accountId,
      accountName: accountName,
      type: 'Debit',
      category: 'Client Income',
      amount: record.amount,
      reference: ledgerRef,
      description: ledgerDesc,
    );
    await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);

    final updated = await _repository.getIncomes();
    state = state.copyWith(incomes: updated, isLoading: false);
  }

  Future<void> deleteIncome(String id) async {
    final list = List<IncomeRecord>.from(state.incomes);
    final recordIndex = list.indexWhere((i) => i.id == id);
    if (recordIndex == -1) return;

    final record = list[recordIndex];
    state = state.copyWith(isLoading: true);

    // 1. Rollback bank account balance (Deduct income amount)
    await ref.read(accountsProvider.notifier).adjustBalance(record.accountId, -record.amount);

    // 2. Rollback project payment fields if selected
    if (record.projectId != null) {
      final projectsState = ref.read(projectsProvider);
      final project = projectsState.projects.where((p) => p.id == record.projectId).firstOrNull;
      if (project != null) {
        Project updatedProject = project;
        if (record.projectPaymentType == 'Advance') {
          updatedProject = project.copyWith(advancedPayment: project.advancedPayment - record.amount);
        } else if (record.projectPaymentType == 'Partial') {
          updatedProject = project.copyWith(partialPayments: project.partialPayments - record.amount);
        } else if (record.projectPaymentType == 'Final') {
          updatedProject = project.copyWith(finalPayment: project.finalPayment - record.amount);
        } else {
          updatedProject = project.copyWith(advancedPayment: project.advancedPayment - record.amount);
        }
        await ref.read(projectsProvider.notifier).updateProject(updatedProject);
      }
    }

    // 3. Remove General Ledger entry
    await ref.read(ledgerProvider.notifier).deleteLedgerEntry('led_inc_${record.id}');

    // 4. Delete income record
    await _repository.deleteIncome(id);

    final updated = await _repository.getIncomes();
    state = state.copyWith(incomes: updated, isLoading: false);
  }
}

final incomeProvider = NotifierProvider<IncomeNotifier, IncomeState>(() {
  return IncomeNotifier();
});
