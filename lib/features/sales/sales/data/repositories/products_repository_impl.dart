import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/products_repository.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final DriftDatabaseService _dbService;

  ProductsRepositoryImpl(this._dbService);

  @override
  Future<List<Product>> getProducts() async {
    final list = await _dbService.db.getAll(_dbService.db.productsTable);
    return list.map((p) => Product(
      id: p.id,
      name: p.name,
      description: p.description,
      category: p.category,
      price: p.price,
      status: p.status,
    )).toList();
  }

  @override
  Future<void> addProduct(Product product) async {
    await _dbService.db.upsert(
      _dbService.db.productsTable,
      ProductsTableCompanion.insert(
        id: product.id,
        name: product.name,
        description: product.description,
        category: product.category,
        price: product.price,
        status: product.status,
      ),
    );
  }

  @override
  Future<void> updateProduct(Product product) async {
    await addProduct(product);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _dbService.db.deleteById(_dbService.db.productsTable, id);
  }
}
