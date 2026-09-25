import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/repositories/sales_invoices_repository.dart';
import '../../data/repositories/sales_invoices_repository_impl.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

// ─── State Definition ───────────────────────────

class SalesInvoicesState {
  final List<SalesInvoice> invoices;
  final bool isLoading;

  const SalesInvoicesState({
    required this.invoices,
    required this.isLoading,
  });

  SalesInvoicesState copyWith({
    List<SalesInvoice>? invoices,
    bool? isLoading,
  }) {
    return SalesInvoicesState(
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Repository Provider ─────────────────────────
final salesInvoicesRepositoryProvider = Provider<SalesInvoicesRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return SalesInvoicesRepositoryImpl(dbService);
});

// ─── Notifier & Provider ─────────────────────────
class SalesInvoicesNotifier extends Notifier<SalesInvoicesState> {
  SalesInvoicesRepository get _repository => ref.read(salesInvoicesRepositoryProvider);

  @override
  SalesInvoicesState build() {
    Future.microtask(() => loadInvoices());
    return const SalesInvoicesState(invoices: [], isLoading: true);
  }

  Future<void> loadInvoices() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repository.getInvoices();
      state = state.copyWith(invoices: items, isLoading: false);
    } catch (e) {
      print('Error loading invoices: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addInvoice(SalesInvoice invoice) async {
    await _repository.addInvoice(invoice);
    ref.read(adminProvider.notifier).logAction(
      action: 'Added sales invoice: ${invoice.id} (Client: ${invoice.clientName}, Total: ${invoice.total})',
      module: 'Sales',
    );
    await loadInvoices();
  }

  Future<void> updateInvoice(SalesInvoice invoice) async {
    await _repository.updateInvoice(invoice);
    ref.read(adminProvider.notifier).logAction(
      action: 'Updated sales invoice: ${invoice.id} (Client: ${invoice.clientName}, Total: ${invoice.total})',
      module: 'Sales',
    );
    await loadInvoices();
  }

  Future<void> deleteInvoice(String id) async {
    await _repository.deleteInvoice(id);
    ref.read(adminProvider.notifier).logAction(
      action: 'Deleted sales invoice: $id',
      module: 'Sales',
    );
    await loadInvoices();
  }
}

final salesInvoicesProvider = NotifierProvider<SalesInvoicesNotifier, SalesInvoicesState>(() {
  return SalesInvoicesNotifier();
});
