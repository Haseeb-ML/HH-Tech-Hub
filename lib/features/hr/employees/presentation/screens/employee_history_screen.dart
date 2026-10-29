import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/core/utils/export_helper.dart';
import 'package:software_house_erp/features/hr/shared/widgets/hr_sub_nav.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../../employees/presentation/providers/employees_provider.dart';
import '../../../salaries/presentation/providers/salaries_provider.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../advances/presentation/providers/advances_provider.dart';

class EmployeeHistoryScreen extends ConsumerStatefulWidget {
  const EmployeeHistoryScreen({super.key});

  @override
  ConsumerState<EmployeeHistoryScreen> createState() => _EmployeeHistoryScreenState();
}

class _EmployeeHistoryScreenState extends ConsumerState<EmployeeHistoryScreen> {
  String? _selectedEmployeeId;
  String _rangeFilter = '1 Month'; // '1 Month', '2 Months', '1 Year'
  List<AttendanceRecord> _attendanceLogs = [];
  bool _isAttendanceLoading = false;

  @override
  void initState() {
    super.initState();
    // Fetch initial attendance on next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDefaultEmployee();
    });
  }

  void _initDefaultEmployee() {
    final employees = ref.read(employeesProvider).employees;
    if (employees.isNotEmpty) {
      setState(() {
        _selectedEmployeeId = employees.first.id;
      });
      _loadAttendanceLogs(employees.first.id, _rangeFilter);
    }
  }

  Future<void> _loadAttendanceLogs(String empId, String range) async {
    if (!mounted) return;
    setState(() {
      _isAttendanceLoading = true;
    });

    int monthsCount = 1;
    if (range == '2 Months') {
      monthsCount = 2;
    } else if (range == '1 Year') {
      monthsCount = 12;
    }

    final base = DateTime.now();
    List<String> months = [];
    for (int i = 0; i < monthsCount; i++) {
      DateTime dt = DateTime(base.year, base.month - i, 1);
      months.add(dt.toIso8601String().substring(0, 7)); // 'YYYY-MM'
    }

    final repo = ref.read(attendanceRepositoryProvider);
    List<AttendanceRecord> allLogs = [];
    try {
      for (String month in months) {
        final logs = await repo.getAttendanceForMonth(month);
        allLogs.addAll(logs.where((l) => l.employeeId == empId));
      }
      // Sort logs by date descending
      allLogs.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('Error loading attendance logs: $e');
    }

    if (mounted) {
      setState(() {
        _attendanceLogs = allLogs;
        _isAttendanceLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(translationProvider);
    final employeesState = ref.watch(employeesProvider);
    final salariesState = ref.watch(salariesProvider);
    final advancesState = ref.watch(advancesProvider);

    final employees = employeesState.employees;

    // Resolve active selected employee
    Employee? selectedEmployee;
    if (employees.isNotEmpty) {
      if (_selectedEmployeeId == null || !employees.any((e) => e.id == _selectedEmployeeId)) {
        selectedEmployee = employees.first;
      } else {
        selectedEmployee = employees.firstWhere((e) => e.id == _selectedEmployeeId);
      }
    }

    final emp = selectedEmployee;

    // Filter salary records for this employee
    final employeeSalaries = emp != null
        ? salariesState.salaries.where((s) => s.employeeId == emp.id).toList()
        : <dynamic>[];

    // Filter advance records for this employee
    final employeeAdvances = emp != null
        ? advancesState.advances.where((a) => a.employeeId == emp.id || a.employeeName.toLowerCase().trim() == emp.name.toLowerCase().trim()).toList()
        : <dynamic>[];

    final double empRemainingAdvance = employeeAdvances
        .where((a) => a.status == 'Approved')
        .fold<double>(0.0, (sum, a) => sum + a.remainingAmount);

    final settings = ref.watch(attendanceSettingsProvider).value;
    final workStart = settings?.workStartMinutes ?? 540;
    final grace = settings?.graceMinutes ?? 15;

    // Calculate attendance stats
    int totalPresents = _attendanceLogs.where((l) => l.status == AttendanceStatus.present).length;
    int totalHalfDays = _attendanceLogs.where((l) => l.status == AttendanceStatus.halfDay).length;
    int totalLeaves = _attendanceLogs.where((l) => l.status == AttendanceStatus.leave).length;
    int totalAbsents = _attendanceLogs.where((l) => l.status == AttendanceStatus.absent).length;
    int totalLate = _attendanceLogs.where((l) => l.status == AttendanceStatus.present && l.isLate(workStartMinutes: workStart, graceMinutes: grace)).length;
    int workingDays = _attendanceLogs.where((l) => l.status != AttendanceStatus.off && l.status != AttendanceStatus.holiday).length;
    double attendancePercent = workingDays == 0
        ? 0.0
        : (((totalPresents + (totalHalfDays * 0.5)) / workingDays) * 100).clamp(0.0, 100.0);

    double totalPaidSalary = employeeSalaries.fold<double>(0.0, (sum, s) => sum + s.netPaid);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // HR Sub Navigation
          const HrSubNav(activeRoute: '/hr/history'),
          
          Expanded(
            child: employeesState.isLoading && employees.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : employees.isEmpty
                    ? Center(child: Text(tr('No employees registered.')))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isMobile = constraints.maxWidth < 650;
                                final titleWidget = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr('Employee History & Lifecycle'),
                                      style: theme.textTheme.displaySmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: context.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tr('Trace joining/leaving dates, full salary payments, and attendance timeline.'),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: context.textSecondary,
                                      ),
                                    ),
                                  ],
                                );

                                final actionBtn = selectedEmployee == null
                                    ? const SizedBox.shrink()
                                    : ElevatedButton.icon(
                                        onPressed: () async {
                                          try {
                                            final path = await ExportHelper.exportEmployeeHistoryToExcel(
                                              fileName: '${selectedEmployee!.name.toLowerCase().replaceAll(' ', '_')}_history',
                                              employee: selectedEmployee,
                                              salaries: employeeSalaries.cast(),
                                               advances: employeeAdvances.cast(),
                                              attendance: _attendanceLogs,
                                              attendanceStats: {
                                                'present': totalPresents,
                                                'absent': totalAbsents,
                                                'leave': totalLeaves,
                                                'percentage': attendancePercent,
                                              },
                                            );
                                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(tr('Excel report exported successfully! Click to open.')),
                                                backgroundColor: context.success,
                                                behavior: SnackBarBehavior.floating,
                                                action: SnackBarAction(
                                                  label: 'OPEN',
                                                  textColor: Colors.white,
                                                  onPressed: () => ExportHelper.openFile(path),
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${tr("Failed to export Excel report:")} $e'),
                                                backgroundColor: context.error,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.download, size: 18),
                                        label: Text(tr('Export History to Excel')),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: context.success,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                      );

                                if (isMobile) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      titleWidget,
                                      if (selectedEmployee != null) ...[
                                        const SizedBox(height: 14),
                                        actionBtn,
                                      ],
                                    ],
                                  );
                                }

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(child: titleWidget),
                                    const SizedBox(width: 16),
                                    actionBtn,
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            // Controls Panel: Employee Dropdown & Attendance Range Selector
                            GlassCard(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isMobile = constraints.maxWidth < 600;

                                    final employeeSelector = Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tr('Select Employee'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: context.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        DropdownButtonFormField<String>(
                                          value: selectedEmployee?.id,
                                          dropdownColor: context.cardBg,
                                          style: TextStyle(color: context.textPrimary, fontSize: 13),
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            filled: true,
                                            fillColor: context.scaffoldBg,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: context.border),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: context.border),
                                            ),
                                          ),
                                          items: employees.map((emp) {
                                            final statusText = emp.status == 'Terminated' ? ' (Terminated)' : '';
                                            return DropdownMenuItem(
                                              value: emp.id,
                                              child: Text('${emp.name}$statusText'),
                                            );
                                          }).toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                _selectedEmployeeId = val;
                                              });
                                              _loadAttendanceLogs(val, _rangeFilter);
                                            }
                                          },
                                        ),
                                      ],
                                    );

                                    final rangeSelector = Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tr('Attendance Timeline Filter'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: context.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            {'val': '1 Month', 'label': tr('Past 1 Month')},
                                            {'val': '2 Months', 'label': tr('Past 2 Months')},
                                            {'val': '1 Year', 'label': tr('Past 1 Year')},
                                          ].map((opt) {
                                            final isSelected = _rangeFilter == opt['val'];
                                            return ChoiceChip(
                                              label: Text(
                                                opt['label']!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  color: isSelected ? Colors.white : context.textPrimary,
                                                ),
                                              ),
                                              selected: isSelected,
                                              selectedColor: context.primaryColor,
                                              backgroundColor: context.scaffoldBg,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                side: BorderSide(
                                                  color: isSelected ? context.primaryColor : context.border,
                                                ),
                                              ),
                                              onSelected: (selected) {
                                                if (selected && selectedEmployee != null) {
                                                  setState(() {
                                                    _rangeFilter = opt['val']!;
                                                  });
                                                  _loadAttendanceLogs(selectedEmployee.id, opt['val']!);
                                                }
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    );

                                    if (isMobile) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          employeeSelector,
                                          const SizedBox(height: 14),
                                          rangeSelector,
                                        ],
                                      );
                                    }

                                    return Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: employeeSelector,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          flex: 2,
                                          child: rangeSelector,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (selectedEmployee != null) ...[
                              // Metrics & Stats Cards Grid
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final crossCount = constraints.maxWidth >= 1000 ? 4 : 2;
                                  return GridView.count(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: crossCount,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: crossCount == 4 ? 1.8 : (constraints.maxWidth < 600 ? 0.85 : 2.0),
                                    children: [
                                      StatCard(
                                        title: tr('Total Salaries Drawn'),
                                        tooltipMessage: "Detailed statistics and information regarding ${tr('Total Salaries Drawn')}.",
                                        value: 'Rs. ${(totalPaidSalary / 1000).toStringAsFixed(1)}k',
                                        icon: Icons.payments_outlined,
                                        iconColor: context.success,
                                        iconBgColor: context.successLight,
                                        trendText: tr('Accumulated payments'),
                                      ),
                                      StatCard(
                                        title: tr('Attendance Roster'),
                                        tooltipMessage: "Detailed statistics and information regarding ${tr('Attendance Roster')}.",
                                        value: '${attendancePercent.toStringAsFixed(1)}%',
                                        icon: Icons.done_all_outlined,
                                        iconColor: context.primaryColor,
                                        iconBgColor: context.infoLight,
                                        trendText: tr('Present / Working ratio'),
                                      ),
                                      StatCard(
                                        title: tr('Days Present'),
                                        tooltipMessage: "Detailed statistics and information regarding ${tr('Days Present')}.",
                                        value: '$totalPresents',
                                        icon: Icons.check_circle_outline,
                                        iconColor: context.primaryColor,
                                        iconBgColor: context.infoLight,
                                        trendText: totalLate > 0 ? '$totalLate Late arrivals' : tr('Days on duty'),
                                      ),
                                      StatCard(
                                        title: tr('Absents & Leaves'),
                                        tooltipMessage: "Detailed statistics and information regarding ${tr('Absents & Leaves')}.",
                                        value: '${totalAbsents + totalLeaves}',
                                        icon: Icons.remove_circle_outline_outlined,
                                        iconColor: context.warning,
                                        iconBgColor: context.warningLight,
                                        trendText: '$totalAbsents Absents • $totalLeaves Leaves${totalHalfDays > 0 ? " • $totalHalfDays Half" : ""}',
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 24),

                              // Employee Details Card
                              Text(
                                tr('Employee Profile Summary'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GlassCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  selectedEmployee.name,
                                                  style: theme.textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: context.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${selectedEmployee.designation} • ${selectedEmployee.department}',
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: context.textSecondary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: selectedEmployee.status == 'Active'
                                                  ? context.successLight
                                                  : selectedEmployee.status == 'On Leave'
                                                      ? context.warningLight
                                                      : context.errorLight,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              selectedEmployee.status,
                                              style: TextStyle(
                                                color: selectedEmployee.status == 'Active'
                                                    ? context.success
                                                    : selectedEmployee.status == 'On Leave'
                                                        ? context.warning
                                                        : context.error,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 32),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isMobile = constraints.maxWidth < 700;
                                          final emp = selectedEmployee!;

                                          final latestSalary = employeeSalaries.isNotEmpty
                                              ? (List.from(employeeSalaries)..sort((a, b) => b.paymentDate.compareTo(a.paymentDate))).first
                                              : null;
                                          final latestPaymentMethod = (latestSalary != null && latestSalary.paymentMethod.trim().isNotEmpty)
                                              ? latestSalary.paymentMethod.trim()
                                              : (emp.paymentMethod.trim().isNotEmpty ? emp.paymentMethod.trim() : 'N/A (No Payment Issued)');

                                          final emailPhoneSection = Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildInfoLabel(tr('Email Address')),
                                              _buildInfoValue(emp.email),
                                              const SizedBox(height: 16),
                                              _buildInfoLabel(tr('CNIC Number')),
                                              _buildInfoValue(emp.cnic.trim().isNotEmpty ? emp.cnic.trim() : 'N/A'),
                                              const SizedBox(height: 16),
                                              _buildInfoLabel(tr('Phone Numbers')),
                                              const SizedBox(height: 4),
                                              if (emp.phones.isEmpty)
                                                _buildInfoValue('No Phone')
                                              else
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: emp.phones.map((p) {
                                                    String category = 'Phone';
                                                    String number = p;
                                                    if (p.contains(':')) {
                                                      final parts = p.split(':');
                                                      category = parts[0].trim();
                                                      number = parts.sublist(1).join(':').trim();
                                                    }
                                                    return Padding(
                                                      padding: const EdgeInsets.only(bottom: 4),
                                                      child: Text.rich(
                                                        TextSpan(
                                                          children: [
                                                            TextSpan(
                                                              text: '$category: ',
                                                              style: TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                color: context.textPrimary,
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                            TextSpan(
                                                              text: number,
                                                              style: TextStyle(
                                                                color: context.textSecondary,
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                            ],
                                          );

                                          final dateSection = Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildInfoLabel(tr('Date Joined')),
                                              _buildInfoValue(emp.joiningDate),
                                              const SizedBox(height: 16),
                                              _buildInfoLabel(tr('Date Resigned/Left')),
                                              _buildInfoValue(emp.leavingDate ?? tr('Presently Employed')),
                                            ],
                                          );

                                          final salarySection = Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildInfoLabel(tr('Base Salary')),
                                              _buildInfoValue('Rs. ${emp.baseSalary.toStringAsFixed(0)}'),
                                              const SizedBox(height: 16),
                                              _buildInfoLabel(tr('Payment Method')),
                                              _buildInfoValue(latestPaymentMethod),
                                              const SizedBox(height: 16),
                                              _buildInfoLabel(tr('Active Salary Advance')),
                                              _buildInfoValue(empRemainingAdvance > 0
                                                  ? 'Rs. ${empRemainingAdvance.toStringAsFixed(0)}'
                                                  : tr('No Active Advance')),
                                            ],
                                          );

                                          if (isMobile) {
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                emailPhoneSection,
                                                const SizedBox(height: 16),
                                                dateSection,
                                                const SizedBox(height: 16),
                                                salarySection,
                                              ],
                                            );
                                          }

                                          return Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(child: emailPhoneSection),
                                              const SizedBox(width: 16),
                                              Expanded(child: dateSection),
                                              const SizedBox(width: 16),
                                              Expanded(child: salarySection),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Detailed lists
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isStacked = constraints.maxWidth < 900;

                                  final salaryPaymentsWidget = Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tr('Salary Payments Log'),
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      GlassCard(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: employeeSalaries.isEmpty
                                              ? Padding(
                                                  padding: const EdgeInsets.all(24),
                                                  child: Center(
                                                    child: Text(tr('No salary payments registered for this employee.')),
                                                  ),
                                                )
                                              : SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: ConstrainedBox(
                                                    constraints: const BoxConstraints(minWidth: 460),
                                                    child: Table(
                                                      columnWidths: const {
                                                        0: FlexColumnWidth(2),
                                                        1: FlexColumnWidth(2),
                                                        2: FlexColumnWidth(2),
                                                        3: FlexColumnWidth(2),
                                                      },
                                                      children: [
                                                        TableRow(
                                                          decoration: BoxDecoration(
                                                            border: Border(bottom: BorderSide(color: context.border, width: 1.5)),
                                                          ),
                                                          children: [
                                                            _buildTableHeaderCell(tr('Period')),
                                                            _buildTableHeaderCell(tr('Base Salary')),
                                                            _buildTableHeaderCell(tr('Net Paid')),
                                                            _buildTableHeaderCell(tr('Date Paid')),
                                                          ],
                                                        ),
                                                        ...employeeSalaries.map((sal) {
                                                          return TableRow(
                                                            decoration: BoxDecoration(
                                                              border: Border(bottom: BorderSide(color: context.divider, width: 1)),
                                                            ),
                                                            children: [
                                                              _buildTableCell(sal.payPeriod),
                                                              _buildTableCell('Rs. ${sal.baseSalary.toStringAsFixed(0)}'),
                                                              _buildTableCell('Rs. ${sal.netPaid.toStringAsFixed(0)}'),
                                                              _buildTableCell(sal.paymentDate),
                                                            ],
                                                          );
                                                        }),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  );

                                  final attendanceHistoryWidget = Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            tr('Attendance History Log'),
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                          if (_isAttendanceLoading)
                                            const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      GlassCard(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: _isAttendanceLoading && _attendanceLogs.isEmpty
                                              ? const Padding(
                                                  padding: EdgeInsets.all(24),
                                                  child: Center(child: CircularProgressIndicator()),
                                                )
                                              : _attendanceLogs.isEmpty
                                                  ? Padding(
                                                      padding: const EdgeInsets.all(24),
                                                      child: Center(
                                                        child: Text(tr('No attendance records found for this period.')),
                                                      ),
                                                    )
                                                  : Container(
                                                      constraints: const BoxConstraints(maxHeight: 400),
                                                      child: SingleChildScrollView(
                                                        scrollDirection: Axis.vertical,
                                                        child: SingleChildScrollView(
                                                          scrollDirection: Axis.horizontal,
                                                          child: ConstrainedBox(
                                                            constraints: const BoxConstraints(minWidth: 550),
                                                            child: Table(
                                                              columnWidths: const {
                                                                0: FlexColumnWidth(2),
                                                                1: FlexColumnWidth(2.2),
                                                                2: FlexColumnWidth(2.6),
                                                                3: FlexColumnWidth(1.8),
                                                                4: FlexColumnWidth(1.4),
                                                                5: FlexColumnWidth(3),
                                                              },
                                                              children: [
                                                                TableRow(
                                                                  decoration: BoxDecoration(
                                                                    border: Border(bottom: BorderSide(color: context.border, width: 1.5)),
                                                                  ),
                                                                  children: [
                                                                    _buildTableHeaderCell(tr('Date')),
                                                                    _buildTableHeaderCell(tr('Status')),
                                                                    _buildTableHeaderCell(tr('In / Out')),
                                                                    _buildTableHeaderCell(tr('Hours')),
                                                                    _buildTableHeaderCell(tr('Late')),
                                                                    _buildTableHeaderCell(tr('Notes')),
                                                                  ],
                                                                ),
                                                                ..._attendanceLogs.map((att) {
                                                                  final isLate = att.status == AttendanceStatus.present && att.isLate(workStartMinutes: workStart, graceMinutes: grace);
                                                                  final lateMins = att.lateMinutes(workStartMinutes: workStart, graceMinutes: grace);

                                                                  Color statusColor = context.textMuted;
                                                                  Color statusBg = context.scaffoldBg;
                                                                  if (att.status == AttendanceStatus.present) {
                                                                    statusColor = context.success;
                                                                    statusBg = context.successLight;
                                                                  } else if (att.status == AttendanceStatus.absent) {
                                                                    statusColor = context.error;
                                                                    statusBg = context.errorLight;
                                                                  } else if (att.status == AttendanceStatus.leave) {
                                                                    statusColor = context.warning;
                                                                    statusBg = context.warningLight;
                                                                  } else if (att.status == AttendanceStatus.halfDay) {
                                                                    statusColor = const Color(0xFFD97706);
                                                                    statusBg = const Color(0xFFFEF3C7);
                                                                  } else if (att.status == AttendanceStatus.workFromHome || att.status == AttendanceStatus.officialVisit) {
                                                                    statusColor = context.info;
                                                                    statusBg = context.infoLight;
                                                                  } else if (att.status == AttendanceStatus.holiday) {
                                                                    statusColor = const Color(0xFF0D9488);
                                                                    statusBg = const Color(0xFFCCFBF1);
                                                                  } else if (att.status == AttendanceStatus.off) {
                                                                    statusColor = Colors.grey;
                                                                    statusBg = Colors.grey.withValues(alpha: 0.15);
                                                                  }

                                                                  return TableRow(
                                                                    decoration: BoxDecoration(
                                                                      border: Border(bottom: BorderSide(color: context.divider, width: 1)),
                                                                    ),
                                                                    children: [
                                                                      _buildTableCell(att.date),
                                                                      Padding(
                                                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                                                        child: Align(
                                                                          alignment: Alignment.centerLeft,
                                                                          child: Container(
                                                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                                            decoration: BoxDecoration(
                                                                              color: statusBg,
                                                                              borderRadius: BorderRadius.circular(12),
                                                                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                                                            ),
                                                                            child: Text(
                                                                              att.status,
                                                                              style: TextStyle(
                                                                                color: statusColor,
                                                                                fontWeight: FontWeight.bold,
                                                                                fontSize: 10,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      _buildTableCell('${att.checkIn ?? '--'} / ${att.checkOut ?? '--'}'),
                                                                      _buildTableCell(att.workingHoursDisplay),
                                                                      Padding(
                                                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                                                        child: isLate
                                                                            ? Text(
                                                                                '${lateMins}m',
                                                                                style: const TextStyle(
                                                                                  color: Color(0xFFB45309),
                                                                                  fontWeight: FontWeight.bold,
                                                                                  fontSize: 11,
                                                                                ),
                                                                              )
                                                                            : Text(
                                                                                '-',
                                                                                style: TextStyle(color: context.textMuted, fontSize: 11),
                                                                              ),
                                                                      ),
                                                                      _buildTableCell(att.notes ?? ''),
                                                                    ],
                                                                  );
                                                                }),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                        ),
                                      ),
                                    ],
                                  );

                                  if (isStacked) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        salaryPaymentsWidget,
                                        const SizedBox(height: 24),
                                        attendanceHistoryWidget,
                                      ],
                                    );
                                  }

                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: salaryPaymentsWidget,
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        flex: 4,
                                        child: attendanceHistoryWidget,
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 24),

                              // Salary Advances History Log
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('Salary Advances Log'),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  GlassCard(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: employeeAdvances.isEmpty
                                          ? Padding(
                                              padding: const EdgeInsets.all(24),
                                              child: Center(
                                                child: Text(tr('No salary advance records found for this employee.')),
                                              ),
                                            )
                                          : SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: ConstrainedBox(
                                                constraints: const BoxConstraints(minWidth: 700),
                                                child: Table(
                                                  columnWidths: const {
                                                    0: FlexColumnWidth(1.8),
                                                    1: FlexColumnWidth(2.0),
                                                    2: FlexColumnWidth(2.0),
                                                    3: FlexColumnWidth(2.0),
                                                    4: FlexColumnWidth(1.5),
                                                    5: FlexColumnWidth(2.0),
                                                    6: FlexColumnWidth(1.8),
                                                  },
                                                  children: [
                                                    TableRow(
                                                      decoration: BoxDecoration(
                                                        border: Border(bottom: BorderSide(color: context.border, width: 1.5)),
                                                      ),
                                                      children: [
                                                        _buildTableHeaderCell(tr('Request Date')),
                                                        _buildTableHeaderCell(tr('Total Advance')),
                                                        _buildTableHeaderCell(tr('Monthly Deduction')),
                                                        _buildTableHeaderCell(tr('Status')),
                                                      ],
                                                    ),
                                                    ...employeeAdvances.map((adv) {
                                                      Color statusColor;
                                                      switch (adv.status) {
                                                        case 'Approved':
                                                          statusColor = context.success;
                                                          break;
                                                        case 'Fully Paid':
                                                          statusColor = context.info;
                                                          break;
                                                        case 'Rejected':
                                                          statusColor = context.error;
                                                          break;
                                                        default:
                                                          statusColor = context.warning;
                                                      }

                                                      return TableRow(
                                                        decoration: BoxDecoration(
                                                          border: Border(bottom: BorderSide(color: context.divider, width: 1)),
                                                        ),
                                                        children: [
                                                          _buildTableCell(adv.requestDate),
                                                          _buildTableCell('Rs. ${adv.amount.toStringAsFixed(0)}'),
                                                          _buildTableCell('Rs. ${adv.amountRepaid.toStringAsFixed(0)}'),
                                                          _buildTableCell('Rs. ${adv.remainingAmount.toStringAsFixed(0)}'),
                                                          _buildTableCell('${adv.repaymentMonths} Months'),
                                                          _buildTableCell('Rs. ${adv.monthlyDeduction.toStringAsFixed(0)}/mo'),
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                            child: Align(
                                                              alignment: Alignment.centerLeft,
                                                              child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                                decoration: BoxDecoration(
                                                                  color: statusColor.withValues(alpha: 0.1),
                                                                  borderRadius: BorderRadius.circular(10),
                                                                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                                                ),
                                                                child: Text(
                                                                  adv.status,
                                                                  style: TextStyle(
                                                                    color: statusColor,
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 11,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    }),
                                                  ],
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        color: context.textMuted,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoValue(String val) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        val,
        style: TextStyle(
          fontSize: 13,
          color: context.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: context.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: context.textPrimary,
          fontSize: 12,
        ),
      ),
    );
  }
}
