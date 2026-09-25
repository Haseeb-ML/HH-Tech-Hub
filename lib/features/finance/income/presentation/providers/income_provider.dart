import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/income_record.dart';
import '../../domain/repositories/income_repository.dart';
import '../../data/repositories/income_repository_impl.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../ledger/domain/entities/ledger_entry.dart';
import '../../../../projects/projects/presentation/providers/projects_provider.dart';
import '../../../../clients/clients/presentation/providers/clients_provider.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class IncomeState {
  final List<IncomeRecord> incomes;
  final bool isLoading;
  final String searchQuery;
  final String clientFilter; // 'All' or clientId
  final String accountIdFilter; // 'All' or accountId
  final String statusFilter; // 'All', 'Received', 'Pending'
  final String? fromDateFilter; // YYYY-MM-DD
  final String? toDateFilter; // YYYY-MM-DD

  const IncomeState({
    required this.incomes,
    required this.isLoading,
    required this.searchQuery,
    required this.clientFilter,
    this.accountIdFilter = 'All',
    this.statusFilter = 'All',
    this.fromDateFilter,
    this.toDateFilter,
  });

  IncomeState copyWith({
    List<IncomeRecord>? incomes,
    bool? isLoading,
    String? searchQuery,
    String? clientFilter,
    String? accountIdFilter,
    String? statusFilter,
    String? fromDateFilter,
    String? toDateFilter,
    bool clearDates = false,
  }) {
    return IncomeState(
      incomes: incomes ?? this.incomes,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      clientFilter: clientFilter ?? this.clientFilter,
      accountIdFilter: accountIdFilter ?? this.accountIdFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      fromDateFilter: clearDates ? null : (fromDateFilter ?? this.fromDateFilter),
      toDateFilter: clearDates ? null : (toDateFilter ?? this.toDateFilter),
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
      final q = searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          i.description.toLowerCase().contains(q) ||
          i.clientName.toLowerCase().contains(q) ||
          i.invoiceNumber.toLowerCase().contains(q) ||
          i.id.toLowerCase().contains(q);

      final matchesClient = clientFilter == 'All' || i.clientId == clientFilter;
      final matchesAccount = accountIdFilter == 'All' || i.accountId == accountIdFilter;
      final matchesStatus = statusFilter == 'All' || i.status.toLowerCase() == statusFilter.toLowerCase();

      bool matchesDate = true;
      if (fromDateFilter != null && fromDateFilter!.isNotEmpty) {
        final recordDate = i.date.length >= 10 ? i.date.substring(0, 10) : i.date;
        if (recordDate.compareTo(fromDateFilter!) < 0) {
          matchesDate = false;
        }
      }
      if (toDateFilter != null && toDateFilter!.isNotEmpty) {
        final recordDate = i.date.length >= 10 ? i.date.substring(0, 10) : i.date;
        if (recordDate.compareTo(toDateFilter!) > 0) {
          matchesDate = false;
        }
      }

      return matchesSearch && matchesClient && matchesAccount && matchesStatus && matchesDate;
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
      accountIdFilter: 'All',
      statusFilter: 'All',
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

  void setAccountIdFilter(String id) {
    state = state.copyWith(accountIdFilter: id);
  }

  void setStatusFilter(String status) {
    state = state.copyWith(statusFilter: status);
  }

  void setDateRange(String? from, String? to) {
    state = state.copyWith(
      fromDateFilter: from,
      toDateFilter: to,
    );
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      clientFilter: 'All',
      accountIdFilter: 'All',
      statusFilter: 'All',
      clearDates: true,
    );
  }

  Future<void> addIncome(IncomeRecord record) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.income, PermissionAction.create)) {
      throw Exception('Access Denied: You do not have permission to create income records.');
    }

    record = record.copyWith(amount: record.amount.abs());
    state = state.copyWith(isLoading: true);
    await _repository.addIncome(record);

    // Resolve Account Name
    final accounts = ref.read(accountsProvider).accounts;
    final account = accounts.where((a) => a.id == record.accountId).firstOrNull;
    final accountName = account?.name ?? 'Unknown Account';

    // 1. Adjust bank account balance (Add income amount)
    await ref.read(accountsProvider.notifier).adjustBalance(record.accountId, record.amount);

    // 2. Adjust project payment fields if selected
    if (record.projectId != null && record.projectId!.isNotEmpty) {
      final projectsState = ref.read(projectsProvider);
      final project = projectsState.projects.where((p) => p.id == record.projectId).firstOrNull;
      if (project != null) {
        double adv = project.advancedPayment;
        double part = project.partialPayments;
        double fin = project.finalPayment;

        if (record.projectPaymentType == 'Advance') {
          adv += record.amount;
        } else if (record.projectPaymentType == 'Final' || record.projectPaymentType == 'Full') {
          fin += record.amount;
        } else {
          part += record.amount;
        }

        final totalRecv = adv + part + fin;
        final newStatus = totalRecv >= project.budget ? 'Fully Paid' : (totalRecv > 0 ? 'Partially Paid' : 'Pending');
        final updatedProject = project.copyWith(
          advancedPayment: adv,
          partialPayments: part,
          finalPayment: fin,
          paymentStatus: newStatus,
        );
        await ref.read(projectsProvider.notifier).updateProject(updatedProject);
      }
    }

    // 3. Adjust client payment
    if (record.clientId.isNotEmpty) {
      final clientsState = ref.read(clientsProvider);
      final client = clientsState.clients.where((c) => c.id == record.clientId).firstOrNull;
      if (client != null) {
        final newAdv = client.advancedPayment + record.amount;
        await ref.read(clientsProvider.notifier).updateClient(client.copyWith(advancedPayment: newAdv));
      }
    }

    String isoDate = record.date;
    try {
      final match = RegExp(r'\d{12,14}').firstMatch(record.id);
      if (match != null) {
        final ms = int.tryParse(match.group(0)!);
        if (ms != null && ms > 0 && ms < 8640000000000000) {
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
    } catch (_) {}

    // 4. Add General Ledger entry (Debit / Inflow)
    String paymentTypeText = record.projectPaymentType ?? 'Payment';
    if (record.projectPaymentType == 'Advance') {
      paymentTypeText = 'Advance Payment';
    } else if (record.projectPaymentType == 'Partial') {
      paymentTypeText = 'Partial Payment';
    } else if (record.projectPaymentType == 'Final' || record.projectPaymentType == 'Full') {
      paymentTypeText = 'Full Payment';
    }

    // For project payments, resolve proper description
    String ledgerDesc = record.description;
    if (record.projectId != null && record.projectName != null && record.projectName!.isNotEmpty) {
      ledgerDesc = '${record.projectName} - ${record.clientName}';
    }

    String ledgerRef = record.invoiceNumber.isNotEmpty 
        ? record.invoiceNumber 
        : (record.projectId != null && record.projectId!.isNotEmpty ? record.projectId! : '—');

    final ledgerEntry = LedgerEntry(
      id: 'led_inc_${record.id}',
      date: isoDate,
      accountId: record.accountId,
      accountName: accountName,
      type: 'Debit',
      category: record.projectId != null && record.projectId!.isNotEmpty ? 'Project Payment' : record.incomeType,
      amount: record.amount,
      reference: ledgerRef,
      description: ledgerDesc,
      installmentType: paymentTypeText,
    );
    await ref.read(ledgerProvider.notifier).addLedgerEntry(ledgerEntry);

    ref.read(adminProvider.notifier).logAction(
      action: 'Added income record: ${record.description} (Amount: ${record.amount}, Client: ${record.clientName})',
      module: 'Finance',
    );

    final updated = await _repository.getIncomes();
    state = state.copyWith(incomes: updated, isLoading: false);
    await ref.read(accountsProvider.notifier).syncBalancesFromDb();
  }

  Future<void> updateIncome(IncomeRecord oldRecord, IncomeRecord newRecord) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.income, PermissionAction.edit)) {
      throw Exception('Access Denied: You do not have permission to edit income records.');
    }

    oldRecord = oldRecord.copyWith(amount: oldRecord.amount.abs());
    newRecord = newRecord.copyWith(amount: newRecord.amount.abs());
    state = state.copyWith(isLoading: true);
    await _repository.updateIncome(newRecord);

    // 1. Bank Account balance adjustment
    if (oldRecord.accountId == newRecord.accountId) {
      final diff = newRecord.amount - oldRecord.amount;
      if (diff != 0) {
        await ref.read(accountsProvider.notifier).adjustBalance(newRecord.accountId, diff);
      }
    } else {
      await ref.read(accountsProvider.notifier).adjustBalance(oldRecord.accountId, -oldRecord.amount);
      await ref.read(accountsProvider.notifier).adjustBalance(newRecord.accountId, newRecord.amount);
    }

    // 2. Project payments rollback from old & apply to new
    if (oldRecord.projectId != null && oldRecord.projectId!.isNotEmpty) {
      final oldProj = ref.read(projectsProvider).projects.where((p) => p.id == oldRecord.projectId).firstOrNull;
      if (oldProj != null) {
        double adv = oldProj.advancedPayment;
        double part = oldProj.partialPayments;
        double fin = oldProj.finalPayment;
        if (oldRecord.projectPaymentType == 'Advance') {
          adv = (adv - oldRecord.amount).clamp(0.0, double.infinity);
        } else if (oldRecord.projectPaymentType == 'Final' || oldRecord.projectPaymentType == 'Full') {
          fin = (fin - oldRecord.amount).clamp(0.0, double.infinity);
        } else {
          part = (part - oldRecord.amount).clamp(0.0, double.infinity);
        }
        final totalRecv = adv + part + fin;
        final newStatus = totalRecv >= oldProj.budget ? 'Fully Paid' : (totalRecv > 0 ? 'Partially Paid' : 'Pending');
        await ref.read(projectsProvider.notifier).updateProject(oldProj.copyWith(
          advancedPayment: adv,
          partialPayments: part,
          finalPayment: fin,
          paymentStatus: newStatus,
        ));
      }
    }

    if (newRecord.projectId != null && newRecord.projectId!.isNotEmpty) {
      final freshProjects = ref.read(projectsProvider).projects;
      final newProj = freshProjects.where((p) => p.id == newRecord.projectId).firstOrNull;
      if (newProj != null) {
        double adv = newProj.advancedPayment;
        double part = newProj.partialPayments;
        double fin = newProj.finalPayment;
        if (newRecord.projectPaymentType == 'Advance') {
          adv += newRecord.amount;
        } else if (newRecord.projectPaymentType == 'Final' || newRecord.projectPaymentType == 'Full') {
          fin += newRecord.amount;
        } else {
          part += newRecord.amount;
        }
        final totalRecv = adv + part + fin;
        final newStatus = totalRecv >= newProj.budget ? 'Fully Paid' : (totalRecv > 0 ? 'Partially Paid' : 'Pending');
        await ref.read(projectsProvider.notifier).updateProject(newProj.copyWith(
          advancedPayment: adv,
          partialPayments: part,
          finalPayment: fin,
          paymentStatus: newStatus,
        ));
      }
    }

    // 3. Client payments rollback from old & apply to new
    if (oldRecord.clientId.isNotEmpty) {
      final oldClient = ref.read(clientsProvider).clients.where((c) => c.id == oldRecord.clientId).firstOrNull;
      if (oldClient != null) {
        final newAdv = (oldClient.advancedPayment - oldRecord.amount).clamp(0.0, double.infinity);
        await ref.read(clientsProvider.notifier).updateClient(oldClient.copyWith(advancedPayment: newAdv));
      }
    }
    if (newRecord.clientId.isNotEmpty) {
      final freshClients = ref.read(clientsProvider).clients;
      final newClient = freshClients.where((c) => c.id == newRecord.clientId).firstOrNull;
      if (newClient != null) {
        final newAdv = newClient.advancedPayment + newRecord.amount;
        await ref.read(clientsProvider.notifier).updateClient(newClient.copyWith(advancedPayment: newAdv));
      }
    }

    // 4. Update Ledger Entry
    final accounts = ref.read(accountsProvider).accounts;
    final account = accounts.where((a) => a.id == newRecord.accountId).firstOrNull;
    final accountName = account?.name ?? 'Unknown Account';

    String paymentTypeText = newRecord.projectPaymentType ?? 'Payment';
    if (newRecord.projectPaymentType == 'Advance') {
      paymentTypeText = 'Advance Payment';
    } else if (newRecord.projectPaymentType == 'Partial') {
      paymentTypeText = 'Partial Payment';
    } else if (newRecord.projectPaymentType == 'Final' || newRecord.projectPaymentType == 'Full') {
      paymentTypeText = 'Full Payment';
    }

    String ledgerDesc = newRecord.description;
    if (newRecord.projectId != null && newRecord.projectName != null && newRecord.projectName!.isNotEmpty) {
      ledgerDesc = '${newRecord.projectName} - ${newRecord.clientName}';
    }

    String ledgerRef = newRecord.invoiceNumber.isNotEmpty
        ? newRecord.invoiceNumber
        : (newRecord.projectId != null && newRecord.projectId!.isNotEmpty ? newRecord.projectId! : '—');

    final ledgerEntry = LedgerEntry(
      id: 'led_inc_${newRecord.id}',
      date: newRecord.date,
      accountId: newRecord.accountId,
      accountName: accountName,
      type: 'Debit',
      category: newRecord.projectId != null && newRecord.projectId!.isNotEmpty ? 'Project Payment' : newRecord.incomeType,
      amount: newRecord.amount,
      reference: ledgerRef,
      description: ledgerDesc,
      installmentType: paymentTypeText,
    );
    await ref.read(ledgerProvider.notifier).updateLedgerEntry(ledgerEntry);

    ref.read(adminProvider.notifier).logAction(
      action: 'Updated income record: ${newRecord.description} (Amount: ${oldRecord.amount} → ${newRecord.amount}, Client: ${newRecord.clientName})',
      module: 'Finance',
    );

    final updated = await _repository.getIncomes();
    state = state.copyWith(incomes: updated, isLoading: false);
    await ref.read(accountsProvider.notifier).syncBalancesFromDb();
  }

  Future<void> deleteIncome(String id) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.income, PermissionAction.delete)) {
      throw Exception('Access Denied: You do not have permission to delete income records.');
    }

    final list = List<IncomeRecord>.from(state.incomes);
    final recordIndex = list.indexWhere((i) => i.id == id);
    if (recordIndex == -1) return;

    final record = list[recordIndex];
    state = state.copyWith(isLoading: true);

    // 1. Rollback bank account balance (Deduct income amount)
    await ref.read(accountsProvider.notifier).adjustBalance(record.accountId, -record.amount);

    // 2. Rollback project payment fields if selected
    if (record.projectId != null && record.projectId!.isNotEmpty) {
      final projectsState = ref.read(projectsProvider);
      final project = projectsState.projects.where((p) => p.id == record.projectId).firstOrNull;
      if (project != null) {
        double adv = project.advancedPayment;
        double part = project.partialPayments;
        double fin = project.finalPayment;
        if (record.projectPaymentType == 'Advance') {
          adv = (adv - record.amount).clamp(0.0, double.infinity);
        } else if (record.projectPaymentType == 'Final' || record.projectPaymentType == 'Full') {
          fin = (fin - record.amount).clamp(0.0, double.infinity);
        } else {
          part = (part - record.amount).clamp(0.0, double.infinity);
        }
        final totalRecv = adv + part + fin;
        final newStatus = totalRecv >= project.budget ? 'Fully Paid' : (totalRecv > 0 ? 'Partially Paid' : 'Pending');
        final updatedProject = project.copyWith(
          advancedPayment: adv,
          partialPayments: part,
          finalPayment: fin,
          paymentStatus: newStatus,
        );
        await ref.read(projectsProvider.notifier).updateProject(updatedProject);
      }
    }

    // 3. Rollback client payment
    if (record.clientId.isNotEmpty) {
      final clientsState = ref.read(clientsProvider);
      final client = clientsState.clients.where((c) => c.id == record.clientId).firstOrNull;
      if (client != null) {
        final newAdv = (client.advancedPayment - record.amount).clamp(0.0, double.infinity);
        await ref.read(clientsProvider.notifier).updateClient(client.copyWith(advancedPayment: newAdv));
      }
    }

    // 4. Remove General Ledger entry
    await ref.read(ledgerProvider.notifier).deleteLedgerEntry('led_inc_${record.id}');

    // 5. Delete income record
    await _repository.deleteIncome(id);

    ref.read(adminProvider.notifier).logAction(
      action: 'Deleted income record: ${record.description} (Amount: ${record.amount}, Client: ${record.clientName})',
      module: 'Finance',
    );

    final updated = await _repository.getIncomes();
    state = state.copyWith(incomes: updated, isLoading: false);
    await ref.read(accountsProvider.notifier).syncBalancesFromDb();
  }
}

final incomeProvider = NotifierProvider<IncomeNotifier, IncomeState>(() {
  return IncomeNotifier();
});
