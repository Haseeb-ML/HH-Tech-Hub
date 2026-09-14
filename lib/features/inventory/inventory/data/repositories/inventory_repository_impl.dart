import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final DriftDatabaseService _dbService;

  InventoryRepositoryImpl(this._dbService);

  @override
  Future<List<InventoryItem>> getInventoryItems() async {
    final list = await _dbService.db.getAll(_dbService.db.inventoryItemsTable);
    return list.map((i) => InventoryItem(
      id: i.id,
      name: i.name,
      category: i.category,
      quantity: i.quantity,
      minQuantity: i.minQuantity,
      unit: i.unit,
      pricePerUnit: i.pricePerUnit,
      lastRestockedDate: i.lastRestockedDate,
    )).toList();
  }

  @override
  Future<void> addInventoryItem(InventoryItem item) async {
    await _dbService.db.upsert(
      _dbService.db.inventoryItemsTable,
      InventoryItemsTableCompanion.insert(
        id: item.id,
        name: item.name,
        category: item.category,
        quantity: item.quantity,
        minQuantity: item.minQuantity,
        unit: item.unit,
        pricePerUnit: item.pricePerUnit,
        lastRestockedDate: item.lastRestockedDate,
      ),
    );
  }

  @override
  Future<void> updateInventoryItem(InventoryItem item) async {
    await addInventoryItem(item);
  }

  @override
  Future<void> deleteInventoryItem(String id) async {
    await (_dbService.db.delete(_dbService.db.inventoryItemsTable)..where((t) => t.id.equals(id))).go();
  }
}
