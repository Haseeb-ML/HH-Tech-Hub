import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/purchase_order.dart';
import '../../domain/repositories/purchase_orders_repository.dart';

class PurchaseOrdersRepositoryImpl implements PurchaseOrdersRepository {
  final DriftDatabaseService _dbService;

  PurchaseOrdersRepositoryImpl(this._dbService);

  @override
  Future<List<PurchaseOrder>> getPurchaseOrders() async {
    final list = await _dbService.db.getAll(_dbService.db.purchaseOrdersTable);
    return list.map((p) => PurchaseOrder(
      id: p.id,
      vendorId: p.vendorId,
      vendorName: p.vendorName,
      date: p.date,
      deliveryDate: p.deliveryDate,
      items: p.items.map((i) => PurchaseItem(
        itemId: i['itemId'],
        itemName: i['itemName'],
        quantity: i['quantity'],
        unitPrice: i['unitPrice'],
        totalPrice: i['totalPrice'],
      )).toList(),
      subtotal: p.subtotal,
      tax: p.tax,
      total: p.total,
      status: p.status,
    )).toList();
  }

  @override
  Future<void> addPurchaseOrder(PurchaseOrder order) async {
    await _dbService.db.upsert(
      _dbService.db.purchaseOrdersTable,
      PurchaseOrdersTableCompanion.insert(
        id: order.id,
        vendorId: order.vendorId,
        vendorName: order.vendorName,
        date: order.date,
        deliveryDate: order.deliveryDate,
        items: order.items.map((i) => {
          'itemId': i.itemId,
          'itemName': i.itemName,
          'quantity': i.quantity,
          'unitPrice': i.unitPrice,
          'totalPrice': i.totalPrice,
        }).toList(),
        subtotal: order.subtotal,
        tax: order.tax,
        total: order.total,
        status: order.status,
      ),
    );
  }

  @override
  Future<void> updatePurchaseOrder(PurchaseOrder order) async {
    await addPurchaseOrder(order);
  }

  @override
  Future<void> deletePurchaseOrder(String id) async {
    await _dbService.db.deleteById(_dbService.db.purchaseOrdersTable, id);
  }
}
