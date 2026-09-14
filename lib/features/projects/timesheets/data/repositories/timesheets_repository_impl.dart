import 'package:software_house_erp/core/services/database_service.dart';
import '../../domain/entities/timesheet_entry.dart';
import '../../domain/repositories/timesheets_repository.dart';

class TimesheetsRepositoryImpl implements TimesheetsRepository {
  final DriftDatabaseService _dbService;

  TimesheetsRepositoryImpl(this._dbService);

  @override
  Future<List<TimesheetEntry>> getTimesheets() async {
    final list = await _dbService.db.getAll(_dbService.db.timesheetEntriesTable);
    return list.map((t) => TimesheetEntry(
      id: t.id,
      employeeId: t.employeeId,
      employeeName: t.employeeName,
      projectId: t.projectId,
      projectName: t.projectName,
      taskTitle: t.taskTitle,
      date: t.date,
      hours: t.hours,
      description: t.description,
      status: t.status,
    )).toList();
  }

  @override
  Future<void> addTimesheet(TimesheetEntry entry) async {
    await _dbService.db.upsert(
      _dbService.db.timesheetEntriesTable,
      TimesheetEntriesTableCompanion.insert(
        id: entry.id,
        employeeId: entry.employeeId,
        employeeName: entry.employeeName,
        projectId: entry.projectId,
        projectName: entry.projectName,
        taskTitle: entry.taskTitle,
        date: entry.date,
        hours: entry.hours,
        description: entry.description,
        status: entry.status,
      ),
    );
  }

  @override
  Future<void> updateTimesheet(TimesheetEntry entry) async {
    await addTimesheet(entry);
  }

  @override
  Future<void> deleteTimesheet(String id) async {
    await _dbService.db.deleteById(_dbService.db.timesheetEntriesTable, id);
  }
}
