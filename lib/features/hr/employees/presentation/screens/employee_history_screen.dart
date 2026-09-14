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
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../attendance/domain/entities/attendance_record.dart';

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

    // Filter salary records for this employee
    final employeeSalaries = selectedEmployee != null
        ? salariesState.salaries.where((s) => s.employeeId == selectedEmployee!.id).toList()
        : <dynamic>[];

    // Calculate attendance stats
    int totalPresents = _attendanceLogs.where((l) => l.status == 'Present').length;
    int totalAbsents = _attendanceLogs.where((l) => l.status == 'Absent').length;
    int totalLeaves = _attendanceLogs.where((l) => l.status == 'Leave').length;
    int totalDays = _attendanceLogs.length;
    double attendancePercent = totalDays == 0 ? 0.0 : (totalPresents / totalDays) * 100;

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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
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
                                ),
                                if (selectedEmployee != null)
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        final path = await ExportHelper.exportEmployeeHistoryToExcel(
                                          fileName: '${selectedEmployee!.name.toLowerCase().replaceAll(' ', '_')}_history',
                                          employee: selectedEmployee,
                                          salaries: employeeSalaries.cast(),
                                          attendance: _attendanceLogs,
                                          attendanceStats: {
                                            'present': totalPresents,
                                            'absent': totalAbsents,
                                            'leave': totalLeaves,
                                            'percentage': attendancePercent,
                                          },
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
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
                                        ScaffoldMessenger.of(context).showSnackBar(
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
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Controls Panel: Employee Dropdown & Attendance Range Selector
                            GlassCard(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
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
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
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
                                          DropdownButtonFormField<String>(
                                            value: _rangeFilter,
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
                                            items: [
                                              DropdownMenuItem(value: '1 Month', child: Text(tr('Past 1 Month'))),
                                              DropdownMenuItem(value: '2 Months', child: Text(tr('Past 2 Months'))),
                                              DropdownMenuItem(value: '1 Year', child: Text(tr('Past 1 Year'))),
                                            ],
                                            onChanged: (val) {
                                              if (val != null && selectedEmployee != null) {
                                                setState(() {
                                                  _rangeFilter = val;
                                                });
                                                _loadAttendanceLogs(selectedEmployee.id, val);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (selectedEmployee != null) ...[
                              // Metrics & Stats Cards Grid
                              Row(
                                children: [
                                  Expanded(
                                    child: StatCard(
                                      title: tr('Total Salaries Drawn'),
                                      tooltipMessage: "Detailed statistics and information regarding ${tr('Total Salaries Drawn')}.",
                                      value: 'Rs. ${(totalPaidSalary / 1000).toStringAsFixed(1)}k',
                                      icon: Icons.payments_outlined,
                                      iconColor: context.success,
                                      iconBgColor: context.successLight,
                                      trendText: tr('Accumulated payments'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: StatCard(
                                      title: tr('Attendance Roster'),
                                      tooltipMessage: "Detailed statistics and information regarding ${tr('Attendance Roster')}.",
                                      value: '${attendancePercent.toStringAsFixed(1)}%',
                                      icon: Icons.done_all_outlined,
                                      iconColor: context.primaryColor,
                                      iconBgColor: context.infoLight,
                                      trendText: tr('Present / Working ratio'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: StatCard(
                                      title: tr('Days Present'),
                                      tooltipMessage: "Detailed statistics and information regarding ${tr('Days Present')}.",
                                      value: '$totalPresents',
                                      icon: Icons.check_circle_outline,
                                      iconColor: context.primaryColor,
                                      iconBgColor: context.infoLight,
                                      trendText: tr('Days on duty'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: StatCard(
                                      title: tr('Absents & Leaves'),
                                      tooltipMessage: "Detailed statistics and information regarding ${tr('Absents & Leaves')}.",
                                      value: '${totalAbsents + totalLeaves}',
                                      icon: Icons.remove_circle_outline_outlined,
                                      iconColor: context.warning,
                                      iconBgColor: context.warningLight,
                                      trendText: '$totalAbsents Absents • $totalLeaves Leaves',
                                    ),
                                  ),
                                ],
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
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                selectedEmployee.name,
                                                style: theme.textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: context.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${selectedEmployee.designation} • ${selectedEmployee.department}',
                                                style: theme.textTheme.bodyMedium?.copyWith(
                                                  color: context.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
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
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildInfoLabel(tr('Email Address')),
                                                _buildInfoValue(selectedEmployee.email),
                                                const SizedBox(height: 16),
                                                _buildInfoLabel(tr('Phone Numbers')),
                                                _buildInfoValue(selectedEmployee.phones.join(', ')),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildInfoLabel(tr('Date Joined')),
                                                _buildInfoValue(selectedEmployee.joiningDate),
                                                const SizedBox(height: 16),
                                                _buildInfoLabel(tr('Date Resigned/Left')),
                                                _buildInfoValue(selectedEmployee.leavingDate ?? tr('Presently Employed')),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildInfoLabel(tr('Base Salary')),
                                                _buildInfoValue('Rs. ${selectedEmployee.baseSalary.toStringAsFixed(0)}'),
                                                const SizedBox(height: 16),
                                                _buildInfoLabel(tr('Payment Method')),
                                                _buildInfoValue(selectedEmployee.paymentMethod),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Detailed lists
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Salary payouts table
                                  Expanded(
                                    flex: 3,
                                    child: Column(
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
                                                : Table(
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
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),

                                  // Attendance timeline logs
                                  Expanded(
                                    flex: 4,
                                    child: Column(
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
                                                          child: Table(
                                                            columnWidths: const {
                                                              0: FlexColumnWidth(2),
                                                              1: FlexColumnWidth(2),
                                                              2: FlexColumnWidth(3),
                                                              3: FlexColumnWidth(3),
                                                            },
                                                            children: [
                                                              TableRow(
                                                                decoration: BoxDecoration(
                                                                  border: Border(bottom: BorderSide(color: context.border, width: 1.5)),
                                                                ),
                                                                children: [
                                                                  _buildTableHeaderCell(tr('Date')),
                                                                  _buildTableHeaderCell(tr('Status')),
                                                                  _buildTableHeaderCell(tr('Check-In / Out')),
                                                                  _buildTableHeaderCell(tr('Notes')),
                                                                ],
                                                              ),
                                                              ..._attendanceLogs.map((att) {
                                                                return TableRow(
                                                                  decoration: BoxDecoration(
                                                                    border: Border(bottom: BorderSide(color: context.divider, width: 1)),
                                                                  ),
                                                                  children: [
                                                                    _buildTableCell(att.date),
                                                                    Padding(
                                                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                                                      child: Text(
                                                                        att.status,
                                                                        style: TextStyle(
                                                                          color: att.status == 'Present'
                                                                              ? context.success
                                                                              : att.status == 'Leave'
                                                                                  ? context.warning
                                                                                  : context.error,
                                                                          fontWeight: FontWeight.bold,
                                                                          fontSize: 12,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    _buildTableCell('${att.checkIn ?? '--'} / ${att.checkOut ?? '--'}'),
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
                                      ],
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
