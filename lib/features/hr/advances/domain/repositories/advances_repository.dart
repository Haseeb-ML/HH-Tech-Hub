import '../entities/advance_record.dart';

abstract class AdvancesRepository {
  Future<List<AdvanceRecord>> getAdvances();
  Future<void> addAdvance(AdvanceRecord record);
  Future<void> updateAdvance(AdvanceRecord record);
  Future<void> deleteAdvance(String id);
}
