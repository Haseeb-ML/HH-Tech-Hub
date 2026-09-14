import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/core/widgets/explain_tooltip.dart';
import 'package:software_house_erp/features/hr/shared/widgets/hr_sub_nav.dart';
import '../providers/attendance_provider.dart';
import '../../domain/entities/attendance_record.dart';
import '../../../employees/presentation/providers/employees_provider.dart';
import '../../../employees/domain/entities/employee.dart';
import '../../../../../core/widgets/export_button.dart';
import '../../../../../core/utils/export_helper.dart';

// ═══════════════════════════════════════════════════════════
//  AttendanceScreen — Daily + Monthly toggle
// ═══════════════════════════════════════════════════════════
class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Available months for dropdown (last 12 months + current)
  late final List<String> _monthOptions;
  late String _selectedMonth;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Build month list: current month and 11 previous months
    final now = DateTime.now();
    _monthOptions = List.generate(12, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });
    _selectedMonth = _monthOptions.first;

    // Month option is initialized. Loading is handled by attendanceProvider.

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────
  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }

  String _monthLabel(String yearMonth) {
    final parts = yearMonth.split('-');
    if (parts.length < 2) return yearMonth;
    final m = int.tryParse(parts[1]) ?? 1;
    return '${_monthName(m)} ${parts[0]}';
  }

  String _shortMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }

  String _displayDate(String dateStr) {
    final parts = dateStr.split('-');
    return parts.length == 3
        ? '${_shortMonthName(int.parse(parts[1]))} ${parts[2]}, ${parts[0]}'
        : dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HR Sub Navigation ────────────────────
          const HrSubNav(activeRoute: '/hr/attendance'),
          // ── Page Header ───────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track daily check-in/out and view monthly attendance summaries.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!ref.watch(attendanceProvider).isRangeLoading &&
                        ref.watch(attendanceProvider).rangeRecords.isNotEmpty)
                      const _AttendanceExportWidget(),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Tab Bar ──────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: context.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: context.textSecondary,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: '📅  Daily Roster'),
                      Tab(text: '📊  Monthly Summary'),
                      Tab(text: '📋  Attendance List'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ── Tab Views ────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DailyView(
                  displayDate: _displayDate,
                  monthName: _shortMonthName,
                ),
                _MonthlyView(
                  monthOptions: _monthOptions,
                  selectedMonth: _selectedMonth,
                  monthLabel: _monthLabel,
                  onMonthChanged: (val) {
                    setState(() => _selectedMonth = val);
                    ref
                        .read(attendanceProvider.notifier)
                        .loadMonthlyAttendance(val);
                  },
                ),
                const _AttendanceListView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Daily View
// ═══════════════════════════════════════════════════════════
class _DailyView extends ConsumerWidget {
  final String Function(String) displayDate;
  final String Function(int) monthName;

  const _DailyView({required this.displayDate, required this.monthName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceProvider);
    final theme = Theme.of(context);

    return state.isLoading && state.records.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Date Selector ──────────────────────
                Row(
                  children: [
                    Text(
                      displayDate(state.selectedDate),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final parsedDate =
                            DateTime.tryParse(state.selectedDate) ??
                            DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: parsedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          final dateStr = picked.toIso8601String().substring(
                            0,
                            10,
                          );
                          ref
                              .read(attendanceProvider.notifier)
                              .loadAttendance(dateStr);
                        }
                      },
                      icon: Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: context.primaryColor,
                      ),
                      label: Text(
                        'Change Date',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        backgroundColor: context.cardBg,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: state.records.isEmpty ||
                              state.selectedDate.compareTo(
                                    DateTime.now().toIso8601String().substring(0, 10),
                                  ) >
                                  0
                          ? null
                          : () async {
                              await ref.read(attendanceProvider.notifier).markAllPresent();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All active employees marked present.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text('Mark All Present'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final settings = ref.read(attendanceSettingsProvider).value;
                        if (settings == null) return;
                        final updated = await showDialog<AttendanceSettings>(
                          context: context,
                          builder: (_) => _AttendanceRulesDialog(settings: settings),
                        );
                        if (updated != null) {
                          await ref.read(attendanceSettingsProvider.notifier).save(updated);
                          await ref.read(attendanceProvider.notifier).loadAttendance(state.selectedDate);
                        }
                      },
                      icon: const Icon(Icons.tune, size: 16),
                      label: const Text('Attendance Rules'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Stat Cards ─────────────────────────
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      return Column(
                        children: [
                          StatCard(
                            title: 'Present Today',
                            tooltipMessage:
                                'Detailed statistics and information regarding Present Today.',
                            value: state.presentCount.toString(),
                            icon: Icons.check_circle_outline,
                            iconColor: context.success,
                            iconBgColor: context.successLight,
                            trendText: 'Active staff',
                          ),
                          const SizedBox(height: 12),
                          StatCard(
                            title: 'On Leave',
                            tooltipMessage:
                                'Detailed statistics and information regarding On Leave.',
                            value: state.leaveCount.toString(),
                            icon: Icons.time_to_leave_outlined,
                            iconColor: context.warning,
                            iconBgColor: context.warningLight,
                            trendText: 'Approved absences',
                          ),
                          const SizedBox(height: 12),
                          StatCard(
                            title: 'Absent',
                            tooltipMessage:
                                'Detailed statistics and information regarding Absent.',
                            value: state.absentCount.toString(),
                            icon: Icons.error_outline,
                            iconColor: context.error,
                            iconBgColor: context.errorLight,
                            trendText: 'Unexcused absences',
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Present Today',
                            tooltipMessage:
                                'Detailed statistics and information regarding Present Today.',
                            value: state.presentCount.toString(),
                            icon: Icons.check_circle_outline,
                            iconColor: context.success,
                            iconBgColor: context.successLight,
                            trendText: 'Active staff',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            title: 'On Leave',
                            tooltipMessage:
                                'Detailed statistics and information regarding On Leave.',
                            value: state.leaveCount.toString(),
                            icon: Icons.time_to_leave_outlined,
                            iconColor: context.warning,
                            iconBgColor: context.warningLight,
                            trendText: 'Approved absences',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            title: 'Absent',
                            tooltipMessage:
                                'Detailed statistics and information regarding Absent.',
                            value: state.absentCount.toString(),
                            icon: Icons.error_outline,
                            iconColor: context.error,
                            iconBgColor: context.errorLight,
                            trendText: 'Unexcused absences',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ── Attendance Roster Table ─────────────
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Attendance Log',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        state.records.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Text(
                                    'No employees are currently logged.',
                                    style: TextStyle(
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.records.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(),
                                itemBuilder: (context, index) {
                                  return _AttendanceRow(
                                    record: state.records[index],
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}

class _AttendanceRulesDialog extends StatefulWidget {
  final AttendanceSettings settings;

  const _AttendanceRulesDialog({required this.settings});

  @override
  State<_AttendanceRulesDialog> createState() => _AttendanceRulesDialogState();
}

class _AttendanceRulesDialogState extends State<_AttendanceRulesDialog> {
  late int _startMinutes;
  late int _endMinutes;
  late int _graceMinutes;
  late Set<int> _offDays;
  late List<String> _holidays;

  @override
  void initState() {
    super.initState();
    _startMinutes = widget.settings.workStartMinutes;
    _endMinutes = widget.settings.workEndMinutes;
    _graceMinutes = widget.settings.graceMinutes;
    _offDays = widget.settings.weeklyOffDays.toSet();
    _holidays = List<String>.from(widget.settings.holidayDates);
  }

  String _formatMinutes(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> _pickTime(bool start) async {
    final current = start ? _startMinutes : _endMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked != null) {
      setState(() {
        final minutes = picked.hour * 60 + picked.minute;
        if (start) {
          _startMinutes = minutes;
        } else {
          _endMinutes = minutes;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const dayNames = <int, String>{
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };

    return AlertDialog(
      title: const Text('Attendance Rules'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Office Hours', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(true),
                      child: Text('Start: ${_formatMinutes(_startMinutes)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(false),
                      child: Text('End: ${_formatMinutes(_endMinutes)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Late grace period: $_graceMinutes minutes', style: const TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: _graceMinutes.toDouble(),
                min: 0,
                max: 60,
                divisions: 12,
                label: '$_graceMinutes min',
                onChanged: (value) => setState(() => _graceMinutes = value.round()),
              ),
              const Divider(),
              const Text('Weekly Off Days', style: TextStyle(fontWeight: FontWeight.bold)),
              ...dayNames.entries.map(
                (entry) => CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.value),
                  value: _offDays.contains(entry.key),
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _offDays.add(entry.key);
                      } else {
                        _offDays.remove(entry.key);
                      }
                    });
                  },
                ),
              ),
              const Divider(),
              const Text('Public Holidays', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ..._holidays.map(
                    (date) => Chip(
                      label: Text(date),
                      onDeleted: () => setState(() => _holidays.remove(date)),
                    ),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: const Text('Add Holiday'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: DateTime.now(),
                      );
                      if (picked != null) {
                        final date = picked.toIso8601String().substring(0, 10);
                        if (!_holidays.contains(date)) {
                          setState(() => _holidays.add(date));
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              AttendanceSettings(
                workStartMinutes: _startMinutes,
                workEndMinutes: _endMinutes,
                graceMinutes: _graceMinutes,
                weeklyOffDays: _offDays.toList()..sort(),
                holidayDates: _holidays..sort(),
              ),
            );
          },
          child: const Text('Save Rules'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Monthly View
// ═══════════════════════════════════════════════════════════
class _MonthlyView extends ConsumerStatefulWidget {
  final List<String> monthOptions;
  final String selectedMonth;
  final String Function(String) monthLabel;
  final ValueChanged<String> onMonthChanged;

  const _MonthlyView({
    required this.monthOptions,
    required this.selectedMonth,
    required this.monthLabel,
    required this.onMonthChanged,
  });

  @override
  ConsumerState<_MonthlyView> createState() => _MonthlyViewState();
}

class _MonthlyViewState extends ConsumerState<_MonthlyView> {
  String _searchQuery = '';
  String _selectedDepartment = 'All';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceProvider);
    final employeesState = ref.watch(employeesProvider);
    final theme = Theme.of(context);

    // Get unique departments for filter
    final departments = [
      'All',
      ...employeesState.employees.map((e) => e.department).toSet(),
    ];

    // Filter summaries
    var filteredSummaries = state.monthlySummaries.where((s) {
      if (_searchQuery.isNotEmpty &&
          !s.employeeName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedDepartment != 'All') {
        final emp = employeesState.employees.firstWhere(
          (e) => e.id == s.employeeId,
          orElse: () => employeesState.employees.first,
        );
        if (emp.department != _selectedDepartment && emp.id == s.employeeId)
          return false;
      }
      return true;
    }).toList();

    // Aggregate totals for the filtered list
    int totalPresent = 0, totalAbsent = 0, totalLeave = 0;
    for (final s in filteredSummaries) {
      totalPresent += s.presentDays;
      totalAbsent += s.absentDays;
      totalLeave += s.leaveDays;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter Bar ──────────────────
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by Employee Name',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: context.cardBg,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: departments.contains(_selectedDepartment)
                      ? _selectedDepartment
                      : 'All',
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: context.cardBg,
                  ),
                  items: departments
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDepartment = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: widget.selectedMonth,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: context.cardBg,
                  ),
                  items: widget.monthOptions
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(widget.monthLabel(m)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) widget.onMonthChanged(val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Summary Stat Cards ──────────────────
          if (!state.isMonthlyLoading) ...[
            Row(
              children: [
                Expanded(
                  child: _MonthStatCard(
                    label: 'Total Present Days',
                    tooltipMessage:
                        'Detailed statistics and information regarding Total Present Days.',
                    value: totalPresent,
                    color: context.success,
                    bg: context.successLight,
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MonthStatCard(
                    label: 'Total Leave Days',
                    tooltipMessage:
                        'Detailed statistics and information regarding Total Leave Days.',
                    value: totalLeave,
                    color: context.warning,
                    bg: context.warningLight,
                    icon: Icons.time_to_leave_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MonthStatCard(
                    label: 'Total Absent Days',
                    tooltipMessage:
                        'Detailed statistics and information regarding Total Absent Days.',
                    value: totalAbsent,
                    color: context.error,
                    bg: context.errorLight,
                    icon: Icons.error_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // ── Monthly Summary Table ────────────────
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Employee Attendance Summary',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Table Header
                  _buildTableHeader(context, theme),
                  const Divider(),

                  // Loading or rows
                  if (state.isMonthlyLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (filteredSummaries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No attendance records found.',
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredSummaries.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: context.border.withValues(alpha: 0.5)),
                      itemBuilder: (context, index) {
                        return _MonthlySummaryRow(
                          summary: filteredSummaries[index],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, ThemeData theme) {
    final headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: context.textSecondary,
      letterSpacing: 0.5,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('EMPLOYEE', style: headerStyle)),
          Expanded(
            flex: 1,
            child: Text(
              'PRESENT',
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'ABSENT',
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'WORKING DAYS',
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ATTENDANCE %',
              style: headerStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Monthly Stat Card
// ─────────────────────────────────────────────
class _MonthStatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color bg;
  final IconData icon;
  final String? tooltipMessage;

  const _MonthStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.icon,
    this.tooltipMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget card = GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (tooltipMessage != null) {
      return ExplainTooltip(message: tooltipMessage!, child: card);
    }
    return card;
  }
}

// ─────────────────────────────────────────────
//  Monthly Summary Row
// ─────────────────────────────────────────────
class _MonthlySummaryRow extends StatelessWidget {
  final EmployeeMonthSummary summary;

  const _MonthlySummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = summary.attendancePercent;

    Color pctColor;
    if (pct >= 90) {
      pctColor = context.success;
    } else if (pct >= 70) {
      pctColor = context.warning;
    } else {
      pctColor = context.error;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Employee name + avatar
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: context.primaryColor.withValues(alpha: 0.15),
                  child: Text(
                    summary.employeeName.isNotEmpty
                        ? summary.employeeName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: context.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    summary.employeeName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Present
          Expanded(
            flex: 1,
            child: Center(
              child: _DayBadge(
                value: summary.presentDays,
                color: context.success,
                bg: context.successLight,
              ),
            ),
          ),

          // Absent
          Expanded(
            flex: 1,
            child: Center(
              child: _DayBadge(
                value: summary.absentDays,
                color: context.error,
                bg: context.errorLight,
              ),
            ),
          ),

          // Working Days
          Expanded(
            flex: 1,
            child: Center(
              child: _DayBadge(
                value: summary.totalDays,
                color: context.primaryColor,
                bg: context.primaryColor.withOpacity(0.15),
              ),
            ),
          ),

          // Attendance % with progress bar
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: pctColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: pctColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Day Badge
// ─────────────────────────────────────────────
class _DayBadge extends StatelessWidget {
  final int value;
  final Color color;
  final Color bg;

  const _DayBadge({required this.value, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value.toString(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Attendance Row (Daily)
// ═══════════════════════════════════════════════════════════
class _AttendanceRow extends ConsumerWidget {
  final AttendanceRecord record;
  const _AttendanceRow({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    Color statusColor = context.textMuted;
    Color statusBg = context.scaffoldBg;
    if (record.status == 'Present') {
      statusColor = context.success;
      statusBg = context.successLight;
    } else if (record.status == 'Late') {
      statusColor = context.warning;
      statusBg = context.warningLight;
    } else if (record.status == 'Absent') {
      statusColor = context.error;
      statusBg = context.errorLight;
    } else if (record.status == 'Leave') {
      statusColor = context.warning;
      statusBg = context.warningLight;
    } else if (record.status == 'Half Day') {
      statusColor = context.warning;
      statusBg = context.warningLight;
    } else if (record.status == 'Work From Home' || record.status == 'Official Visit') {
      statusColor = context.info;
      statusBg = context.infoLight;
    } else if (record.status == 'Off') {
      statusColor = Colors.grey;
      statusBg = Colors.grey.withValues(alpha: 0.1);
    } else if (record.status == 'Holiday') {
      statusColor = context.info;
      statusBg = context.infoLight;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          return Row(
            children: [
              // Name
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.employeeName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    if (record.notes != null && record.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          record.notes!,
                          style: TextStyle(
                            color: context.textMuted,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Status badge and Times
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        record.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Times (wide only)
                    if (isWide) ...[
                      _buildTimeBadge(
                        'Check-In:',
                        const {'Present', 'Half Day', 'Work From Home', 'Official Visit'}
                            .contains(record.status)
                          ? record.checkIn
                          : null,
                        context,
                      ),
                      const SizedBox(width: 12),
                      _buildTimeBadge(
                        'Check-Out:',
                        const {'Present', 'Half Day', 'Work From Home', 'Official Visit'}
                            .contains(record.status)
                          ? record.checkOut
                          : null,
                        context,
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: () => _showEditDialog(context, ref),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Update'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.primaryColor,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    initialValue: record.status,
                    tooltip: 'Set Status',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: context.primaryColor.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(6),
                        color: context.primaryColor.withValues(alpha: 0.05),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_calendar,
                            size: 14,
                            color: context.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Status',
                            style: TextStyle(
                              color: context.primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'Not Marked', child: Text('Not Marked')),
                      PopupMenuItem(value: 'Present', child: Text('Present')),
                      PopupMenuItem(value: 'Late', child: Text('Late')),
                      PopupMenuItem(value: 'Leave', child: Text('Leave')),
                      PopupMenuItem(value: 'Absent', child: Text('Absent')),
                      PopupMenuItem(value: 'Half Day', child: Text('Half Day')),
                      PopupMenuItem(value: 'Work From Home', child: Text('Work From Home')),
                      PopupMenuItem(value: 'Official Visit', child: Text('Official Visit')),
                      PopupMenuItem(value: 'Holiday', child: Text('Holiday')),
                      PopupMenuItem(value: 'Off', child: Text('Off')),
                    ],
                    onSelected: (val) {
                      if (val != record.status) {
                        final updated = record.copyWith(
                          status: val,
                            checkIn: const {'Present', 'Late', 'Half Day', 'Work From Home', 'Official Visit'}.contains(val)
                              ? record.checkIn
                              : null,
                            checkOut: const {'Present', 'Late', 'Half Day', 'Work From Home', 'Official Visit'}.contains(val)
                              ? record.checkOut
                              : null,
                        );
                        ref
                            .read(attendanceProvider.notifier)
                            .updateRecord(updated);
                      }
                    },
                  ),
                  if (record.status == 'Present' || record.status == 'Late') ...[
                    const SizedBox(width: 8),
                    if (record.checkIn == null)
                      ElevatedButton(
                        onPressed: () => ref
                            .read(attendanceProvider.notifier)
                            .checkInEmployee(record.employeeId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'In',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (record.checkOut == null)
                      ElevatedButton(
                        onPressed: () => ref
                            .read(attendanceProvider.notifier)
                            .checkOutEmployee(record.employeeId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Out',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeBadge(String label, String? time, BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(color: context.textSecondary, fontSize: 11),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: context.scaffoldBg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: context.border),
          ),
          child: Text(
            time ?? '--:--',
            style: TextStyle(
              color: time != null ? context.textPrimary : context.textMuted,
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _EditAttendanceDialog(record: record),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Edit Dialog
// ═══════════════════════════════════════════════════════════
class _EditAttendanceDialog extends ConsumerStatefulWidget {
  final AttendanceRecord record;
  const _EditAttendanceDialog({required this.record});

  @override
  ConsumerState<_EditAttendanceDialog> createState() =>
      _EditAttendanceDialogState();
}

class _EditAttendanceDialogState extends ConsumerState<_EditAttendanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _status;
  late TextEditingController _checkInController;
  late TextEditingController _checkOutController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _status = widget.record.status;
    _checkInController = TextEditingController(
      text: widget.record.checkIn ?? '',
    );
    _checkOutController = TextEditingController(
      text: widget.record.checkOut ?? '',
    );
    _notesController = TextEditingController(text: widget.record.notes ?? '');
  }

  @override
  void dispose() {
    _checkInController.dispose();
    _checkOutController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatCurrentTime() {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  Future<void> _selectTime(TextEditingController controller) async {
    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.trim().split(' ');
        final timeParts = parts[0].split(':');
        int h = int.parse(timeParts[0]);
        int m = int.parse(timeParts[1]);
        if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && h < 12) h += 12;
        if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && h == 12) h = 0;
        initial = TimeOfDay(hour: h, minute: m);
      } catch (_) {}
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      setState(() {
        controller.text = '${hour.toString().padLeft(2, '0')}:$minute $period';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Attendance Record',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.record.employeeName,
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Status
              _buildLabel('Attendance Status'),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _status,
                dropdownColor: context.cardBg,
                style: TextStyle(color: context.textPrimary, fontSize: 13),
                decoration: _buildInputDecoration(''),
                items: const [
                  DropdownMenuItem(value: 'Not Marked', child: Text('Not Marked')),
                  DropdownMenuItem(value: 'Present', child: Text('Present')),
                  DropdownMenuItem(value: 'Late', child: Text('Late')),
                  DropdownMenuItem(value: 'Absent', child: Text('Absent')),
                  DropdownMenuItem(value: 'Leave', child: Text('Leave')),
                  DropdownMenuItem(value: 'Half Day', child: Text('Half Day')),
                  DropdownMenuItem(value: 'Work From Home', child: Text('Work From Home')),
                  DropdownMenuItem(value: 'Official Visit', child: Text('Official Visit')),
                  DropdownMenuItem(value: 'Holiday', child: Text('Holiday')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _status = val;
                      if (const {'Present', 'Work From Home', 'Official Visit'}.contains(val)) {
                        if (_checkInController.text.isEmpty) _checkInController.text = '09:00 AM';
                        if (_checkOutController.text.isEmpty) _checkOutController.text = '06:00 PM';
                      } else if (val == 'Half Day') {
                        if (_checkInController.text.isEmpty) _checkInController.text = '09:00 AM';
                        if (_checkOutController.text.isEmpty) _checkOutController.text = '01:30 PM';
                      } else if (val == 'Late') {
                        if (_checkInController.text.isEmpty) _checkInController.text = '09:30 AM';
                        if (_checkOutController.text.isEmpty) _checkOutController.text = '06:00 PM';
                      } else {
                        _checkInController.clear();
                        _checkOutController.clear();
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              if (const {'Present', 'Late', 'Half Day', 'Work From Home', 'Official Visit'}.contains(_status)) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Check-In Time'),
                          TextFormField(
                            controller: _checkInController,
                            readOnly: true,
                            onTap: () => _selectTime(_checkInController),
                            style: TextStyle(color: context.textPrimary, fontSize: 13),
                            decoration: _buildInputDecoration('e.g. 09:00 AM').copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(Icons.access_time, color: context.primaryColor, size: 18),
                                onPressed: () => _selectTime(_checkInController),
                                tooltip: 'Pick Check-In Time',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Check-Out Time'),
                          TextFormField(
                            controller: _checkOutController,
                            readOnly: true,
                            onTap: () => _selectTime(_checkOutController),
                            style: TextStyle(color: context.textPrimary, fontSize: 13),
                            decoration: _buildInputDecoration('e.g. 06:00 PM').copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(Icons.access_time, color: context.primaryColor, size: 18),
                                onPressed: () => _selectTime(_checkOutController),
                                tooltip: 'Pick Check-Out Time',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Quick Preset Shortcut Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.schedule, size: 14),
                        label: const Text('09:00 AM - 06:00 PM', style: TextStyle(fontSize: 11)),
                        backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                        side: BorderSide(color: context.primaryColor.withValues(alpha: 0.3)),
                        onPressed: () {
                          setState(() {
                            _checkInController.text = '09:00 AM';
                            _checkOutController.text = '06:00 PM';
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.login, size: 14, color: Colors.green),
                        label: const Text('In: Now', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setState(() {
                            _checkInController.text = _formatCurrentTime();
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.logout, size: 14, color: Colors.orange),
                        label: const Text('Out: Now', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setState(() {
                            _checkOutController.text = _formatCurrentTime();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _buildLabel('Notes / Remarks'),
              TextFormField(
                controller: _notesController,
                style: TextStyle(color: context.textPrimary),
                decoration: _buildInputDecoration(
                  'e.g. Medical leave, Late entry...',
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Attendance Log'),
                          content: Text(
                            'Are you sure you want to delete the attendance log for "${widget.record.employeeName}"? This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: context.textSecondary),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                'Delete',
                                style: TextStyle(color: context.error),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        ref
                            .read(attendanceProvider.notifier)
                            .deleteRecord(widget.record.id);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Attendance log reset for ${widget.record.employeeName}.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: context.error,
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: context.error,
                    ),
                    label: Text(
                      'Delete Log',
                      style: TextStyle(
                        color: context.error,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: context.textSecondary,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final updated = widget.record.copyWith(
                        status: _status,
                        checkIn: const {'Present', 'Half Day', 'Work From Home', 'Official Visit'}.contains(_status)
                            ? (_checkInController.text.trim().isNotEmpty
                                  ? _checkInController.text.trim()
                                  : null)
                            : null,
                        checkOut: const {'Present', 'Half Day', 'Work From Home', 'Official Visit'}.contains(_status)
                            ? (_checkOutController.text.trim().isNotEmpty
                                  ? _checkOutController.text.trim()
                                  : null)
                            : null,
                        notes: _notesController.text.trim().isNotEmpty
                            ? _notesController.text.trim()
                            : null,
                      );
                      ref
                          .read(attendanceProvider.notifier)
                          .updateRecord(updated);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: context.textSecondary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: context.isDarkMode
          ? const Color(0xFF1F2937)
          : const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.primaryColor, width: 1.5),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Attendance List View (Range Filter & Export)
// ═══════════════════════════════════════════════════════════
class _AttendanceListView extends ConsumerStatefulWidget {
  const _AttendanceListView();

  @override
  ConsumerState<_AttendanceListView> createState() =>
      _AttendanceListViewState();
}

class _AttendanceListViewState extends ConsumerState<_AttendanceListView> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String _selectedEmployeeId = 'All';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    // Default to current month to date
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    if (_fromDate == null || _toDate == null) return;

    final fromStr =
        '${_fromDate!.year}-${_fromDate!.month.toString().padLeft(2, '0')}-${_fromDate!.day.toString().padLeft(2, '0')}';
    final toStr =
        '${_toDate!.year}-${_toDate!.month.toString().padLeft(2, '0')}-${_toDate!.day.toString().padLeft(2, '0')}';

    ref
        .read(attendanceProvider.notifier)
        .loadAttendanceRange(
          fromStr,
          toStr,
          employeeId: _selectedEmployeeId,
          statusFilter: _selectedStatus,
        );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Select Date';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceProvider);
    final employeesState = ref.watch(employeesProvider);
    final theme = Theme.of(context);

    // Compute stats
    int totalPresent = 0, totalAbsent = 0, totalLeave = 0;
    for (final r in state.rangeRecords) {
      if (r.status == 'Present')
        totalPresent++;
      else if (r.status == 'Absent')
        totalAbsent++;
      else if (r.status == 'Leave')
        totalLeave++;
    }

    // Build employee dropdown items
    final empItems = [
      const DropdownMenuItem(value: 'All', child: Text('All Employees')),
      ...employeesState.employees.map(
        (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
      ),
    ];

    final statusItems = [
      const DropdownMenuItem(value: 'All', child: Text('All Statuses')),
      const DropdownMenuItem(value: 'Present', child: Text('Present')),
      const DropdownMenuItem(value: 'Late', child: Text('Late')),
      const DropdownMenuItem(value: 'Absent', child: Text('Absent')),
      const DropdownMenuItem(value: 'Leave', child: Text('Leave')),
      const DropdownMenuItem(value: 'Half Day', child: Text('Half Day')),
      const DropdownMenuItem(value: 'Work From Home', child: Text('Work From Home')),
      const DropdownMenuItem(value: 'Official Visit', child: Text('Official Visit')),
      const DropdownMenuItem(value: 'Holiday', child: Text('Holiday')),
      const DropdownMenuItem(value: 'Off', child: Text('Off')),
    ];

    // Prepare Export Data
    final headers = [
      'Date',
      'Day',
      'Employee',
      'Check-In',
      'Check-Out',
      'Total Hours',
      'Status',
    ];
    final rows = state.rangeRecords.map((r) {
      final dateObj = DateTime.tryParse(r.date);
      final dayName = dateObj != null
          ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dateObj.weekday -
                1]
          : '';

      String totalHours = '-';
      if (r.checkIn != null && r.checkOut != null) {
        // rough calculation if needed, or simply leave blank if not tracked strictly.
        // Assuming simple 9 hours for present if we don't parse strings here.
        totalHours = r.status == 'Present' ? '9h 0m' : '-';
      }

      return [
        r.date,
        dayName,
        r.employeeName,
        r.checkIn ?? '-',
        r.checkOut ?? '-',
        totalHours,
        r.status,
      ];
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter Bar ──────────────────
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Employee Dropdown
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Employee',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _selectedEmployeeId,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: context.scaffoldBg,
                              ),
                              items: empItems,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedEmployeeId = val);
                                  _loadData();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Date Range
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date Range',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final d = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            _fromDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (d != null) {
                                        setState(() => _fromDate = d);
                                        _loadData();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: context.border,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        color: context.scaffoldBg,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatDate(_fromDate),
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('to'),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final d = await showDatePicker(
                                        context: context,
                                        initialDate: _toDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (d != null) {
                                        setState(() => _toDate = d);
                                        _loadData();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: context.border,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        color: context.scaffoldBg,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatDate(_toDate),
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Status
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: context.scaffoldBg,
                              ),
                              items: statusItems,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedStatus = val);
                                  _loadData();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Summary Stat Cards ──────────────────
          if (!state.isRangeLoading) ...[
            Row(
              children: [
                Expanded(
                  child: _MonthStatCard(
                    label: 'Present Records',
                    tooltipMessage:
                        'Detailed statistics and information regarding Present Records.',
                    value: totalPresent,
                    color: context.success,
                    bg: context.successLight,
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MonthStatCard(
                    label: 'Leave Records',
                    tooltipMessage:
                        'Detailed statistics and information regarding Leave Records.',
                    value: totalLeave,
                    color: context.warning,
                    bg: context.warningLight,
                    icon: Icons.time_to_leave_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MonthStatCard(
                    label: 'Absent Records',
                    tooltipMessage:
                        'Detailed statistics and information regarding Absent Records.',
                    value: totalAbsent,
                    color: context.error,
                    bg: context.errorLight,
                    icon: Icons.error_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // ── Data Table ────────────────
          GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filtered Daily Records',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'DATE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'EMPLOYEE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'CHECK-IN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'CHECK-OUT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'STATUS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: context.textSecondary,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Loading or rows
                  if (state.isRangeLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.rangeRecords.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No attendance records found for this filter.',
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.rangeRecords.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: context.border.withValues(alpha: 0.5)),
                      itemBuilder: (context, index) {
                        final record = state.rangeRecords[index];
                        final dateObj = DateTime.tryParse(record.date);
                        final dayName = dateObj != null
                            ? [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun',
                              ][dateObj.weekday - 1]
                            : '';

                        Color badgeColor = context.success;
                        if (record.status == 'Absent')
                          badgeColor = context.error;
                        if (record.status == 'Leave')
                          badgeColor = context.warning;
                        if (record.status == 'Off') badgeColor = Colors.grey;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.date,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: context.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      dayName,
                                      style: TextStyle(
                                        color: context.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  record.employeeName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: context.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  record.checkIn ?? '-',
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  record.checkOut ?? '-',
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.1),
                                      border: Border.all(
                                        color: badgeColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      record.status,
                                      style: TextStyle(
                                        color: badgeColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------
//  Custom Attendance Export Widget
// ---------------------------------------------
class _AttendanceExportWidget extends ConsumerWidget {
  const _AttendanceExportWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
      ),
      onPressed: () async {
        final employees = ref.read(employeesProvider).employees;
        final records = ref.read(attendanceProvider).rangeRecords;

        Employee? selectedEmployee;
        bool isAll = true;

        final result = await showDialog<bool>(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  backgroundColor: Theme.of(context).cardColor,
                  title: Text(
                    'Export Attendance PDF',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Employee to generate report:',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: isAll ? 'All Employees' : selectedEmployee?.id,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                        ),
                        dropdownColor: Theme.of(context).cardColor,
                        items: [
                          const DropdownMenuItem(
                            value: 'All Employees',
                            child: Text('All Employees'),
                          ),
                          ...employees
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(e.name),
                                ),
                              )
                              .toList(),
                        ],
                        onChanged: (val) {
                          setState(() {
                            if (val == 'All Employees') {
                              isAll = true;
                              selectedEmployee = null;
                            } else {
                              isAll = false;
                              selectedEmployee = employees.firstWhere(
                                (e) => e.id == val,
                              );
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Export PDF'),
                    ),
                  ],
                );
              },
            );
          },
        );

        if (result == true) {
          final filteredRecords = selectedEmployee != null
              ? records
                    .where((r) => r.employeeId == selectedEmployee!.id)
                    .toList()
              : records;

          if (filteredRecords.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No records found for this selection.'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          try {
            final path = await ExportHelper.exportAttendanceDashboardPdf(
              records: filteredRecords,
              fileName: 'Attendance_List_${selectedEmployee?.id ?? 'All'}',
              title: 'ATTENDANCE LIST DASHBOARD',
              subtitle: 'Showing ${filteredRecords.length} records',
              employee: selectedEmployee,
            );
            ExportHelper.openFile(path);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Export failed: $e'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
      label: const Text(
        'Export Data',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
