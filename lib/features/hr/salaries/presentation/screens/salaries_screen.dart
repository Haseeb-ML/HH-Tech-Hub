import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/core/widgets/explain_tooltip.dart';
import 'package:software_house_erp/features/hr/shared/widgets/hr_sub_nav.dart';
import '../providers/salaries_provider.dart';
import '../../../employees/presentation/providers/employees_provider.dart';
import '../../../advances/presentation/providers/advances_provider.dart';
import '../../domain/entities/salary_record.dart';

class SalariesScreen extends ConsumerWidget {
  const SalariesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salariesProvider);
    final theme = Theme.of(context);

    // Calculate total payroll paid for May 2026
    final totalPaid = state.totalPayoutsThisMonth;
    final totalPayslips = state.filteredSalaries.length;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: state.isLoading && state.salaries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const HrSubNav(activeRoute: '/hr/salaries'),
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
                            'Payroll & Salaries',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Process monthly payroll, track allowances, deductions, and print payslips.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final employees = ref.read(employeesProvider).employees;
                          if (employees.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Add employees in the Directory first before processing payroll.'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: context.error,
                              ),
                            );
                            return;
                          }

                          final result = await showDialog<SalaryRecord>(
                            context: context,
                            builder: (context) => const _ProcessPayrollDialog(),
                          );
                          if (result != null) {
                            ref.read(salariesProvider.notifier).addSalary(result);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Payroll processed for ${result.employeeName}.'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: context.success,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text('Process Payroll'),
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

                  // Stats Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      if (isMobile) {
                        return Column(
                          children: [
                            ExplainTooltip(
                              message: 'Monthly Payroll: Total amount paid out to employees for the current payroll month.',
                              child: StatCard(
                                title: 'May 2026 Payroll',
                                tooltipMessage: 'Detailed statistics and information regarding May 2026 Payroll.',
                                value: 'Rs. ${totalPaid.toStringAsFixed(0)}',
                                icon: Icons.check_circle_outline,
                                iconColor: context.success,
                                iconBgColor: context.successLight,
                                trendText: 'Paid this month',
                              ),
                            ),
                            const SizedBox(height: 12),
                            ExplainTooltip(
                              message: 'Total Payslips: Total number of payslips generated and logged in the system.',
                              child: StatCard(
                                title: 'Total Payslips',
                                tooltipMessage: 'Detailed statistics and information regarding Total Payslips.',
                                value: totalPayslips.toString(),
                                icon: Icons.receipt_long_outlined,
                                iconColor: context.primaryColor,
                                iconBgColor: context.infoLight,
                                trendText: 'Issued logs',
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: ExplainTooltip(
                              message: 'Monthly Payroll: Total amount paid out to employees for the current payroll month.',
                              child: StatCard(
                                title: 'May 2026 Payroll',
                                tooltipMessage: 'Detailed statistics and information regarding May 2026 Payroll.',
                                value: '\$${totalPaid.toStringAsFixed(0)}',
                                icon: Icons.check_circle_outline,
                                iconColor: context.success,
                                iconBgColor: context.successLight,
                                trendText: 'Paid this month',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ExplainTooltip(
                              message: 'Total Payslips: Total number of payslips generated and logged in the system.',
                              child: StatCard(
                                title: 'Total Payslips',
                                tooltipMessage: 'Detailed statistics and information regarding Total Payslips.',
                                value: totalPayslips.toString(),
                                icon: Icons.receipt_long_outlined,
                                iconColor: context.primaryColor,
                                iconBgColor: context.infoLight,
                                trendText: 'Issued logs',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Payroll History List
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
                                'Issued Payslips Log',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                              
                              // Filters dropdown
                              SizedBox(
                                width: 180,
                                child: DropdownButtonFormField<String>(
                                  value: state.periodFilter,
                                  dropdownColor: context.cardBg,
                                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                                  decoration: InputDecoration(
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
                                  items: const [
                                    DropdownMenuItem(value: 'All', child: Text('All Pay Periods')),
                                    DropdownMenuItem(value: 'May 2026', child: Text('May 2026')),
                                    DropdownMenuItem(value: 'April 2026', child: Text('April 2026')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      ref.read(salariesProvider.notifier).setPeriodFilter(val);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Table of payouts
                          state.filteredSalaries.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Text(
                                      'No payslip records found.',
                                      style: TextStyle(color: context.textSecondary),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: state.filteredSalaries.length,
                                  separatorBuilder: (context, index) => const Divider(),
                                  itemBuilder: (context, index) {
                                    final record = state.filteredSalaries[index];
                                    return _SalaryRow(record: record);
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

class _SalaryRow extends ConsumerWidget {
  final SalaryRecord record;

  const _SalaryRow({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          return Row(
            children: [
              // Employee Name & Period
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
                    Text(
                      'Period: ${record.payPeriod} | Paid on ${record.paymentDate}',
                      style: TextStyle(color: context.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Details (Base, Allowance, Deduction)
              if (isWide) ...[
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailItem('Base Pay', 'Rs. ${record.baseSalary.toStringAsFixed(0)}', context),
                      _buildDetailItem('Allowance', '+Rs. ${record.allowances.toStringAsFixed(0)}', context, color: context.success),
                      _buildDetailItem('Deductions', '-Rs. ${record.deductions.toStringAsFixed(0)}', context, color: context.error),
                    ],
                  ),
                ),
              ],

              // Net Paid Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs. ${record.netPaid.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: context.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    record.paymentMethod,
                    style: TextStyle(color: context.textMuted, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Edit / Delete action
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: context.textSecondary),
                color: context.cardBg,
                onSelected: (val) async {
                  if (val == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Payslip'),
                        content: Text('Are you sure you want to delete payslip log for "${record.employeeName}"? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel', style: TextStyle(color: context.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Delete', style: TextStyle(color: context.error)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      ref.read(salariesProvider.notifier).deleteSalary(record.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payslip for "${record.employeeName}" deleted.'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: context.error,
                        ),
                      );
                    }
                  } else if (val == 'edit') {
                    showDialog(
                      context: context,
                      builder: (context) => _EditPayrollDialog(record: record),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Payslip', style: TextStyle(color: context.textPrimary, fontSize: 13)),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Log', style: TextStyle(color: context.error, fontSize: 13)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String val, BuildContext context, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: context.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        Text(
          val,
          style: TextStyle(
            color: color ?? context.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProcessPayrollDialog extends ConsumerStatefulWidget {
  const _ProcessPayrollDialog();

  @override
  ConsumerState<_ProcessPayrollDialog> createState() => _ProcessPayrollDialogState();
}

class _ProcessPayrollDialogState extends ConsumerState<_ProcessPayrollDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  String? _selectedEmployeeName;
  late List<String> _payPeriodOptions;
  late String _payPeriod;
  double _baseSalary = 0.0;
  String _paymentMethod = 'Bank Transfer';

  final _allowancesController = TextEditingController(text: '0');
  final _deductionsController = TextEditingController(text: '0');
  
  // Salary advance details
  double _advanceDeduction = 0.0;
  bool _hasActiveAdvance = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _payPeriodOptions = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      final monthName = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][d.month - 1];
      return '$monthName ${d.year}';
    });
    _payPeriod = _payPeriodOptions.first;
  }

  @override
  void dispose() {
    _allowancesController.dispose();
    _deductionsController.dispose();
    super.dispose();
  }

  double get netSalary {
    final allowances = double.tryParse(_allowancesController.text) ?? 0.0;
    final otherDeductions = double.tryParse(_deductionsController.text) ?? 0.0;
    return _baseSalary + allowances - (otherDeductions + _advanceDeduction);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Fetch active employees
    final employees = ref.watch(employeesProvider).employees.where((e) => e.status == 'Active').toList();

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
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
                      'Process Payroll Slip',
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

                // Pay Period
                _buildLabel('Pay Period'),
                DropdownButtonFormField<String>(
                  value: _payPeriod,
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration(''),
                  items: _payPeriodOptions.map((period) {
                    return DropdownMenuItem(value: period, child: Text(period));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _payPeriod = val);
                  },
                ),
                const SizedBox(height: 16),

                // Employee Select
                _buildLabel('Select Employee'),
                DropdownButtonFormField<String>(
                  value: _selectedEmployeeId,
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration('Choose employee'),
                  validator: (val) => val == null ? 'Please select employee' : null,
                  items: employees.map((emp) {
                    return DropdownMenuItem(
                      value: emp.id,
                      child: Text(emp.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final emp = employees.firstWhere((e) => e.id == val);
                      
                      // INTEGRATION: Check for active salary advances for this employee
                      final activeAdvances = ref.read(advancesProvider).advances
                          .where((adv) => adv.employeeId == val && adv.status == 'Approved')
                          .toList();
                      
                      double deductionVal = 0.0;
                      bool activeAdv = false;
                      if (activeAdvances.isNotEmpty) {
                        deductionVal = activeAdvances.first.monthlyDeduction;
                        activeAdv = true;
                      }

                      setState(() {
                        _selectedEmployeeId = val;
                        _selectedEmployeeName = emp.name;
                        _baseSalary = emp.baseSalary;
                        _paymentMethod = emp.paymentMethod;
                        _advanceDeduction = deductionVal;
                        _hasActiveAdvance = activeAdv;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                if (_hasActiveAdvance) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.warningLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: context.warning, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Active advance detected. Monthly installment of Rs. ${_advanceDeduction.toStringAsFixed(0)} will be auto-deducted.',
                            style: TextStyle(color: context.warning, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Base Salary Display
                _buildLabel('Base Salary (Rs. / month)'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.scaffoldBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.border),
                  ),
                  child: Text(
                    'Rs. ${_baseSalary.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Allowances & Other Deductions Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Allowances (+)'),
                          TextFormField(
                            controller: _allowancesController,
                            style: TextStyle(color: context.textPrimary),
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration('e.g. 100'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Other Deductions (-)'),
                          TextFormField(
                            controller: _deductionsController,
                            style: TextStyle(color: context.textPrimary),
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration('e.g. 50'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Final Net Salary Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.successLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Calculated Pay:',
                        style: TextStyle(
                          color: context.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rs. ${netSalary.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: context.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(foregroundColor: context.textSecondary),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate() && _selectedEmployeeId != null) {
                          final slip = SalaryRecord(
                            id: 'sal_${DateTime.now().millisecondsSinceEpoch}',
                            employeeId: _selectedEmployeeId!,
                            employeeName: _selectedEmployeeName!,
                            payPeriod: _payPeriod,
                            baseSalary: _baseSalary,
                            allowances: double.tryParse(_allowancesController.text) ?? 0.0,
                            deductions: (double.tryParse(_deductionsController.text) ?? 0.0) + _advanceDeduction,
                            netPaid: netSalary,
                            paymentDate: DateTime.now().toIso8601String().substring(0, 10),
                            status: 'Paid',
                            paymentMethod: _paymentMethod,
                          );
                          Navigator.of(context).pop(slip);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Pay Out & Log'),
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

class _EditPayrollDialog extends ConsumerStatefulWidget {
  final SalaryRecord record;
  const _EditPayrollDialog({required this.record});

  @override
  ConsumerState<_EditPayrollDialog> createState() => _EditPayrollDialogState();
}

class _EditPayrollDialogState extends ConsumerState<_EditPayrollDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _payPeriod;
  late double _baseSalary;
  late String _paymentMethod;
  late final TextEditingController _allowancesController;
  late final TextEditingController _deductionsController;

  @override
  void initState() {
    super.initState();
    _payPeriod = widget.record.payPeriod;
    _baseSalary = widget.record.baseSalary;
    _paymentMethod = widget.record.paymentMethod;
    _allowancesController = TextEditingController(text: widget.record.allowances.toStringAsFixed(0));
    _deductionsController = TextEditingController(text: widget.record.deductions.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _allowancesController.dispose();
    _deductionsController.dispose();
    super.dispose();
  }

  double get netSalary {
    final allowances = double.tryParse(_allowancesController.text) ?? 0.0;
    final deductions = double.tryParse(_deductionsController.text) ?? 0.0;
    return _baseSalary + allowances - deductions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
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
                      'Edit Payroll Details',
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

                Text(
                  'Employee: ${widget.record.employeeName}',
                  style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Pay Period
                _buildLabel('Pay Period'),
                DropdownButtonFormField<String>(
                  value: _payPeriod,
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration(''),
                  items: const [
                    DropdownMenuItem(value: 'May 2026', child: Text('May 2026')),
                    DropdownMenuItem(value: 'April 2026', child: Text('April 2026')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _payPeriod = val);
                  },
                ),
                const SizedBox(height: 16),

                // Base Salary Display
                _buildLabel('Base Salary (Rs. / month)'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.scaffoldBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.border),
                  ),
                  child: Text(
                    'Rs. ${_baseSalary.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Allowances & Other Deductions Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Allowances (+)'),
                          TextFormField(
                            controller: _allowancesController,
                            style: TextStyle(color: context.textPrimary),
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration('e.g. 100'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Deductions (-)'),
                          TextFormField(
                            controller: _deductionsController,
                            style: TextStyle(color: context.textPrimary),
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration('e.g. 50'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Payment Method
                _buildLabel('Payment Method'),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration(''),
                  items: const [
                    DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _paymentMethod = val);
                  },
                ),
                const SizedBox(height: 20),

                // Final Net Salary Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.successLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Calculated Pay:',
                        style: TextStyle(
                          color: context.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rs. ${netSalary.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: context.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(foregroundColor: context.textSecondary),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final updated = widget.record.copyWith(
                            payPeriod: _payPeriod,
                            allowances: double.tryParse(_allowancesController.text) ?? 0.0,
                            deductions: double.tryParse(_deductionsController.text) ?? 0.0,
                            netPaid: netSalary,
                            paymentMethod: _paymentMethod,
                          );
                          ref.read(salariesProvider.notifier).updateSalary(updated);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Payroll details updated successfully.'),
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
                      ),
                      child: const Text('Save Changes'),
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
