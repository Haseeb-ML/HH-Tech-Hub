import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/products_repository.dart';
import '../../data/repositories/products_repository_impl.dart';

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
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await _repository.updateProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await _repository.deleteProduct(id);
    await loadProducts();
  }
}

final productsProvider = NotifierProvider<ProductsNotifier, ProductsState>(() {
  return ProductsNotifier();
});
