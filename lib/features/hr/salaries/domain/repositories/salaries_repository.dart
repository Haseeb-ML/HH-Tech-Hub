import '../entities/salary_record.dart';

abstract class SalariesRepository {
  Future<List<SalaryRecord>> getSalaries();
  Future<void> addSalary(SalaryRecord record);
  Future<void> updateSalary(SalaryRecord record);
  Future<void> deleteSalary(String id);
}
