import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/advance_record.dart';
import '../../domain/repositories/advances_repository.dart';

class AdvancesRepositoryImpl implements AdvancesRepository {
  final DriftDatabaseService _dbService;

  AdvancesRepositoryImpl(this._dbService);

  @override
  Future<List<AdvanceRecord>> getAdvances() async {
    final list = await _dbService.db.getAll(_dbService.db.advanceRecordsTable);
    return list.map((a) => AdvanceRecord(
      id: a.id,
      employeeId: a.employeeId,
      employeeName: a.employeeName,
      amount: a.amount,
      requestDate: a.requestDate,
      reason: a.reason,
      repaymentMonths: a.repaymentMonths,
      amountRepaid: a.amountRepaid,
      status: a.status,
    )).toList();
  }

  @override
  Future<void> addAdvance(AdvanceRecord advance) async {
    await _dbService.db.upsert(
      _dbService.db.advanceRecordsTable,
      AdvanceRecordsTableCompanion.insert(
        id: advance.id,
        employeeId: advance.employeeId,
        employeeName: advance.employeeName,
        amount: advance.amount,
        requestDate: advance.requestDate,
        reason: advance.reason,
        repaymentMonths: advance.repaymentMonths,
        amountRepaid: advance.amountRepaid,
        status: advance.status,
      ),
    );
  }

  @override
  Future<void> updateAdvance(AdvanceRecord advance) async {
    await addAdvance(advance);
  }

  @override
  Future<void> deleteAdvance(String id) async {
    await _dbService.db.deleteById(_dbService.db.advanceRecordsTable, id);
  }
}
