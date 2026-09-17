import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/core/widgets/export_button.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:software_house_erp/features/hr/shared/widgets/hr_sub_nav.dart';
import '../providers/employees_provider.dart';
import '../providers/departments_provider.dart';
import '../../domain/entities/employee.dart';

class DepartmentsScreen extends ConsumerStatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  ConsumerState<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends ConsumerState<DepartmentsScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Ensure departments sync with current employee roster
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(departmentsProvider.notifier).syncFromEmployees();
    });
  }

  void _showAddDepartmentDialog(BuildContext context) {
    final tr = ref.read(translationProvider);
    final controller = TextEditingController();
    String? errorMessage;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: context.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.corporate_fare, color: context.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  tr('Add Department'),
                  style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Enter the name of the new department to add to the company roster:'),
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(color: context.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Android Developer, Marketing, DevOps...',
                    hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                    errorText: errorMessage,
                    filled: true,
                    fillColor: context.scaffoldBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (_) {
                    if (errorMessage != null) {
                      setDialogState(() => errorMessage = null);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isEmpty) {
                    setDialogState(() => errorMessage = 'Please enter a department name.');
                    return;
                  }

                  final existing = ref.read(departmentsProvider).any(
                    (d) => d.trim().toLowerCase() == text.toLowerCase(),
                  );
                  if (existing) {
                    setDialogState(() => errorMessage = 'This department already exists.');
                    return;
                  }

                  final added = await ref.read(departmentsProvider.notifier).addDepartment(text);
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Department "$added" created and saved successfully.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: context.success,
                      ),
                    );
                  }
                },
                child: Text(tr('Save Department')),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(translationProvider);
    final departments = ref.watch(departmentsProvider);
    final employeesState = ref.watch(employeesProvider);
    final allEmployees = employeesState.employees;

    // Filtered departments by search
    final filteredDepts = departments.where((d) {
      if (_searchQuery.isEmpty) return true;
      return d.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Map department to list of employees
    final Map<String, List<Employee>> deptEmployees = {};
    for (final dept in departments) {
      deptEmployees[dept] = allEmployees.where((e) => e.department.toLowerCase() == dept.toLowerCase()).toList();
    }

    // Calculations
    final totalDepartments = departments.length;
    final totalActiveStaff = allEmployees.where((e) => e.status == 'Active').length;

    String largestDeptName = 'None';
    int largestDeptCount = 0;
    for (final entry in deptEmployees.entries) {
      final activeInDept = entry.value.where((e) => e.status == 'Active').length;
      if (activeInDept > largestDeptCount) {
        largestDeptCount = activeInDept;
        largestDeptName = entry.key;
      }
    }

    final avgTeamSize = totalDepartments > 0 ? (totalActiveStaff / totalDepartments).toStringAsFixed(1) : '0';

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1400 ? 4 : (width >= 950 ? 3 : (width >= 650 ? 2 : 1));

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // HR Sub Navigation
          const HrSubNav(activeRoute: '/hr/departments'),

          // Screen Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Add Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('Departments Directory'),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('Manage company departments, team structures, and active headcount.'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ExportButton(
                            title: tr('Departments Directory'),
                            fileName: 'departments_directory',
                            headers: const ['Department Name', 'Total Staff', 'Active Staff', 'Members'],
                            rows: departments.map((d) {
                              final members = deptEmployees[d] ?? [];
                              final active = members.where((e) => e.status == 'Active').length;
                              final names = members.map((e) => e.name).join(', ');
                              return [d, members.length.toString(), active.toString(), names];
                            }).toList(),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showAddDepartmentDialog(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(tr('Add Department')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Metrics Cards
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: tr('Total Departments'),
                          tooltipMessage: 'Total active corporate and technical departments.',
                          value: '$totalDepartments',
                          icon: Icons.corporate_fare_outlined,
                          iconColor: context.primaryColor,
                          iconBgColor: context.infoLight,
                          trendText: tr('Company divisions'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          title: tr('Active Staff'),
                          tooltipMessage: 'Total active employees assigned across departments.',
                          value: '$totalActiveStaff',
                          icon: Icons.people_outline,
                          iconColor: context.success,
                          iconBgColor: context.successLight,
                          trendText: tr('Working personnel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          title: tr('Largest Department'),
                          tooltipMessage: 'Department with the highest number of active employees.',
                          value: largestDeptName,
                          icon: Icons.star_outline,
                          iconColor: context.warning,
                          iconBgColor: context.warningLight,
                          trendText: '$largestDeptCount active members',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          title: tr('Avg. Team Size'),
                          tooltipMessage: 'Average number of active staff per department.',
                          value: avgTeamSize,
                          icon: Icons.groups_outlined,
                          iconColor: Colors.purple,
                          iconBgColor: Colors.purple.withValues(alpha: 0.1),
                          trendText: tr('Staff per division'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search Bar
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (val) => setState(() => _searchQuery = val.trim()),
                              style: TextStyle(color: context.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: tr('Search department by name (e.g. Android Developer, Quality Assurance)...'),
                                hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                                prefixIcon: Icon(Icons.search, size: 18, color: context.textMuted),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            TextButton.icon(
                              onPressed: () => setState(() => _searchQuery = ''),
                              icon: const Icon(Icons.clear, size: 16),
                              label: Text(tr('Clear')),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Departments Grid
                  filteredDepts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              tr('No departments found.'),
                              style: TextStyle(color: context.textSecondary, fontSize: 14),
                            ),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 220,
                          ),
                          itemCount: filteredDepts.length,
                          itemBuilder: (context, index) {
                            final deptName = filteredDepts[index];
                            final members = deptEmployees[deptName] ?? [];
                            final activeMembers = members.where((e) => e.status == 'Active').toList();

                            return _DepartmentCard(
                              departmentName: deptName,
                              allMembers: members,
                              activeMembers: activeMembers,
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

class _DepartmentCard extends StatelessWidget {
  final String departmentName;
  final List<Employee> allMembers;
  final List<Employee> activeMembers;

  const _DepartmentCard({
    required this.departmentName,
    required this.allMembers,
    required this.activeMembers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Name + Headcount Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: context.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.corporate_fare, color: context.primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      departmentName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${activeMembers.length} active • ${allMembers.length} total',
                      style: TextStyle(fontSize: 11, color: context.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: activeMembers.isNotEmpty ? context.successLight : context.scaffoldBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: activeMembers.isNotEmpty ? context.success.withValues(alpha: 0.3) : context.border,
                  ),
                ),
                child: Text(
                  '${allMembers.length} Staff',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: activeMembers.isNotEmpty ? context.success : context.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Team Members Preview
          Text(
            'Assigned Personnel:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.textSecondary),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: allMembers.isEmpty
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'No employees assigned yet.',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: context.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: allMembers.length > 3 ? 3 : allMembers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, idx) {
                      final emp = allMembers[idx];
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: context.primaryColor.withValues(alpha: 0.15),
                            child: Text(
                              emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: context.primaryColor),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              emp.name,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            emp.designation,
                            style: TextStyle(fontSize: 10, color: context.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          if (allMembers.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${allMembers.length - 3} more staff members',
                style: TextStyle(fontSize: 10, color: context.primaryColor, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }
}
