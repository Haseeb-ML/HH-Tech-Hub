import '../entities/ledger_entry.dart';

abstract class LedgerRepository {
  Future<List<LedgerEntry>> getLedgerEntries();
  Future<void> addLedgerEntry(LedgerEntry entry);
  Future<void> updateLedgerEntry(LedgerEntry entry);
  Future<void> deleteLedgerEntry(String id);
}
