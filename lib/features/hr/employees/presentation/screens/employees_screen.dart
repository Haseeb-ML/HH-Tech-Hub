import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/core/utils/currency_formatter.dart';
import 'package:software_house_erp/features/hr/shared/widgets/hr_sub_nav.dart';
import '../providers/employees_provider.dart';
import '../providers/departments_provider.dart';
import '../../domain/entities/employee.dart';
import 'package:go_router/go_router.dart';
import 'package:software_house_erp/core/widgets/export_button.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(employeesProvider);
    final departments = ref.watch(departmentsProvider);
    final theme = Theme.of(context);
    final tr = ref.watch(translationProvider);
    final adminState = ref.watch(adminProvider);
    final canCreate = adminState.hasPermission(AppModule.employees, PermissionAction.create);
    final canExport = adminState.hasPermission(AppModule.employees, PermissionAction.export);

    // Calculate metrics
    final totalEmployees = state.employees.length;
    final activeCount = state.employees.where((e) => e.status == 'Active').length;
    final leaveCount = state.employees.where((e) => e.status == 'On Leave').length;
    final monthlyPayroll = state.employees
        .where((e) => e.status != 'Terminated')
        .fold<double>(0, (sum, e) => sum + e.baseSalary);

    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = width >= 1400 ? 4 : (width >= 950 ? 3 : (width >= 600 ? 2 : 1));

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: state.isLoading && state.employees.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── HR Sub Navigation ────────────────────
                const HrSubNav(activeRoute: '/hr/employees'),
                // ── Screen Content ───────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Title and Add Button
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 650;
                      final titleWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('Employees Directory'),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('Manage organizational chart, roles, designations, and base salaries.'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      );

                      final actionButtons = Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (canExport)
                            ExportButton(
                              title: tr('Employees Directory'),
                              fileName: 'employees_directory',
                              headers: const ['ID', 'Name', 'Email', 'Designation', 'Department', 'Status', 'Base Salary'],
                              rows: state.filteredEmployees.map((e) => [
                                e.id,
                                e.name,
                                e.email,
                                e.designation,
                                e.department,
                                e.status,
                                'Rs. ${e.baseSalary.toStringAsFixed(0)}',
                              ]).toList(),
                            ),
                          if (canCreate)
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await showDialog<Employee>(
                                  context: context,
                                  builder: (context) => const _AddEmployeeDialog(),
                                );
                                if (result != null) {
                                  ref.read(employeesProvider.notifier).addEmployee(result);
                                  ref.read(departmentsProvider.notifier).addDepartment(result.department);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Employee "${result.name}" added successfully.'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: context.success,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(tr('Add Employee')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                        ],
                      );

                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleWidget,
                            const SizedBox(height: 14),
                            actionButtons,
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: titleWidget),
                          const SizedBox(width: 16),
                          actionButtons,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Statistics Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth >= 1100 ? 4 : (constraints.maxWidth >= 600 ? 2 : 1);
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: crossAxisCount == 1 ? 2.6 : (crossAxisCount == 2 ? 2.1 : 1.8),
                        children: [
                          StatCard(
                            title: tr('Total Employees'),
                            tooltipMessage: "Detailed statistics and information regarding ${tr('Total Employees')}.",
                            value: '$totalEmployees',
                            icon: Icons.people_outline,
                            iconColor: context.primaryColor,
                            iconBgColor: context.infoLight,
                            trendText: tr('Registered staff'),
                          ),
                          StatCard(
                            title: tr('Active Employees'),
                            tooltipMessage: "Detailed statistics and information regarding ${tr('Active Employees')}.",
                            value: '$activeCount',
                            icon: Icons.check_circle_outline,
                            iconColor: context.success,
                            iconBgColor: context.successLight,
                            trendText: tr('Working today'),
                          ),
                          StatCard(
                            title: tr('On Leave'),
                            tooltipMessage: "Detailed statistics and information regarding ${tr('On Leave')}.",
                            value: '$leaveCount',
                            icon: Icons.beach_access_outlined,
                            iconColor: context.warning,
                            iconBgColor: context.warningLight,
                            trendText: tr('Approved leaves'),
                          ),
                          StatCard(
                            title: tr('Monthly Payroll'),
                            tooltipMessage: "Detailed statistics and information regarding ${tr('Monthly Payroll')}.",
                            value: CurrencyFormatter.formatCurrency(monthlyPayroll),
                            icon: Icons.payments_outlined,
                            iconColor: context.error,
                            iconBgColor: context.errorLight,
                            trendText: tr('Total staff salary'),
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isMobile = constraints.maxWidth < 700;

                          final searchField = TextField(
                            onChanged: (val) => ref.read(employeesProvider.notifier).setSearchQuery(val),
                            style: TextStyle(color: context.textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: tr('Search by name, designation, or email...'),
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
                          );

                          final departmentField = DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: (state.departmentFilter == 'All' || departments.contains(state.departmentFilter))
                                ? state.departmentFilter
                                : 'All',
                            dropdownColor: context.cardBg,
                            style: TextStyle(color: context.textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: tr('Department'),
                              labelStyle: TextStyle(color: context.textSecondary, fontSize: 11),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              DropdownMenuItem(value: 'All', child: Text(tr('All Departments'))),
                              ...departments.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(employeesProvider.notifier).setDepartmentFilter(val);
                              }
                            },
                          );

                          final statusField = DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: state.statusFilter,
                            dropdownColor: context.cardBg,
                            style: TextStyle(color: context.textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: tr('Status'),
                              labelStyle: TextStyle(color: context.textSecondary, fontSize: 11),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              DropdownMenuItem(value: 'All', child: Text(tr('All Statuses'))),
                              DropdownMenuItem(value: 'Active', child: Text(tr('Active'))),
                              DropdownMenuItem(value: 'On Leave', child: Text(tr('On Leave'))),
                              DropdownMenuItem(value: 'Terminated', child: Text(tr('Terminated'))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(employeesProvider.notifier).setStatusFilter(val);
                              }
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
                                if (isMobile)
                                  Row(
                                    children: [
                                      Expanded(child: departmentField),
                                      const SizedBox(width: 12),
                                      Expanded(child: statusField),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      Expanded(child: departmentField),
                                      const SizedBox(width: 16),
                                      Expanded(child: statusField),
                                      const Expanded(child: SizedBox()),
                                    ],
                                  ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Grid view of Employees
                  state.filteredEmployees.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                            child: GlassCard(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: context.primaryColor.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.people_outline,
                                        size: 48,
                                        color: context.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      state.employees.isEmpty
                                          ? tr('No Employees in Directory')
                                          : tr('No Matching Employees Found'),
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 450),
                                      child: Text(
                                        state.employees.isEmpty
                                            ? tr('Your employee roster is currently empty. You can add your staff members or load demo employees to immediately test Attendance, Salaries, Advances, and Payroll.')
                                            : tr('No employees matched your current search filters. Try clearing the search or changing department/status filters.'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: context.textSecondary,
                                          fontSize: 13,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 10,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        if (state.employees.isEmpty) ...[
                                          if (canCreate) ...[
                                            ElevatedButton.icon(
                                            onPressed: () async {
                                              final result = await showDialog<Employee>(
                                                context: context,
                                                builder: (context) => const _AddEmployeeDialog(),
                                              );
                                              if (result != null) {
                                                ref.read(employeesProvider.notifier).addEmployee(result);
                                                ref.read(departmentsProvider.notifier).addDepartment(result.department);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Employee "${result.name}" added successfully.'),
                                                      behavior: SnackBarBehavior.floating,
                                                      backgroundColor: context.success,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            icon: const Icon(Icons.add, size: 18),
                                            label: Text(tr('Add Employee')),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: context.primaryColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            ),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () async {
                                              final demoList = [
                                                Employee(
                                                  id: 'emp_${DateTime.now().millisecondsSinceEpoch}_1',
                                                  name: 'Muhammad Haseeb',
                                                  email: 'haseeb@hhtech.com',
                                                  phones: const ['Personal: +92 300 1234567'],
                                                  designation: 'Tech Lead / Mobile Architect',
                                                  department: 'Mobile Apps',
                                                  joiningDate: '2024-01-15',
                                                  status: 'Active',
                                                  salaryType: 'Monthly',
                                                  baseSalary: 120000.0,
                                                  paymentMethod: 'Bank Transfer',
                                                ),
                                                Employee(
                                                  id: 'emp_${DateTime.now().millisecondsSinceEpoch}_2',
                                                  name: 'Ahmed Khan',
                                                  email: 'ahmed.khan@hhtech.com',
                                                  phones: const ['Personal: +92 301 9876543'],
                                                  designation: 'Senior Flutter Developer',
                                                  department: 'Mobile Apps',
                                                  joiningDate: '2024-03-01',
                                                  status: 'Active',
                                                  salaryType: 'Monthly',
                                                  baseSalary: 85000.0,
                                                  paymentMethod: 'Bank Transfer',
                                                ),
                                                Employee(
                                                  id: 'emp_${DateTime.now().millisecondsSinceEpoch}_3',
                                                  name: 'Fatima Noor',
                                                  email: 'fatima@hhtech.com',
                                                  phones: const ['Personal: +92 321 4567890'],
                                                  designation: 'UI/UX Lead Designer',
                                                  department: 'Design',
                                                  joiningDate: '2024-02-10',
                                                  status: 'Active',
                                                  salaryType: 'Monthly',
                                                  baseSalary: 75000.0,
                                                  paymentMethod: 'Bank Transfer',
                                                ),
                                                Employee(
                                                  id: 'emp_${DateTime.now().millisecondsSinceEpoch}_4',
                                                  name: 'Zain Ali',
                                                  email: 'zain.ali@hhtech.com',
                                                  phones: const ['Personal: +92 333 1122334'],
                                                  designation: 'QA Automation Engineer',
                                                  department: 'Quality Assurance',
                                                  joiningDate: '2024-04-01',
                                                  status: 'Active',
                                                  salaryType: 'Monthly',
                                                  baseSalary: 60000.0,
                                                  paymentMethod: 'Cash',
                                                ),
                                              ];
                                              for (final emp in demoList) {
                                                await ref.read(employeesProvider.notifier).addEmployee(emp);
                                                await ref.read(departmentsProvider.notifier).addDepartment(emp.department);
                                              }
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(tr('Demo employees loaded successfully! All HR modules are now active.')),
                                                    behavior: SnackBarBehavior.floating,
                                                    backgroundColor: context.success,
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.download_done, size: 18),
                                            label: Text(tr('Load Demo Employees')),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: context.primaryColor,
                                              side: BorderSide(color: context.primaryColor),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            ),
                                          ),
                                        ],
                                        ] else ...[
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              ref.read(employeesProvider.notifier).setSearchQuery('');
                                              ref.read(employeesProvider.notifier).setDepartmentFilter('All');
                                              ref.read(employeesProvider.notifier).setStatusFilter('All');
                                            },
                                            icon: const Icon(Icons.clear, size: 18),
                                            label: Text(tr('Reset Filters')),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: context.primaryColor,
                                              side: BorderSide(color: context.primaryColor),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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
                            mainAxisExtent: width < 600 ? 275 : 295,
                          ),
                          itemCount: state.filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final employee = state.filteredEmployees[index];
                            return _EmployeeCard(employee: employee);
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

class _EmployeeCard extends ConsumerWidget {
  final Employee employee;

  const _EmployeeCard({required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = ref.watch(translationProvider);
    final adminState = ref.watch(adminProvider);
    final canEdit = adminState.hasPermission(AppModule.employees, PermissionAction.edit);
    final canDelete = adminState.hasPermission(AppModule.employees, PermissionAction.delete);
    final cleanName = employee.name.trim();
    final nameParts = cleanName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = nameParts.isEmpty
        ? 'EMP'
        : (nameParts.length == 1
            ? nameParts[0].substring(0, nameParts[0].length >= 2 ? 2 : 1).toUpperCase()
            : (nameParts[0][0] + nameParts[1][0]).toUpperCase());

    // Determine status badge colors
    Color statusColor = context.success;
    Color statusBg = context.successLight;
    if (employee.status == 'On Leave') {
      statusColor = context.warning;
      statusBg = context.warningLight;
    } else if (employee.status == 'Terminated') {
      statusColor = context.error;
      statusBg = context.errorLight;
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => _ViewEmployeeDetailsDialog(employee: employee),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header info: Avatar & Name & Status & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
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
                            cleanName.isNotEmpty ? cleanName : tr('Unnamed Employee'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            employee.designation.isNotEmpty ? employee.designation : tr('Staff Member'),
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: context.textSecondary),
                color: context.cardBg,
                onSelected: (val) async {
                  if (val == 'history') {
                    context.go('/hr/history');
                  } else if (val == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(tr('Delete Employee')),
                        content: Text(tr('Are you sure you want to delete this employee? This action cannot be undone.')),
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
                      if (!canDelete) return;
                      ref.read(employeesProvider.notifier).deleteEmployee(employee.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${employee.name} - ${tr("Employee deleted.")}'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: context.error,
                        ),
                      );
                    }
                  } else if (val == 'toggle_status') {
                    if (!canEdit) return;
                    final nextStatus = employee.status == 'Active'
                        ? 'On Leave'
                        : (employee.status == 'On Leave' ? 'Terminated' : 'Active');
                    ref.read(employeesProvider.notifier).updateEmployee(employee.copyWith(status: nextStatus));
                  } else if (val == 'edit') {
                    if (!canEdit) return;
                    showDialog(
                      context: context,
                      builder: (context) => _EditEmployeeDialog(employee: employee),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(Icons.history_outlined, size: 16, color: context.primaryColor),
                        const SizedBox(width: 8),
                        Text(tr('Attendance & History'), style: TextStyle(color: context.textPrimary, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (canEdit)
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(tr('Edit Details'), style: TextStyle(color: context.textPrimary, fontSize: 13)),
                    ),
                  if (canEdit)
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Text(tr('Cycle Status'), style: TextStyle(color: context.textPrimary, fontSize: 13)),
                    ),
                  if (canDelete)
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(tr('Delete Employee'), style: TextStyle(color: context.error, fontSize: 13)),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Department & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.business, size: 14, color: context.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        employee.department,
                        style: TextStyle(color: context.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  employee.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Contact Details
          Row(
            children: [
              Icon(Icons.email_outlined, size: 14, color: context.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  employee.email,
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.phone_outlined, size: 14, color: context.textMuted),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final displayVal = employee.phones.isEmpty
                        ? 'No Phone'
                        : employee.phones.length == 1
                            ? employee.phones[0]
                            : '${employee.phones[0]} (+${employee.phones.length - 1} more)';
                    
                    return Tooltip(
                      message: employee.phones.isNotEmpty ? employee.phones.join('\n') : 'No Phone',
                      child: Text(
                        displayVal,
                        style: TextStyle(color: context.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Joining Date
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: context.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${tr("Joined:")} ${employee.joiningDate.isNotEmpty ? employee.joiningDate : tr("N/A")}',
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (employee.cnic.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.badge_outlined, size: 14, color: context.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${tr("CNIC:")} ${employee.cnic.trim()}',
                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),

          // Salary details
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: context.scaffoldBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('Base Pay:'),
                  style: TextStyle(color: context.textSecondary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Rs. ${employee.baseSalary.toStringAsFixed(0)} / mo',
                      style: TextStyle(
                        color: context.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}

class _AddEmployeeDialog extends ConsumerStatefulWidget {
  const _AddEmployeeDialog();

  @override
  ConsumerState<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends ConsumerState<_AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cnicController = TextEditingController();
  final List<TextEditingController> _phoneControllers = [TextEditingController()];
  final List<String> _phoneRelationships = ['Personal'];
  final List<TextEditingController> _customRelationshipControllers = [TextEditingController()];
  final _designationController = TextEditingController();
  String _department = '';
  final String _salaryType = 'Monthly';
  final _salaryController = TextEditingController();
  final _joiningDateController = TextEditingController();
  String _paymentMethod = 'Bank Transfer';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cnicController.dispose();
    for (final controller in _phoneControllers) {
      controller.dispose();
    }
    for (final controller in _customRelationshipControllers) {
      controller.dispose();
    }
    _designationController.dispose();
    _salaryController.dispose();
    _joiningDateController.dispose();
    super.dispose();
  }

  Widget _buildFormRow(BuildContext context, Widget child1, Widget child2) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          child1,
          const SizedBox(height: 16),
          child2,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: child1),
        const SizedBox(width: 16),
        Expanded(child: child2),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(translationProvider);
    final departments = ref.watch(departmentsProvider);

    if (_department.isEmpty && departments.isNotEmpty) {
      _department = departments.first;
    }

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tr('Add Employee Details'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
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

                // Name
                _buildLabel(tr('Full Name'), isRequired: true),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration(''),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter employee name' : null,
                ),
                const SizedBox(height: 16),

                // Email Address
                _buildLabel('${tr('Email Address')} (Optional)'),
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration('email@company.com'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return null;
                    if (!val.contains('@')) return 'Please enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // CNIC Number
                _buildLabel('${tr('CNIC Number')} (Optional)'),
                TextFormField(
                  controller: _cnicController,
                  style: TextStyle(color: context.textPrimary),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                    LengthLimitingTextInputFormatter(15),
                  ],
                  decoration: _buildInputDecoration('35202-1234567-1'),
                ),
                const SizedBox(height: 16),

                // Phone Numbers Section
                _buildLabel(tr('Phone Number(s)'), isRequired: true),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _phoneControllers.length,
                  itemBuilder: (context, index) {
                    final isCustom = _phoneRelationships[index] == 'Other (Custom)...';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormRow(
                            context,
                            // Relationship Dropdown
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              isDense: true,
                              value: _phoneRelationships[index],
                              dropdownColor: context.cardBg,
                              style: TextStyle(color: context.textPrimary, fontSize: 12),
                              decoration: _buildInputDecoration(''),
                              items: [
                                'Personal',
                                'Work',
                                'Home',
                                'Spouse (Emergency)',
                                'Parent (Emergency)',
                                'Sibling (Emergency)',
                                'Friend (Emergency)',
                                'Other (Custom)...',
                              ].map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(
                                  r,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              )).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _phoneRelationships[index] = val;
                                  });
                                }
                              },
                            ),
                            // Phone Number TextFormField and Delete Button
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _phoneControllers[index],
                                    style: TextStyle(color: context.textPrimary),
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]')),
                                      LengthLimitingTextInputFormatter(20),
                                    ],
                                    decoration: _buildInputDecoration('+92 300 1234567'),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        if (index == 0) return 'Please enter phone number';
                                        return null;
                                      }
                                      final regex = RegExp(r'^\+?[0-9\s\-]{10,20}$');
                                      if (!regex.hasMatch(val.trim())) {
                                        return 'Enter 10-20 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                if (_phoneControllers.length > 1) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _phoneControllers[index].dispose();
                                        _phoneControllers.removeAt(index);
                                        _phoneRelationships.removeAt(index);
                                        _customRelationshipControllers[index].dispose();
                                        _customRelationshipControllers.removeAt(index);
                                      });
                                    },
                                    icon: Icon(Icons.delete_outline, color: context.error, size: 20),
                                    tooltip: 'Remove phone number',
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isCustom) ...[
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _customRelationshipControllers[index],
                              style: TextStyle(color: context.textPrimary, fontSize: 13),
                              decoration: _buildInputDecoration('Enter custom relationship (e.g. Brother, Cousin)'),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter relationship' : null,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                if (_phoneControllers.length < 3)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _phoneControllers.add(TextEditingController());
                        _phoneRelationships.add('Personal');
                        _customRelationshipControllers.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(tr('Add Phone Number'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: context.primaryColor,
                      padding: EdgeInsets.zero,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      'Maximum 3 phone numbers allowed',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Designation & Department Row
                _buildFormRow(
                  context,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(tr('Designation'), isRequired: true),
                      TextFormField(
                        controller: _designationController,
                        style: TextStyle(color: context.textPrimary),
                        decoration: _buildInputDecoration('e.g. Flutter Developer'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Please enter designation' : null,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLabel(tr('Department')),
                          GestureDetector(
                            onTap: () async {
                              final controller = TextEditingController();
                              final newDept = await showDialog<String>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: context.cardBg,
                                  title: Text(tr('Add Department'), style: TextStyle(color: context.textPrimary)),
                                  content: TextField(
                                    controller: controller,
                                    style: TextStyle(color: context.textPrimary),
                                    decoration: InputDecoration(
                                      hintText: 'Enter department name',
                                      hintStyle: TextStyle(color: context.textMuted),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                                      child: Text(tr('Add')),
                                    ),
                                  ],
                                ),
                              );
                              if (newDept != null && newDept.trim().isNotEmpty) {
                                final canonical = await ref.read(departmentsProvider.notifier).addDepartment(newDept.trim());
                                setState(() {
                                  _department = canonical;
                                });
                              }
                            },
                            child: Text(
                              '+ Add Department',
                              style: TextStyle(color: context.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      DropdownButtonFormField<String>(
                        value: departments.contains(_department) ? _department : (departments.isNotEmpty ? departments.first : null),
                        dropdownColor: context.cardBg,
                        style: TextStyle(color: context.textPrimary, fontSize: 13),
                        decoration: _buildInputDecoration(''),
                        items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _department = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Salary Field
                _buildLabel(tr('Base Salary (Rs. / month)'), isRequired: true),
                TextFormField(
                  controller: _salaryController,
                  style: TextStyle(color: context.textPrimary),
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration('e.g. 30000'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter salary';
                    if (double.tryParse(val) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Joining Date
                _buildLabel(tr('Joining Date'), isRequired: true),
                TextFormField(
                  controller: _joiningDateController,
                  style: TextStyle(color: context.textPrimary),
                  readOnly: true,
                  decoration: _buildInputDecoration(tr('Select Joining Date')).copyWith(
                    suffixIcon: Icon(Icons.calendar_today, size: 16, color: context.textSecondary),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? tr('Joining Date is mandatory') : null,
                  onTap: () async {
                    DateTime initial = DateTime.tryParse(_joiningDateController.text) ?? DateTime.now();
                    final date = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() {
                        _joiningDateController.text = date.toIso8601String().substring(0, 10);
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Form Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: context.textSecondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text(tr('Cancel')),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final newEmp = Employee(
                            id: 'emp_${DateTime.now().millisecondsSinceEpoch}',
                            name: _nameController.text.trim(),
                            email: _emailController.text.trim(),
                            phones: () {
                              final list = <String>[];
                              for (int i = 0; i < _phoneControllers.length; i++) {
                                final phoneVal = _phoneControllers[i].text.trim();
                                if (phoneVal.isNotEmpty) {
                                  var rel = _phoneRelationships[i];
                                  if (rel == 'Other (Custom)...') {
                                    rel = _customRelationshipControllers[i].text.trim();
                                    if (rel.isEmpty) rel = 'Other';
                                  }
                                  list.add('$rel: $phoneVal');
                                }
                              }
                              return list;
                            }(),
                            cnic: _cnicController.text.trim(),
                            designation: _designationController.text.trim(),
                            department: _department,
                            joiningDate: _joiningDateController.text.trim(),
                            status: 'Active',
                            salaryType: _salaryType,
                            baseSalary: double.tryParse(_salaryController.text) ?? 0.0,
                            paymentMethod: _paymentMethod,
                          );
                          Navigator.of(context).pop(newEmp);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(tr('Add Employee')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.textSecondary,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
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

class _EditEmployeeDialog extends ConsumerStatefulWidget {
  final Employee employee;
  const _EditEmployeeDialog({required this.employee});

  @override
  ConsumerState<_EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends ConsumerState<_EditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _cnicController;
  late final List<TextEditingController> _phoneControllers;
  late final List<String> _phoneRelationships;
  late final List<TextEditingController> _customRelationshipControllers;
  late final TextEditingController _designationController;
  late String _department;
  late final TextEditingController _salaryController;
  late String _paymentMethod;
  late String _status;
  late final TextEditingController _joiningDateController;
  late final TextEditingController _leavingDateController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.employee.name);
    _emailController = TextEditingController(text: widget.employee.email);
    _cnicController = TextEditingController(text: widget.employee.cnic);

    _phoneControllers = [];
    _phoneRelationships = [];
    _customRelationshipControllers = [];
    
    if (widget.employee.phones.isEmpty) {
      _phoneControllers.add(TextEditingController());
      _phoneRelationships.add('Personal');
      _customRelationshipControllers.add(TextEditingController());
    } else {
      for (final p in widget.employee.phones) {
        String relationship = 'Personal';
        String number = p;
        String customVal = '';
        if (p.contains(':')) {
          final parts = p.split(':');
          if (parts.length >= 2) {
            relationship = parts[0].trim();
            number = parts.sublist(1).join(':').trim();
          }
        }
        
        final standardRelationships = [
          'Personal', 'Work', 'Home', 
          'Emergency - Spouse', 'Emergency - Parent', 
          'Emergency - Sibling', 'Emergency - Friend'
        ];
        
        if (!standardRelationships.contains(relationship)) {
          customVal = relationship;
          relationship = 'Other (Custom)...';
        }
        
        _phoneControllers.add(TextEditingController(text: number));
        _phoneRelationships.add(relationship);
        _customRelationshipControllers.add(TextEditingController(text: customVal));
      }
    }
    
    _designationController = TextEditingController(text: widget.employee.designation);
    _department = widget.employee.department;
    _salaryController = TextEditingController(text: widget.employee.baseSalary.toStringAsFixed(0));
    _paymentMethod = widget.employee.paymentMethod;
    _status = widget.employee.status;
    _joiningDateController = TextEditingController(text: widget.employee.joiningDate);
    _leavingDateController = TextEditingController(
        text: widget.employee.leavingDate ?? DateTime.now().toIso8601String().substring(0, 10));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cnicController.dispose();
    for (final controller in _phoneControllers) {
      controller.dispose();
    }
    for (final controller in _customRelationshipControllers) {
      controller.dispose();
    }
    _designationController.dispose();
    _salaryController.dispose();
    _joiningDateController.dispose();
    _leavingDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(translationProvider);
    final savedDepts = ref.watch(departmentsProvider);
    final departments = [
      ...savedDepts,
      if (_department.isNotEmpty && !savedDepts.contains(_department)) _department,
    ];

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
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
                      tr('Edit Employee Details'),
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

                // Name
                _buildLabel(tr('Full Name'), isRequired: true),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration('Enter full name'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter employee name' : null,
                ),
                const SizedBox(height: 16),

                // Email Address
                _buildLabel('${tr('Email Address')} (Optional)'),
                TextFormField(
                  controller: _emailController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration('email@company.com'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return null;
                    if (!val.contains('@')) return 'Please enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // CNIC Number
                _buildLabel('${tr('CNIC Number')} (Optional)'),
                TextFormField(
                  controller: _cnicController,
                  style: TextStyle(color: context.textPrimary),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                    LengthLimitingTextInputFormatter(15),
                  ],
                  decoration: _buildInputDecoration('35202-1234567-1'),
                ),
                const SizedBox(height: 16),

                // Phone Numbers Section
                _buildLabel(tr('Phone Number(s)'), isRequired: true),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _phoneControllers.length,
                  itemBuilder: (context, index) {
                    final isCustom = _phoneRelationships[index] == 'Other (Custom)...';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Relationship Dropdown
                              SizedBox(
                                width: 170,
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  isDense: true,
                                  value: _phoneRelationships[index],
                                  dropdownColor: context.cardBg,
                                  style: TextStyle(color: context.textPrimary, fontSize: 12),
                                  decoration: _buildInputDecoration(''),
                                  items: [
                                    'Personal',
                                    'Work',
                                    'Home',
                                    'Spouse (Emergency)',
                                    'Parent (Emergency)',
                                    'Sibling (Emergency)',
                                    'Friend (Emergency)',
                                    'Other (Custom)...',
                                  ].map((r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(
                                      r,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  )).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _phoneRelationships[index] = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Phone Number TextFormField
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneControllers[index],
                                  style: TextStyle(color: context.textPrimary),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]')),
                                    LengthLimitingTextInputFormatter(20),
                                  ],
                                  decoration: _buildInputDecoration('+92 300 1234567'),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      if (index == 0) return 'Please enter phone number';
                                      return null;
                                    }
                                    final regex = RegExp(r'^\+?[0-9\s\-]{10,20}$');
                                    if (!regex.hasMatch(val.trim())) {
                                      return 'Enter 10-20 digits';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              if (_phoneControllers.length > 1) ...[
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _phoneControllers[index].dispose();
                                        _phoneControllers.removeAt(index);
                                        _phoneRelationships.removeAt(index);
                                        _customRelationshipControllers[index].dispose();
                                        _customRelationshipControllers.removeAt(index);
                                      });
                                    },
                                    icon: Icon(Icons.delete_outline, color: context.error, size: 20),
                                    tooltip: 'Remove phone number',
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (isCustom) ...[
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _customRelationshipControllers[index],
                              style: TextStyle(color: context.textPrimary, fontSize: 13),
                              decoration: _buildInputDecoration('Enter custom relationship (e.g. Brother, Cousin)'),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter relationship' : null,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                if (_phoneControllers.length < 3)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _phoneControllers.add(TextEditingController());
                        _phoneRelationships.add('Personal');
                        _customRelationshipControllers.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(tr('Add Phone Number'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: context.primaryColor,
                      padding: EdgeInsets.zero,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Text(
                      'Maximum 3 phone numbers allowed',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Designation & Department Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(tr('Designation'), isRequired: true),
                          TextFormField(
                            controller: _designationController,
                            style: TextStyle(color: context.textPrimary),
                            decoration: _buildInputDecoration('e.g. Flutter Developer'),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Please enter designation' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLabel(tr('Department')),
                              GestureDetector(
                                onTap: () async {
                                  final controller = TextEditingController();
                                  final newDept = await showDialog<String>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: context.cardBg,
                                      title: Text(tr('Add Department'), style: TextStyle(color: context.textPrimary)),
                                      content: TextField(
                                        controller: controller,
                                        style: TextStyle(color: context.textPrimary),
                                        decoration: InputDecoration(
                                          hintText: 'Enter department name',
                                          hintStyle: TextStyle(color: context.textMuted),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                                          child: Text(tr('Add')),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (newDept != null && newDept.trim().isNotEmpty) {
                                    final canonical = await ref.read(departmentsProvider.notifier).addDepartment(newDept.trim());
                                    setState(() {
                                      _department = canonical;
                                    });
                                  }
                                },
                                child: Text(
                                  '+ Add Department',
                                  style: TextStyle(color: context.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          DropdownButtonFormField<String>(
                            value: departments.contains(_department) ? _department : (departments.isNotEmpty ? departments.first : null),
                            dropdownColor: context.cardBg,
                            style: TextStyle(color: context.textPrimary, fontSize: 13),
                            decoration: _buildInputDecoration(''),
                            items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _department = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Employee Status Field
                _buildLabel(tr('Employee Status'), isRequired: true),
                DropdownButtonFormField<String>(
                  value: _status,
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration(''),
                  items: [
                    DropdownMenuItem(value: 'Active', child: Text(tr('Active'))),
                    DropdownMenuItem(value: 'On Leave', child: Text(tr('On Leave'))),
                    DropdownMenuItem(value: 'Terminated', child: Text(tr('Terminated'))),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
                const SizedBox(height: 16),

                // Joining & Leaving Dates Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(tr('Joining Date'), isRequired: true),
                          TextFormField(
                            controller: _joiningDateController,
                            style: TextStyle(color: context.textPrimary),
                            readOnly: true,
                            decoration: _buildInputDecoration(tr('Select Joining Date')).copyWith(
                              suffixIcon: Icon(Icons.calendar_today, size: 16, color: context.textSecondary),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? tr('Joining Date is mandatory') : null,
                            onTap: () async {
                              DateTime initial = DateTime.tryParse(_joiningDateController.text) ?? DateTime.now();
                              final date = await showDatePicker(
                                context: context,
                                initialDate: initial,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() {
                                  _joiningDateController.text = date.toIso8601String().substring(0, 10);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _status == 'Terminated'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(tr('Leaving Date'), isRequired: true),
                                TextFormField(
                                  controller: _leavingDateController,
                                  style: TextStyle(color: context.textPrimary),
                                  readOnly: true,
                                  decoration: _buildInputDecoration('Select Leaving Date').copyWith(
                                    suffixIcon: Icon(Icons.calendar_today, size: 16, color: context.textSecondary),
                                  ),
                                  onTap: () async {
                                    DateTime initial = DateTime.tryParse(_leavingDateController.text) ?? DateTime.now();
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: initial,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        _leavingDateController.text = date.toIso8601String().substring(0, 10);
                                      });
                                    }
                                  },
                                ),
                              ],
                            )
                          : const SizedBox(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Salary
                _buildLabel(tr('Base Salary (Rs. / month)'), isRequired: true),
                TextFormField(
                  controller: _salaryController,
                  style: TextStyle(color: context.textPrimary),
                  keyboardType: TextInputType.number,
                  decoration: _buildInputDecoration('e.g. 30000'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter salary';
                    if (double.tryParse(val) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Form Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: context.textSecondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text(tr('Cancel')),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (!ref.read(adminProvider).hasPermission(AppModule.employees, PermissionAction.edit)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Access Denied: You do not have permission to edit employees.')),
                          );
                          return;
                        }
                        if (_formKey.currentState!.validate()) {
                          final updatedEmp = widget.employee.copyWith(
                            name: _nameController.text.trim(),
                            email: _emailController.text.trim(),
                            phones: () {
                              final list = <String>[];
                              for (int i = 0; i < _phoneControllers.length; i++) {
                                final phoneVal = _phoneControllers[i].text.trim();
                                if (phoneVal.isNotEmpty) {
                                  var rel = _phoneRelationships[i];
                                  if (rel == 'Other (Custom)...') {
                                    rel = _customRelationshipControllers[i].text.trim();
                                    if (rel.isEmpty) rel = 'Other';
                                  }
                                  list.add('$rel: $phoneVal');
                                }
                              }
                              return list;
                            }(),
                            cnic: _cnicController.text.trim(),
                            designation: _designationController.text.trim(),
                            department: _department,
                            status: _status,
                            joiningDate: _joiningDateController.text,
                            leavingDate: _status == 'Terminated' ? _leavingDateController.text : null,
                            baseSalary: double.tryParse(_salaryController.text) ?? 0.0,
                            paymentMethod: _paymentMethod,
                          );
                          ref.read(employeesProvider.notifier).updateEmployee(updatedEmp);
                          ref.read(departmentsProvider.notifier).addDepartment(updatedEmp.department);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${updatedEmp.name} - ${tr("Employee details updated.")}'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: context.success,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(tr('Save Changes')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.textSecondary,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
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

class _ViewEmployeeDetailsDialog extends ConsumerWidget {
  final Employee employee;

  const _ViewEmployeeDetailsDialog({required this.employee});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = ref.watch(translationProvider);
    final cleanName = employee.name.trim();
    final nameParts = cleanName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = nameParts.isEmpty
        ? 'EMP'
        : (nameParts.length == 1
            ? nameParts[0].substring(0, nameParts[0].length >= 2 ? 2 : 1).toUpperCase()
            : (nameParts[0][0] + nameParts[1][0]).toUpperCase());

    // Determine status badge colors
    Color statusColor = context.success;
    Color statusBg = context.successLight;
    if (employee.status == 'On Leave') {
      statusColor = context.warning;
      statusBg = context.warningLight;
    } else if (employee.status == 'Terminated') {
      statusColor = context.error;
      statusBg = context.errorLight;
    }

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('Employee Profile'),
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

              // Profile Header Card
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: context.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          employee.designation,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            employee.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Details Grid
              _buildDetailItem(context, tr('CNIC Number'), employee.cnic.trim().isNotEmpty ? employee.cnic.trim() : tr('N/A')),
              _buildDetailItem(context, tr('Department'), employee.department),
              _buildDetailItem(context, tr('Joining Date'), employee.joiningDate),
              if (employee.leavingDate != null && employee.status == 'Terminated')
                _buildDetailItem(context, tr('Leaving Date'), employee.leavingDate!),
              _buildDetailItem(context, tr('Salary Type'), employee.salaryType),
              _buildDetailItem(context, tr('Base Salary'), 'Rs. ${employee.baseSalary.toStringAsFixed(0)} / month'),
              _buildDetailItem(context, tr('Email Address'), employee.email),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Phone Numbers Section
              Text(
                tr('Phone Number(s)'),
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (employee.phones.isEmpty)
                Text(
                  tr('No Phone Number registered'),
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                )
              else
                ...employee.phones.map((phone) {
                  String relationship = 'Phone';
                  String number = phone;
                  if (phone.contains(':')) {
                    final parts = phone.split(':');
                    if (parts.length >= 2) {
                      relationship = parts[0].trim();
                      number = parts.sublist(1).join(':').trim();
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 16, color: context.primaryColor),
                        const SizedBox(width: 10),
                        Text(
                          number,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: context.primaryColor.withOpacity(0.15)),
                          ),
                          child: Text(
                            relationship,
                            style: TextStyle(
                              color: context.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
