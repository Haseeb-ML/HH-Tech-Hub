import '../entities/purchase_order.dart';

abstract class PurchaseOrdersRepository {
  Future<List<PurchaseOrder>> getPurchaseOrders();
  Future<void> addPurchaseOrder(PurchaseOrder order);
  Future<void> updatePurchaseOrder(PurchaseOrder order);
  Future<void> deletePurchaseOrder(String id);
}
