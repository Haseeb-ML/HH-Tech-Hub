import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/salary_record.dart';
import '../../domain/repositories/salaries_repository.dart';

class SalariesRepositoryImpl implements SalariesRepository {
  final DriftDatabaseService _dbService;

  SalariesRepositoryImpl(this._dbService);

  @override
  Future<List<SalaryRecord>> getSalaries() async {
    final list = await _dbService.db.getAll(_dbService.db.salaryRecordsTable);
    return list.map((s) => SalaryRecord(
      id: s.id,
      employeeId: s.employeeId,
      employeeName: s.employeeName,
      payPeriod: s.payPeriod,
      baseSalary: s.baseSalary,
      allowances: s.allowances,
      deductions: s.deductions,
      netPaid: s.netPaid,
      paymentDate: s.paymentDate,
      status: s.status,
      paymentMethod: s.paymentMethod,
    )).toList();
  }

  @override
  Future<void> addSalary(SalaryRecord salary) async {
    await _dbService.db.upsert(
      _dbService.db.salaryRecordsTable,
      SalaryRecordsTableCompanion.insert(
        id: salary.id,
        employeeId: salary.employeeId,
        employeeName: salary.employeeName,
        payPeriod: salary.payPeriod,
        baseSalary: salary.baseSalary,
        allowances: salary.allowances,
        deductions: salary.deductions,
        netPaid: salary.netPaid,
        paymentDate: salary.paymentDate,
        status: salary.status,
        paymentMethod: salary.paymentMethod,
      ),
    );
  }

  @override
  Future<void> updateSalary(SalaryRecord salary) async {
    await addSalary(salary);
  }

  @override
  Future<void> deleteSalary(String id) async {
    await _dbService.db.deleteById(_dbService.db.salaryRecordsTable, id);
  }
}
