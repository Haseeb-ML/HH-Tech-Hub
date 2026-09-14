import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/repositories/ledger_repository.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  final DriftDatabaseService _dbService;

  LedgerRepositoryImpl(this._dbService);

  @override
  Future<List<LedgerEntry>> getLedgerEntries() async {
    final list = await _dbService.db.getAll(_dbService.db.ledgerEntriesTable);
    return list.map((l) => LedgerEntry(
      id: l.id,
      date: l.date,
      accountId: l.accountId,
      accountName: l.accountName,
      type: l.type,
      category: l.category,
      amount: l.amount,
      reference: l.reference,
      description: l.description,
    )).toList();
  }

  @override
  Future<void> addLedgerEntry(LedgerEntry entry) async {
    await _dbService.db.upsert(
      _dbService.db.ledgerEntriesTable,
      LedgerEntriesTableCompanion.insert(
        id: entry.id,
        date: entry.date,
        accountId: entry.accountId,
        accountName: entry.accountName,
        type: entry.type,
        category: entry.category,
        amount: entry.amount,
        reference: entry.reference,
        description: entry.description,
      ),
    );
  }

  @override
  Future<void> updateLedgerEntry(LedgerEntry entry) async {
    await addLedgerEntry(entry);
  }

  @override
  Future<void> deleteLedgerEntry(String id) async {
    await _dbService.db.deleteById(_dbService.db.ledgerEntriesTable, id);
  }
}
