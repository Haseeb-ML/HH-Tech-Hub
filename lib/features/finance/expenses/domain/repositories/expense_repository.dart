import '../entities/expense_record.dart';

abstract class ExpenseRepository {
  Future<List<ExpenseRecord>> getExpenses();
  Future<void> addExpense(ExpenseRecord record);
  Future<void> updateExpense(ExpenseRecord record);
  Future<void> deleteExpense(String id);
}
