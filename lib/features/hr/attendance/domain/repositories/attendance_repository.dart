import '../entities/attendance_record.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceRecord>> getAttendanceForDate(String date);
  Future<void> updateAttendance(AttendanceRecord record);
  Future<void> saveDailyAttendance(List<AttendanceRecord> records);
  Future<void> deleteAttendance(String id);
  Future<List<AttendanceRecord>> getAttendanceForMonth(String yearMonth);
  Future<List<AttendanceRecord>> getAttendanceForDateRange(String fromDate, String toDate);
}
