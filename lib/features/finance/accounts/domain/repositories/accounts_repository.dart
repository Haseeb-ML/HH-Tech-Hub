import '../entities/bank_account.dart';

abstract class AccountsRepository {
  Future<List<BankAccount>> getAccounts();
  Future<void> addAccount(BankAccount account);
  Future<void> updateAccount(BankAccount account);
  Future<void> deleteAccount(String id);
}
