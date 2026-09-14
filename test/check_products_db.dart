
import 'package:software_house_erp/core/services/database_service.dart';
import 'package:software_house_erp/features/sales/sales/data/repositories/products_repository_impl.dart';

void main() async {
  print('Initializing DB...');
  final dbService = DriftDatabaseService();
  final repo = ProductsRepositoryImpl(dbService);
  
  try {
    print('Fetching products...');
    final products = await repo.getProducts();
    print('Products found: ${products.length}');
  } catch (e, st) {
    print('Error: $e');
    print(st);
  }
}
