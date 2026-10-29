import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/products_repository.dart';
import '../../data/repositories/products_repository_impl.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/features/administration/recovery/presentation/providers/recovery_provider.dart';

// ─── State Definition ───────────────────────────

class ProductsState {
  final List<Product> products;
  final bool isLoading;

  const ProductsState({
    required this.products,
    required this.isLoading,
  });

  ProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ─── Repository Provider ─────────────────────────
final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return ProductsRepositoryImpl(dbService);
});

// ─── Notifier & Provider ─────────────────────────
class ProductsNotifier extends Notifier<ProductsState> {
  ProductsRepository get _repository => ref.read(productsRepositoryProvider);

  @override
  ProductsState build() {
    Future.microtask(() => loadProducts());
    return const ProductsState(products: [], isLoading: true);
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repository.getProducts();
      state = state.copyWith(products: items, isLoading: false);
    } catch (e) {
      print('Error loading products: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addProduct(Product product) async {
    await _repository.addProduct(product);
    ref.read(adminProvider.notifier).logAction(
      action: 'Added product: ${product.name} (Price: ${product.price})',
      module: 'Sales',
    );
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await _repository.updateProduct(product);
    ref.read(adminProvider.notifier).logAction(
      action: 'Updated product: ${product.name} (Price: ${product.price})',
      module: 'Sales',
    );
    await loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    final prod = state.products.where((p) => p.id == id).firstOrNull;
    if (prod != null) {
      final adminState = ref.read(adminProvider);
      await ref.read(recoveryProvider.notifier).addDeletedItem(
        id: prod.id,
        itemType: 'Product',
        title: prod.name,
        subtitle: 'Price: Rs. ${prod.price.toStringAsFixed(0)}',
        jsonData: prod.toMap(),
        deletedBy: adminState.currentUser?.name ?? 'Admin',
      );
    }
    await _repository.deleteProduct(id);
    ref.read(adminProvider.notifier).logAction(
      action: 'Deleted product: $id',
      module: 'Sales',
    );
    await loadProducts();
  }
}

final productsProvider = NotifierProvider<ProductsNotifier, ProductsState>(() {
  return ProductsNotifier();
});
