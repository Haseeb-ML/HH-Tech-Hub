import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../../employees/domain/repositories/employees_repository.dart';
import '../../../employees/presentation/providers/employees_provider.dart';

// ─────────────────────────────────────────────
//  Monthly Summary helper model
// ─────────────────────────────────────────────
class EmployeeMonthSummary {
  final String employeeId;
  final String employeeName;
  final int workingDays;
  final int presentDays;
  final int absentDays;
  final int leaveDays;
  final int halfDays;
  final int workFromHomeDays;
  final int officialVisitDays;
  final int lateDays;
  final double totalWorkingHours;

  const EmployeeMonthSummary({
    required this.employeeId,
    required this.employeeName,
    required this.workingDays,
    required this.presentDays,
    required this.absentDays,
    required this.leaveDays,
    required this.halfDays,
    required this.workFromHomeDays,
    required this.officialVisitDays,
    required this.lateDays,
    required this.totalWorkingHours,
  });

  /// Alias for backward compatibility
  int get totalDays => workingDays;

  /// (Present Days + Half Days * 0.5) / Working Days * 100
  double get attendancePercent =>
      workingDays == 0 ? 0.0 : (((presentDays + (halfDays * 0.5)) / workingDays) * 100).clamp(0.0, 100.0);
}

class AttendanceSettings {
  final int workStartMinutes;
  final int workEndMinutes;
  final int graceMinutes;
  final List<int> weeklyOffDays;
  final List<String> holidayDates;

  const AttendanceSettings({
    required this.workStartMinutes,
    required this.workEndMinutes,
    required this.graceMinutes,
    required this.weeklyOffDays,
    required this.holidayDates,
  });

  AttendanceSettings copyWith({
    int? workStartMinutes,
    int? workEndMinutes,
    int? graceMinutes,
    List<int>? weeklyOffDays,
    List<String>? holidayDates,
  }) {
    return AttendanceSettings(
      workStartMinutes: workStartMinutes ?? this.workStartMinutes,
      workEndMinutes: workEndMinutes ?? this.workEndMinutes,
      graceMinutes: graceMinutes ?? this.graceMinutes,
      weeklyOffDays: weeklyOffDays ?? this.weeklyOffDays,
      holidayDates: holidayDates ?? this.holidayDates,
    );
  }
}

class AttendanceSettingsNotifier extends AsyncNotifier<AttendanceSettings> {
  static const _startKey = 'attendance_work_start_minutes';
  static const _endKey = 'attendance_work_end_minutes';
  static const _graceKey = 'attendance_grace_minutes';
  static const _offDaysKey = 'attendance_weekly_off_days';
  static const _holidaysKey = 'attendance_holiday_dates';

  @override
  Future<AttendanceSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return AttendanceSettings(
      workStartMinutes: prefs.getInt(_startKey) ?? 9 * 60,
      workEndMinutes: prefs.getInt(_endKey) ?? 18 * 60,
      graceMinutes: prefs.getInt(_graceKey) ?? 15,
      weeklyOffDays: prefs.getStringList(_offDaysKey)?.map(int.parse).toList() ?? [7],
      holidayDates: prefs.getStringList(_holidaysKey) ?? const [],
    );
  }

  Future<void> save(AttendanceSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_startKey, settings.workStartMinutes);
    await prefs.setInt(_endKey, settings.workEndMinutes);
    await prefs.setInt(_graceKey, settings.graceMinutes);
    await prefs.setStringList(_offDaysKey, settings.weeklyOffDays.map((day) => day.toString()).toList());
    await prefs.setStringList(_holidaysKey, settings.holidayDates);
    state = AsyncData(settings);
  }
}

final attendanceSettingsProvider =
    AsyncNotifierProvider<AttendanceSettingsNotifier, AttendanceSettings>(
  AttendanceSettingsNotifier.new,
);

// ─────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────

class AttendanceState {
  final List<AttendanceRecord> records;
  final String selectedDate; // 'YYYY-MM-DD'
  final bool isLoading;

  // Monthly view
  final String selectedYearMonth; // 'YYYY-MM'
  final List<EmployeeMonthSummary> monthlySummaries;
  final bool isMonthlyLoading;

  // Range view
  final List<AttendanceRecord> rangeRecords;
  final bool isRangeLoading;

  const AttendanceState({
    required this.records,
    required this.selectedDate,
    required this.isLoading,
    required this.selectedYearMonth,
    required this.monthlySummaries,
    required this.isMonthlyLoading,
    required this.rangeRecords,
    required this.isRangeLoading,
  });

  AttendanceState copyWith({
    List<AttendanceRecord>? records,
    String? selectedDate,
    bool? isLoading,
    String? selectedYearMonth,
    List<EmployeeMonthSummary>? monthlySummaries,
    bool? isMonthlyLoading,
    List<AttendanceRecord>? rangeRecords,
    bool? isRangeLoading,
  }) {
    return AttendanceState(
      records: records ?? this.records,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      selectedYearMonth: selectedYearMonth ?? this.selectedYearMonth,
      monthlySummaries: monthlySummaries ?? this.monthlySummaries,
      isMonthlyLoading: isMonthlyLoading ?? this.isMonthlyLoading,
      rangeRecords: rangeRecords ?? this.rangeRecords,
      isRangeLoading: isRangeLoading ?? this.isRangeLoading,
    );
  }

  int get presentCount => records.where((r) => r.status == AttendanceStatus.present).length;
  int get absentCount => records.where((r) => r.status == AttendanceStatus.absent).length;
  int get leaveCount => records.where((r) => r.status == AttendanceStatus.leave).length;
  int get halfDayCount => records.where((r) => r.status == AttendanceStatus.halfDay).length;
  int get workFromHomeCount => records.where((r) => r.status == AttendanceStatus.workFromHome).length;
  int get officialVisitCount => records.where((r) => r.status == AttendanceStatus.officialVisit).length;
  int get offCount => records.where((r) => r.status == AttendanceStatus.off).length;
  int get holidayCount => records.where((r) => r.status == AttendanceStatus.holiday).length;
  int get notMarkedCount => records.where((r) => r.status == AttendanceStatus.notMarked).length;
}

// ─────────────────────────────────────────────
//  Repository Provider
// ─────────────────────────────────────────────
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return AttendanceRepositoryImpl(dbService);
});

// ─────────────────────────────────────────────
//  Notifier
// ─────────────────────────────────────────────
class AttendanceNotifier extends Notifier<AttendanceState> {
  AttendanceRepository get _repository => ref.read(attendanceRepositoryProvider);
  EmployeesRepository get _employeesRepository => ref.read(employeesRepositoryProvider);

  @override
  AttendanceState build() {
    // Listen to employees list changes so roster auto-updates
    ref.listen(employeesProvider, (prev, next) {
      Future.microtask(() async {
        await loadAttendance(state.selectedDate);
        await loadMonthlyAttendance(state.selectedYearMonth);
      });
    });

    final now = DateTime.now();
    final targetDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final targetMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    Future.microtask(() async {
      await loadAttendance(targetDate);
      await loadMonthlyAttendance(targetMonth);
    });

    return AttendanceState(
      records: [],
      selectedDate: targetDate,
      isLoading: true,
      selectedYearMonth: targetMonth,
      monthlySummaries: [],
      isMonthlyLoading: false,
      rangeRecords: [],
      isRangeLoading: false,
    );
  }

  // ── Daily ────────────────────────────────────
  Future<void> loadAttendance(String dateStr) async {
    state = state.copyWith(isLoading: true, selectedDate: dateStr);
    try {
      final logs = await _repository.getAttendanceForDate(dateStr);
      final employees = await _employeesRepository.getEmployees();
      final settings = ref.read(attendanceSettingsProvider).value;

      final List<AttendanceRecord> updatedLogs = [];
      for (final emp in employees) {
        if (emp.status == 'Terminated') continue;

        final existing = logs.firstWhere(
          (log) => log.employeeId == emp.id,
          orElse: () {
            final parsedDate = DateTime.tryParse(dateStr);
            final weeklyOffDays = settings?.weeklyOffDays ?? const [7];
            final isWeeklyOff = parsedDate != null && weeklyOffDays.contains(parsedDate.weekday);
            final isHoliday = settings?.holidayDates.contains(dateStr) ?? false;
            final isEmpOnLeave = emp.status == 'On Leave';

            final defaultStatus = isHoliday
                ? AttendanceStatus.holiday
                : (isWeeklyOff
                    ? AttendanceStatus.off
                    : (isEmpOnLeave
                        ? AttendanceStatus.leave
                        : AttendanceStatus.notMarked));

            final defaultNotes = isHoliday
                ? 'Company Holiday'
                : (isWeeklyOff
                    ? 'Weekly Off'
                    : (isEmpOnLeave ? 'Approved Leave' : null));

            return AttendanceRecord(
              id: 'att_${emp.id}_$dateStr',
              employeeId: emp.id,
              employeeName: emp.name,
              date: dateStr,
              status: defaultStatus,
              notes: defaultNotes,
            );
          },
        );

        // Normalize legacy row status and ensure employee name is fresh
        final normalizedStatus = AttendanceStatus.normalize(existing.status);
        final normalizedRecord = existing.copyWith(
          employeeName: emp.name,
          status: normalizedStatus,
        );
        updatedLogs.add(normalizedRecord);
      }

      state = state.copyWith(records: updatedLogs, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateRecord(AttendanceRecord record) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.attendance, PermissionAction.edit)) {
      throw Exception('Access Denied: You do not have permission to edit attendance records.');
    }
    final normalized = record.copyWith(
      status: AttendanceStatus.normalize(record.status),
      checkIn: (record.status == AttendanceStatus.present ||
              record.status == AttendanceStatus.halfDay ||
              record.status == AttendanceStatus.workFromHome ||
              record.status == AttendanceStatus.officialVisit)
          ? record.checkIn
          : null,
      checkOut: (record.status == AttendanceStatus.present ||
              record.status == AttendanceStatus.halfDay ||
              record.status == AttendanceStatus.workFromHome ||
              record.status == AttendanceStatus.officialVisit)
          ? record.checkOut
          : null,
    );
    await _repository.updateAttendance(normalized);
    ref.read(adminProvider.notifier).logAction(
      action: 'Updated attendance for ${record.employeeName} to ${record.status} (Date: ${record.date})',
      module: 'Attendance',
    );
    await loadAttendance(state.selectedDate);
    await loadMonthlyAttendance(state.selectedYearMonth);
  }

  Future<void> markAllPresent() async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.attendance, PermissionAction.edit)) {
      throw Exception('Access Denied: You do not have permission to mark attendance.');
    }
    final date = state.selectedDate;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (date.compareTo(today) > 0) return;

    final recordsToSave = state.records
        .where((record) =>
            record.status != AttendanceStatus.off &&
            record.status != AttendanceStatus.holiday &&
            record.status != AttendanceStatus.leave)
        .map((record) => record.copyWith(
              status: AttendanceStatus.present,
              checkIn: record.checkIn,
              checkOut: record.checkOut,
              notes: record.notes,
            ))
        .toList();
    for (final record in recordsToSave) {
      await _repository.updateAttendance(record);
    }
    ref.read(adminProvider.notifier).logAction(
      action: 'Marked all (${recordsToSave.length}) employees present for $date',
      module: 'Attendance',
    );
    await loadAttendance(date);
    await loadMonthlyAttendance(state.selectedYearMonth);
  }

  Future<void> checkInEmployee(String empId) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.attendance, PermissionAction.create) &&
        !adminState.hasPermission(AppModule.attendance, PermissionAction.edit)) {
      throw Exception('Access Denied: You do not have permission to check in employees.');
    }
    final now = DateTime.now();
    final h = now.hour;
    final m = now.minute;
    final ampm = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final timeStr =
        '${displayH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $ampm';

    final recordIdx = state.records.indexWhere((r) => r.employeeId == empId);
    if (recordIdx != -1) {
      final record = state.records[recordIdx];
      if (record.checkIn != null && record.checkIn!.trim().isNotEmpty) return;
      if (record.date != DateTime.now().toIso8601String().substring(0, 10)) return;

      final updated = state.records[recordIdx].copyWith(
        status: AttendanceStatus.present,
        checkIn: timeStr,
      );
      await updateRecord(updated);
    }
  }

  Future<void> checkOutEmployee(String empId) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.attendance, PermissionAction.edit)) {
      throw Exception('Access Denied: You do not have permission to check out employees.');
    }
    final now = DateTime.now();
    final h = now.hour;
    final m = now.minute;
    final ampm = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final timeStr =
        '${displayH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $ampm';

    final recordIdx = state.records.indexWhere((r) => r.employeeId == empId);
    if (recordIdx != -1) {
      final record = state.records[recordIdx];
      if (record.checkIn == null || record.checkIn!.trim().isEmpty) return;
      if (record.checkOut != null && record.checkOut!.trim().isNotEmpty) return;
      if (record.date != DateTime.now().toIso8601String().substring(0, 10)) return;

      final updated = state.records[recordIdx].copyWith(checkOut: timeStr);
      await updateRecord(updated);
    }
  }

  Future<void> deleteRecord(String id) async {
    final adminState = ref.read(adminProvider);
    if (!adminState.hasPermission(AppModule.attendance, PermissionAction.delete)) {
      throw Exception('Access Denied: You do not have permission to delete attendance records.');
    }
    final found = state.records.where((r) => r.id == id).firstOrNull;
    final empName = found != null ? found.employeeName : 'ID $id';
    await _repository.deleteAttendance(id);
    ref.read(adminProvider.notifier).logAction(
      action: 'Deleted attendance record of $empName',
      module: 'Attendance',
    );
    await loadAttendance(state.selectedDate);
    await loadMonthlyAttendance(state.selectedYearMonth);
  }

  // ── Monthly ──────────────────────────────────
  Future<void> loadMonthlySummary(String yearMonth) => loadMonthlyAttendance(yearMonth);

  Future<void> loadMonthlyAttendance(String yearMonth) async {
    state = state.copyWith(
      isMonthlyLoading: true,
      selectedYearMonth: yearMonth,
    );
    try {
      final logs = await _repository.getAttendanceForMonth(yearMonth);
      final employees = await _employeesRepository.getEmployees();
      final settings = ref.read(attendanceSettingsProvider).value;

      final startMinutes = settings?.workStartMinutes ?? 9 * 60;
      final graceMinutes = settings?.graceMinutes ?? 15;

      // Group logs by employeeId
      final Map<String, List<AttendanceRecord>> empLogs = {};
      for (final log in logs) {
        empLogs.putIfAbsent(log.employeeId, () => []).add(log);
      }

      final totalWorkingDays = _workingDaysInMonth(yearMonth, settings);

      final List<EmployeeMonthSummary> summaries = [];
      for (final emp in employees) {
        if (emp.status == 'Terminated') continue;
        final list = empLogs[emp.id] ?? [];

        int present = 0, absent = 0, leave = 0, halfDay = 0, workFromHome = 0, officialVisit = 0, lateCount = 0;
        double totalHours = 0.0;

        for (final r in list) {
          final s = AttendanceStatus.normalize(r.status);
          if (s == AttendanceStatus.present) {
            present++;
          } else if (s == AttendanceStatus.absent) {
            absent++;
          } else if (s == AttendanceStatus.leave) {
            leave++;
          } else if (s == AttendanceStatus.halfDay) {
            halfDay++;
          } else if (s == AttendanceStatus.workFromHome) {
            workFromHome++;
          } else if (s == AttendanceStatus.officialVisit) {
            officialVisit++;
          }

          if (r.isLate(workStartMinutes: startMinutes, graceMinutes: graceMinutes)) {
            lateCount++;
          }

          totalHours += (r.workingHours ?? 0.0);
        }

        summaries.add(
          EmployeeMonthSummary(
            employeeId: emp.id,
            employeeName: emp.name,
            workingDays: totalWorkingDays,
            presentDays: present,
            absentDays: absent,
            leaveDays: leave,
            halfDays: halfDay,
            workFromHomeDays: workFromHome,
            officialVisitDays: officialVisit,
            lateDays: lateCount,
            totalWorkingHours: totalHours,
          ),
        );
      }

      state = state.copyWith(
        monthlySummaries: summaries,
        isMonthlyLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isMonthlyLoading: false);
    }
  }

  int _workingDaysInMonth(String yearMonth, AttendanceSettings? settings) {
    final parts = yearMonth.split('-');
    if (parts.length < 2) return 22;
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final weeklyOffDays = settings?.weeklyOffDays ?? const [7];
    final holidays = settings?.holidayDates ?? const [];

    int working = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final dt = DateTime(year, month, d);
      final dateStr =
          '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      if (weeklyOffDays.contains(dt.weekday)) continue;
      if (holidays.contains(dateStr)) continue;
      working++;
    }
    return working;
  }

  // ── Date Range (Attendance List) ─────────────
  Future<void> loadAttendanceRange(
    String fromDate,
    String toDate, {
    String? employeeId,
    String? statusFilter,
  }) async {
    state = state.copyWith(isRangeLoading: true);
    try {
      final logs = await _repository.getAttendanceForDateRange(
        fromDate,
        toDate,
      );

      var filtered = logs;

      if (employeeId != null && employeeId != 'All') {
        filtered = filtered.where((r) => r.employeeId == employeeId).toList();
      }

      if (statusFilter != null && statusFilter != 'All') {
        filtered = filtered.where((r) => r.status == statusFilter).toList();
      }

      // Sort most recent first
      filtered.sort((a, b) => b.date.compareTo(a.date));

      state = state.copyWith(rangeRecords: filtered, isRangeLoading: false);
    } catch (_) {
      state = state.copyWith(isRangeLoading: false);
    }
  }
}

final attendanceProvider =
    NotifierProvider<AttendanceNotifier, AttendanceState>(() {
      return AttendanceNotifier();
    });
