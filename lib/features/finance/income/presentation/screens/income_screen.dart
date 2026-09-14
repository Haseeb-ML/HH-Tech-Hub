import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/finance/shared/widgets/finance_sub_nav.dart';
import '../providers/income_provider.dart';
import 'package:software_house_erp/core/widgets/export_button.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../../clients/clients/presentation/providers/clients_provider.dart';
import '../../../../projects/projects/presentation/providers/projects_provider.dart';
import '../../../../projects/projects/domain/entities/project.dart';
import '../../domain/entities/income_record.dart';

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(incomeProvider);
    final accountsState = ref.watch(accountsProvider);
    final clientsState = ref.watch(clientsProvider);
    final theme = Theme.of(context);

    // Calculate metrics
    final totalIncomes = state.incomes.length;
    final totalAmount = state.incomes.fold<double>(0.0, (sum, i) => sum + i.amount);
    final pendingAmount = state.incomes
        .where((i) => i.status == 'Pending')
        .fold<double>(0.0, (sum, i) => sum + i.amount);
    final receivedAmount = totalAmount - pendingAmount;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: state.isLoading && state.incomes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const FinanceSubNav(activeRoute: '/finance/income'),
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
                                  'Income Registry',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Record client receipts, invoices paid, and project revenues.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                  ExportButton(
                                    title: 'Income Registry',
                                    fileName: 'income_registry_export',
                                    headers: ['Receipt ID', tr('Date'), 'Client Name', 'Amount', 'Account ID', 'Invoice Number', tr('Description'), tr('Status')],
                                    rows: state.filteredIncomes.map((i) => [
                                      i.id,
                                      i.date,
                                      i.clientName,
                                      'Rs. ${i.amount.toStringAsFixed(2)}',
                                      i.accountId,
                                      i.invoiceNumber,
                                      i.description,
                                      i.status,
                                    ]).toList(),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Metrics Cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final gridCrossCount = constraints.maxWidth >= 1200 ? 4 : (constraints.maxWidth >= 600 ? 2 : 1);
                            return GridView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridCrossCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: gridCrossCount == 4 ? 1.6 : 2.5,
                              ),
                              children: [
                                StatCard(
                                  title: 'Total Invoiced',
                                  tooltipMessage: 'Detailed statistics and information regarding Total Invoiced.',
                                  value: 'Rs. ${(totalAmount / 1000).toStringAsFixed(1)}k',
                                  icon: Icons.assignment_turned_in_outlined,
                                  iconColor: context.primaryColor,
                                  iconBgColor: context.infoLight,
                                ),
                                StatCard(
                                  title: tr('Received Inflow'),
                                  tooltipMessage: "Detailed statistics and information regarding ${tr('Received Inflow')}.",
                                  value: 'Rs. ${(receivedAmount / 1000).toStringAsFixed(1)}k',
                                  icon: Icons.check_circle_outline,
                                  iconColor: context.success,
                                  iconBgColor: context.successLight,
                                ),
                                StatCard(
                                  title: tr('Pending Inflow'),
                                  tooltipMessage: "Detailed statistics and information regarding ${tr('Pending Inflow')}.",
                                  value: 'Rs. ${(pendingAmount / 1000).toStringAsFixed(1)}k',
                                  icon: Icons.hourglass_empty,
                                  iconColor: context.warning,
                                  iconBgColor: context.warningLight,
                                ),
                                StatCard(
                                  title: 'Registry Count',
                                  tooltipMessage: 'Detailed statistics and information regarding Registry Count.',
                                  value: '$totalIncomes Receipts',
                                  icon: Icons.receipt_outlined,
                                  iconColor: Colors.purple,
                                  iconBgColor: context.isDarkMode ? Colors.purple.withValues(alpha: 0.2) : const Color(0xFFF3E8FF),
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
                                      onChanged: (val) => ref.read(incomeProvider.notifier).setSearchQuery(val),
                                      style: TextStyle(color: context.textPrimary),
                                      decoration: InputDecoration(
                                        hintText: tr('Search by client, invoice or description...'),
                                        hintStyle: TextStyle(fontSize: 13, color: context.textMuted),
                                        prefixIcon: Icon(Icons.search, size: 18, color: context.textMuted),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Client Filter
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
                                        value: state.clientFilter,
                                        dropdownColor: context.cardBg,
                                        style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                                        items: [
                                          DropdownMenuItem(value: 'All', child: Text(tr('All Clients'))),
                                          ...clientsState.clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            ref.read(incomeProvider.notifier).setClientFilter(val);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Income Table/List
                        state.filteredIncomes.isEmpty
                            ? _buildEmptyState(context)
                            : Container(
                                decoration: BoxDecoration(
                                  color: context.cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: context.border),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: state.filteredIncomes.length,
                                    separatorBuilder: (context, index) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final income = state.filteredIncomes[index];
                                      final account = accountsState.accounts.where((a) => a.id == income.accountId).firstOrNull;
                                      return _IncomeListTile(income: income, accountName: account?.name ?? 'Unknown');
                                    },
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 48, color: context.textMuted),
            const SizedBox(height: 16),
            Text(
              'No Incomes Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Record a new client invoice/revenue entry to start tracking.',
              style: TextStyle(fontSize: 13, color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeListTile extends ConsumerWidget {
  final IncomeRecord income;
  final String accountName;

  const _IncomeListTile({required this.income, required this.accountName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final isReceived = income.status == 'Received';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isReceived ? context.successLight : context.warningLight,
            child: Icon(
              isReceived ? Icons.done : Icons.hourglass_bottom,
              size: 16,
              color: isReceived ? context.success : context.warning,
            ),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      income.clientName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    if (income.invoiceNumber.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.infoLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          income.invoiceNumber,
                          style: TextStyle(fontSize: 9, color: context.info, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  income.description,
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      income.date,
                      style: TextStyle(color: context.textMuted, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(color: context.textMuted, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Deposited: $accountName',
                      style: TextStyle(color: context.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Amount & Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${income.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: context.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Income Record'),
                      content: Text('${tr("Are you sure you want to delete this income log for")} "${income.clientName}"? ${tr("This will rollback the deposit account balance and ledger entry.")}'),
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
                    ref.read(incomeProvider.notifier).deleteIncome(income.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Income record deleted & rolled back.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: context.error,
                      ),
                    );
                  }
                },
                child: Text(
                  'Delete Log',
                  style: TextStyle(color: context.error, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordIncomeDialog extends ConsumerStatefulWidget {
  const _RecordIncomeDialog();

  @override
  ConsumerState<_RecordIncomeDialog> createState() => _RecordIncomeDialogState();
}

class _RecordIncomeDialogState extends ConsumerState<_RecordIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _invoiceController;
  late final TextEditingController _descController;

  String? _selectedClientId;
  String? _selectedClientName;
  String? _selectedAccountId;
  String? _selectedProjectId;
  String? _selectedProjectName;
  String _status = 'Received';
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _invoiceController = TextEditingController();
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _invoiceController.dispose();
    _descController.dispose();
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
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Consumer(
          builder: (context, ref, child) {
            final clients = ref.watch(clientsProvider).clients.where((c) => c.status == 'Active').toList();
            final accounts = ref.watch(accountsProvider).accounts.where((a) => a.status == 'Active').toList();
            final allProjects = ref.watch(projectsProvider).projects;

            // Set default account if not selected
            if (_selectedAccountId == null && accounts.isNotEmpty) {
              _selectedAccountId = accounts.first.id;
            }

            final clientProjects = _selectedClientId == null
                ? <Project>[]
                : allProjects.where((p) => p.clientId == _selectedClientId).toList();

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
                          'Record Business Income',
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

                    // Client Dropdown
                    _buildLabel('Associated Client'),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedClientId,
                      dropdownColor: context.cardBg,
                      style: TextStyle(color: context.textPrimary, fontSize: 13),
                      decoration: _buildInputDecoration('Select Client'),
                      validator: (val) => val == null ? 'Please select client' : null,
                      items: clients.map((c) {
                        return DropdownMenuItem(value: c.id, child: Text(c.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final cl = clients.firstWhere((c) => c.id == val);
                          setState(() {
                            _selectedClientId = val;
                            _selectedClientName = cl.name;
                            _selectedProjectId = null;
                            _selectedProjectName = null;
                          });
                        }
                      },
                    ),

                    if (_selectedClientId != null && clientProjects.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildLabel('Associated Project'),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _selectedProjectId,
                        dropdownColor: context.cardBg,
                        style: TextStyle(color: context.textPrimary, fontSize: 13),
                        decoration: _buildInputDecoration('Select Project'),
                        items: clientProjects.map((p) {
                          return DropdownMenuItem(value: p.id, child: Text(p.name));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final pr = clientProjects.firstWhere((p) => p.id == val);
                            setState(() {
                              _selectedProjectId = val;
                              _selectedProjectName = pr.name;
                            });
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Amount & Invoice Number
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Amount Received (Rs.)'),
                              TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: context.textPrimary),
                                decoration: _buildInputDecoration('e.g. 50000'),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Enter amount';
                                  if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Invalid amount';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Invoice / Ref No.'),
                              TextFormField(
                                controller: _invoiceController,
                                style: TextStyle(color: context.textPrimary),
                                decoration: _buildInputDecoration('e.g. INV-2026-004'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Deposit Account & Date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Deposit Account'),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _selectedAccountId,
                                dropdownColor: context.cardBg,
                                style: TextStyle(color: context.textPrimary, fontSize: 13),
                                decoration: _buildInputDecoration('Select Account'),
                                items: accounts.map((a) {
                                  return DropdownMenuItem(value: a.id, child: Text(a.name));
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedAccountId = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Date Received'),
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
                                      style: TextStyle(color: context.textPrimary, fontSize: 13),
                                    ),
                                    Icon(Icons.calendar_today, size: 16, color: context.primaryColor),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildLabel('Description / Specifications'),
                    TextFormField(
                      controller: _descController,
                      maxLines: 2,
                      style: TextStyle(color: context.textPrimary),
                      decoration: _buildInputDecoration('Enter detail notes about this revenue receipt...'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter description' : null,
                    ),
                    const SizedBox(height: 16),

                    // Status Dropdown
                    _buildLabel('Receipt Status'),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _status,
                      dropdownColor: context.cardBg,
                      style: TextStyle(color: context.textPrimary, fontSize: 13),
                      decoration: _buildInputDecoration('Select Status'),
                      items: [tr('Received'), 'Pending'].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _status = val);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Actions Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() == true) {
                              final income = IncomeRecord(
                                id: 'inc_${DateTime.now().millisecondsSinceEpoch}',
                                date: _date.toIso8601String().substring(0, 10),
                                clientId: _selectedClientId!,
                                clientName: _selectedClientName!,
                                amount: double.parse(_amountController.text),
                                accountId: _selectedAccountId!,
                                invoiceNumber: _invoiceController.text.trim(),
                                description: _descController.text.trim(),
                                status: _status,
                                projectId: _selectedProjectId,
                                projectName: _selectedProjectName,
                              );
                              Navigator.of(context).pop(income);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Text(tr('Record Inflow')),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: context.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: context.primaryColor, width: 1.5),
      ),
    );
  }
}
