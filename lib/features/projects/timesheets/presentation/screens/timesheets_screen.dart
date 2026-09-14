import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/projects/shared/widgets/projects_sub_nav.dart';
import '../providers/timesheets_provider.dart';
import '../../domain/entities/timesheet_entry.dart';
import '../../../projects/presentation/providers/projects_provider.dart';
import '../../../../hr/employees/presentation/providers/employees_provider.dart';

class TimesheetsScreen extends ConsumerWidget {
  const TimesheetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    debugPrint('TimesheetsScreen: build method called');
    final state = ref.watch(timesheetsProvider);
    final projects = ref.watch(projectsProvider).projects;
    final employees = ref.watch(employeesProvider).employees;
    final theme = Theme.of(context);

    // Calculate metrics
    final totalHours = state.entries.fold<double>(0, (sum, e) => sum + e.hours);
    final billableHours = state.entries
        .where((e) => e.status == 'Approved')
        .fold<double>(0, (sum, e) => sum + e.hours);
    final pendingApprovals = state.entries.where((e) => e.status == 'Pending').length;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: state.isLoading && state.entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const ProjectsSubNav(activeRoute: '/projects/timesheets'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Add Button Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Employee Timesheets',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Track billable hours, project tasks logging, and approve team timesheets.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await showDialog<TimesheetEntry>(
                                  context: context,
                                  builder: (context) => const _AddEditTimesheetDialog(),
                                );
                                if (result != null) {
                                  ref.read(timesheetsProvider.notifier).addTimesheet(result);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Time logged successfully and is pending approval.'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: context.success,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Log Time'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Metrics Cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final gridCrossCount = constraints.maxWidth >= 1200 ? 3 : (constraints.maxWidth >= 600 ? 2 : 1);
                            return GridView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridCrossCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: gridCrossCount == 3 ? 1.8 : 2.5,
                              ),
                              children: [
                                StatCard(
                                  title: 'Total Hours Logged',
                                  tooltipMessage: 'Detailed statistics and information regarding Total Hours Logged.',
                                  value: '${totalHours.toStringAsFixed(1)} hrs',
                                  icon: Icons.access_time,
                                  iconColor: context.primaryColor,
                                  iconBgColor: context.infoLight,
                                ),
                                StatCard(
                                  title: 'Billable (Approved)',
                                  tooltipMessage: 'Detailed statistics and information regarding Billable (Approved).',
                                  value: '${billableHours.toStringAsFixed(1)} hrs',
                                  icon: Icons.check_circle_outline,
                                  iconColor: context.success,
                                  iconBgColor: context.successLight,
                                ),
                                StatCard(
                                  title: 'Pending Approvals',
                                  tooltipMessage: 'Detailed statistics and information regarding Pending Approvals.',
                                  value: '$pendingApprovals logs',
                                  icon: Icons.rate_review_outlined,
                                  iconColor: context.warning,
                                  iconBgColor: context.warningLight,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Search and Filters Bar
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Search
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: context.border, width: 1),
                                    ),
                                    child: TextField(
                                      onChanged: (val) => ref.read(timesheetsProvider.notifier).setSearchQuery(val),
                                      style: TextStyle(color: context.textPrimary),
                                      decoration: InputDecoration(
                                        hintText: tr('Search logs by employee or description...'),
                                        hintStyle: TextStyle(
                                          fontSize: 13,
                                          color: context.textMuted,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search,
                                          size: 18,
                                          color: context.textMuted,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Project Filter
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: context.border, width: 1),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: state.projectIdFilter,
                                        dropdownColor: context.cardBg,
                                        style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                        items: [
                                          const DropdownMenuItem(value: 'All', child: Text('All Projects')),
                                          ...projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            ref.read(timesheetsProvider.notifier).setProjectIdFilter(val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Employee Filter
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: context.border, width: 1),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        value: state.employeeIdFilter,
                                        dropdownColor: context.cardBg,
                                        style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                        items: [
                                          const DropdownMenuItem(value: 'All', child: Text('All Employees')),
                                          ...employees.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            ref.read(timesheetsProvider.notifier).setEmployeeIdFilter(val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Status Filter
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: context.border, width: 1),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: state.statusFilter,
                                      dropdownColor: context.cardBg,
                                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                      items: ['All', 'Pending', 'Approved', 'Rejected'].map((s) {
                                        return DropdownMenuItem<String>(
                                          value: s,
                                          child: Text('${tr("Status")}: $s'),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          ref.read(timesheetsProvider.notifier).setStatusFilter(val);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Timesheets Log Table Card
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Logged Timesheets Log',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),

                                state.filteredEntries.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(40),
                                          child: Text(
                                            'No timesheet logs found.',
                                            style: TextStyle(color: context.textSecondary),
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: state.filteredEntries.length,
                                        separatorBuilder: (context, index) => const Divider(),
                                        itemBuilder: (context, index) {
                                          final entry = state.filteredEntries[index];
                                          return _TimesheetRow(entry: entry);
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
}

class _TimesheetRow extends ConsumerWidget {
  final TimesheetEntry entry;

  const _TimesheetRow({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);

    // Status mapping
    Color statusColor = context.warning;
    Color statusBg = context.warningLight;
    if (entry.status == 'Approved') {
      statusColor = context.success;
      statusBg = context.successLight;
    } else if (entry.status == 'Rejected') {
      statusColor = context.error;
      statusBg = context.errorLight;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          return Row(
            children: [
              // Employee Name & Date
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.employeeName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Date: ${entry.date} | Project: ${entry.projectName}',
                      style: TextStyle(color: context.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Task Title & Description
              if (isWide) ...[
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.taskTitle,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        entry.description,
                        style: TextStyle(color: context.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],

              // Hours logged
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.hours.toStringAsFixed(1)} hrs',
                    style: TextStyle(
                      color: context.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Actions (Approve / Reject / Edit / Delete)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: context.textSecondary),
                color: context.cardBg,
                onSelected: (val) async {
                  if (val == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Timesheet Log'),
                        content: Text('${tr("Are you sure you want to delete this timesheet log for")} "${entry.employeeName}"? ${tr("This action cannot be undone.")}'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(tr('Delete'), style: TextStyle(color: context.error)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      ref.read(timesheetsProvider.notifier).deleteTimesheet(entry.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Timesheet entry deleted.'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: context.error,
                        ),
                      );
                    }
                  } else if (val == 'approve') {
                    ref.read(timesheetsProvider.notifier).updateTimesheet(entry.copyWith(status: 'Approved'));
                  } else if (val == 'reject') {
                    ref.read(timesheetsProvider.notifier).updateTimesheet(entry.copyWith(status: 'Rejected'));
                  } else if (val == 'edit') {
                    final result = await showDialog<TimesheetEntry>(
                      context: context,
                      builder: (context) => _AddEditTimesheetDialog(entry: entry),
                    );
                    if (result != null) {
                      ref.read(timesheetsProvider.notifier).updateTimesheet(result);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Timesheet entry updated.'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: context.success,
                        ),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  if (entry.status == 'Pending') ...[
                    PopupMenuItem(
                      value: 'approve',
                      child: Text('Approve log', style: TextStyle(color: context.success, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    PopupMenuItem(
                      value: 'reject',
                      child: Text('Reject log', style: TextStyle(color: context.error, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit details', style: TextStyle(color: context.textPrimary, fontSize: 12)),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete log', style: TextStyle(color: context.error, fontSize: 12)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddEditTimesheetDialog extends ConsumerStatefulWidget {
  final TimesheetEntry? entry;
  const _AddEditTimesheetDialog({this.entry});

  @override
  ConsumerState<_AddEditTimesheetDialog> createState() => _AddEditTimesheetDialogState();
}

class _AddEditTimesheetDialogState extends ConsumerState<_AddEditTimesheetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _taskController;
  late final TextEditingController _descController;
  late final TextEditingController _hoursController;
  
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;
  String? _selectedProjectId;
  String? _selectedProjectName;
  
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController(text: widget.entry?.taskTitle ?? '');
    _descController = TextEditingController(text: widget.entry?.description ?? '');
    _hoursController = TextEditingController(text: widget.entry?.hours.toString() ?? '');
    
    if (widget.entry != null) {
      _selectedEmployeeId = widget.entry!.employeeId;
      _selectedEmployeeName = widget.entry!.employeeName;
      _selectedProjectId = widget.entry!.projectId;
      _selectedProjectName = widget.entry!.projectName;
      _date = DateTime.tryParse(widget.entry!.date) ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    _descController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Consumer(
          builder: (context, ref, child) {
            final projects = ref.watch(projectsProvider).projects;
            final employees = ref.watch(employeesProvider).employees.where((e) => e.status == 'Active').toList();

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.entry == null ? 'Log Working Hours' : 'Edit Time Entry',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          color: context.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Employee Select
                    _buildLabel(tr('Select Employee')),
                    DropdownButtonFormField<String>(
                      value: _selectedEmployeeId,
                      dropdownColor: context.cardBg,
                      style: TextStyle(color: context.textPrimary, fontSize: 13),
                      decoration: _buildInputDecoration('Choose Employee'),
                      validator: (val) => val == null ? 'Please select employee' : null,
                      items: employees.map((emp) {
                        return DropdownMenuItem(value: emp.id, child: Text(emp.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final emp = employees.firstWhere((e) => e.id == val);
                          setState(() {
                            _selectedEmployeeId = val;
                            _selectedEmployeeName = emp.name;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Project Select
                    _buildLabel('Select Project'),
                    DropdownButtonFormField<String>(
                      value: _selectedProjectId,
                      dropdownColor: context.cardBg,
                      style: TextStyle(color: context.textPrimary, fontSize: 13),
                      decoration: _buildInputDecoration('Select Project'),
                      validator: (val) => val == null ? 'Please select project' : null,
                      items: projects.map((p) {
                        return DropdownMenuItem(value: p.id, child: Text(p.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final project = projects.firstWhere((p) => p.id == val);
                          setState(() {
                            _selectedProjectId = val;
                            _selectedProjectName = project.name;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Task Title
                    _buildLabel('Task Title'),
                    TextFormField(
                      controller: _taskController,
                      style: TextStyle(color: context.textPrimary),
                      decoration: _buildInputDecoration('e.g. Design review'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter task title' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildLabel('Details / Accomplishments'),
                    TextFormField(
                      controller: _descController,
                      style: TextStyle(color: context.textPrimary),
                      maxLines: 2,
                      decoration: _buildInputDecoration('Summary of work done...'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter achievements' : null,
                    ),
                    const SizedBox(height: 16),

                    // Date & Hours Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(tr('Date')),
                              OutlinedButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _date,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setState(() => _date = picked);
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: context.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _date.toIso8601String().substring(0, 10),
                                      style: TextStyle(color: context.textPrimary, fontSize: 12),
                                    ),
                                    Icon(Icons.calendar_today, size: 14, color: context.primaryColor),
                                  ],
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
                              _buildLabel('Hours Worked'),
                              TextFormField(
                                controller: _hoursController,
                                style: TextStyle(color: context.textPrimary),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _buildInputDecoration('e.g. 4.5'),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Enter hours';
                                  final num = double.tryParse(val);
                                  if (num == null || num <= 0 || num > 24) return 'Enter hours (0-24)';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate() &&
                                _selectedEmployeeId != null &&
                                _selectedProjectId != null) {
                              final entry = TimesheetEntry(
                                id: widget.entry?.id ?? 'time_${DateTime.now().millisecondsSinceEpoch}',
                                employeeId: _selectedEmployeeId!,
                                employeeName: _selectedEmployeeName!,
                                projectId: _selectedProjectId!,
                                projectName: _selectedProjectName!,
                                taskTitle: _taskController.text.trim(),
                                description: _descController.text.trim(),
                                date: _date.toIso8601String().substring(0, 10),
                                hours: double.tryParse(_hoursController.text) ?? 0.0,
                                status: widget.entry?.status ?? 'Pending',
                              );
                              Navigator.of(context).pop(entry);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: Text(widget.entry == null ? 'Log Time' : tr('Save Changes')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
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
      fillColor: context.isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
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
