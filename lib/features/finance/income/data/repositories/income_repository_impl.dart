import 'package:drift/drift.dart';
import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/income_record.dart';
import '../../domain/repositories/income_repository.dart';

class IncomeRepositoryImpl implements IncomeRepository {
  final DriftDatabaseService _dbService;

  IncomeRepositoryImpl(this._dbService);

  @override
  Future<List<IncomeRecord>> getIncomes() async {
    final list = await _dbService.db.getAll(_dbService.db.incomeRecordsTable);
    return list.map((i) => IncomeRecord(
      id: i.id,
      date: i.date,
      clientId: i.clientId,
      clientName: i.clientName,
      amount: i.amount,
      accountId: i.accountId,
      invoiceNumber: i.invoiceNumber,
      description: i.description,
      status: i.status,
      projectId: i.projectId,
      projectName: i.projectName,
      projectPaymentType: i.projectPaymentType,
    )).toList();
  }

  @override
  Future<void> addIncome(IncomeRecord record) async {
    await _dbService.db.upsert(
      _dbService.db.incomeRecordsTable,
      IncomeRecordsTableCompanion.insert(
        id: record.id,
        date: record.date,
        clientId: record.clientId,
        clientName: record.clientName,
        amount: record.amount,
        accountId: record.accountId,
        invoiceNumber: record.invoiceNumber,
        description: record.description,
        status: record.status,
        projectId: Value(record.projectId),
        projectName: Value(record.projectName),
        projectPaymentType: Value(record.projectPaymentType),
      ),
    );
  }

  @override
  Future<void> updateIncome(IncomeRecord record) async {
    await addIncome(record);
  }

  @override
  Future<void> deleteIncome(String id) async {
    await _dbService.db.deleteById(_dbService.db.incomeRecordsTable, id);
  }
}
