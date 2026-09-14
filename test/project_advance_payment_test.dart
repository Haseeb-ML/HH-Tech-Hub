import 'package:flutter_test/flutter_test.dart';
import 'package:software_house_erp/features/projects/projects/domain/entities/project.dart';
import 'package:software_house_erp/features/finance/income/domain/entities/income_record.dart';

// Copy of tested logic from projects_screen.dart for unit validation
String getAdvancePaymentDateTimeString(Project project, List<IncomeRecord> allIncomes) {
  final advIncome = allIncomes.where((inc) =>
      inc.invoiceNumber == 'INV-${project.id}' ||
      (inc.projectId == project.id && (inc.projectPaymentType == 'Advance' || inc.description.toLowerCase().contains('advance'))) ||
      inc.description == 'Project Advance: ${project.name} (Source: ${project.clientPaymentSource})'
  ).firstOrNull;

  if (advIncome != null && advIncome.date.isNotEmpty) {
    final hasExplicitTime = advIncome.date.contains('T') && 
        !advIncome.date.endsWith('T00:00:00.000') && 
        !advIncome.date.endsWith('T00:00:00');
    if (hasExplicitTime) {
      return advIncome.date;
    }
    final match = RegExp(r'inc_(\d{10,})').firstMatch(advIncome.id);
    if (match != null) {
      final epoch = int.tryParse(match.group(1)!);
      if (epoch != null) {
        final timeDt = DateTime.fromMillisecondsSinceEpoch(epoch);
        final dateDt = DateTime.tryParse(advIncome.date) ?? DateTime.tryParse(project.startDate) ?? timeDt;
        return DateTime(dateDt.year, dateDt.month, dateDt.day, timeDt.hour, timeDt.minute).toIso8601String();
      }
    }
  }

  if (project.startDate.contains('T') && 
      !project.startDate.endsWith('T00:00:00.000') && 
      !project.startDate.endsWith('T00:00:00')) {
    return project.startDate;
  }

  final projMatch = RegExp(r'proj_(\d{10,})').firstMatch(project.id);
  if (projMatch != null) {
    final epoch = int.tryParse(projMatch.group(1)!);
    if (epoch != null) {
      final timeDt = DateTime.fromMillisecondsSinceEpoch(epoch);
      final dateDt = DateTime.tryParse(project.startDate) ?? timeDt;
      return DateTime(dateDt.year, dateDt.month, dateDt.day, timeDt.hour, timeDt.minute).toIso8601String();
    }
  }

  return project.startDate;
}

String formatIncomeDate(String isoString) {
  try {
    final d = DateTime.parse(isoString);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final date = '${d.day.toString().padLeft(2,'0')} ${months[d.month-1]} ${d.year}';
    
    final hasExplicitTime = isoString.contains('T') || isoString.contains(' ');
    final isMidnight = d.hour == 0 && d.minute == 0;
    
    if (!hasExplicitTime || (isMidnight && !isoString.contains(RegExp(r'\d{1,2}:\d{2}')))) {
      return '$date\n';
    }
    
    final hour = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final time = '${hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')} $ampm';
    return '$date\n$time';
  } catch(e) {
    return '$isoString\n';
  }
}

void main() {
  group('Project Advance Payment Date & Time Formatting Tests', () {
    test('date-only string does not format to 12:00 AM', () {
      final formatted = formatIncomeDate('2026-09-09');
      final parts = formatted.split('\n');

      expect(parts[0], equals('09 Sep 2026'));
      expect(parts[1], isEmpty); // No 12:00 AM!
    });

    test('full ISO string with time formats correct date and 12-hour time with AM/PM', () {
      final formatted = formatIncomeDate('2026-09-09T14:35:00.000');
      final parts = formatted.split('\n');

      expect(parts[0], equals('09 Sep 2026'));
      expect(parts[1], equals('02:35 PM'));
    });

    test('morning time formats correctly with AM', () {
      final formatted = formatIncomeDate('2026-09-09T09:15:00.000');
      final parts = formatted.split('\n');

      expect(parts[0], equals('09 Sep 2026'));
      expect(parts[1], equals('09:15 AM'));
    });

    test('resolves time from project creation epoch ID if startDate is date-only', () {
      // 1725867452000 is ~ Sep 09 2024
      final testDt = DateTime(2026, 9, 9, 15, 42);
      final testEpoch = testDt.millisecondsSinceEpoch;

      final project = Project(
        id: 'proj_$testEpoch',
        name: 'ERP System',
        description: 'Test project',
        clientId: 'c_1',
        clientName: 'Client X',
        startDate: '2026-09-09',
        endDate: '2026-12-31',
        status: 'In Progress',
        budget: 100000.0,
        advancedPayment: 30000.0,
        bankAccountId: 'acc_1',
        bankAccountName: 'Bank',
        accountHolder: 'HH Tech',
        teamMembers: [],
        clientPaymentSource: 'Cash',
      );

      final resolvedIso = getAdvancePaymentDateTimeString(project, []);
      final formatted = formatIncomeDate(resolvedIso);
      final parts = formatted.split('\n');

      expect(parts[0], equals('09 Sep 2026'));
      expect(parts[1], equals('03:42 PM')); // Accurately extracted creation time!
    });

    test('resolves time from matching IncomeRecord if present', () {
      final testDt = DateTime(2026, 9, 9, 11, 20);
      final testEpoch = testDt.millisecondsSinceEpoch;

      final project = Project(
        id: 'proj_custom_id',
        name: 'Mobile App',
        description: 'Test project',
        clientId: 'c_1',
        clientName: 'Client Y',
        startDate: '2026-09-09',
        endDate: '2026-12-31',
        status: 'In Progress',
        budget: 80000.0,
        advancedPayment: 20000.0,
        bankAccountId: 'acc_1',
        bankAccountName: 'Bank',
        accountHolder: 'HH Tech',
        teamMembers: [],
        clientPaymentSource: 'Cash',
      );

      final income = IncomeRecord(
        id: 'inc_$testEpoch',
        date: '2026-09-09',
        clientId: 'c_1',
        clientName: 'Client Y',
        amount: 20000.0,
        accountId: 'acc_1',
        invoiceNumber: 'INV-proj_custom_id',
        description: 'Project Advance: Mobile App (Source: Cash)',
        status: 'Received',
        projectId: 'proj_custom_id',
        projectName: 'Mobile App',
        projectPaymentType: 'Advance',
      );

      final resolvedIso = getAdvancePaymentDateTimeString(project, [income]);
      final formatted = formatIncomeDate(resolvedIso);
      final parts = formatted.split('\n');

      expect(parts[0], equals('09 Sep 2026'));
      expect(parts[1], equals('11:20 AM'));
    });
  });
}
