import 'package:software_house_erp/core/services/database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final int presentDays;
  final int absentDays;
  final int leaveDays;
  final int halfDays;
  final int workFromHomeDays;
  final int totalDays;

  const EmployeeMonthSummary({
    required this.employeeId,
    required this.employeeName,
    required this.presentDays,
    required this.absentDays,
    required this.leaveDays,
    required this.halfDays,
    required this.workFromHomeDays,
    required this.totalDays,
  });

  double get attendancePercent =>
      totalDays == 0 ? 0 : ((presentDays + (halfDays * 0.5)) / totalDays) * 100;
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

  int get presentCount => records.where((r) => r.status == 'Present').length;
  int get absentCount => records.where((r) => r.status == 'Absent').length;
  int get leaveCount => records.where((r) => r.status == 'Leave').length;
  int get halfDayCount => records.where((r) => r.status == 'Half Day').length;
  int get workFromHomeCount => records.where((r) => r.status == 'Work From Home').length;
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
            final defaultStatus = isHoliday
              ? 'Holiday'
              : (isWeeklyOff ? 'Off' : 'Not Marked');

            return AttendanceRecord(
              id: 'att_${emp.id}_$dateStr',
              employeeId: emp.id,
              employeeName: emp.name,
              date: dateStr,
              status: defaultStatus,
              notes: isHoliday ? 'Company Holiday' : (isWeeklyOff ? 'Weekly Off' : null),
            );
          },
        );
        updatedLogs.add(existing);
      }

      state = state.copyWith(records: updatedLogs, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateRecord(AttendanceRecord record) async {
    final normalized = record.status == 'Present' ||
            record.status == 'Half Day' ||
            record.status == 'Work From Home' ||
            record.status == 'Official Visit' ||
            record.status == 'Late'
        ? record
        : record.copyWith(checkIn: null, checkOut: null);
    await _repository.updateAttendance(normalized);
    await loadAttendance(state.selectedDate);
  }

  Future<void> markAllPresent() async {
    final date = state.selectedDate;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (date.compareTo(today) > 0) return;

    final recordsToSave = state.records
        .where((record) => record.status != 'Off')
        .map((record) => record.copyWith(
              status: 'Present',
              checkIn: record.checkIn,
              checkOut: record.checkOut,
              notes: record.notes,
            ))
        .toList();
    for (final record in recordsToSave) {
      await _repository.updateAttendance(record);
    }
    await loadAttendance(date);
  }

  Future<void> checkInEmployee(String empId) async {
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
      if (record.status != 'Present' || record.checkIn != null) return;
      if (record.date != DateTime.now().toIso8601String().substring(0, 10)) return;
      final settings = ref.read(attendanceSettingsProvider).value;
      final lateAfter = (settings?.workStartMinutes ?? 540) + (settings?.graceMinutes ?? 15);
      final currentMinutes = now.hour * 60 + now.minute;
      final updated = state.records[recordIdx].copyWith(
        status: currentMinutes > lateAfter ? 'Late' : 'Present',
        checkIn: timeStr,
      );
      await updateRecord(updated);
    }
  }

  Future<void> checkOutEmployee(String empId) async {
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
      if ((record.status != 'Present' && record.status != 'Late') || record.checkIn == null || record.checkOut != null) return;
      if (record.date != DateTime.now().toIso8601String().substring(0, 10)) return;
      final updated = state.records[recordIdx].copyWith(checkOut: timeStr);
      await updateRecord(updated);
    }
  }

  Future<void> deleteRecord(String id) async {
    await _repository.deleteAttendance(id);
    await loadAttendance(state.selectedDate);
  }

  // ── Monthly ──────────────────────────────────
  Future<void> loadMonthlyAttendance(String yearMonth) async {
    state = state.copyWith(
      isMonthlyLoading: true,
      selectedYearMonth: yearMonth,
    );
    try {
      final logs = await _repository.getAttendanceForMonth(yearMonth);
      final employees = await _employeesRepository.getEmployees();

      // Group logs by employeeId → date
      final Map<String, Map<String, String>> empDateStatus = {};
      for (final log in logs) {
        empDateStatus.putIfAbsent(log.employeeId, () => <String, String>{});
        empDateStatus[log.employeeId]![log.date] = log.status;
      }

        // Use the calendar rather than the number of saved rows. Missing logs
        // must count as unmarked working days, not shrink the denominator.
        final totalWorkingDays = _workingDaysInMonth(yearMonth);

      final List<EmployeeMonthSummary> summaries = [];
      for (final emp in employees) {
        if (emp.status == 'Terminated') continue;
        final dateMap = empDateStatus[emp.id] ?? {};
        int present = 0, absent = 0, leave = 0, halfDay = 0, workFromHome = 0;
        for (final status in dateMap.values) {
          if (status == 'Present') {
            present++;
          } else if (status == 'Absent') {
            absent++;
          } else if (status == 'Leave') {
            leave++;
          } else if (status == 'Half Day') {
            halfDay++;
          } else if (status == 'Work From Home') {
            workFromHome++;
          }
        }
        summaries.add(
          EmployeeMonthSummary(
            employeeId: emp.id,
            employeeName: emp.name,
            presentDays: present,
            absentDays: absent,
            leaveDays: leave,
            halfDays: halfDay,
            workFromHomeDays: workFromHome,
            totalDays: totalWorkingDays,
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

  int _workingDaysInMonth(String yearMonth) {
    final parts = yearMonth.split('-');
    if (parts.length < 2) return 26;
    final year = int.tryParse(parts[0]) ?? 2026;
    final month = int.tryParse(parts[1]) ?? 6;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    int working = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final wd = DateTime(year, month, d).weekday;
      if (wd != DateTime.saturday && wd != DateTime.sunday) working++;
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
