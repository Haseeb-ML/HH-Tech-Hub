import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/core/widgets/explain_tooltip.dart';
import 'package:software_house_erp/features/hr/shared/widgets/hr_sub_nav.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import '../providers/attendance_provider.dart';
import '../../domain/entities/attendance_record.dart';
import '../../../employees/presentation/providers/employees_provider.dart';
import '../../../employees/presentation/providers/departments_provider.dart';
import '../../../../../core/widgets/export_button.dart';

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
    final tr = ref.watch(translationProvider);

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
                            tr('Attendance'),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('Track daily check-in/out and view monthly attendance summaries.'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
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
                    tabs: [
                      Tab(text: '📅  ${tr('Daily Attendance')}'),
                      Tab(text: '📊  ${tr('Monthly Summary')}'),
                      Tab(text: '📋  ${tr('Attendance')}'),
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
                  onMonthChanged: (m) {
                    setState(() => _selectedMonth = m);
                    ref.read(attendanceProvider.notifier).loadMonthlyAttendance(m, force: true);
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
class _DailyView extends ConsumerStatefulWidget {

  final String Function(String) displayDate;
  final String Function(int) monthName;

  const _DailyView({required this.displayDate, required this.monthName});

  @override
  ConsumerState<_DailyView> createState() => _DailyViewState();
}

class _DailyViewState extends ConsumerState<_DailyView> {
  String _searchQuery = '';
  String _selectedDepartment = 'All';
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceProvider);
    final employeesState = ref.watch(employeesProvider);
    final allSavedDepts = ref.watch(departmentsProvider);
    final settings = ref.watch(attendanceSettingsProvider).value;
    final theme = Theme.of(context);

    final startMinutes = settings?.workStartMinutes ?? 9 * 60;
    final graceMinutes = settings?.graceMinutes ?? 15;

    final departments = {
      'All',
      ...allSavedDepts,
      ...employeesState.employees.map((e) => e.department).where((d) => d.trim().isNotEmpty),
    }.toList();

    // Filter records
    final filteredRecords = state.records.where((r) {
      final emp = employeesState.employees.where((e) => e.id == r.employeeId).firstOrNull;
      final dept = emp?.department ?? '';
      final desig = emp?.designation ?? '';

      if (_selectedDepartment != 'All' && dept.toLowerCase() != _selectedDepartment.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesName = r.employeeName.toLowerCase().contains(q);
        final matchesDept = dept.toLowerCase().contains(q);
        final matchesDesig = desig.toLowerCase().contains(q);
        final matchesNotes = (r.notes ?? '').toLowerCase().contains(q);
        if (!matchesName && !matchesDept && !matchesDesig && !matchesNotes) {
          return false;
        }
      }
      return true;
    }).toList();

    final int lateCount = state.records.where((r) => r.isLate(workStartMinutes: startMinutes, graceMinutes: graceMinutes)).length;

    return state.isLoading && state.records.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width < 600 ? 14 : 24,
              0,
              MediaQuery.of(context).size.width < 600 ? 14 : 24,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Date Selector ──────────────────────
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 750;
                    final dateNavRow = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          tooltip: 'Previous Day',
                          onPressed: () {
                            final cur = DateTime.tryParse(state.selectedDate) ?? DateTime.now();
                            final prev = cur.subtract(const Duration(days: 1));
                            final dateStr = prev.toIso8601String().substring(0, 10);
                            ref.read(attendanceProvider.notifier).loadAttendance(dateStr);
                          },
                        ),
                        Text(
                          widget.displayDate(state.selectedDate),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          tooltip: 'Next Day',
                          onPressed: () {
                            final cur = DateTime.tryParse(state.selectedDate) ?? DateTime.now();
                            final next = cur.add(const Duration(days: 1));
                            final dateStr = next.toIso8601String().substring(0, 10);
                            ref.read(attendanceProvider.notifier).loadAttendance(dateStr);
                          },
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            final today = DateTime.now().toIso8601String().substring(0, 10);
                            ref.read(attendanceProvider.notifier).loadAttendance(today);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Today'),
                        ),
                      ],
                    );

                    final actionButtons = SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
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
                                final dateStr = picked.toIso8601String().substring(0, 10);
                                ref.read(attendanceProvider.notifier).loadAttendance(dateStr);
                              }
                            },
                            icon: Icon(Icons.calendar_today, size: 16, color: context.primaryColor),
                            label: Text(
                              'Change Date',
                              style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              backgroundColor: context.cardBg,
                            ),
                          ),
                          if (ref.watch(adminProvider).hasPermission(AppModule.attendance, PermissionAction.edit)) ...[
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: state.records.isEmpty ||
                                      state.selectedDate.compareTo(DateTime.now().toIso8601String().substring(0, 10)) > 0
                                  ? null
                                  : () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Mark All Present'),
                                          content: Text(
                                            'Mark all active employees as Present for ${state.selectedDate}?\n\n'
                                            'Note: Employees on Leave, Weekly Offs, and Holidays will NOT be overwritten.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx, false),
                                              child: Text('Cancel', style: TextStyle(color: context.textSecondary)),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(ctx, true),
                                              style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor),
                                              child: const Text('Confirm'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await ref.read(attendanceProvider.notifier).markAllPresent();
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Unmarked active employees marked Present. Leaves & Offs preserved.'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.done_all, size: 16),
                              label: const Text('Mark All Present'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final currentSettings = ref.read(attendanceSettingsProvider).value;
                                if (currentSettings == null) return;
                                final updated = await showDialog<AttendanceSettings>(
                                  context: context,
                                  builder: (_) => _AttendanceRulesDialog(settings: currentSettings),
                                );
                                if (updated != null) {
                                  await ref.read(attendanceSettingsProvider.notifier).save(updated);
                                  await ref.read(attendanceProvider.notifier).loadAttendance(state.selectedDate);
                                }
                              },
                              icon: const Icon(Icons.tune, size: 16),
                              label: const Text('Attendance Rules'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: context.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                backgroundColor: context.cardBg,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: dateNavRow,
                          ),
                          const SizedBox(height: 12),
                          actionButtons,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        dateNavRow,
                        const Spacer(),
                        actionButtons,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ── Stat Cards ─────────────────────────
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidgets = [
                      _MonthStatCard(
                        label: 'Total Active Staff',
                        tooltipMessage: 'Total registered active staff in the roster.',
                        value: state.records.length,
                        icon: Icons.people_outline,
                        color: context.primaryColor,
                        bg: context.infoLight,
                      ),
                      _MonthStatCard(
                        label: 'Present Today',
                        tooltipMessage: 'Active staff marked present today.',
                        value: state.presentCount,
                        icon: Icons.check_circle_outline,
                        color: context.success,
                        bg: context.successLight,
                      ),
                      _MonthStatCard(
                        label: 'On Leave',
                        tooltipMessage: 'Staff on approved leaves.',
                        value: state.leaveCount,
                        icon: Icons.beach_access_outlined,
                        color: context.warning,
                        bg: context.warningLight,
                      ),
                      _MonthStatCard(
                        label: 'Absent',
                        tooltipMessage: 'Unexcused absences.',
                        value: state.absentCount,
                        icon: Icons.error_outline,
                        color: context.error,
                        bg: context.errorLight,
                      ),
                      _MonthStatCard(
                        label: 'Half Day / WFH',
                        tooltipMessage: 'Staff working half day or remotely.',
                        value: state.halfDayCount + state.workFromHomeCount,
                        icon: Icons.home_work_outlined,
                        color: context.info,
                        bg: context.infoLight,
                      ),
                      _MonthStatCard(
                        label: 'Late Arrivals',
                        tooltipMessage: 'Checked in past allowed start time.',
                        value: lateCount,
                        icon: Icons.schedule_outlined,
                        color: const Color(0xFFD97706),
                        bg: const Color(0xFFFEF3C7),
                      ),
                    ];

                    if (constraints.maxWidth < 650) {
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.15,
                        physics: const NeverScrollableScrollPhysics(),
                        children: cardWidgets,
                      );
                    }
                    if (constraints.maxWidth < 1050) {
                      return GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.8,
                        physics: const NeverScrollableScrollPhysics(),
                        children: cardWidgets,
                      );
                    }
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: cardWidgets
                            .map((w) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 5),
                                    child: w,
                                  ),
                                ))
                            .toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ── Filter Bar ─────────────────────────
                LayoutBuilder(
                  builder: (context, filterConstraints) {
                    final isFilterMobile = filterConstraints.maxWidth < 600;
                    final searchWidget = TextField(
                      decoration: InputDecoration(
                        hintText: 'Search employee, department, designation...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: context.cardBg,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    );

                    final deptWidget = DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: departments.contains(_selectedDepartment) ? _selectedDepartment : 'All',
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: context.cardBg,
                      ),
                      dropdownColor: context.cardBg,
                      items: departments
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(
                                  d == 'All' ? 'All Departments' : d,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDepartment = val);
                      },
                    );

                    final searchRow = Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                          icon: Icon(
                            Icons.filter_list,
                            color: _showFilters ? context.primaryColor : context.textMuted,
                          ),
                          tooltip: 'Toggle Filters',
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: searchWidget),
                      ],
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        searchRow,
                        if (_showFilters) ...[
                          const SizedBox(height: 12),
                          if (isFilterMobile)
                            deptWidget
                          else
                            Row(
                              children: [
                                Expanded(child: deptWidget),
                                const Expanded(flex: 2, child: SizedBox()),
                              ],
                            ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ── Attendance Roster Table ─────────────
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Text(
                              'Daily Attendance Log',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                            Text(
                              'Showing ${filteredRecords.length} of ${state.records.length} staff',
                              style: TextStyle(fontSize: 12, color: context.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        filteredRecords.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Text(
                                    'No employees match the applied filter.',
                                    style: TextStyle(color: context.textSecondary),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredRecords.length,
                                separatorBuilder: (context, index) => const Divider(),
                                itemBuilder: (context, index) {
                                  return _AttendanceRow(
                                    record: filteredRecords[index],
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
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(attendanceProvider).selectedYearMonth != widget.selectedMonth ||
          ref.read(attendanceProvider).monthlySummaries.isEmpty) {
        ref.read(attendanceProvider.notifier).loadMonthlyAttendance(widget.selectedMonth);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _MonthlyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth) {
      if (ref.read(attendanceProvider).selectedYearMonth != widget.selectedMonth) {
        ref.read(attendanceProvider.notifier).loadMonthlyAttendance(widget.selectedMonth, force: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceProvider);
    final employeesState = ref.watch(employeesProvider);
    final theme = Theme.of(context);

    // Get unique departments for filter
    final allSavedDepts = ref.watch(departmentsProvider);
    final departments = {
      'All',
      ...allSavedDepts,
      ...employeesState.employees.map((e) => e.department).where((d) => d.trim().isNotEmpty),
    }.toList();

    // Filter summaries
    var filteredSummaries = state.monthlySummaries.where((s) {
      if (_searchQuery.isNotEmpty &&
          !s.employeeName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedDepartment != 'All') {
        final emp = employeesState.employees.where((e) => e.id == s.employeeId).firstOrNull;
        if (emp == null || emp.department != _selectedDepartment) {
          return false;
        }
      }
      return true;
    }).toList();

    // Aggregate totals for the filtered list
    int totalPresent = 0, totalAbsent = 0, totalLeave = 0, totalHalfDay = 0, totalWFH = 0, totalLate = 0;
    for (final s in filteredSummaries) {
      totalPresent += s.presentDays;
      totalAbsent += s.absentDays;
      totalLeave += s.leaveDays;
      totalHalfDay += s.halfDays;
      totalWFH += s.workFromHomeDays;
      totalLate += s.lateDays;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width < 600 ? 14 : 24,
        0,
        MediaQuery.of(context).size.width < 600 ? 14 : 24,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter Bar ──────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              final searchField = TextField(
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
              );

              final deptDropdown = DropdownButtonFormField<String>(
                isExpanded: true,
                value: departments.contains(_selectedDepartment)
                    ? _selectedDepartment
                    : 'All',
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: context.cardBg,
                ),
                dropdownColor: context.cardBg,
                items: departments
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(
                            d == 'All' ? 'All Departments' : d,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDepartment = val);
                },
              );

              final monthDropdown = DropdownButtonFormField<String>(
                isExpanded: true,
                value: widget.selectedMonth,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: context.cardBg,
                ),
                dropdownColor: context.cardBg,
                items: widget.monthOptions
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(
                          widget.monthLabel(m),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) widget.onMonthChanged(val);
                },
              );

              final searchRow = Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                    icon: Icon(
                      Icons.filter_list,
                      color: _showFilters ? context.primaryColor : context.textMuted,
                    ),
                    tooltip: 'Toggle Filters',
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: searchField),
                ],
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  searchRow,
                  if (_showFilters) ...[
                    const SizedBox(height: 12),
                    if (isMobile) ...[
                      deptDropdown,
                      const SizedBox(height: 8),
                      monthDropdown,
                    ] else
                      Row(
                        children: [
                          Expanded(child: deptDropdown),
                          const SizedBox(width: 12),
                          Expanded(child: monthDropdown),
                          const Expanded(flex: 2, child: SizedBox()),
                        ],
                      ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Summary Stat Cards ──────────────────
          if (!state.isMonthlyLoading) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final statWidgets = [
                  _MonthStatCard(
                    label: 'Present Days',
                    tooltipMessage: 'Total present occurrences across all employees.',
                    value: totalPresent,
                    color: context.success,
                    bg: context.successLight,
                    icon: Icons.check_circle_outline,
                  ),
                  _MonthStatCard(
                    label: 'Leave Days',
                    tooltipMessage: 'Total approved leaves this month.',
                    value: totalLeave,
                    color: context.warning,
                    bg: context.warningLight,
                    icon: Icons.beach_access_outlined,
                  ),
                  _MonthStatCard(
                    label: 'Absent Days',
                    tooltipMessage: 'Total unexcused absences.',
                    value: totalAbsent,
                    color: context.error,
                    bg: context.errorLight,
                    icon: Icons.error_outline,
                  ),
                  _MonthStatCard(
                    label: 'Half Day / WFH',
                    tooltipMessage: 'Total half days and remote work days.',
                    value: totalHalfDay + totalWFH,
                    color: context.info,
                    bg: context.infoLight,
                    icon: Icons.home_work_outlined,
                  ),
                  _MonthStatCard(
                    label: 'Late Occurrences',
                    tooltipMessage: 'Total times staff arrived past grace period.',
                    value: totalLate,
                    color: const Color(0xFFD97706),
                    bg: const Color(0xFFFEF3C7),
                    icon: Icons.schedule_outlined,
                  ),
                ];

                if (constraints.maxWidth < 650) {
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.15,
                    physics: const NeverScrollableScrollPhysics(),
                    children: statWidgets,
                  );
                }
                if (constraints.maxWidth < 950) {
                  return GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    physics: const NeverScrollableScrollPhysics(),
                    children: statWidgets,
                  );
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: statWidgets
                        .map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: w)))
                        .toList(),
                  ),
                );
              },
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
                  LayoutBuilder(
                    builder: (context, tblConstraints) {
                      final isMobile = tblConstraints.maxWidth < 650;
                      final titleCol = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Attendance Summary',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Formula: (Present + Half Day × 0.5) / Working Days × 100 • Working Days exclude Off & Holidays',
                            style: TextStyle(fontSize: 11, color: context.textSecondary),
                          ),
                        ],
                      );
                      final exportBtn = ExportButton(
                        title: 'Attendance Summary - ${widget.monthLabel(widget.selectedMonth)}',
                        fileName: 'monthly_attendance_${widget.selectedMonth}',
                        headers: const [
                          'Employee',
                          'Department',
                          'Working Days',
                          'Present',
                          'Absent',
                          'Leave',
                          'Half Day',
                          'WFH',
                          'Official Visit',
                          'Late Days',
                          'Total Hours',
                          'Attendance %',
                        ],
                        rows: filteredSummaries.map((s) {
                          final emp = employeesState.employees.where((e) => e.id == s.employeeId).firstOrNull;
                          return [
                            s.employeeName,
                            emp?.department.isNotEmpty == true ? emp!.department : 'General',
                            s.workingDays,
                            s.presentDays,
                            s.absentDays,
                            s.leaveDays,
                            s.halfDays,
                            s.workFromHomeDays,
                            s.officialVisitDays,
                            s.lateDays,
                            '${s.totalWorkingHours.toStringAsFixed(1)} hrs',
                            '${s.attendancePercent.toStringAsFixed(1)}%',
                          ];
                        }).toList(),
                      );
                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleCol,
                            const SizedBox(height: 12),
                            exportBtn,
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: titleCol),
                          const SizedBox(width: 12),
                          exportBtn,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Table Content
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
                          'No attendance records found for this period.',
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 1080,
                        child: Column(
                          children: [
                            _buildTableHeader(context, theme),
                            const Divider(),
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
          SizedBox(width: 200, child: Text('EMPLOYEE', style: headerStyle)),
          SizedBox(width: 90, child: Text('WORKING', style: headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 80, child: Text('PRESENT', style: headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 80, child: Text('ABSENT', style: headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 80, child: Text('LEAVE', style: headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 80, child: Text('HALF DAY', style: headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 70, child: Text('WFH', style: headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 70, child: Text('VISIT', style: headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 90, child: Text('LATE DAYS', style: headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 100, child: Text('HOURS', style: headerStyle, textAlign: TextAlign.center)),
          SizedBox(width: 140, child: Text('ATTENDANCE %', style: headerStyle, textAlign: TextAlign.center)),
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
    final isMobile = MediaQuery.of(context).size.width < 650;

    Widget card = GlassCard(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 10 : 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 7 : 9),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isMobile ? 18 : 20),
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value.toString(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: isMobile ? 20 : 24,
                    color: context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ],
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
class _MonthlySummaryRow extends ConsumerWidget {
  final EmployeeMonthSummary summary;

  const _MonthlySummaryRow({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pct = summary.attendancePercent;
    final employees = ref.watch(employeesProvider).employees;
    final emp = employees.where((e) => e.id == summary.employeeId).firstOrNull;
    final displayName = (emp != null && emp.name.trim().isNotEmpty)
        ? emp.name
        : (summary.employeeName.trim().isNotEmpty ? summary.employeeName : 'Unknown Employee');
    final deptName = emp != null && emp.department.isNotEmpty ? emp.department : 'General';

    Color pctColor;
    if (pct >= 85) {
      pctColor = context.success;
    } else if (pct >= 70) {
      pctColor = context.warning;
    } else {
      pctColor = context.error;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Employee name + department + avatar
          SizedBox(
            width: 200,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: context.primaryColor.withValues(alpha: 0.15),
                  child: Text(
                    displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: context.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        deptName,
                        style: TextStyle(color: context.textSecondary, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Working Days
          SizedBox(
            width: 90,
            child: Center(
              child: _DayBadge(
                value: summary.workingDays,
                color: context.primaryColor,
                bg: context.primaryColor.withValues(alpha: 0.12),
              ),
            ),
          ),

          // Present
          SizedBox(
            width: 80,
            child: Center(
              child: _DayBadge(
                value: summary.presentDays,
                color: context.success,
                bg: context.successLight,
              ),
            ),
          ),

          // Absent
          SizedBox(
            width: 80,
            child: Center(
              child: _DayBadge(
                value: summary.absentDays,
                color: context.error,
                bg: context.errorLight,
              ),
            ),
          ),

          // Leave
          SizedBox(
            width: 80,
            child: Center(
              child: _DayBadge(
                value: summary.leaveDays,
                color: context.warning,
                bg: context.warningLight,
              ),
            ),
          ),

          // Half Day
          SizedBox(
            width: 80,
            child: Center(
              child: _DayBadge(
                value: summary.halfDays,
                color: const Color(0xFFD97706),
                bg: const Color(0xFFFEF3C7),
              ),
            ),
          ),

          // WFH
          SizedBox(
            width: 70,
            child: Center(
              child: _DayBadge(
                value: summary.workFromHomeDays,
                color: context.info,
                bg: context.infoLight,
              ),
            ),
          ),

          // Official Visit
          SizedBox(
            width: 70,
            child: Center(
              child: _DayBadge(
                value: summary.officialVisitDays,
                color: const Color(0xFF8B5CF6),
                bg: const Color(0xFFEDE9FE),
              ),
            ),
          ),

          // Late Days
          SizedBox(
            width: 90,
            child: Center(
              child: _DayBadge(
                value: summary.lateDays,
                color: summary.lateDays > 0 ? const Color(0xFFD97706) : context.textSecondary,
                bg: summary.lateDays > 0 ? const Color(0xFFFEF3C7) : context.scaffoldBg,
              ),
            ),
          ),

          // Working Hours
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                '${summary.totalWorkingHours.toStringAsFixed(1)}h',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ),
          ),

          // Attendance % with progress bar
          SizedBox(
            width: 140,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: pctColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      backgroundColor: pctColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                      minHeight: 4,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value.toString(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
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
    final adminState = ref.watch(adminProvider);
    final canEdit = adminState.hasPermission(AppModule.attendance, PermissionAction.edit);
    final canCreate = adminState.hasPermission(AppModule.attendance, PermissionAction.create);
    final employees = ref.watch(employeesProvider).employees;
    final emp = employees.where((e) => e.id == record.employeeId).firstOrNull;
    final displayName = (emp != null && emp.name.trim().isNotEmpty)
        ? emp.name
        : (record.employeeName.trim().isNotEmpty ? record.employeeName : 'Unknown Employee');
    final deptName = emp != null && emp.department.isNotEmpty ? emp.department : 'General';
    final desigName = emp != null && emp.designation.isNotEmpty ? emp.designation : 'Staff';

    final settings = ref.watch(attendanceSettingsProvider).value;
    final isLate = record.isLate(
      workStartMinutes: settings?.workStartMinutes ?? (9 * 60),
      graceMinutes: settings?.graceMinutes ?? 15,
    );
    final lateMins = record.lateMinutes(
      workStartMinutes: settings?.workStartMinutes ?? (9 * 60),
      graceMinutes: settings?.graceMinutes ?? 15,
    );

    Color statusColor = context.textMuted;
    Color statusBg = context.scaffoldBg;
    if (record.status == 'Present') {
      statusColor = context.success;
      statusBg = context.successLight;
    } else if (record.status == 'Absent') {
      statusColor = context.error;
      statusBg = context.errorLight;
    } else if (record.status == 'Leave') {
      statusColor = context.warning;
      statusBg = context.warningLight;
    } else if (record.status == 'Half Day') {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
    } else if (record.status == 'Work From Home' || record.status == 'Official Visit') {
      statusColor = context.info;
      statusBg = context.infoLight;
    } else if (record.status == 'Off') {
      statusColor = Colors.grey;
      statusBg = Colors.grey.withValues(alpha: 0.15);
    } else if (record.status == 'Holiday') {
      statusColor = const Color(0xFF0D9488);
      statusBg = const Color(0xFFCCFBF1);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 850;

          final employeeInfo = Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: context.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: context.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$deptName • $desigName',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (record.notes != null && record.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          record.notes!,
                          style: TextStyle(
                            color: context.textMuted,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );

          final badgesWrap = Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  record.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Late Badge (Separated from status!)
              if (record.status == 'Present' && isLate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.alarm, size: 12, color: Color(0xFFB45309)),
                      const SizedBox(width: 4),
                      Text(
                        'Late (${lateMins}m)',
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // Working Duration Badge
              if (record.checkIn != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: record.workingHoursDisplay == 'Incomplete'
                        ? context.warningLight
                        : context.scaffoldBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: record.workingHoursDisplay == 'Incomplete'
                          ? context.warning.withValues(alpha: 0.5)
                          : context.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        record.workingHoursDisplay == 'Incomplete'
                            ? Icons.timelapse
                            : Icons.check_circle_outline,
                        size: 11,
                        color: record.workingHoursDisplay == 'Incomplete'
                            ? context.warning
                            : context.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        record.workingHoursDisplay,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: record.workingHoursDisplay == 'Incomplete'
                              ? context.warning
                              : context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

              // Times (visible on both narrow and wide views)
              if (const {'Present', 'Half Day', 'Work From Home', 'Official Visit'}.contains(record.status)) ...[
                if (record.checkIn != null)
                  _buildTimeBadge('In:', record.checkIn, context),
                if (record.checkOut != null)
                  _buildTimeBadge('Out:', record.checkOut, context),
              ],
            ],
          );

          final actionsWidget = (!canEdit && !canCreate)
              ? const SizedBox.shrink()
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canEdit) ...[
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
                      const SizedBox(width: 6),
                      PopupMenuButton<String>(
                        initialValue: record.status,
                        tooltip: 'Quick Status Change',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
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
                                Icons.arrow_drop_down,
                                size: 16,
                                color: context.primaryColor,
                              ),
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
                          PopupMenuItem(value: 'Absent', child: Text('Absent')),
                          PopupMenuItem(value: 'Half Day', child: Text('Half Day')),
                          PopupMenuItem(value: 'Leave', child: Text('Leave')),
                          PopupMenuItem(value: 'Work From Home', child: Text('Work From Home')),
                          PopupMenuItem(value: 'Official Visit', child: Text('Official Visit')),
                          PopupMenuItem(value: 'Off', child: Text('Off')),
                          PopupMenuItem(value: 'Holiday', child: Text('Holiday')),
                        ],
                        onSelected: (val) {
                          if (!canEdit) return;
                          if (val != record.status) {
                            final allowsTime = const {'Present', 'Half Day', 'Work From Home', 'Official Visit'}.contains(val);
                            final updated = record.copyWith(
                              status: val,
                              checkIn: allowsTime ? record.checkIn : null,
                              checkOut: allowsTime ? record.checkOut : null,
                            );
                            ref.read(attendanceProvider.notifier).updateRecord(updated);
                          }
                        },
                      ),
                    ],
                    if (const {'Present', 'Half Day', 'Work From Home', 'Official Visit'}.contains(record.status)) ...[
                      const SizedBox(width: 6),
                      if (record.checkIn == null && (canCreate || canEdit))
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
                      else if (record.checkOut == null && canEdit)
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
                );

          if (isNarrow) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: 200, child: employeeInfo),
                    const SizedBox(width: 12),
                    badgesWrap,
                    const SizedBox(width: 12),
                    actionsWidget,
                  ],
                ),
              ),
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: employeeInfo),
              Expanded(flex: 5, child: badgesWrap),
              actionsWidget,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeBadge(String label, String? time, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
    if (!ref.read(adminProvider).hasPermission(AppModule.attendance, PermissionAction.edit)) return;
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
    _status = AttendanceStatus.normalize(widget.record.status);
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

  String _getActorName() {
    final user = ref.read(adminProvider).currentUser;
    if (user == null) return 'Admin';
    final name = user.name.trim();
    final role = user.role.trim();
    final uname = user.username.trim();
    if (name.isNotEmpty) {
      if (role.isNotEmpty && role.toLowerCase() != name.toLowerCase()) {
        return '$name ($role)';
      }
      return name;
    }
    if (role.isNotEmpty) return role;
    if (uname.isNotEmpty) return uname;
    return 'Admin';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allowsTime = const {'Present', 'Half Day', 'Work From Home', 'Official Visit'}.contains(_status);

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Attendance Record',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.record.employeeName} • Date: ${widget.record.date}',
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Attendance Status Dropdown (9 official statuses only)
              _buildLabel('Attendance Status'),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: AttendanceStatus.values.contains(_status) ? _status : AttendanceStatus.notMarked,
                dropdownColor: context.cardBg,
                style: TextStyle(color: context.textPrimary, fontSize: 13),
                decoration: _buildInputDecoration(''),
                items: AttendanceStatus.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _status = val;
                      if (const {'Present', 'Work From Home', 'Official Visit'}.contains(val)) {
                        if (_checkInController.text.isEmpty) _checkInController.text = '10:00 AM';
                        if (_checkOutController.text.isEmpty) _checkOutController.text = '07:00 PM';
                      } else if (val == 'Half Day') {
                        if (_checkInController.text.isEmpty) _checkInController.text = '10:00 AM';
                        if (_checkOutController.text.isEmpty) _checkOutController.text = '02:30 PM';
                      } else {
                        _checkInController.clear();
                        _checkOutController.clear();
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              if (allowsTime) ...[
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
                            decoration: _buildInputDecoration('e.g. 10:00 AM').copyWith(
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
                            decoration: _buildInputDecoration('e.g. 07:00 PM').copyWith(
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
                        label: const Text('10:00 AM - 07:00 PM', style: TextStyle(fontSize: 11)),
                        backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                        side: BorderSide(color: context.primaryColor.withValues(alpha: 0.3)),
                        onPressed: () {
                          setState(() {
                            _checkInController.text = '10:00 AM';
                            _checkOutController.text = '07:00 PM';
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.schedule, size: 14, color: Colors.blueAccent),
                        label: const Text('10:15 AM - 07:10 PM', style: TextStyle(fontSize: 11)),
                        backgroundColor: context.primaryColor.withValues(alpha: 0.1),
                        side: BorderSide(color: context.primaryColor.withValues(alpha: 0.3)),
                        onPressed: () {
                          setState(() {
                            _checkInController.text = '10:15 AM';
                            _checkOutController.text = '07:10 PM';
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
                      const SizedBox(width: 6),
                      ActionChip(
                        avatar: const Icon(Icons.clear, size: 14, color: Colors.grey),
                        label: const Text('Clear Times', style: TextStyle(fontSize: 11)),
                        onPressed: () {
                          setState(() {
                            _checkInController.clear();
                            _checkOutController.clear();
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
                style: TextStyle(color: context.textPrimary, fontSize: 13),
                decoration: _buildInputDecoration(
                  'e.g. Medical emergency, Client meeting...',
                ),
              ),
              const SizedBox(height: 24),

              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      if (!ref.read(adminProvider).hasPermission(AppModule.attendance, PermissionAction.edit)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Access Denied: You do not have permission to edit attendance.')),
                        );
                        return;
                      }
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Reset Attendance Record'),
                          content: Text(
                            'Reset attendance log for "${widget.record.employeeName}" on ${widget.record.date} back to "Not Marked"?\n\n'
                            'This safely clears times while preserving employee history and preventing record loss.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('Cancel', style: TextStyle(color: context.textSecondary)),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: context.warning),
                              child: const Text('Reset Record'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        final auditNote = '[Reset on ${DateTime.now().toIso8601String().substring(0, 16).replaceAll('T', ' ')} by ${_getActorName()}]';
                        final reset = widget.record.copyWith(
                          status: AttendanceStatus.notMarked,
                          checkIn: null,
                          checkOut: null,
                          notes: auditNote,
                        );
                        await ref.read(attendanceProvider.notifier).updateRecord(reset);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Attendance reset to Not Marked for ${widget.record.employeeName}.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.restart_alt, size: 16, color: context.warning),
                    label: Text(
                      'Reset',
                      style: TextStyle(
                        color: context.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: context.textSecondary,
                    ),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (!ref.read(adminProvider).hasPermission(AppModule.attendance, PermissionAction.edit)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Access Denied: You do not have permission to edit attendance.')),
                        );
                        return;
                      }
                      String? notes = _notesController.text.trim().isNotEmpty
                          ? _notesController.text.trim()
                          : null;
                      // Append audit trail stamp
                      final nowStr = DateTime.now().toIso8601String().substring(0, 16).replaceAll('T', ' ');
                      final auditStamp = '[${_getActorName()} Edit: $nowStr]';
                      if (notes == null || notes.isEmpty) {
                        notes = auditStamp;
                      } else if (!notes.contains(nowStr)) {
                        notes = '$notes • $auditStamp';
                      }

                      final updated = widget.record.copyWith(
                        status: _status,
                        checkIn: allowsTime
                            ? (_checkInController.text.trim().isNotEmpty
                                ? _checkInController.text.trim()
                                : null)
                            : null,
                        checkOut: allowsTime
                            ? (_checkOutController.text.trim().isNotEmpty
                                ? _checkOutController.text.trim()
                                : null)
                            : null,
                        notes: notes,
                      );
                      ref.read(attendanceProvider.notifier).updateRecord(updated);
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
  String _selectedDepartment = 'All';
  String _selectedStatus = 'All';
  String _selectedMonth = 'All';
  bool _showFilters = false;

  final List<String> _months = [
    'All',
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

  @override
  void initState() {
    super.initState();
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

  void _clearFilters() {
    final now = DateTime.now();
    setState(() {
      _selectedMonth = 'All';
      _fromDate = DateTime(now.year, now.month, 1);
      _toDate = now;
      _selectedEmployeeId = 'All';
      _selectedDepartment = 'All';
      _selectedStatus = 'All';
    });
    _loadData();
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Select Date';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceProvider);
    final employeesState = ref.watch(employeesProvider);
    final settings = ref.watch(attendanceSettingsProvider).value;
    final theme = Theme.of(context);

    // Filter by department if needed
    final records = state.rangeRecords.where((r) {
      if (_selectedDepartment == 'All') return true;
      final emp = employeesState.employees.where((e) => e.id == r.employeeId).firstOrNull;
      final deptName = emp != null && emp.department.isNotEmpty ? emp.department : 'General';
      return deptName == _selectedDepartment;
    }).toList();

    // Compute stats
    int totalPresent = 0, totalAbsent = 0, totalLeave = 0, totalHalfDay = 0, totalLate = 0;
    for (final r in records) {
      if (r.status == 'Present') {
        totalPresent++;
        if (r.isLate(
          workStartMinutes: settings?.workStartMinutes ?? 540,
          graceMinutes: settings?.graceMinutes ?? 15,
        )) {
          totalLate++;
        }
      } else if (r.status == 'Absent') {
        totalAbsent++;
      } else if (r.status == 'Leave') {
        totalLeave++;
      } else if (r.status == 'Half Day') {
        totalHalfDay++;
      }
    }

    // Build department dropdown items
    final allSavedDepts = ref.watch(departmentsProvider);
    final departments = {
      'All',
      ...allSavedDepts,
      ...employeesState.employees.map((e) => e.department).where((d) => d.trim().isNotEmpty),
    }.toList();

    // Build employee dropdown items (active employees + former/deleted employees with attendance logs)
    final Map<String, String> empNameMap = {};
    for (final e in employeesState.employees) {
      empNameMap[e.id] = e.name;
    }
    for (final r in state.rangeRecords) {
      if (!empNameMap.containsKey(r.employeeId)) {
        final name = r.employeeName.isNotEmpty ? r.employeeName : 'Former Employee';
        empNameMap[r.employeeId] = name.contains('(Deleted)') ? name : '$name (Deleted)';
      }
    }
    for (final s in state.monthlySummaries) {
      if (!empNameMap.containsKey(s.employeeId)) {
        final name = s.employeeName.isNotEmpty ? s.employeeName : 'Former Employee';
        empNameMap[s.employeeId] = name.contains('(Deleted)') ? name : '$name (Deleted)';
      }
    }
    for (final log in state.records) {
      if (!empNameMap.containsKey(log.employeeId)) {
        final name = log.employeeName.isNotEmpty ? log.employeeName : 'Former Employee';
        empNameMap[log.employeeId] = name.contains('(Deleted)') ? name : '$name (Deleted)';
      }
    }

    final empItems = [
      const DropdownMenuItem(
        value: 'All',
        child: Text('All Employees', overflow: TextOverflow.ellipsis),
      ),
      ...empNameMap.entries.map(
        (entry) => DropdownMenuItem(
          value: entry.key,
          child: Text(entry.value, overflow: TextOverflow.ellipsis),
        ),
      ),
    ];

    final statusItems = [
      const DropdownMenuItem(
        value: 'All',
        child: Text('All Statuses', overflow: TextOverflow.ellipsis),
      ),
      ...AttendanceStatus.values.map(
        (s) => DropdownMenuItem(
          value: s,
          child: Text(s, overflow: TextOverflow.ellipsis),
        ),
      ),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width < 600 ? 14 : 24,
        0,
        MediaQuery.of(context).size.width < 600 ? 14 : 24,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter Bar ──────────────────
          Row(
            children: [
              Text(
                'Attendance Records',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _showFilters = !_showFilters),
                icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  color: _showFilters ? context.primaryColor : context.textMuted,
                ),
                tooltip: 'Toggle Filters',
              ),
            ],
          ),
          if (_showFilters) ...[
            const SizedBox(height: 12),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    // Month Filter Dropdown
                    SizedBox(
                      width: 150,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Month Filter',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedMonth,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: context.scaffoldBg,
                            ),
                            dropdownColor: context.cardBg,
                            items: _months
                                .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(
                                        m == 'All' ? 'All Months' : m,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedMonth = val;
                                  if (val != 'All') {
                                    final monthIndex = _months.indexOf(val);
                                    final year = DateTime.now().year;
                                    _fromDate = DateTime(year, monthIndex, 1);
                                    _toDate = DateTime(year, monthIndex + 1, 0);
                                  }
                                });
                                _loadData();
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // Department Filter
                    SizedBox(
                      width: 160,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Department',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: departments.contains(_selectedDepartment) ? _selectedDepartment : 'All',
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: context.scaffoldBg,
                            ),
                            dropdownColor: context.cardBg,
                            items: departments
                                .map((d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(
                                        d == 'All' ? 'All Depts' : d,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedDepartment = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    // Employee Dropdown
                    SizedBox(
                      width: 170,
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
                            isExpanded: true,
                            value: (empNameMap.containsKey(_selectedEmployeeId) || _selectedEmployeeId == 'All')
                                ? _selectedEmployeeId
                                : 'All',
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: context.scaffoldBg,
                            ),
                            dropdownColor: context.cardBg,
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

                    // Date Range
                    SizedBox(
                      width: 250,
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
                                      initialDate: _fromDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (d != null) {
                                      setState(() {
                                        _fromDate = d;
                                        _selectedMonth = 'All';
                                      });
                                      _loadData();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: context.border),
                                      borderRadius: BorderRadius.circular(8),
                                      color: context.scaffoldBg,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 12),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _formatDate(_fromDate),
                                            style: const TextStyle(fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text('to', style: TextStyle(fontSize: 11)),
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
                                      setState(() {
                                        _toDate = d;
                                        _selectedMonth = 'All';
                                      });
                                      _loadData();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: context.border),
                                      borderRadius: BorderRadius.circular(8),
                                      color: context.scaffoldBg,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 12),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _formatDate(_toDate),
                                            style: const TextStyle(fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
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

                    // Status
                    SizedBox(
                      width: 150,
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
                            isExpanded: true,
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: context.scaffoldBg,
                            ),
                            dropdownColor: context.cardBg,
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

                    // Actions
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.textSecondary,
                        side: BorderSide(color: context.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                      ),
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.filter_alt_off, size: 15),
                      label: const Text('Reset', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // ── Summary Stat Cards ──────────────────
          if (!state.isRangeLoading) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final statCards = [
                  _MonthStatCard(
                    label: 'Present Records',
                    tooltipMessage: 'Recorded present instances.',
                    value: totalPresent,
                    color: context.success,
                    bg: context.successLight,
                    icon: Icons.check_circle_outline,
                  ),
                  _MonthStatCard(
                    label: 'Half Day Records',
                    tooltipMessage: 'Recorded half day instances.',
                    value: totalHalfDay,
                    color: const Color(0xFFD97706),
                    bg: const Color(0xFFFEF3C7),
                    icon: Icons.timelapse_outlined,
                  ),
                  _MonthStatCard(
                    label: 'Leave Records',
                    tooltipMessage: 'Approved leave records in this date range.',
                    value: totalLeave,
                    color: context.warning,
                    bg: context.warningLight,
                    icon: Icons.beach_access_outlined,
                  ),
                  _MonthStatCard(
                    label: 'Absent Records',
                    tooltipMessage: 'Marked absences in this range.',
                    value: totalAbsent,
                    color: context.error,
                    bg: context.errorLight,
                    icon: Icons.error_outline,
                  ),
                  _MonthStatCard(
                    label: 'Late Occurrences',
                    tooltipMessage: 'Present records that arrived past grace period.',
                    value: totalLate,
                    color: Colors.deepOrange,
                    bg: Colors.deepOrange.withValues(alpha: 0.12),
                    icon: Icons.schedule_outlined,
                  ),
                ];

                if (constraints.maxWidth < 900) {
                  return GridView.count(
                    crossAxisCount: constraints.maxWidth < 600 ? 2 : 3,
                    shrinkWrap: true,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: constraints.maxWidth < 600 ? 1.15 : 1.6,
                    physics: const NeverScrollableScrollPhysics(),
                    children: statCards,
                  );
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: statCards
                        .map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: w)))
                        .toList(),
                  ),
                );
              },
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 650;
                      final titleCol = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Historical Attendance Logs',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Showing ${records.length} records • Click Edit to correct any historical log safely',
                            style: TextStyle(fontSize: 11, color: context.textSecondary),
                          ),
                        ],
                      );

                      final exportBtn = ExportButton(
                        title: 'Attendance History Logs',
                        fileName: 'attendance_logs_${_formatDate(_fromDate)}_${_formatDate(_toDate)}',
                        headers: const [
                          'Date',
                          'Employee',
                          'Department',
                          'Status',
                          'Check In',
                          'Check Out',
                          'Working Hours',
                          'Late',
                          'Late Minutes',
                          'Notes',
                        ],
                        rows: records.map((r) {
                          final emp = employeesState.employees.where((e) => e.id == r.employeeId).firstOrNull;
                          final deptName = emp != null && emp.department.isNotEmpty ? emp.department : 'General';
                          final isLate = r.isLate(
                            workStartMinutes: settings?.workStartMinutes ?? 540,
                            graceMinutes: settings?.graceMinutes ?? 15,
                          );
                          final lateMins = r.lateMinutes(
                            workStartMinutes: settings?.workStartMinutes ?? 540,
                            graceMinutes: settings?.graceMinutes ?? 15,
                          );
                          return [
                            r.date,
                            r.employeeName,
                            deptName,
                            r.status,
                            r.checkIn ?? '-',
                            r.checkOut ?? '-',
                            r.workingHoursDisplay,
                            isLate ? 'Yes' : 'No',
                            isLate ? lateMins.toString() : '0',
                            r.notes ?? '',
                          ];
                        }).toList(),
                      );

                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleCol,
                            const SizedBox(height: 12),
                            exportBtn,
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: titleCol),
                          const SizedBox(width: 12),
                          exportBtn,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Loading or rows
                  if (state.isRangeLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (records.isEmpty)
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 1060,
                        child: Column(
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: Text('DATE', style: _headerStyle(context)),
                                  ),
                                  SizedBox(
                                    width: 220,
                                    child: Text('EMPLOYEE', style: _headerStyle(context)),
                                  ),
                                  SizedBox(
                                    width: 160,
                                    child: Text('STATUS', style: _headerStyle(context)),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text('CHECK-IN', style: _headerStyle(context)),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: Text('CHECK-OUT', style: _headerStyle(context)),
                                  ),
                                  SizedBox(
                                    width: 110,
                                    child: Text('HOURS', style: _headerStyle(context)),
                                  ),
                                  SizedBox(
                                    width: 190,
                                    child: Text('NOTES', style: _headerStyle(context)),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: Text('ACTION', style: _headerStyle(context), textAlign: TextAlign.center),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: records.length,
                              separatorBuilder: (context, index) =>
                                  Divider(color: context.border.withValues(alpha: 0.5)),
                              itemBuilder: (context, index) {
                                final record = records[index];
                                final dateObj = DateTime.tryParse(record.date);
                                final dayName = dateObj != null
                                    ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dateObj.weekday - 1]
                                    : '';

                                final emp = employeesState.employees.where((e) => e.id == record.employeeId).firstOrNull;
                                final deptName = emp != null && emp.department.isNotEmpty ? emp.department : 'General';

                                final isLate = record.isLate(
                                  workStartMinutes: settings?.workStartMinutes ?? 540,
                                  graceMinutes: settings?.graceMinutes ?? 15,
                                );
                                final lateMins = record.lateMinutes(
                                  workStartMinutes: settings?.workStartMinutes ?? 540,
                                  graceMinutes: settings?.graceMinutes ?? 15,
                                );

                                Color badgeColor = context.success;
                                Color badgeBg = context.successLight;
                                if (record.status == 'Absent') {
                                  badgeColor = context.error;
                                  badgeBg = context.errorLight;
                                } else if (record.status == 'Leave') {
                                  badgeColor = context.warning;
                                  badgeBg = context.warningLight;
                                } else if (record.status == 'Half Day') {
                                  badgeColor = const Color(0xFFD97706);
                                  badgeBg = const Color(0xFFFEF3C7);
                                } else if (record.status == 'Work From Home' || record.status == 'Official Visit') {
                                  badgeColor = context.info;
                                  badgeBg = context.infoLight;
                                } else if (record.status == 'Off') {
                                  badgeColor = Colors.grey;
                                  badgeBg = Colors.grey.withValues(alpha: 0.15);
                                } else if (record.status == 'Holiday') {
                                  badgeColor = const Color(0xFF0D9488);
                                  badgeBg = const Color(0xFFCCFBF1);
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      // Date
                                      SizedBox(
                                        width: 100,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              record.date,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: context.textPrimary,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              dayName,
                                              style: TextStyle(
                                                color: context.textSecondary,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Employee
                                      SizedBox(
                                        width: 220,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              record.employeeName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: context.textPrimary,
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              deptName,
                                              style: TextStyle(
                                                color: context.textSecondary,
                                                fontSize: 10,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Status + Late Pill
                                      SizedBox(
                                        width: 160,
                                        child: Wrap(
                                          spacing: 4,
                                          runSpacing: 2,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: badgeBg,
                                                border: Border.all(
                                                  color: badgeColor.withValues(alpha: 0.3),
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                record.status,
                                                style: TextStyle(
                                                  color: badgeColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (record.status == 'Present' && isLate)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFEF3C7),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: const Color(0xFFF59E0B)),
                                                ),
                                                child: Text(
                                                  'Late (${lateMins}m)',
                                                  style: const TextStyle(
                                                    color: Color(0xFFB45309),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Check-In
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          record.checkIn ?? '--:--',
                                          style: TextStyle(
                                            color: record.checkIn != null ? context.textPrimary : context.textMuted,
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),

                                      // Check-Out
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          record.checkOut ?? '--:--',
                                          style: TextStyle(
                                            color: record.checkOut != null ? context.textPrimary : context.textMuted,
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),

                                      // Working Hours
                                      SizedBox(
                                        width: 110,
                                        child: Text(
                                          record.workingHoursDisplay,
                                          style: TextStyle(
                                            color: record.workingHoursDisplay == 'Incomplete'
                                                ? context.warning
                                                : context.textPrimary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      // Notes
                                      SizedBox(
                                        width: 190,
                                        child: Text(
                                          record.notes ?? '-',
                                          style: TextStyle(
                                            color: context.textMuted,
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      // Action
                                      SizedBox(
                                        width: 80,
                                        child: Center(
                                          child: IconButton(
                                            icon: Icon(Icons.edit, size: 16, color: context.primaryColor),
                                            tooltip: 'Edit Record',
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => _EditAttendanceDialog(record: record),
                                              );
                                            },
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
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle(BuildContext context) {
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: context.textSecondary,
      letterSpacing: 0.5,
    );
  }
}

