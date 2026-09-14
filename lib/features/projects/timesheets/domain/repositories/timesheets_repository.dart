import '../entities/timesheet_entry.dart';

abstract class TimesheetsRepository {
  Future<List<TimesheetEntry>> getTimesheets();
  Future<void> addTimesheet(TimesheetEntry entry);
  Future<void> updateTimesheet(TimesheetEntry entry);
  Future<void> deleteTimesheet(String id);
}
