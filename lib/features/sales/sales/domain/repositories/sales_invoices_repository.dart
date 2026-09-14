import '../entities/sales_invoice.dart';

abstract class SalesInvoicesRepository {
  Future<List<SalesInvoice>> getInvoices();
  Future<void> addInvoice(SalesInvoice invoice);
  Future<void> updateInvoice(SalesInvoice invoice);
  Future<void> deleteInvoice(String id);
}
