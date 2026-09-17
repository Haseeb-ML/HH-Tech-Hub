import 'package:flutter_test/flutter_test.dart';
import 'package:software_house_erp/features/hr/attendance/domain/entities/attendance_record.dart';
import 'package:software_house_erp/features/hr/attendance/presentation/providers/attendance_provider.dart';

void main() {
  group('AttendanceStatus Tests', () {
    test('Official 9 statuses defined and normalized properly', () {
      expect(AttendanceStatus.all.length, 9);
      expect(AttendanceStatus.all, contains(AttendanceStatus.notMarked));
      expect(AttendanceStatus.all, contains(AttendanceStatus.present));
      expect(AttendanceStatus.all, contains(AttendanceStatus.absent));
      expect(AttendanceStatus.all, contains(AttendanceStatus.halfDay));
      expect(AttendanceStatus.all, contains(AttendanceStatus.leave));
      expect(AttendanceStatus.all, contains(AttendanceStatus.workFromHome));
      expect(AttendanceStatus.all, contains(AttendanceStatus.officialVisit));
      expect(AttendanceStatus.all, contains(AttendanceStatus.off));
      expect(AttendanceStatus.all, contains(AttendanceStatus.holiday));

      // Must NOT treat Late as a status; legacy 'Late' normalizes to 'Present'
      expect(AttendanceStatus.normalize('Late'), AttendanceStatus.present);
      expect(AttendanceStatus.normalize('late'), AttendanceStatus.present);
      expect(AttendanceStatus.normalize('Present'), AttendanceStatus.present);
      expect(AttendanceStatus.normalize('absent'), AttendanceStatus.absent);
      expect(AttendanceStatus.normalize('random_invalid_status'), AttendanceStatus.notMarked);
    });
  });

  group('AttendanceRecord Late & Duration Calculations', () {
    test('Late calculation against 09:00 AM start and 15m grace', () {
      const workStart = 9 * 60; // 540
      const grace = 15; // cutoff is 555 (09:15 AM)

      final onTimeRecord = AttendanceRecord(
        id: '1',
        employeeId: 'emp1',
        employeeName: 'John',
        date: '2026-03-10',
        status: AttendanceStatus.present,
        checkIn: '09:10 AM',
      );
      expect(onTimeRecord.isLate(workStartMinutes: workStart, graceMinutes: grace), isFalse);
      expect(onTimeRecord.lateMinutes(workStartMinutes: workStart, graceMinutes: grace), 0);

      final graceLimitRecord = AttendanceRecord(
        id: '2',
        employeeId: 'emp1',
        employeeName: 'John',
        date: '2026-03-10',
        status: AttendanceStatus.present,
        checkIn: '09:15 AM',
      );
      expect(graceLimitRecord.isLate(workStartMinutes: workStart, graceMinutes: grace), isFalse);
      expect(graceLimitRecord.lateMinutes(workStartMinutes: workStart, graceMinutes: grace), 0);

      final lateRecord = AttendanceRecord(
        id: '3',
        employeeId: 'emp1',
        employeeName: 'John',
        date: '2026-03-10',
        status: AttendanceStatus.present,
        checkIn: '09:30 AM',
      );
      expect(lateRecord.isLate(workStartMinutes: workStart, graceMinutes: grace), isTrue);
      expect(lateRecord.lateMinutes(workStartMinutes: workStart, graceMinutes: grace), 30);
    });

    test('Missing Check-Out shows Incomplete duration and null hours', () {
      final incompleteRecord = AttendanceRecord(
        id: '4',
        employeeId: 'emp1',
        employeeName: 'John',
        date: '2026-03-10',
        status: AttendanceStatus.present,
        checkIn: '09:00 AM',
        checkOut: null,
      );
      expect(incompleteRecord.workingHoursDisplay, 'Incomplete');
      expect(incompleteRecord.workingHours, isNull);

      final completeRecord = AttendanceRecord(
        id: '5',
        employeeId: 'emp1',
        employeeName: 'John',
        date: '2026-03-10',
        status: AttendanceStatus.present,
        checkIn: '09:00 AM',
        checkOut: '06:00 PM',
      );
      expect(completeRecord.workingHoursDisplay, '9h 00m');
      expect(completeRecord.workingHours, 9.0);
    });
  });

  group('EmployeeMonthSummary Metrics & Percentage Formula', () {
    test('Attendance percentage formula (Present + HalfDay * 0.5) / WorkingDays * 100', () {
      const summary = EmployeeMonthSummary(
        employeeId: 'emp1',
        employeeName: 'Haseeb',
        workingDays: 22,
        presentDays: 18,
        absentDays: 2,
        leaveDays: 1,
        halfDays: 1,
        workFromHomeDays: 0,
        officialVisitDays: 0,
        lateDays: 3,
        totalWorkingHours: 160.0,
      );

      // (18 + 0.5) / 22 * 100 = 18.5 / 22 * 100 = 84.0909...
      expect(summary.attendancePercent, closeTo(84.09, 0.01));
    });

    test('Zero working days handles safely without divide-by-zero error', () {
      const summary = EmployeeMonthSummary(
        employeeId: 'emp2',
        employeeName: 'Ali',
        workingDays: 0,
        presentDays: 0,
        absentDays: 0,
        leaveDays: 0,
        halfDays: 0,
        workFromHomeDays: 0,
        officialVisitDays: 0,
        lateDays: 0,
        totalWorkingHours: 0.0,
      );

      expect(summary.attendancePercent, 0.0);
    });
  });
}
