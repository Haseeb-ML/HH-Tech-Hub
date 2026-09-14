import '../entities/income_record.dart';

abstract class IncomeRepository {
  Future<List<IncomeRecord>> getIncomes();
  Future<void> addIncome(IncomeRecord record);
  Future<void> updateIncome(IncomeRecord record);
  Future<void> deleteIncome(String id);
}
