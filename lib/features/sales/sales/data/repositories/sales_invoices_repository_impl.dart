import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/repositories/sales_invoices_repository.dart';

class SalesInvoicesRepositoryImpl implements SalesInvoicesRepository {
  final DriftDatabaseService _dbService;

  SalesInvoicesRepositoryImpl(this._dbService);

  @override
  Future<List<SalesInvoice>> getInvoices() async {
    final list = await _dbService.db.getAll(_dbService.db.salesInvoicesTable);
    return list.map((i) => SalesInvoice(
      id: i.id,
      clientId: i.clientId,
      clientName: i.clientName,
      date: i.date,
      dueDate: i.dueDate,
      items: i.items.map((it) => InvoiceItem(
        productId: it['productId'],
        productName: it['productName'],
        quantity: it['quantity'],
        unitPrice: it['unitPrice'],
        totalPrice: it['totalPrice'],
      )).toList(),
      subtotal: i.subtotal,
      tax: i.tax,
      total: i.total,
      status: i.status,
    )).toList();
  }

  @override
  Future<void> addInvoice(SalesInvoice invoice) async {
    await _dbService.db.upsert(
      _dbService.db.salesInvoicesTable,
      SalesInvoicesTableCompanion.insert(
        id: invoice.id,
        clientId: invoice.clientId,
        clientName: invoice.clientName,
        date: invoice.date,
        dueDate: invoice.dueDate,
        items: invoice.items.map((it) => {
          'productId': it.productId,
          'productName': it.productName,
          'quantity': it.quantity,
          'unitPrice': it.unitPrice,
          'totalPrice': it.totalPrice,
        }).toList(),
        subtotal: invoice.subtotal,
        tax: invoice.tax,
        total: invoice.total,
        status: invoice.status,
      ),
    );
  }

  @override
  Future<void> updateInvoice(SalesInvoice invoice) async {
    await addInvoice(invoice);
  }

  @override
  Future<void> deleteInvoice(String id) async {
    await _dbService.db.deleteById(_dbService.db.salesInvoicesTable, id);
  }
}
