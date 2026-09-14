import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/loan_record.dart';
import '../../domain/repositories/loans_repository.dart';

class LoansRepositoryImpl implements LoansRepository {
  final DriftDatabaseService _dbService;

  LoansRepositoryImpl(this._dbService);

  @override
  Future<List<LoanRecord>> getLoans() async {
    final list = await _dbService.db.getAll(_dbService.db.loanRecordsTable);
    return list.map((l) => LoanRecord(
      id: l.id,
      borrowerName: l.borrowerName,
      type: l.type,
      amount: l.amount,
      remainingBalance: l.remainingBalance,
      startDate: l.startDate,
      endDate: l.endDate,
      status: l.status,
      description: l.description,
      repayments: l.repayments.map((r) => LoanRepayment(id: r['id'], date: r['date'], amount: r['amount'], accountId: r['accountId'], accountName: r['accountName'])).toList(),
    )).toList();
  }

  @override
  Future<void> addLoan(LoanRecord loan) async {
    await _dbService.db.upsert(
      _dbService.db.loanRecordsTable,
      LoanRecordsTableCompanion.insert(
        id: loan.id,
        borrowerName: loan.borrowerName,
        type: loan.type,
        amount: loan.amount,
        remainingBalance: loan.remainingBalance,
        startDate: loan.startDate,
        endDate: loan.endDate,
        status: loan.status,
        description: loan.description,
        repayments: loan.repayments.map((r) => r.toJson()).toList(),
      ),
    );
  }

  @override
  Future<void> updateLoan(LoanRecord loan) async {
    await addLoan(loan);
  }

  @override
  Future<void> deleteLoan(String id) async {
    await _dbService.db.deleteById(_dbService.db.loanRecordsTable, id);
  }
}
