import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/purchase_order.dart';
import '../../domain/repositories/purchase_orders_repository.dart';
import '../../data/repositories/purchase_orders_repository_impl.dart';

// ─── State Definition ───────────────────────────

class PurchaseOrdersState {
  final List<PurchaseOrder> orders;
  final bool isLoading;

  const PurchaseOrdersState({
    required this.orders,
    required this.isLoading,
  });

  PurchaseOrdersState copyWith({
    List<PurchaseOrder>? orders,
    bool? isLoading,
  }) {
    return PurchaseOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Repository Provider ─────────────────────────
final purchaseOrdersRepositoryProvider = Provider<PurchaseOrdersRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return PurchaseOrdersRepositoryImpl(dbService);
});

// ─── Notifier & Provider ─────────────────────────
class PurchaseOrdersNotifier extends Notifier<PurchaseOrdersState> {
  PurchaseOrdersRepository get _repository => ref.read(purchaseOrdersRepositoryProvider);

  @override
  PurchaseOrdersState build() {
    Future.microtask(() => loadOrders());
    return const PurchaseOrdersState(orders: [], isLoading: true);
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repository.getPurchaseOrders();
      state = state.copyWith(orders: items, isLoading: false);
    } catch (e) {
      print('Error loading purchase orders: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addOrder(PurchaseOrder order) async {
    await _repository.addPurchaseOrder(order);
    await loadOrders();
  }

  Future<void> updateOrder(PurchaseOrder order) async {
    await _repository.updatePurchaseOrder(order);
    await loadOrders();
  }

  Future<void> deleteOrder(String id) async {
    await _repository.deletePurchaseOrder(id);
    await loadOrders();
  }
}

final purchaseOrdersProvider = NotifierProvider<PurchaseOrdersNotifier, PurchaseOrdersState>(() {
  return PurchaseOrdersNotifier();
});
