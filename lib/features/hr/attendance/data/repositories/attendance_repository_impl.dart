import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import 'package:software_house_erp/core/services/database_service.dart';
import 'package:drift/drift.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final DriftDatabaseService _dbService;

  AttendanceRepositoryImpl(this._dbService);

  @override
  Future<List<AttendanceRecord>> getAttendanceForDate(String date) async {
    final list = await _dbService.db.getAll(_dbService.db.attendanceRecordsTable);
    final filtered = list.where((a) => a.date == date);
    return filtered.map((a) => AttendanceRecord(
      id: a.id,
      employeeId: a.employeeId,
      employeeName: a.employeeName,
      date: a.date,
      status: AttendanceStatus.normalize(a.status),
      checkIn: a.checkIn,
      checkOut: a.checkOut,
      notes: a.notes,
    )).toList();
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceForDateRange(String fromDate, String toDate) async {
    final list = await _dbService.db.getAll(_dbService.db.attendanceRecordsTable);
    return list.map((a) => AttendanceRecord(
      id: a.id,
      employeeId: a.employeeId,
      employeeName: a.employeeName,
      date: a.date,
      status: AttendanceStatus.normalize(a.status),
      checkIn: a.checkIn,
      checkOut: a.checkOut,
      notes: a.notes,
    )).where((a) => a.date.compareTo(fromDate) >= 0 && a.date.compareTo(toDate) <= 0).toList();
  }

  @override
  Future<List<AttendanceRecord>> getAttendanceForMonth(String yearMonth) async {
    final list = await _dbService.db.getAll(_dbService.db.attendanceRecordsTable);
    return list.map((a) => AttendanceRecord(
      id: a.id,
      employeeId: a.employeeId,
      employeeName: a.employeeName,
      date: a.date,
      status: AttendanceStatus.normalize(a.status),
      checkIn: a.checkIn,
      checkOut: a.checkOut,
      notes: a.notes,
    )).where((a) => a.date.startsWith(yearMonth)).toList();
  }

  @override
  Future<void> saveDailyAttendance(List<AttendanceRecord> records) async {
    for (var record in records) {
      await updateAttendance(record);
    }
  }

  @override
  Future<void> updateAttendance(AttendanceRecord record) async {
    final normalizedStatus = AttendanceStatus.normalize(record.status);
    final all = await _dbService.db.getAll(_dbService.db.attendanceRecordsTable);
    final existing = all.where((a) => a.employeeId == record.employeeId && a.date == record.date);

    final String targetId = existing.isNotEmpty
        ? existing.first.id
        : (record.id.isNotEmpty ? record.id : 'att_${record.employeeId}_${record.date}');

    await _dbService.db.upsert(
      _dbService.db.attendanceRecordsTable,
      AttendanceRecordsTableCompanion.insert(
        id: targetId,
        employeeId: record.employeeId,
        employeeName: record.employeeName,
        date: record.date,
        status: normalizedStatus,
        checkIn: Value(record.checkIn),
        checkOut: Value(record.checkOut),
        notes: Value(record.notes),
      ),
    );
  }

  @override
  Future<void> deleteAttendance(String id) async {
    await _dbService.db.deleteById(_dbService.db.attendanceRecordsTable, id);
  }
}
