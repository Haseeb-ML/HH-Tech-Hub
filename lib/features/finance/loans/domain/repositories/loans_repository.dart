import '../entities/loan_record.dart';

abstract class LoansRepository {
  Future<List<LoanRecord>> getLoans();
  Future<void> addLoan(LoanRecord record);
  Future<void> updateLoan(LoanRecord record);
  Future<void> deleteLoan(String id);
}
