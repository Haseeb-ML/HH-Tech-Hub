import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/projects/shared/widgets/projects_sub_nav.dart';
import '../providers/projects_provider.dart';
import '../../domain/entities/project.dart';
import '../../../../clients/clients/presentation/providers/clients_provider.dart';
import '../../../../clients/clients/domain/entities/client.dart';
import '../../../../hr/employees/presentation/providers/employees_provider.dart';
import '../../../../hr/employees/domain/entities/employee.dart';
import '../../../tasks/presentation/providers/tasks_provider.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import '../../domain/entities/project_addon.dart';
import '../providers/project_addons_provider.dart';

import '../../../../finance/accounts/presentation/providers/accounts_provider.dart';
import '../../../../finance/accounts/domain/entities/bank_account.dart';
import '../../../../finance/accounts/presentation/screens/accounts_screen.dart';
import '../../../../finance/income/domain/entities/income_record.dart';
import '../../../../finance/income/presentation/providers/income_provider.dart';
import '../../../../clients/clients/presentation/screens/clients_screen.dart';
import '../../../../clients/clients/data/models/client_model.dart';

class ClientAccount {
  final String id;
  final String clientId;
  final String name;
  final String bankName;
  final String accountNumber;
  final String paymentMethod; // 'Cash', 'Bank', 'Online'

  const ClientAccount({
    required this.id,
    required this.clientId,
    required this.name,
    required this.bankName,
    required this.accountNumber,
    required this.paymentMethod,
  });
}

class ClientAccountsNotifier extends Notifier<List<ClientAccount>> {
  static const _prefKey = 'client_accounts_list';

  @override
  List<ClientAccount> build() {
    _loadFromPrefs();
    return [];
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);
      if (jsonStr != null) {
        final List<dynamic> decoded = json.decode(jsonStr);
        final loaded = decoded.map((item) {
          return ClientAccount(
            id: item['id'] ?? '',
            clientId: item['clientId'] ?? '',
            name: item['name'] ?? '',
            bankName: item['bankName'] ?? '',
            accountNumber: item['accountNumber'] ?? '',
            paymentMethod: item['paymentMethod'] ?? 'Bank',
          );
        }).toList();

        final ids = state.map((c) => c.id).toSet();
        final newItems = loaded
            .where((item) => !ids.contains(item.id))
            .toList();
        if (newItems.isNotEmpty) {
          state = [...state, ...newItems];
        }
      }
    } catch (e) {
      debugPrint('Failed to load client accounts: $e');
    }
  }

  Future<void> addClientAccount(ClientAccount account) async {
    state = [...state, account];
    await _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = state
          .map(
            (ca) => {
              'id': ca.id,
              'clientId': ca.clientId,
              'name': ca.name,
              'bankName': ca.bankName,
              'accountNumber': ca.accountNumber,
              'paymentMethod': ca.paymentMethod,
            },
          )
          .toList();
      await prefs.setString(_prefKey, json.encode(serialized));
    } catch (e) {
      debugPrint('Failed to save client accounts: $e');
    }
  }
}

final clientAccountsProvider =
    NotifierProvider<ClientAccountsNotifier, List<ClientAccount>>(() {
      return ClientAccountsNotifier();
    });

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    debugPrint('ProjectsScreen: build method called');
    final state = ref.watch(projectsProvider);
    final theme = Theme.of(context);

    // Calculate metrics
    final totalProjects = state.projects.length;
    final inProgressCount = state.projects
        .where((p) => p.status == 'In Progress')
        .length;
    final completedCount = state.projects
        .where((p) => p.status == 'Completed')
        .length;
    final totalBudget = state.projects.fold<double>(
      0,
      (sum, p) => sum + p.budget,
    );

    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = width >= 1400
        ? 4
        : (width >= 900
            ? 3
            : (width >= 600 ? 2 : 1));

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: state.isLoading && state.projects.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const ProjectsSubNav(activeRoute: '/projects/list'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(width < 600 ? 12 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Add Button Row
                        LayoutBuilder(
                          builder: (context, constraints) {
    final adminState = ref.watch(adminProvider);
    final canCreate = adminState.hasPermission(AppModule.projectsList, PermissionAction.create);

    final isNarrow = constraints.maxWidth < 650;
    final titleCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr('Projects & Operations'),
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Track software house software projects, deliverables, timelines, and budgets.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.textSecondary,
          ),
        ),
      ],
    );

    final addBtn = ElevatedButton.icon(
      onPressed: () async {
        final hasDraft =
            await _AddEditProjectDialog.hasDraft();
        var resumeDraft = false;
        if (hasDraft && context.mounted) {
          final choice = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text(
                'Unsaved Project Draft',
              ),
              content: const Text(
                'A previously started project form was saved. Would you like to resume it?',
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, 'new'),
                  child: const Text('Start New'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, 'resume'),
                  child: const Text('Resume Draft'),
                ),
              ],
            ),
          );
          if (choice == null) return;
          resumeDraft = choice == 'resume';
          if (!resumeDraft) {
            await _AddEditProjectDialog.clearDraft();
          }
        }
        final result = await showDialog<Project>(
          context: context,
          builder: (context) => _AddEditProjectDialog(
            resumeDraft: resumeDraft,
          ),
        );
        if (result != null) {
          ref
              .read(projectsProvider.notifier)
              .addProject(result);

          // Automatically sync inflow transaction to Finance Accounts
          if (result.advancedPayment > 0) {
            String targetAccId = result.bankAccountId;
            final caList = ref.read(clientAccountsProvider);
            final ca = caList.where((c) =>
                c.name == result.clientPaymentSource ||
                c.id == result.clientPaymentSource ||
                (result.clientPaymentSource.contains(c.name)) ||
                (result.clientId.isNotEmpty && c.clientId == result.clientId)).firstOrNull;
            if (ca != null && ca.paymentMethod == 'Bank' && (targetAccId.isEmpty || targetAccId.contains('cash'))) {
              final bankAcc = ref.read(accountsProvider).accounts.where((a) => a.type == 'Bank' && a.status == 'Active').firstOrNull;
              targetAccId = bankAcc?.id ?? ca.id;
            }

            final incomeRecord = IncomeRecord(
              id: 'inc_${DateTime.now().millisecondsSinceEpoch}',
              date: result.startDate,
              clientId: result.clientId,
              clientName: result.clientName,
              amount: result.advancedPayment,
              accountId: targetAccId.isNotEmpty ? targetAccId : result.bankAccountId,
              invoiceNumber: 'INV-${result.id}',
              description:
                  'Project Advance: ${result.name} (Source: ${result.clientPaymentSource})',
              status: 'Received',
              projectId: result.id,
              projectName: result.name,
              projectPaymentType: 'Advance',
            );
            ref
                .read(incomeProvider.notifier)
                .addIncome(incomeRecord);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${tr("Project")} "${result.name}" ${tr("added successfully.")}',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: context.success,
            ),
          );
        }
      },
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add Project'),
      style: ElevatedButton.styleFrom(
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleCol,
          if (canCreate) ...[
            const SizedBox(height: 14),
            addBtn,
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(child: titleCol),
        if (canCreate) ...[
          const SizedBox(width: 16),
          addBtn,
        ],
      ],
    );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Metrics Cards
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final gridCrossCount = constraints.maxWidth >= 1200 ? 4 : 2;
                            final childAspect = constraints.maxWidth < 600 ? 1.25 : (gridCrossCount == 4 ? 1.6 : 2.5);
                            return GridView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: gridCrossCount,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: childAspect,
                                  ),
                              children: [
                                StatCard(
                                  title: tr('Total Projects'),
                                  tooltipMessage:
                                      "Detailed statistics and information regarding ${tr('Total Projects')}.",
                                  value: '$totalProjects',
                                  icon: Icons.assignment_outlined,
                                  iconColor: context.primaryColor,
                                  iconBgColor: context.infoLight,
                                ),
                                StatCard(
                                  title: 'In Progress',
                                  tooltipMessage:
                                      'Detailed statistics and information regarding In Progress.',
                                  value: '$inProgressCount',
                                  icon: Icons.sync,
                                  iconColor: context.warning,
                                  iconBgColor: context.warningLight,
                                ),
                                StatCard(
                                  title: 'Completed',
                                  tooltipMessage:
                                      'Detailed statistics and information regarding Completed.',
                                  value: '$completedCount',
                                  icon: Icons.check_circle_outline,
                                  iconColor: context.success,
                                  iconBgColor: context.successLight,
                                ),
                                StatCard(
                                  title: 'Total Budget',
                                  tooltipMessage:
                                      'Detailed statistics and information regarding Total Budget.',
                                  value:
                                      'Rs. ${(totalBudget / 1000).toStringAsFixed(1)}k',
                                  icon: Icons.monetization_on_outlined,
                                  iconColor: Colors.deepPurple,
                                  iconBgColor: context.isDarkMode
                                      ? Colors.deepPurple.withOpacity(0.2)
                                      : const Color(0xFFF3E8FF),
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
                                final isNarrow = constraints.maxWidth < 600;
                                final searchWidget = Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: context.isDarkMode
                                        ? const Color(0xFF111827)
                                        : context.scaffoldBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: context.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    onChanged: (val) => ref
                                        .read(projectsProvider.notifier)
                                        .setSearchQuery(val),
                                    style: TextStyle(
                                      color: context.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: tr(
                                        'Search by project name, client, or description...',
                                      ),
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                );

                                final statusWidget = Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.isDarkMode
                                        ? const Color(0xFF111827)
                                        : context.scaffoldBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: context.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: state.statusFilter,
                                      dropdownColor: context.cardBg,
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      items:
                                          [
                                            'All',
                                            'Planning',
                                            'In Progress',
                                            'On Hold',
                                            'Completed',
                                          ].map((s) {
                                            return DropdownMenuItem<String>(
                                              value: s,
                                              child: Text(
                                                '${tr("Status")}: $s',
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          ref
                                              .read(projectsProvider.notifier)
                                              .setStatusFilter(val);
                                        }
                                      },
                                    ),
                                  ),
                                );

                                if (isNarrow) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      searchWidget,
                                      const SizedBox(height: 12),
                                      statusWidget,
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: searchWidget),
                                    const SizedBox(width: 16),
                                    statusWidget,
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Projects Grid
                        state.filteredProjects.isEmpty
                            ? _buildEmptyState(context)
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: width < 600 ? 10 : 16,
                                      mainAxisSpacing: width < 600 ? 10 : 16,
                                      childAspectRatio: width < 600
                                          ? (width - 24) / 215
                                          : (crossAxisCount == 2
                                              ? 1.45
                                              : (crossAxisCount == 3 ? 1.25 : 1.05)),
                                    ),
                                itemCount: state.filteredProjects.length,
                                itemBuilder: (context, index) {
                                  final project = state.filteredProjects[index];
                                  return _ProjectCard(project: project);
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
            Icon(
              Icons.assignment_late_outlined,
              size: 48,
              color: context.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No Projects Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting filters or add a new project.',
              style: TextStyle(fontSize: 13, color: context.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  final Project project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final adminState = ref.watch(adminProvider);
    final canEdit = adminState.hasPermission(AppModule.projectsList, PermissionAction.edit);
    final canDelete = adminState.hasPermission(AppModule.projectsList, PermissionAction.delete);

    // Watch live project state so dialog updates in real time
    final liveProject =
        ref
            .watch(projectsProvider)
            .projects
            .where((p) => p.id == project.id)
            .firstOrNull ??
        project;

    // Status styling
    Color statusColor;
    Color statusBg;
    if (project.status == 'Completed') {
      statusColor = context.success;
      statusBg = context.successLight;
    } else if (project.status == 'In Progress') {
      statusColor = context.warning;
      statusBg = context.warningLight;
    } else if (project.status == 'Planning') {
      statusColor = context.primaryColor;
      statusBg = context.infoLight;
    } else {
      statusColor = context.textSecondary;
      statusBg = context.isDarkMode
          ? const Color(0xFF374151)
          : const Color(0xFFF3F4F6);
    }

    // Resolve team member initials
    final allEmployees = ref.watch(employeesProvider).employees;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => _ViewProjectDetailsDialog(project: project),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(isMobile ? 10 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Project Name & Status & Popup Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                          fontSize: isMobile ? 13 : 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Client: ${project.clientName}',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: isMobile ? 10 : 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 6 : 8,
                    vertical: isMobile ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tr(project.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: isMobile ? 8 : 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (canEdit || canDelete)
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: isMobile ? 16 : 18,
                      color: context.textSecondary,
                    ),
                    color: context.cardBg,
                    padding: EdgeInsets.zero,
                    onSelected: (val) async {
                      if (val == 'delete' && canDelete) {
                        ref
                            .read(projectsProvider.notifier)
                            .deleteProject(project.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${tr("Project")} "${project.name}" ${tr("deleted.")}',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: context.error,
                          ),
                        );
                      } else if (val == 'addons') {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              _ProjectAddonsDialog(project: liveProject),
                        );
                      } else if (val == 'edit' && canEdit) {
                        final result = await showDialog<Project>(
                          context: context,
                          builder: (context) =>
                              _AddEditProjectDialog(project: project),
                        );
                        if (result != null) {
                          ref
                              .read(projectsProvider.notifier)
                              .updateProject(result);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'addons',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.extension_outlined,
                              size: 16,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add-Ons & Scope',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (canEdit)
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(
                            tr('Edit Details'),
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (canDelete)
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete Project',
                            style: TextStyle(color: context.error, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Expanded(
              child: Text(
                project.description,
                style: TextStyle(color: context.textSecondary, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),

            const Divider(height: 1),
            const SizedBox(height: 10),

            // Row 4: Financials (Budget, Advanced/Received, Remaining)
            (() {
              final projectAddons = ref
                  .watch(projectAddonsProvider)
                  .where((a) => a.projectId == project.id)
                  .toList();
              final double totalAddonsAmount =
                  projectAddons.fold(0.0, (sum, a) => sum + a.amount);
              final double totalRevisedBudget = project.budget + totalAddonsAmount;

              final projectIncomes = ref
                  .watch(incomeProvider)
                  .incomes
                  .where((i) => i.projectId == project.id)
                  .toList();
              final double actualReceived = projectIncomes.isNotEmpty
                  ? projectIncomes.fold(0.0, (sum, i) => sum + i.amount)
                  : (project.advancedPayment +
                      project.partialPayments +
                      project.finalPayment);
              final double actualRemaining =
                  (totalRevisedBudget - actualReceived).clamp(0.0, double.infinity);

              if (isMobile) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('Budget'),
                                style: TextStyle(
                                  color: context.textMuted,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Rs. ${totalRevisedBudget.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: context.primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (totalAddonsAmount > 0)
                                Text(
                                  '+Rs. ${totalAddonsAmount.toStringAsFixed(0)} Add-on',
                                  style: const TextStyle(
                                    color: Colors.purple,
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                tr('Remaining Payment'),
                                style: TextStyle(
                                  color: context.textMuted,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                actualRemaining <= 0
                                    ? 'Fully Paid'
                                    : 'Rs. ${actualRemaining.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: actualRemaining > 0
                                      ? context.error
                                      : context.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('Received Payment'),
                                style: TextStyle(
                                  color: context.textMuted,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Rs. ${actualReceived.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: context.primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('Budget'),
                            style: TextStyle(
                              color: context.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Rs. ${totalRevisedBudget.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: context.primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (totalAddonsAmount > 0)
                            Text(
                              '+Rs. ${totalAddonsAmount.toStringAsFixed(0)} Add-on',
                              style: const TextStyle(
                                color: Colors.purple,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            tr('Received Payment'),
                            style: TextStyle(
                              color: context.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Rs. ${actualReceived.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: context.primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            tr('Remaining Payment'),
                            style: TextStyle(
                              color: context.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            actualRemaining <= 0
                                ? 'Fully Paid'
                                : 'Rs. ${actualRemaining.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: actualRemaining > 0
                                  ? context.error
                                  : context.success,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            })(),
            const SizedBox(height: 10),

            // Row 5: Bank Account & Team Members
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance,
                        size: 14,
                        color: context.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          project.bankAccountName.isNotEmpty
                              ? '${project.bankAccountName} (${project.accountHolder}) • Source: ${project.clientPaymentSource}'
                              : 'Source: ${project.clientPaymentSource}',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (project.teamMembers.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  // Team member overlapping avatars
                  SizedBox(
                    height: 28,
                    width: isMobile
                        ? ((project.teamMembers.length > 3 ? 3 : project.teamMembers.length) * 16.0 + 12.0)
                        : ((project.teamMembers.length > 3 ? 3 : project.teamMembers.length) * 18.0 + 14.0),
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: List.generate(
                        project.teamMembers.length > 3
                            ? 3
                            : project.teamMembers.length,
                        (index) {
                          final empId = project.teamMembers[index];
                          final emp = allEmployees
                              .where((e) => e.id == empId)
                              .firstOrNull;
                          final initials = emp != null
                              ? emp.name
                                    .split(' ')
                                    .map((e) => e[0])
                                    .take(2)
                                    .join()
                                    .toUpperCase()
                              : '?';

                          return Positioned(
                            right: index * (isMobile ? 15.0 : 18.0),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: context.cardBg,
                                  width: 1.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: isMobile ? 11 : 12,
                                backgroundColor: context.isDarkMode
                                    ? const Color(0xFF374151)
                                    : const Color(0xFFDBEAFE),
                                child: Text(
                                  initials,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: context.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Row 6: Project Add-Ons Bar / Button
            Builder(
              builder: (context) {
                final projectAddons = ref
                    .watch(projectAddonsProvider)
                    .where((a) => a.projectId == project.id)
                    .toList();
                final totalAddons = projectAddons.length;
                final totalAddonAmount =
                    projectAddons.fold(0.0, (sum, a) => sum + a.amount);
                final totalAddonPaid =
                    projectAddons.fold(0.0, (sum, a) => sum + a.amountPaid);
                final totalAddonPending = totalAddonAmount - totalAddonPaid;

                return InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          _ProjectAddonsDialog(project: liveProject),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: totalAddons > 0
                          ? (totalAddonPending > 0
                              ? Colors.purple.withOpacity(0.08)
                              : context.success.withOpacity(0.08))
                          : context.primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: totalAddons > 0
                            ? (totalAddonPending > 0
                                ? Colors.purple.withOpacity(0.3)
                                : context.success.withOpacity(0.3))
                            : context.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.extension_rounded,
                                size: 13,
                                color: totalAddons > 0
                                    ? Colors.purple
                                    : context.primaryColor,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  totalAddons > 0
                                      ? '$totalAddons Add-On${totalAddons > 1 ? 's' : ''} (+Rs. ${totalAddonAmount.toStringAsFixed(0)})'
                                      : '+ Add-On / Scope Change',
                                  style: TextStyle(
                                    fontSize: isMobile ? 9.5 : 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: totalAddons > 0
                                        ? Colors.purple
                                        : context.primaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (totalAddons > 0 && totalAddonPending > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: context.error.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Rs. ${totalAddonPending.toStringAsFixed(0)} Due',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: context.error,
                              ),
                            ),
                          )
                        else if (totalAddons > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: context.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'All Paid',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: context.success,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 9,
                            color: context.textMuted,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddEditProjectDialog extends ConsumerStatefulWidget {
  final Project? project;
  final bool resumeDraft;

  const _AddEditProjectDialog({this.project, this.resumeDraft = false});

  static const _draftKey = 'project_add_form_draft';

  static Future<bool> hasDraft() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_draftKey);
  }

  static Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  @override
  ConsumerState<_AddEditProjectDialog> createState() =>
      _AddEditProjectDialogState();
}

class _AddEditProjectDialogState extends ConsumerState<_AddEditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _budgetController;
  late final TextEditingController _advancedController;
  late final TextEditingController _partialPaymentController;

  String? _selectedClientId;
  String? _selectedClientName;
  Client? _pendingNewClient;
  String _status = 'Planning';
  String? _selectedBankAccountId;
  String? _selectedBankAccountName;

  // Client Account selection
  String? _selectedClientAccountId;
  String? _selectedClientAccountName;

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 90));

  List<String> _teamMembers = [];
  Future<void> _draftSaveQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descController = TextEditingController(
      text: widget.project?.description ?? '',
    );
    _budgetController = TextEditingController(
      text: widget.project?.budget.toStringAsFixed(0) ?? '',
    );
    _advancedController = TextEditingController(
      text: widget.project?.advancedPayment.toStringAsFixed(0) ?? '0',
    );
    _partialPaymentController = TextEditingController(text: '0');

    if (widget.project == null) {
      _nameController.addListener(_queueDraftSave);
      _descController.addListener(_queueDraftSave);
      _budgetController.addListener(_queueDraftSave);
      _advancedController.addListener(_queueDraftSave);
      if (widget.resumeDraft) {
        _restoreDraft();
      }
    }

    if (widget.project != null) {
      _selectedClientId = widget.project!.clientId;
      _selectedClientName = widget.project!.clientName;
      _status = widget.project!.status;
      final parsedStart = DateTime.tryParse(widget.project!.startDate);
      if (parsedStart != null) {
        _startDate = parsedStart;
        if (parsedStart.hour != 0 || parsedStart.minute != 0) {
          _startTime = TimeOfDay(
            hour: parsedStart.hour,
            minute: parsedStart.minute,
          );
        } else {
          final match = RegExp(
            r'proj_(\d{10,})',
          ).firstMatch(widget.project!.id);
          if (match != null) {
            final epoch = int.tryParse(match.group(1)!);
            if (epoch != null) {
              final dt = DateTime.fromMillisecondsSinceEpoch(epoch);
              _startTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
            }
          }
        }
      }
      _endDate = DateTime.tryParse(widget.project!.endDate) ?? DateTime.now();
      _teamMembers = List.from(widget.project!.teamMembers);
      _selectedBankAccountId = widget.project!.bankAccountId;
      _selectedBankAccountName = widget.project!.bankAccountName;

      // Look up if there's a matching client account name/source
      final caList = ref.read(clientAccountsProvider);
      final matchedCa = caList.where((ca) =>
          ca.id == widget.project!.clientPaymentSource ||
          ca.name == widget.project!.clientPaymentSource ||
          (widget.project!.clientPaymentSource.contains(ca.name)) ||
          (widget.project!.clientId.isNotEmpty && ca.clientId == widget.project!.clientId)
      ).firstOrNull;
      if (matchedCa != null) {
        _selectedClientAccountId = matchedCa.id;
        _selectedClientAccountName = matchedCa.name;
      } else {
        _selectedClientAccountName = widget.project!.clientPaymentSource;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _budgetController.dispose();
    _advancedController.dispose();
    _partialPaymentController.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_AddEditProjectDialog._draftKey);
    if (!mounted || jsonString == null) return;

    try {
      final draft = json.decode(jsonString) as Map<String, dynamic>;
      setState(() {
        _nameController.text = draft['name'] as String? ?? '';
        _descController.text = draft['description'] as String? ?? '';
        _budgetController.text = draft['budget'] as String? ?? '';
        _advancedController.text = draft['advancedPayment'] as String? ?? '0';
        _selectedClientId = draft['clientId'] as String?;
        _selectedClientName = draft['clientName'] as String?;
        _status = draft['status'] as String? ?? 'Planning';
        _selectedBankAccountId = draft['bankAccountId'] as String?;
        _selectedBankAccountName = draft['bankAccountName'] as String?;
        _selectedClientAccountId = draft['clientAccountId'] as String?;
        _selectedClientAccountName = draft['clientAccountName'] as String?;
        _startDate =
            DateTime.tryParse(draft['startDate'] as String? ?? '') ??
            _startDate;
        _endDate =
            DateTime.tryParse(draft['endDate'] as String? ?? '') ?? _endDate;
        final startHour = draft['startHour'] as int?;
        final startMinute = draft['startMinute'] as int?;
        if (startHour != null && startMinute != null) {
          _startTime = TimeOfDay(hour: startHour, minute: startMinute);
        }
        _teamMembers = List<String>.from(
          draft['teamMembers'] as List? ?? const [],
        );
        if (draft['pendingClient'] != null) {
          try {
            _pendingNewClient = ClientModel.fromJson(
              draft['pendingClient'] as Map<String, dynamic>,
            );
          } catch (_) {}
        }
      });
      _queueDraftSave();
    } catch (e) {
      debugPrint('Failed to restore project draft: $e');
    }
  }

  void _queueDraftSave() {
    if (widget.project != null) return;
    final draft = {
      'name': _nameController.text,
      'description': _descController.text,
      'budget': _budgetController.text,
      'advancedPayment': _advancedController.text,
      'clientId': _selectedClientId,
      'clientName': _selectedClientName,
      'status': _status,
      'bankAccountId': _selectedBankAccountId,
      'bankAccountName': _selectedBankAccountName,
      'clientAccountId': _selectedClientAccountId,
      'clientAccountName': _selectedClientAccountName,
      'startDate': _startDate.toIso8601String(),
      'endDate': _endDate.toIso8601String(),
      'startHour': _startTime.hour,
      'startMinute': _startTime.minute,
      'teamMembers': _teamMembers,
      'pendingClient': _pendingNewClient != null
          ? ClientModel.fromEntity(_pendingNewClient!).toJson()
          : null,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    _draftSaveQueue = _draftSaveQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _AddEditProjectDialog._draftKey,
        json.encode(draft),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: context.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 750),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Consumer(
          builder: (context, ref, child) {
            final clients = ref
                .watch(clientsProvider)
                .clients
                .where((c) => c.status == 'Active')
                .toList();
            final employees = ref
                .watch(employeesProvider)
                .employees
                .where((e) => e.status == 'Active')
                .toList();

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
                          widget.project == null
                              ? 'Add New Project'
                              : 'Edit Project Details',
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

                    // Project Name
                    _buildLabel('Project Name'),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: context.textPrimary),
                      decoration: _buildInputDecoration('Enter project name'),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Please enter project name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    _buildLabel(tr('Description')),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      style: TextStyle(color: context.textPrimary),
                      decoration: _buildInputDecoration(
                        'Enter project specifications',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Please enter description'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Client & Budget Row
                    if (isMobile) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLabel(tr('Client')),
                              GestureDetector(
                                onTap: () async {
                                  final newClient =
                                      await showDialog<Client>(
                                        context: context,
                                        builder: (context) =>
                                            AddClientDialog(),
                                      );
                                  if (newClient != null) {
                                    setState(() {
                                      _pendingNewClient = newClient;
                                      _selectedClientId = newClient.id;
                                      _selectedClientName = newClient.name;
                                      if (newClient.fullPayment > 0) {
                                        _budgetController.text = newClient
                                            .fullPayment
                                            .toStringAsFixed(0);
                                      }
                                      if (newClient.advancedPayment > 0) {
                                        _advancedController.text = newClient
                                            .advancedPayment
                                            .toStringAsFixed(0);
                                      }
                                    });
                                    _queueDraftSave();
                                  }
                                },
                                child: Text(
                                  '+ Add Client',
                                  style: TextStyle(
                                    color: context.primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Builder(
                            builder: (context) {
                              final displayedClients = [...clients];
                              if (_pendingNewClient != null &&
                                  !displayedClients.any((c) => c.id == _pendingNewClient!.id)) {
                                displayedClients.add(_pendingNewClient!);
                              }
                              return DropdownButtonFormField<String>(
                                value: displayedClients.any(
                                  (c) => c.id == _selectedClientId,
                                )
                                    ? _selectedClientId
                                    : null,
                                dropdownColor: context.cardBg,
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 13,
                                ),
                                decoration: _buildInputDecoration('Select Client').copyWith(
                                  suffixIcon: _selectedClientId == null
                                      ? null
                                      : IconButton(
                                          tooltip: 'Edit Client',
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          color: context.primaryColor,
                                          onPressed: () async {
                                            final selectedClient = _pendingNewClient?.id == _selectedClientId
                                                ? _pendingNewClient!
                                                : displayedClients.firstWhere(
                                                    (client) => client.id == _selectedClientId,
                                                  );
                                            final updatedClient = await showDialog<Client>(
                                              context: context,
                                              builder: (context) => AddClientDialog(client: selectedClient),
                                            );
                                            if (updatedClient != null) {
                                              if (_pendingNewClient?.id == _selectedClientId) {
                                                setState(() {
                                                  _pendingNewClient = updatedClient;
                                                  _selectedClientName = updatedClient.name;
                                                  if (updatedClient.fullPayment > 0) {
                                                    _budgetController.text = updatedClient.fullPayment.toStringAsFixed(0);
                                                  }
                                                  if (updatedClient.advancedPayment > 0) {
                                                    _advancedController.text = updatedClient.advancedPayment.toStringAsFixed(0);
                                                  }
                                                });
                                                _queueDraftSave();
                                              } else {
                                                await ref
                                                    .read(clientsProvider.notifier)
                                                    .updateClient(updatedClient);
                                                setState(() {
                                                  _selectedClientName = updatedClient.name;
                                                  if (updatedClient.fullPayment > 0) {
                                                    _budgetController.text = updatedClient.fullPayment.toStringAsFixed(0);
                                                  }
                                                  if (updatedClient.advancedPayment > 0) {
                                                    _advancedController.text = updatedClient.advancedPayment.toStringAsFixed(0);
                                                  }
                                                });
                                                _queueDraftSave();
                                              }
                                            }
                                          },
                                        ),
                                ),
                                validator: (val) =>
                                    val == null ? 'Select client' : null,
                                items: displayedClients.map((c) {
                                  return DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final client = displayedClients.firstWhere(
                                      (c) => c.id == val,
                                    );
                                    final caList = ref
                                        .read(clientAccountsProvider)
                                        .where((ca) => ca.clientId == val)
                                        .toList();
                                    setState(() {
                                      _selectedClientId = val;
                                      _selectedClientName = client.name;
                                      if (caList.isNotEmpty) {
                                        _selectedClientAccountId = caList.first.id;
                                        _selectedClientAccountName = caList.first.name;
                                        if (caList.first.paymentMethod == 'Bank') {
                                          final accs = ref.read(accountsProvider).accounts;
                                          final bankAcc = accs.where((a) => a.type == 'Bank' && a.status == 'Active').firstOrNull;
                                          if (bankAcc != null && (_selectedBankAccountId == null || _selectedBankAccountId!.contains('cash'))) {
                                            _selectedBankAccountId = bankAcc.id;
                                            _selectedBankAccountName = bankAcc.name;
                                          }
                                        }
                                      }
                                    });
                                    _queueDraftSave();
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Budget (Rs.)'),
                          TextFormField(
                            controller: _budgetController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: context.textPrimary),
                            decoration: _buildInputDecoration(
                              'Budget value',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty)
                                return 'Enter budget';
                              if (double.tryParse(val) == null)
                                return 'Enter valid budget';
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('${tr('Advanced Payment')} (Rs.)'),
                          TextFormField(
                            controller: _advancedController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: context.textPrimary),
                            decoration: _buildInputDecoration(
                              'Advanced Payment value',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty)
                                return 'Enter advanced payment';
                              final numVal = double.tryParse(val);
                              if (numVal == null)
                                return 'Enter valid amount';
                              final budgetVal =
                                  double.tryParse(_budgetController.text) ??
                                  0.0;
                              if (numVal > budgetVal)
                                return 'Cannot exceed budget';
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(tr('Status')),
                          DropdownButtonFormField<String>(
                            value: _status,
                            dropdownColor: context.cardBg,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 13,
                            ),
                            decoration: _buildInputDecoration(''),
                            items: [
                              DropdownMenuItem(
                                value: 'Planning',
                                child: Text(tr('Planning')),
                              ),
                              DropdownMenuItem(
                                value: 'In Progress',
                                child: Text(tr('In Progress')),
                              ),
                              DropdownMenuItem(
                                value: 'On Hold',
                                child: Text(tr('On Hold')),
                              ),
                              DropdownMenuItem(
                                value: 'Completed',
                                child: Text(tr('Completed')),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _status = val);
                                _queueDraftSave();
                              }
                            },
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildLabel(tr('Client')),
                                    GestureDetector(
                                      onTap: () async {
                                        final newClient =
                                            await showDialog<Client>(
                                              context: context,
                                              builder: (context) =>
                                                  AddClientDialog(),
                                            );
                                        if (newClient != null) {
                                          setState(() {
                                            _pendingNewClient = newClient;
                                            _selectedClientId = newClient.id;
                                            _selectedClientName = newClient.name;
                                            if (newClient.fullPayment > 0) {
                                              _budgetController.text = newClient
                                                  .fullPayment
                                                  .toStringAsFixed(0);
                                            }
                                            if (newClient.advancedPayment > 0) {
                                              _advancedController.text = newClient
                                                  .advancedPayment
                                                  .toStringAsFixed(0);
                                            }
                                          });
                                          _queueDraftSave();
                                        }
                                      },
                                      child: Text(
                                        '+ Add Client',
                                        style: TextStyle(
                                          color: context.primaryColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Builder(
                                  builder: (context) {
                                    final displayedClients = [...clients];
                                    if (_pendingNewClient != null &&
                                        !displayedClients.any((c) => c.id == _pendingNewClient!.id)) {
                                      displayedClients.add(_pendingNewClient!);
                                    }
                                    return DropdownButtonFormField<String>(
                                      value: displayedClients.any(
                                        (c) => c.id == _selectedClientId,
                                      )
                                          ? _selectedClientId
                                          : null,
                                      dropdownColor: context.cardBg,
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 13,
                                      ),
                                      decoration: _buildInputDecoration('Select Client').copyWith(
                                        suffixIcon: _selectedClientId == null
                                            ? null
                                            : IconButton(
                                                tooltip: 'Edit Client',
                                                icon: const Icon(Icons.edit_outlined, size: 18),
                                                color: context.primaryColor,
                                                onPressed: () async {
                                                  final selectedClient = _pendingNewClient?.id == _selectedClientId
                                                      ? _pendingNewClient!
                                                      : displayedClients.firstWhere(
                                                          (client) => client.id == _selectedClientId,
                                                        );
                                                  final updatedClient = await showDialog<Client>(
                                                    context: context,
                                                    builder: (context) => AddClientDialog(client: selectedClient),
                                                  );
                                                  if (updatedClient != null) {
                                                    if (_pendingNewClient?.id == _selectedClientId) {
                                                      setState(() {
                                                        _pendingNewClient = updatedClient;
                                                        _selectedClientName = updatedClient.name;
                                                        if (updatedClient.fullPayment > 0) {
                                                          _budgetController.text = updatedClient.fullPayment.toStringAsFixed(0);
                                                        }
                                                        if (updatedClient.advancedPayment > 0) {
                                                          _advancedController.text = updatedClient.advancedPayment.toStringAsFixed(0);
                                                        }
                                                      });
                                                      _queueDraftSave();
                                                    } else {
                                                      await ref
                                                          .read(clientsProvider.notifier)
                                                          .updateClient(updatedClient);
                                                      setState(() {
                                                        _selectedClientName = updatedClient.name;
                                                        if (updatedClient.fullPayment > 0) {
                                                          _budgetController.text = updatedClient.fullPayment.toStringAsFixed(0);
                                                        }
                                                        if (updatedClient.advancedPayment > 0) {
                                                          _advancedController.text = updatedClient.advancedPayment.toStringAsFixed(0);
                                                        }
                                                      });
                                                      _queueDraftSave();
                                                    }
                                                  }
                                                },
                                              ),
                                      ),
                                      validator: (val) =>
                                          val == null ? 'Select client' : null,
                                      items: displayedClients.map((c) {
                                        return DropdownMenuItem(
                                          value: c.id,
                                          child: Text(c.name),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          final client = displayedClients.firstWhere(
                                            (c) => c.id == val,
                                          );
                                          final caList = ref
                                              .read(clientAccountsProvider)
                                              .where((ca) => ca.clientId == val)
                                              .toList();
                                          setState(() {
                                            _selectedClientId = val;
                                            _selectedClientName = client.name;
                                            if (caList.isNotEmpty) {
                                              _selectedClientAccountId = caList.first.id;
                                              _selectedClientAccountName = caList.first.name;
                                              if (caList.first.paymentMethod == 'Bank') {
                                                final accs = ref.read(accountsProvider).accounts;
                                                final bankAcc = accs.where((a) => a.type == 'Bank' && a.status == 'Active').firstOrNull;
                                                if (bankAcc != null && (_selectedBankAccountId == null || _selectedBankAccountId!.contains('cash'))) {
                                                  _selectedBankAccountId = bankAcc.id;
                                                  _selectedBankAccountName = bankAcc.name;
                                                }
                                              }
                                            }
                                          });
                                          _queueDraftSave();
                                        }
                                      },
                                    );
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
                                _buildLabel('Budget (Rs.)'),
                                TextFormField(
                                  controller: _budgetController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: context.textPrimary),
                                  decoration: _buildInputDecoration(
                                    'Budget value',
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty)
                                      return 'Enter budget';
                                    if (double.tryParse(val) == null)
                                      return 'Enter valid budget';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Advanced Payment & Status Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('${tr('Advanced Payment')} (Rs.)'),
                                TextFormField(
                                  controller: _advancedController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: context.textPrimary),
                                  decoration: _buildInputDecoration(
                                    'Advanced Payment value',
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty)
                                      return 'Enter advanced payment';
                                    final numVal = double.tryParse(val);
                                    if (numVal == null)
                                      return 'Enter valid amount';
                                    final budgetVal =
                                        double.tryParse(_budgetController.text) ??
                                        0.0;
                                    if (numVal > budgetVal)
                                      return 'Cannot exceed budget';
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
                                _buildLabel(tr('Status')),
                                DropdownButtonFormField<String>(
                                  value: _status,
                                  dropdownColor: context.cardBg,
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 13,
                                  ),
                                  decoration: _buildInputDecoration(''),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'Planning',
                                      child: Text(tr('Planning')),
                                    ),
                                    DropdownMenuItem(
                                      value: 'In Progress',
                                      child: Text(tr('In Progress')),
                                    ),
                                    DropdownMenuItem(
                                      value: 'On Hold',
                                      child: Text(tr('On Hold')),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Completed',
                                      child: Text(tr('Completed')),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _status = val);
                                      _queueDraftSave();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Client Bank Account / Source Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: _buildLabel(
                                      'Client Payment Source',
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      final newClientAcc =
                                          await showDialog<ClientAccount>(
                                            context: context,
                                            builder: (context) =>
                                                AddClientAccountDialog(
                                                  clientId:
                                                      _selectedClientId ?? '',
                                                ),
                                          );
                                      if (newClientAcc != null) {
                                        ref
                                            .read(
                                              clientAccountsProvider.notifier,
                                            )
                                            .addClientAccount(newClientAcc);
                                        setState(() {
                                          _selectedClientAccountId =
                                              newClientAcc.id;
                                          _selectedClientAccountName =
                                              newClientAcc.name;
                                          if (newClientAcc.paymentMethod == 'Bank') {
                                            final accs = ref.read(accountsProvider).accounts;
                                            final bankAcc = accs.where((a) => a.type == 'Bank' && a.status == 'Active').firstOrNull;
                                            if (bankAcc != null && (_selectedBankAccountId == null || _selectedBankAccountId!.contains('cash'))) {
                                              _selectedBankAccountId = bankAcc.id;
                                              _selectedBankAccountName = bankAcc.name;
                                            }
                                          }
                                        });
                                        _queueDraftSave();
                                      }
                                    },
                                    child: Text(
                                      '+ Add Client Account',
                                      style: TextStyle(
                                        color: context.primaryColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              (() {
                                final availAccounts =
                                    (_selectedClientId == null
                                            ? ref.watch(clientAccountsProvider)
                                            : ref
                                                  .watch(clientAccountsProvider)
                                                  .where(
                                                    (ca) =>
                                                        ca.clientId ==
                                                        _selectedClientId,
                                                  ))
                                        .toList();
                                final validValue =
                                    availAccounts.any(
                                      (ca) => ca.id == _selectedClientAccountId,
                                    )
                                    ? _selectedClientAccountId
                                    : null;
                                return DropdownButtonFormField<String>(
                                  value: validValue,
                                  dropdownColor: context.cardBg,
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 13,
                                  ),
                                  decoration: _buildInputDecoration(
                                    'Select Client Account (Optional)',
                                  ),
                                  validator: null,
                                  items: availAccounts.map((ca) {
                                    return DropdownMenuItem(
                                      value: ca.id,
                                      child: Text(ca.name),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      final ca = ref
                                          .read(clientAccountsProvider)
                                          .firstWhere((c) => c.id == val);
                                      setState(() {
                                        _selectedClientAccountId = val;
                                        _selectedClientAccountName = ca.name;
                                        if (ca.paymentMethod == 'Bank') {
                                          final accs = ref.read(accountsProvider).accounts;
                                          final bankAcc = accs.where((a) => a.type == 'Bank' && a.status == 'Active').firstOrNull;
                                          if (bankAcc != null && (_selectedBankAccountId == null || _selectedBankAccountId!.contains('cash'))) {
                                            _selectedBankAccountId = bankAcc.id;
                                            _selectedBankAccountName = bankAcc.name;
                                          }
                                        }
                                      });
                                      _queueDraftSave();
                                    }
                                  },
                                );
                              })(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Owner's Receiving Account Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildLabel(
                                    'Owner\'s Receiving Account',
                                    isRequired: true,
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      final newAccount =
                                          await showDialog<BankAccount>(
                                            context: context,
                                            builder: (context) =>
                                                const AddEditAccountDialog(),
                                          );
                                      if (newAccount != null) {
                                        ref
                                            .read(accountsProvider.notifier)
                                            .addAccount(newAccount);
                                        setState(() {
                                          _selectedBankAccountId =
                                              newAccount.id;
                                          _selectedBankAccountName =
                                              newAccount.name;
                                        });
                                        _queueDraftSave();
                                      }
                                    },
                                    child: Text(
                                      '+ Add Account',
                                      style: TextStyle(
                                        color: context.primaryColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              DropdownButtonFormField<String>(
                                value:
                                    (ref
                                        .watch(accountsProvider)
                                        .accounts
                                        .any(
                                          (acc) =>
                                              acc.id == _selectedBankAccountId,
                                        ))
                                    ? _selectedBankAccountId
                                    : null,
                                dropdownColor: context.cardBg,
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 13,
                                ),
                                decoration: _buildInputDecoration(
                                  'Select Account',
                                ),
                                validator: (val) => val == null
                                    ? 'Select owner receiving account'
                                    : null,
                                items: ref.watch(accountsProvider).accounts.map(
                                  (acc) {
                                    return DropdownMenuItem(
                                      value: acc.id,
                                      child: Text(acc.name),
                                    );
                                  },
                                ).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final accList = ref
                                        .read(accountsProvider)
                                        .accounts;
                                    final acc = accList.firstWhere(
                                      (a) => a.id == val,
                                      orElse: () => accList.first,
                                    );
                                    setState(() {
                                      _selectedBankAccountId = val;
                                      _selectedBankAccountName = acc.name;
                                    });
                                    _queueDraftSave();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Start Date & End Date Row
                    if (isMobile) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Start Date'),
                          OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() => _startDate = picked);
                                _queueDraftSave();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _startDate.toIso8601String().substring(
                                    0,
                                    10,
                                  ),
                                  style: TextStyle(
                                    color: context.textPrimary,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: context.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('End Date (Optional)'),
                          OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() => _endDate = picked);
                                _queueDraftSave();
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _endDate.toIso8601String().substring(
                                    0,
                                    10,
                                  ),
                                  style: TextStyle(
                                    color: context.textPrimary,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: context.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Start Date'),
                                OutlinedButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      setState(() => _startDate = picked);
                                      _queueDraftSave();
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: context.border),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _startDate.toIso8601String().substring(
                                          0,
                                          10,
                                        ),
                                        style: TextStyle(
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: context.primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('End Date (Optional)'),
                                OutlinedButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _endDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      setState(() => _endDate = picked);
                                      _queueDraftSave();
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: context.border),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _endDate.toIso8601String().substring(
                                          0,
                                          10,
                                        ),
                                        style: TextStyle(
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: context.primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    _buildLabel('Assign Team Members'),
                    GestureDetector(
                      onTap: () async {
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setDialogState) {
                                return AlertDialog(
                                  backgroundColor: context.cardBg,
                                  title: Text(
                                    tr('Assign Team Members'),
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Container(
                                    width: 350,
                                    constraints: const BoxConstraints(
                                      maxHeight: 350,
                                    ),
                                    child: Scrollbar(
                                      thumbVisibility: true,
                                      child: ListView.builder(
                                        itemCount: employees.length,
                                        itemBuilder: (context, index) {
                                          final emp = employees[index];
                                          final isSelected = _teamMembers
                                              .contains(emp.id);
                                          return CheckboxListTile(
                                            activeColor: context.primaryColor,
                                            checkColor: Colors.white,
                                            title: Text(
                                              emp.name,
                                              style: TextStyle(
                                                color: context.textPrimary,
                                              ),
                                            ),
                                            subtitle: Text(
                                              emp.designation,
                                              style: TextStyle(
                                                color: context.textSecondary,
                                                fontSize: 11,
                                              ),
                                            ),
                                            value: isSelected,
                                            onChanged: (val) {
                                              setState(() {
                                                if (val == true) {
                                                  _teamMembers.add(emp.id);
                                                } else {
                                                  _teamMembers.remove(emp.id);
                                                }
                                              });
                                              _queueDraftSave();
                                              setDialogState(() {});
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        tr('Done'),
                                        style: TextStyle(
                                          color: context.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? const Color(0xFF1F2937)
                              : const Color(0xFFF9FAFB),
                          border: Border.all(color: context.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _teamMembers.isEmpty
                                    ? 'Select Team Members'
                                    : employees
                                          .where(
                                            (e) => _teamMembers.contains(e.id),
                                          )
                                          .map((e) => e.name)
                                          .join(', '),
                                style: TextStyle(
                                  color: _teamMembers.isEmpty
                                      ? context.textMuted
                                      : context.textPrimary,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: context.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_teamMembers.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _teamMembers.map((empId) {
                          final emp = employees
                              .where((e) => e.id == empId)
                              .firstOrNull;
                          if (emp == null) return const SizedBox.shrink();
                          return Chip(
                            label: Text(
                              emp.name,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.textPrimary,
                              ),
                            ),
                            onDeleted: () {
                              setState(() {
                                _teamMembers.remove(empId);
                              });
                              _queueDraftSave();
                            },
                            backgroundColor: context.primaryColor.withOpacity(
                              0.05,
                            ),
                            side: BorderSide(
                              color: context.primaryColor.withOpacity(0.2),
                            ),
                            deleteIconColor: context.error,
                            padding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            tr('Cancel'),
                            style: TextStyle(color: context.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate() &&
                                _selectedClientId != null) {
                              final partialAmount =
                                  double.tryParse(
                                    _partialPaymentController.text,
                                  ) ??
                                  0.0;
                              final now = DateTime.now();
                              final startDateTime = DateTime(
                                _startDate.year,
                                _startDate.month,
                                _startDate.day,
                                _startTime.hour,
                                _startTime.minute,
                                now.second,
                                now.millisecond,
                              );
                              final ca = _selectedClientAccountId != null
                                  ? ref.read(clientAccountsProvider).where((c) => c.id == _selectedClientAccountId).firstOrNull
                                  : ref.read(clientAccountsProvider).where((c) => c.name == _selectedClientAccountName).firstOrNull;

                              final paymentSourceStr = ca != null
                                  ? (ca.paymentMethod == 'Bank'
                                      ? (ca.bankName.isNotEmpty && !ca.name.toLowerCase().contains(ca.bankName.toLowerCase())
                                          ? '${ca.name} (${ca.bankName})'
                                          : ca.name)
                                      : (ca.name.isNotEmpty ? ca.name : ca.paymentMethod))
                                  : (_selectedClientAccountName?.isNotEmpty == true
                                      ? _selectedClientAccountName!
                                      : 'Bank');

                              final proj = Project(
                                id:
                                    widget.project?.id ??
                                    'proj_${DateTime.now().millisecondsSinceEpoch}',
                                name: _nameController.text.trim().isNotEmpty
                                    ? _nameController.text.trim()
                                    : 'Account',
                                description: _descController.text.trim(),
                                clientId: _selectedClientId!,
                                clientName: _selectedClientName!,
                                startDate: startDateTime.toIso8601String(),
                                endDate: _endDate.toIso8601String().substring(
                                  0,
                                  10,
                                ),
                                status: _status,
                                budget:
                                    double.tryParse(_budgetController.text) ??
                                    0.0,
                                advancedPayment:
                                    double.tryParse(_advancedController.text) ??
                                    0.0,
                                bankAccountId: _selectedBankAccountId ?? (ca?.id ?? ''),
                                bankAccountName: _selectedBankAccountName ?? (ca?.name ?? 'Bank Account'),
                                accountHolder: 'HH Tech',
                                clientPaymentSource: paymentSourceStr,
                                teamMembers: _teamMembers,
                                partialPayments:
                                    widget.project?.partialPayments ?? 0.0,
                                finalPayment:
                                    widget.project?.finalPayment ?? 0.0,
                                paymentStatus:
                                    widget.project?.paymentStatus ?? 'Pending',
                              );

                              if (widget.project == null) {
                                final canCreate = ref
                                    .read(adminProvider)
                                    .hasPermission(
                                      AppModule.projectsList,
                                      PermissionAction.create,
                                    );
                                if (!canCreate) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Access Denied: You do not have permission to create projects.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                if (_pendingNewClient != null &&
                                    _selectedClientId == _pendingNewClient!.id) {
                                  await ref
                                      .read(clientsProvider.notifier)
                                      .addClient(_pendingNewClient!);
                                  _pendingNewClient = null;
                                }
                                await _AddEditProjectDialog.clearDraft();
                                // Adding a new project, return it as usual
                                Navigator.of(context).pop(proj);
                              } else {
                                final canEdit = ref
                                    .read(adminProvider)
                                    .hasPermission(
                                      AppModule.projectsList,
                                      PermissionAction.edit,
                                    );
                                if (!canEdit) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Access Denied: You do not have permission to edit projects.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                if (_pendingNewClient != null &&
                                    _selectedClientId == _pendingNewClient!.id) {
                                  await ref
                                      .read(clientsProvider.notifier)
                                      .addClient(_pendingNewClient!);
                                  _pendingNewClient = null;
                                }
                                // Updating an existing project.
                                // Update details first
                                await ref
                                    .read(projectsProvider.notifier)
                                    .updateProject(proj);

                                // Process new partial payment if any
                                if (partialAmount > 0) {
                                  final record = IncomeRecord(
                                    id: 'inc_${DateTime.now().millisecondsSinceEpoch}',
                                    date: DateTime.now().toIso8601String(),
                                    clientId: proj.clientId,
                                    clientName: proj.clientName,
                                    amount: partialAmount,
                                    accountId: proj.bankAccountId.isNotEmpty
                                        ? proj.bankAccountId
                                        : 'default_account',
                                    invoiceNumber: '',
                                    description: 'Partial Payment for Project',
                                    status: 'Received',
                                    projectId: proj.id,
                                    projectName: proj.name,
                                    projectPaymentType: 'Partial',
                                  );
                                  await ref
                                      .read(incomeProvider.notifier)
                                      .addIncome(record);
                                }

                                // Return null so the caller doesn't run updateProject again
                                Navigator.of(context).pop(null);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            widget.project == null
                                ? 'Add Project'
                                : tr('Save Changes'),
                          ),
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

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: context.textSecondary,
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
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

void _showStatusChangeDialog(
  BuildContext context,
  WidgetRef ref,
  Project project,
) {
  final canEdit = ref.read(adminProvider).hasPermission(AppModule.projectsList, PermissionAction.edit);
  if (!canEdit) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Access Denied: You do not have permission to edit projects.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final List<String> statuses = [
    'Planning',
    'In Progress',
    'Completed',
    'On Hold',
  ];

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Change Project Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            final isSelected = project.status == status;
            return ListTile(
              title: Text(
                status,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () async {
                Navigator.pop(ctx);
                if (!isSelected) {
                  final updatedProject = project.copyWith(status: status);
                  await ref
                      .read(projectsProvider.notifier)
                      .updateProject(updatedProject);
                }
              },
            );
          }).toList(),
        ),
      );
    },
  );
}

class _ViewProjectDetailsDialog extends ConsumerWidget {
  final Project project;

  const _ViewProjectDetailsDialog({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final canEdit = ref.watch(adminProvider).hasPermission(AppModule.projectsList, PermissionAction.edit);

    // Watch live project state so dialog updates in real time
    final liveProject =
        ref
            .watch(projectsProvider)
            .projects
            .where((p) => p.id == project.id)
            .firstOrNull ??
        project;

    // Dynamic progress from tasks
    final projectTasks = ref
        .watch(tasksProvider)
        .tasks
        .where((t) => t.projectId == project.id)
        .toList();
    final totalTasks = projectTasks.length;
    final completedTasks = projectTasks.where((t) => t.status == 'Done').length;
    final double progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    // Status styling
    Color statusColor;
    Color statusBg;
    if (liveProject.status == 'Completed') {
      statusColor = context.success;
      statusBg = context.successLight;
    } else if (liveProject.status == 'In Progress') {
      statusColor = context.warning;
      statusBg = context.warningLight;
    } else if (liveProject.status == 'Planning') {
      statusColor = context.primaryColor;
      statusBg = context.infoLight;
    } else {
      statusColor = context.textSecondary;
      statusBg = context.isDarkMode
          ? const Color(0xFF374151)
          : const Color(0xFFF3F4F6);
    }

    // Get Bank details
    final accounts = ref.watch(accountsProvider).accounts;
    final bankAccount = accounts
        .where((a) => a.id == project.bankAccountId)
        .firstOrNull;

    // Team members names
    final allEmployees = ref.watch(employeesProvider).employees;
    final teamList = project.teamMembers
        .map((empId) {
          return allEmployees.where((e) => e.id == empId).firstOrNull;
        })
        .whereType<Employee>()
        .toList();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: context.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 800),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr('Project Details'),
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

              // Project Name & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  canEdit
                      ? InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () =>
                              _showStatusChangeDialog(context, ref, liveProject),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tr(liveProject.status),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.edit, size: 12, color: statusColor),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tr(liveProject.status),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${tr("Client")}: ${project.clientName}',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                tr('Description'),
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                project.description,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Payment History Table
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobileNarrow = constraints.maxWidth < 460;
                  final title = Text(
                    'Payment Details',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                  final actionButtons = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                _ProjectAddonsDialog(project: liveProject),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.purple,
                          side: const BorderSide(
                            color: Colors.purple,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(Icons.extension_outlined, size: 15),
                        label: Text(
                          'Add-Ons (${ref.watch(projectAddonsProvider).where((a) => a.projectId == liveProject.id).length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (canEdit)
                        OutlinedButton.icon(
                          onPressed: () {
                            _showPartialPaymentDialog(context, ref, liveProject);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.primaryColor,
                            side: BorderSide(
                              color: context.primaryColor.withOpacity(0.5),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          icon: const Icon(Icons.add, size: 15),
                          label: const Text(
                            'Add Payment',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );

                  if (isMobileNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        const SizedBox(height: 8),
                        actionButtons,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      title,
                      actionButtons,
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 560;
                  final tableWidget = Container(
                    width: isCompact ? 560 : double.infinity,
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      border: Border.all(color: context.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? const Color(0xFF1F2937)
                            : const Color(0xFFF9FAFB),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              '#',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Description',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Received Account',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Amount',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Payment Date & Time',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Payments from Income Records or fallback to Advanced Payment
                    ...(() {
                      final projectIncomes = ref
                          .watch(incomeProvider)
                          .incomes
                          .where((inc) => inc.projectId == liveProject.id)
                          .toList();
                      final accountsList = ref.watch(accountsProvider).accounts;

                      if (projectIncomes.isNotEmpty) {
                        return projectIncomes.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final inc = entry.value;
                          final acc = accountsList
                              .where((a) => a.id == inc.accountId)
                              .firstOrNull;
                          final dt = _formatIncomeDate(inc.date);
                          final dParts = dt.split('\n');
                          final pType = inc.projectPaymentType ??
                              (inc.description.contains('Advance') ? 'Advance' : 'Partial');
                          Color pColor = pType == 'Advance'
                              ? Colors.green
                              : (pType == 'Final'
                                    ? const Color(0xFF2563EB)
                                    : (pType == 'Add-on' ? Colors.purple : Colors.orange));
                          return _buildNewPaymentRow(
                            context,
                            index: idx,
                            title: '$pType Payment',
                            badge: pType,
                            accName: acc?.name ?? (acc?.bankName.isNotEmpty == true ? acc!.bankName : liveProject.bankAccountName),
                            bankName: acc?.bankName ?? '',
                            amountStr: 'Rs. ${inc.amount.toStringAsFixed(0)}',
                            amountColor: pColor,
                            dateStr: dParts[0],
                            timeStr: dParts.length > 1 ? dParts[1] : '',
                          );
                        }).toList();
                      } else if (liveProject.advancedPayment > 0) {
                        final allIncomes = ref.watch(incomeProvider).incomes;
                        final advDateStr = _getAdvancePaymentDateTimeString(
                          liveProject,
                          allIncomes,
                        );
                        final dt = _formatIncomeDate(advDateStr);
                        final dParts = dt.split('\n');
                        final bankAcc = accountsList
                            .where((a) => a.id == liveProject.bankAccountId)
                            .firstOrNull;
                        return [
                          _buildNewPaymentRow(
                            context,
                            index: 1,
                            title: 'Advanced Payment',
                            badge: 'Advance',
                            accName: bankAcc?.name ?? liveProject.bankAccountName,
                            bankName: bankAcc?.bankName ?? '',
                            amountStr:
                                'Rs. ${liveProject.advancedPayment.toStringAsFixed(0)}',
                            amountColor: context.success,
                            dateStr: dParts[0],
                            timeStr: dParts.length > 1 ? dParts[1] : '',
                          ),
                        ];
                      }
                      return <Widget>[];
                    })(),

                    // Remaining Payment Bottom Row & Add-ons Summary
                    Builder(
                      builder: (context) {
                        final projectIncomes = ref
                            .watch(incomeProvider)
                            .incomes
                            .where((inc) => inc.projectId == liveProject.id)
                            .toList();
                        final projectAddons = ref
                            .watch(projectAddonsProvider)
                            .where((a) => a.projectId == liveProject.id)
                            .toList();
                        final double totalAddonsAmount =
                            projectAddons.fold(0.0, (sum, a) => sum + a.amount);
                        final double totalRevisedBudget =
                            liveProject.budget + totalAddonsAmount;
                        final double actualReceived = projectIncomes.isNotEmpty
                            ? projectIncomes.fold(0.0, (sum, i) => sum + i.amount)
                            : (liveProject.advancedPayment +
                                liveProject.partialPayments +
                                liveProject.finalPayment);
                        final double actualRemaining = (totalRevisedBudget - actualReceived)
                            .clamp(0.0, double.infinity);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: actualRemaining <= 0
                                ? (context.isDarkMode
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : const Color(0xFFE6F4EA))
                                : (context.isDarkMode
                                      ? Colors.orange.withValues(alpha: 0.1)
                                      : const Color(0xFFFFF9E6)),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          child: Column(
                            children: [
                              if (totalAddonsAmount > 0) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Base: Rs. ${liveProject.budget.toStringAsFixed(0)}  •  Add-Ons: Rs. ${totalAddonsAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: context.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Revised Budget: Rs. ${totalRevisedBudget.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Divider(height: 1),
                                const SizedBox(height: 6),
                              ],
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Remaining Payment',
                                    style: TextStyle(
                                      color: actualRemaining <= 0
                                          ? context.success
                                          : Colors.orange,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    actualRemaining <= 0
                                        ? 'Fully Paid'
                                        : 'Rs. ${actualRemaining.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      color: actualRemaining <= 0
                                          ? context.success
                                          : Colors.orange,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );

              if (isCompact) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: tableWidget,
                );
              }
              return tableWidget;
            },
          ),
          const SizedBox(height: 24),

              // Client Bank Details Section
              Text(
                tr('Client Bank Account / Payment Source'),
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              (() {
                final clientAccounts = ref.watch(clientAccountsProvider);
                final clientAccount = clientAccounts
                    .where((ca) =>
                        ca.name == project.clientPaymentSource ||
                        ca.id == project.clientPaymentSource ||
                        (project.clientPaymentSource.contains(ca.name)) ||
                        (project.clientId.isNotEmpty && ca.clientId == project.clientId))
                    .firstOrNull;
                if (clientAccount != null) {
                  return Row(
                    children: [
                      Icon(
                        Icons.payment,
                        size: 24,
                        color: context.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clientAccount.name,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${tr("Payment Method")}: ${clientAccount.paymentMethod}',
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (clientAccount.paymentMethod != 'Cash') ...[
                              Text(
                                '${clientAccount.bankName}',
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${tr("Account Number")}: ${clientAccount.accountNumber}',
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Text(
                    project.clientPaymentSource.isNotEmpty
                        ? project.clientPaymentSource
                        : tr('No Client Account Details Linked'),
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
              })(),
              const SizedBox(height: 24),

              // Assignees
              Text(
                tr('Assigned Team Members'),
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (teamList.isEmpty)
                Text(
                  tr('No team members assigned.'),
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: teamList.map((emp) {
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: context.primaryColor.withOpacity(0.1),
                        child: Text(
                          emp.name
                              .split(' ')
                              .map((e) => e[0])
                              .take(2)
                              .join()
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 8,
                            color: context.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      label: Text(
                        emp.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textPrimary,
                        ),
                      ),
                      backgroundColor: context.cardBg,
                      side: BorderSide(color: context.border),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Close Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(tr('Close')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class AddClientAccountDialog extends StatefulWidget {
  final String clientId;
  const AddClientAccountDialog({super.key, required this.clientId});

  @override
  State<AddClientAccountDialog> createState() => _AddClientAccountDialogState();
}

class _AddClientAccountDialogState extends State<AddClientAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _numberController = TextEditingController();
  String _paymentMethod = 'Bank';

  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _numberController.dispose();
    super.dispose();
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
                'Add Client Bank Account',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Payment Method
              _buildLabel('Payment Method', isRequired: true),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                dropdownColor: context.cardBg,
                style: TextStyle(color: context.textPrimary, fontSize: 13),
                decoration: _buildInputDecoration(''),
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'Bank', child: Text('Bank')),
                  DropdownMenuItem(value: 'Wallet', child: Text('Wallet')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _paymentMethod = val;
                      if (val == 'Cash') {
                        _bankNameController.text = 'Cash';
                        _numberController.text = 'N/A';
                      } else {
                        if (_bankNameController.text == 'Cash')
                          _bankNameController.clear();
                        if (_numberController.text == 'N/A')
                          _numberController.clear();
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Account Name / Label (Hidden when Cash method is selected)
              if (_paymentMethod != 'Cash') ...[
                _buildLabel(
                  'Account Title / Name',
                  isRequired: true,
                ),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration('e.g. Client HBL Account'),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return 'Enter account title';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Bank Name
              _buildLabel(
                _paymentMethod == 'Bank' || _paymentMethod == 'Wallet'
                    ? 'Bank Name (Optional)'
                    : 'Bank Name',
                isRequired: false,
              ),
              TextFormField(
                controller: _bankNameController,
                style: TextStyle(color: context.textPrimary),
                decoration: _buildInputDecoration('e.g. HBL (Optional)'),
                validator: null,
              ),
              const SizedBox(height: 16),

              // Account Number
              _buildLabel(
                'Account Number',
                isRequired: _paymentMethod != 'Cash',
              ),
              TextFormField(
                controller: _numberController,
                style: TextStyle(color: context.textPrimary),
                decoration: _buildInputDecoration('e.g. 1234567890'),
                validator: (val) {
                  if (_paymentMethod == 'Cash') return null;
                  if (val == null || val.trim().isEmpty)
                    return 'Enter account number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: context.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newAcc = ClientAccount(
                          id: 'ca_${DateTime.now().millisecondsSinceEpoch}',
                          clientId: widget.clientId,
                          name: _nameController.text.trim().isNotEmpty
                              ? _nameController.text.trim()
                              : 'Account',
                          bankName: _bankNameController.text.trim(),
                          accountNumber: _numberController.text.trim(),
                          paymentMethod: _paymentMethod,
                        );
                        Navigator.pop(context, newAcc);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Add Account'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: context.textSecondary,
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

void _showPartialPaymentDialog(
  BuildContext context,
  WidgetRef ref,
  Project project,
) {
  final amountController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return _PartialPaymentDialogContent(
        project: project,
        amountController: amountController,
        formKey: formKey,
      );
    },
  );
}

class _PartialPaymentDialogContent extends ConsumerStatefulWidget {
  final Project project;
  final TextEditingController amountController;
  final GlobalKey<FormState> formKey;

  const _PartialPaymentDialogContent({
    required this.project,
    required this.amountController,
    required this.formKey,
  });

  @override
  ConsumerState<_PartialPaymentDialogContent> createState() =>
      _PartialPaymentDialogContentState();
}

class _PartialPaymentDialogContentState
    extends ConsumerState<_PartialPaymentDialogContent> {
  String? _selectedAccountId;
  String? _selectedAccountName;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedPaymentType = 'Partial';

  static const _paymentTypes = ['Partial', 'Advance', 'Final'];

  String _formatDate(DateTime d) {
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
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  String _paymentTypeHint(String type) {
    switch (type) {
      case 'Advance':
        return 'Upfront payment before work starts';
      case 'Final':
        return 'Last payment to close the project';
      default:
        return 'Installment during project';
    }
  }

  String _getIsoDateString(DateTime date, TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
      now.second,
      now.millisecond,
    ).toIso8601String();
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text.replaceAll(' *', ''),
          style: const TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          children: [
            if (text.contains('*'))
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.isDarkMode
                ? Colors.white54
                : const Color(0xFF6B7280),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).accounts;
    final project = widget.project;

    final projectIncomes = ref
        .watch(incomeProvider)
        .incomes
        .where((i) => i.projectId == project.id)
        .toList();
    final double actualReceived = projectIncomes.isNotEmpty
        ? projectIncomes.fold(0.0, (sum, i) => sum + i.amount)
        : (project.advancedPayment + project.partialPayments + project.finalPayment);
    final double actualRemaining = (project.budget - actualReceived).clamp(0.0, double.infinity);

    if (_selectedAccountId == null && project.bankAccountId.isNotEmpty) {
      _selectedAccountId = project.bankAccountId;
      _selectedAccountName = project.bankAccountName;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Form(
          key: widget.formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Payment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Project: ${project.name}  •  Client: ${project.clientName}',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info,
                        color: Color(0xFFF97316),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text.rich(
                        TextSpan(
                          text: 'Remaining Due: ',
                          style: const TextStyle(
                            color: Color(0xFFF97316),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  'Rs. ${actualRemaining.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                _buildLabel('Payment Type *'),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedPaymentType,
                  dropdownColor: context.cardBg,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: context.textSecondary,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
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
                      borderSide: BorderSide(color: context.primaryColor),
                    ),
                  ),
                  items: _paymentTypes.map((type) {
                    Color c = type == 'Advance'
                        ? Colors.green
                        : (type == 'Final'
                              ? const Color(0xFF2563EB)
                              : Colors.orange);
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: c.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: c,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _paymentTypeHint(type),
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPaymentType = val);
                  },
                ),
                const SizedBox(height: 16),

                _buildLabel('Payment Amount *'),
                TextFormField(
                  controller: widget.amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: context.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    hintStyle: TextStyle(
                      color: context.textMuted,
                      fontSize: 13,
                    ),
                    prefixIcon: Container(
                      width: 50,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? const Color(0xFF374151)
                            : const Color(0xFFF3F4F6),
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Rs.',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
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
                      borderSide: BorderSide(color: context.primaryColor),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty)
                      return 'Please enter an amount';
                    final num = double.tryParse(val);
                    if (num == null || num <= 0) return 'Invalid amount';
                    if (num > actualRemaining)
                      return 'Amount cannot exceed Rs. ${actualRemaining.toStringAsFixed(0)}';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildLabel('Received In (Your Account) *'),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: accounts.any((a) => a.id == _selectedAccountId)
                      ? _selectedAccountId
                      : null,
                  dropdownColor: context.cardBg,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: context.textSecondary,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
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
                      borderSide: BorderSide(color: context.primaryColor),
                    ),
                  ),
                  validator: (val) => val == null ? 'Select an account' : null,
                  items: accounts.map((a) {
                    return DropdownMenuItem(
                      value: a.id,
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance,
                            size: 16,
                            color: context.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${a.name} (${a.bankName})',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final acc = accounts.firstWhere((a) => a.id == val);
                      setState(() {
                        _selectedAccountId = val;
                        _selectedAccountName = acc.name;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Payment Date *'),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null)
                                setState(() {
                                  _selectedDate = picked;
                                });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: context.border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(_selectedDate),
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                    color: context.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Payment Time *'),
                          InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime,
                              );
                              if (picked != null)
                                setState(() {
                                  _selectedTime = picked;
                                });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: context.border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedTime.format(context),
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Icon(
                                    Icons.access_time_outlined,
                                    size: 16,
                                    color: context.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_selectedAccountId != null) ...[
                  Builder(
                    builder: (ctx) {
                      final acc = accounts
                          .where((a) => a.id == _selectedAccountId)
                          .firstOrNull;
                      if (acc == null) return const SizedBox.shrink();
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Details',
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              'Receiving Account',
                              acc.name,
                              context,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow('Bank Name', acc.bankName, context),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Account Number',
                                      style: TextStyle(
                                        color: context.isDarkMode
                                            ? Colors.white54
                                            : const Color(0xFF6B7280),
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      acc.accountNumber,
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.copy,
                                  size: 16,
                                  color: context.textSecondary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: context.isDarkMode
                            ? const Color(0xFF374151)
                            : const Color(0xFFF3F4F6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final canEdit = ref
                            .read(adminProvider)
                            .hasPermission(
                              AppModule.projectsList,
                              PermissionAction.edit,
                            );
                        if (!canEdit) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Access Denied: You do not have permission to edit projects or record payments.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        if (widget.formKey.currentState!.validate()) {
                          final amount = double.parse(
                            widget.amountController.text.trim(),
                          );
                          final accId =
                              _selectedAccountId ??
                              (project.bankAccountId.isNotEmpty
                                  ? project.bankAccountId
                                  : 'default_account');

                          final record = IncomeRecord(
                            id: 'inc_${DateTime.now().millisecondsSinceEpoch}',
                            date: _getIsoDateString(
                              _selectedDate,
                              _selectedTime,
                            ),
                            clientId: project.clientId,
                            clientName: project.clientName,
                            amount: amount,
                            accountId: accId,
                            invoiceNumber: '',
                            description:
                                '$_selectedPaymentType Payment - ${project.name}',
                            status: 'Received',
                            projectId: project.id,
                            projectName: project.name,
                            projectPaymentType: _selectedPaymentType,
                          );

                          await ref
                              .read(incomeProvider.notifier)
                              .addIncome(record);
                          if (context.mounted) Navigator.pop(context);

                          if (context.mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$_selectedPaymentType Payment of Rs. ${amount.toStringAsFixed(0)} added to ${_selectedAccountName ?? "account"}',
                                ),
                              ),
                            );
                        }
                      },
                      icon: const Icon(Icons.credit_card, size: 18),
                      label: const Text(
                        'Save Payment',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
}

String _getAdvancePaymentDateTimeString(
  Project project,
  List<IncomeRecord> allIncomes,
) {
  // 1. Check if an IncomeRecord exists for this initial advance payment
  final advIncome = allIncomes
      .where(
        (inc) =>
            inc.invoiceNumber == 'INV-${project.id}' ||
            (inc.projectId == project.id &&
                (inc.projectPaymentType == 'Advance' ||
                    inc.description.toLowerCase().contains('advance'))) ||
            inc.description ==
                'Project Advance: ${project.name} (Source: ${project.clientPaymentSource})',
      )
      .firstOrNull;

  if (advIncome != null && advIncome.date.isNotEmpty) {
    final hasExplicitTime =
        advIncome.date.contains('T') &&
        !advIncome.date.endsWith('T00:00:00.000') &&
        !advIncome.date.endsWith('T00:00:00');
    if (hasExplicitTime) {
      return advIncome.date;
    }
    // Check if inc.id has epoch timestamp
    final match = RegExp(r'inc_(\d{10,})').firstMatch(advIncome.id);
    if (match != null) {
      final epoch = int.tryParse(match.group(1)!);
      if (epoch != null) {
        final timeDt = DateTime.fromMillisecondsSinceEpoch(epoch);
        final dateDt =
            DateTime.tryParse(advIncome.date) ??
            DateTime.tryParse(project.startDate) ??
            timeDt;
        return DateTime(
          dateDt.year,
          dateDt.month,
          dateDt.day,
          timeDt.hour,
          timeDt.minute,
        ).toIso8601String();
      }
    }
  }

  // 2. Check if project.startDate has an explicit time
  if (project.startDate.contains('T') &&
      !project.startDate.endsWith('T00:00:00.000') &&
      !project.startDate.endsWith('T00:00:00')) {
    return project.startDate;
  }

  // 3. Check if project.id has epoch timestamp
  final projMatch = RegExp(r'proj_(\d{10,})').firstMatch(project.id);
  if (projMatch != null) {
    final epoch = int.tryParse(projMatch.group(1)!);
    if (epoch != null) {
      final timeDt = DateTime.fromMillisecondsSinceEpoch(epoch);
      final dateDt = DateTime.tryParse(project.startDate) ?? timeDt;
      return DateTime(
        dateDt.year,
        dateDt.month,
        dateDt.day,
        timeDt.hour,
        timeDt.minute,
      ).toIso8601String();
    }
  }

  // 4. Return startDate as fallback
  return project.startDate;
}

String _formatIncomeDate(String isoString) {
  try {
    final d = DateTime.parse(isoString);
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
    final date =
        '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';

    // If isoString doesn't contain a time component, don't invent 12:00 AM
    final hasExplicitTime = isoString.contains('T') || isoString.contains(' ');
    final isMidnight = d.hour == 0 && d.minute == 0;

    if (!hasExplicitTime ||
        (isMidnight && !isoString.contains(RegExp(r'\d{1,2}:\d{2}')))) {
      return '$date\n';
    }

    final hour = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final time =
        '${hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm';
    return '$date\n$time';
  } catch (e) {
    return '$isoString\n';
  }
}

Widget _buildNewPaymentRow(
  BuildContext context, {
  required int index,
  required String title,
  required String badge,
  required String accName,
  required String bankName,
  required String amountStr,
  required Color amountColor,
  required String dateStr,
  required String timeStr,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            '$index',
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badge == 'Advance'
                      ? Colors.green.withOpacity(0.1)
                      : (badge == 'Final'
                            ? const Color(0xFF2563EB).withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badge == 'Advance'
                        ? Colors.green
                        : (badge == 'Final'
                              ? const Color(0xFF2563EB)
                              : Colors.orange),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Icon(
                Icons.account_balance,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accName,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      bankName,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                        fontSize: 11,
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
        Expanded(
          flex: 2,
          child: Text(
            amountStr,
            style: TextStyle(
              color: amountColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 12,
                ),
              ),
              if (timeStr.isNotEmpty)
                Text(
                  timeStr,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ============================================================================
// PROJECT ADD-ONS & SCOPE EXTENSIONS DIALOGS
// ============================================================================

class _ProjectAddonsDialog extends ConsumerStatefulWidget {
  final Project project;

  const _ProjectAddonsDialog({required this.project});

  @override
  ConsumerState<_ProjectAddonsDialog> createState() =>
      _ProjectAddonsDialogState();
}

class _ProjectAddonsDialogState extends ConsumerState<_ProjectAddonsDialog> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final canEdit = ref.watch(adminProvider).hasPermission(
          AppModule.projectsList,
          PermissionAction.edit,
        );

    final allAddons = ref.watch(projectAddonsProvider);
    final projectAddons = allAddons
        .where((a) => a.projectId == widget.project.id)
        .toList();

    final filteredAddons = _selectedFilter == 'All'
        ? projectAddons
        : projectAddons.where((a) => a.status == _selectedFilter).toList();

    final double totalAddonsAmount =
        projectAddons.fold(0.0, (sum, a) => sum + a.amount);
    final double totalAddonsPaid =
        projectAddons.fold(0.0, (sum, a) => sum + a.amountPaid);
    final double totalAddonsPending =
        (totalAddonsAmount - totalAddonsPaid).clamp(0.0, double.infinity);
    final double totalRevisedBudget =
        widget.project.budget + totalAddonsAmount;

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850, maxHeight: 720),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.extension_rounded,
                      color: Colors.purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Project Scope & Add-Ons',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.project.name} • Client: ${widget.project.clientName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (canEdit)
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => _AddAddonModalDialog(
                            project: widget.project,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        isMobile ? 'Add' : 'New Add-On / Scope',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 10 : 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: Icon(Icons.close, color: context.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Metrics Financial Summary Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 450;
                  if (isCompact) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildSummaryMetric(
                                context,
                                label: 'Base Budget',
                                value: 'Rs. ${widget.project.budget.toStringAsFixed(0)}',
                                color: context.textPrimary,
                              ),
                              _buildSummaryDivider(context),
                              _buildSummaryMetric(
                                context,
                                label: 'Add-Ons (${projectAddons.length})',
                                value: 'Rs. ${totalAddonsAmount.toStringAsFixed(0)}',
                                color: Colors.purple,
                              ),
                            ],
                          ),
                          Divider(
                            height: 16,
                            color: context.border.withOpacity(0.5),
                          ),
                          Row(
                            children: [
                              _buildSummaryMetric(
                                context,
                                label: 'Revised Total',
                                value: 'Rs. ${totalRevisedBudget.toStringAsFixed(0)}',
                                color: context.primaryColor,
                              ),
                              _buildSummaryDivider(context),
                              _buildSummaryMetric(
                                context,
                                label: 'Add-Ons Due',
                                value: totalAddonsPending <= 0
                                    ? 'All Paid'
                                    : 'Rs. ${totalAddonsPending.toStringAsFixed(0)}',
                                color: totalAddonsPending <= 0
                                    ? context.success
                                    : context.error,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.border),
                    ),
                    child: Row(
                      children: [
                        _buildSummaryMetric(
                          context,
                          label: 'Base Budget',
                          value: 'Rs. ${widget.project.budget.toStringAsFixed(0)}',
                          color: context.textPrimary,
                        ),
                        _buildSummaryDivider(context),
                        _buildSummaryMetric(
                          context,
                          label: 'Add-Ons (${projectAddons.length})',
                          value: 'Rs. ${totalAddonsAmount.toStringAsFixed(0)}',
                          color: Colors.purple,
                        ),
                        _buildSummaryDivider(context),
                        _buildSummaryMetric(
                          context,
                          label: 'Revised Total',
                          value: 'Rs. ${totalRevisedBudget.toStringAsFixed(0)}',
                          color: context.primaryColor,
                        ),
                        _buildSummaryDivider(context),
                        _buildSummaryMetric(
                          context,
                          label: 'Add-Ons Due',
                          value: totalAddonsPending <= 0
                              ? 'All Paid'
                              : 'Rs. ${totalAddonsPending.toStringAsFixed(0)}',
                          color: totalAddonsPending <= 0
                              ? context.success
                              : context.error,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    Text(
                      'Filter:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    for (final tab in ['All', 'Pending', 'In Progress', 'Completed'])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            tab,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _selectedFilter == tab
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _selectedFilter == tab
                                  ? Colors.purple
                                  : context.textSecondary,
                            ),
                          ),
                          selected: _selectedFilter == tab,
                          selectedColor: Colors.purple.withOpacity(0.15),
                          backgroundColor: context.cardBg,
                          side: BorderSide(
                            color: _selectedFilter == tab
                                ? Colors.purple
                                : context.border,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedFilter = tab);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Addons List / Empty State
              Expanded(
                child: filteredAddons.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.extension_off_outlined,
                              size: 48,
                              color: context.textMuted.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              projectAddons.isEmpty
                                  ? 'No Scope Add-Ons Yet'
                                  : 'No Add-Ons match filter "$_selectedFilter"',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              projectAddons.isEmpty
                                  ? 'When client requests extra features or scope changes, record them here.'
                                  : 'Try choosing another filter tab above.',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (projectAddons.isEmpty && canEdit) ...[
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => _AddAddonModalDialog(
                                      project: widget.project,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add First Add-On'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredAddons.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final addon = filteredAddons[index];
                          return _buildAddonItemCard(context, addon, canEdit);
                        },
                      ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Bottom Close Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(tr('Close')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: context.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider(BuildContext context) {
    return Container(
      height: 28,
      width: 1,
      color: context.border,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildAddonItemCard(
    BuildContext context,
    ProjectAddon addon,
    bool canEdit,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Status colors
    Color statusColor;
    Color statusBg;
    if (addon.status == 'Completed') {
      statusColor = context.success;
      statusBg = context.successLight;
    } else if (addon.status == 'In Progress') {
      statusColor = context.warning;
      statusBg = context.warningLight;
    } else {
      statusColor = Colors.purple;
      statusBg = Colors.purple.withOpacity(0.12);
    }

    // Payment colors
    Color payColor;
    Color payBg;
    if (addon.paymentStatus == 'Paid') {
      payColor = context.success;
      payBg = context.successLight;
    } else if (addon.paymentStatus == 'Partially Paid') {
      payColor = Colors.orange;
      payBg = Colors.orange.withOpacity(0.12);
    } else {
      payColor = context.error;
      payBg = context.errorLight;
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title + Status + Payment Status + Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  addon.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  addon.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Payment Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: payBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  addon.paymentStatus,
                  style: TextStyle(
                    color: payColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (canEdit) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: context.textSecondary,
                  ),
                  color: context.cardBg,
                  padding: EdgeInsets.zero,
                  onSelected: (val) async {
                    if (val == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Add-On'),
                          content: Text(
                            'Are you sure you want to delete add-on "${addon.title}"? This cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: context.textSecondary),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                'Delete',
                                style: TextStyle(color: context.error),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await ref
                            .read(projectAddonsProvider.notifier)
                            .deleteAddon(addon.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Add-on "${addon.title}" deleted.'),
                              backgroundColor: context.error,
                            ),
                          );
                        }
                      }
                    } else if (val.startsWith('status_')) {
                      final newStatus = val.replaceFirst('status_', '');
                      await ref
                          .read(projectAddonsProvider.notifier)
                          .updateAddon(addon.copyWith(status: newStatus));
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      enabled: false,
                      child: Text(
                        'Change Status',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'status_Pending',
                      child: Text('• Mark Pending'),
                    ),
                    const PopupMenuItem(
                      value: 'status_In Progress',
                      child: Text('• Mark In Progress'),
                    ),
                    const PopupMenuItem(
                      value: 'status_Completed',
                      child: Text('• Mark Completed'),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete Add-On',
                        style: TextStyle(color: context.error),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          // Description (if any)
          if (addon.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              addon.description,
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary,
                height: 1.3,
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Financial Breakdown & Receive Payment button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Cost: ',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Rs. ${addon.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Paid: ',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Rs. ${addon.amountPaid.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.success,
                        ),
                      ),
                    ],
                  ),
                  if (addon.remainingAmount > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Due: ',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Rs. ${addon.remainingAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: context.error,
                          ),
                        ),
                      ],
                    ),
                  if (addon.estimatedDelivery.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 11, color: context.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          'Est: ${addon.estimatedDelivery}',
                          style: TextStyle(fontSize: 11, color: context.textMuted),
                        ),
                      ],
                    ),
                ],
              ),
              if (canEdit && addon.remainingAmount > 0)
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => _ReceiveAddonPaymentDialog(
                        project: widget.project,
                        addon: addon,
                      ),
                    );
                  },
                  icon: const Icon(Icons.payment_outlined, size: 14),
                  label: const Text(
                    'Receive Payment',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MODAL TO CREATE A NEW PROJECT ADD-ON / SCOPE EXTENSION
// ============================================================================

class _AddAddonModalDialog extends ConsumerStatefulWidget {
  final Project project;

  const _AddAddonModalDialog({required this.project});

  @override
  ConsumerState<_AddAddonModalDialog> createState() =>
      _AddAddonModalDialogState();
}

class _AddAddonModalDialogState extends ConsumerState<_AddAddonModalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _paymentAmountController = TextEditingController();

  DateTime? _estimatedDeliveryDate;
  bool _receivePaymentNow = false;
  String? _selectedAccountId;
  String? _selectedAccountName;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _amountController.dispose();
    _paymentAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).accounts;

    if (_selectedAccountId == null && widget.project.bankAccountId.isNotEmpty) {
      _selectedAccountId = widget.project.bankAccountId;
      _selectedAccountName = widget.project.bankAccountName;
    }

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: EdgeInsets.all(
            MediaQuery.of(context).size.width < 600 ? 16 : 24,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_task_rounded,
                          color: Colors.purple,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Scope Change / Add-On',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                            ),
                            Text(
                              'Project: ${widget.project.name}',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: context.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 14),

                  // Add-on Title
                  _buildFormLabel(context, 'Add-On / Scope Title *'),
                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                    decoration: _buildInputDeco(
                      context,
                      'e.g. Payment Gateway Integration, Custom Reports, Mobile App Fix',
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Scope Description
                  _buildFormLabel(context, 'Scope Description / Deliverables'),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                    decoration: _buildInputDeco(
                      context,
                      'Describe specific features or changes agreed with client',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Price / Amount
                  _buildFormLabel(context, 'Add-On Amount / Cost (Rs.) *'),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                    decoration: _buildInputDeco(
                      context,
                      '0',
                      prefixText: 'Rs. ',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Amount is required';
                      }
                      final d = double.tryParse(val.trim());
                      if (d == null || d <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onChanged: (val) {
                      if (_receivePaymentNow && _paymentAmountController.text.isEmpty) {
                        _paymentAmountController.text = val;
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Estimated Delivery Date
                  _buildFormLabel(context, 'Estimated Delivery Date (Optional)'),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _estimatedDeliveryDate ??
                            DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() => _estimatedDeliveryDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: context.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _estimatedDeliveryDate == null
                                  ? 'Select estimated delivery date'
                                  : '${_estimatedDeliveryDate!.day}/${_estimatedDeliveryDate!.month}/${_estimatedDeliveryDate!.year}',
                              style: TextStyle(
                                color: _estimatedDeliveryDate == null
                                    ? context.textMuted
                                    : context.textPrimary,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: context.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Receive payment switch
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _receivePaymentNow
                          ? Colors.purple.withValues(alpha: 0.08)
                          : context.textMuted.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _receivePaymentNow
                            ? Colors.purple.withValues(alpha: 0.3)
                            : context.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                size: 18,
                                color: _receivePaymentNow
                                    ? Colors.purple
                                    : context.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Receive Advance / Payment Now',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: _receivePaymentNow,
                          activeThumbColor: Colors.purple,
                          onChanged: (val) {
                            setState(() {
                              _receivePaymentNow = val;
                              if (val && _paymentAmountController.text.isEmpty) {
                                _paymentAmountController.text =
                                    _amountController.text;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Additional payment inputs if switch is enabled
                  if (_receivePaymentNow) ...[
                    const SizedBox(height: 14),
                    _buildFormLabel(context, 'Amount Received (Rs.) *'),
                    TextFormField(
                      controller: _paymentAmountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: context.textPrimary, fontSize: 13),
                      decoration: _buildInputDeco(
                        context,
                        'Enter amount received',
                        prefixText: 'Rs. ',
                      ),
                      validator: (val) {
                        if (!_receivePaymentNow) return null;
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter received amount';
                        }
                        final d = double.tryParse(val.trim());
                        if (d == null || d <= 0) return 'Enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildFormLabel(context, 'Receiving Bank / Cash Account *'),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAccountId,
                      dropdownColor: context.cardBg,
                      isExpanded: true,
                      style: TextStyle(color: context.textPrimary, fontSize: 13),
                      decoration: _buildInputDeco(context, 'Select account'),
                      items: accounts.map((a) {
                        return DropdownMenuItem(
                          value: a.id,
                          child: Text(
                            '${a.name} (${a.bankName})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      validator: (val) {
                        if (_receivePaymentNow && val == null) {
                          return 'Select receiving account';
                        }
                        return null;
                      },
                      onChanged: (val) {
                        if (val != null) {
                          final a = accounts.firstWhere((acc) => acc.id == val);
                          setState(() {
                            _selectedAccountId = val;
                            _selectedAccountName = a.name;
                          });
                        }
                      },
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            final totalAmount = double.parse(
                              _amountController.text.trim(),
                            );
                            final paymentAmount = _receivePaymentNow
                                ? (double.tryParse(
                                        _paymentAmountController.text.trim()) ??
                                    0.0)
                                : 0.0;

                            final addonId =
                                'addon_${DateTime.now().millisecondsSinceEpoch}';

                            final deliveryStr = _estimatedDeliveryDate != null
                                ? '${_estimatedDeliveryDate!.day}/${_estimatedDeliveryDate!.month}/${_estimatedDeliveryDate!.year}'
                                : '';

                            final paymentStatus = paymentAmount >= totalAmount
                                ? 'Paid'
                                : (paymentAmount > 0
                                    ? 'Partially Paid'
                                    : 'Unpaid');

                            final newAddon = ProjectAddon(
                              id: addonId,
                              projectId: widget.project.id,
                              title: _titleController.text.trim(),
                              description: _descController.text.trim(),
                              amount: totalAmount,
                              amountPaid: paymentAmount,
                              status: 'Pending',
                              paymentStatus: paymentStatus,
                              createdAt: DateTime.now().toIso8601String(),
                              estimatedDelivery: deliveryStr,
                              bankAccountId: _selectedAccountId ?? '',
                              bankAccountName: _selectedAccountName ?? '',
                              paymentMethod: 'Bank',
                            );

                            // Save addon
                            await ref
                                .read(projectAddonsProvider.notifier)
                                .addAddon(newAddon);

                            // If payment was made, record income
                            if (_receivePaymentNow && paymentAmount > 0) {
                              final accId = _selectedAccountId ??
                                  (widget.project.bankAccountId.isNotEmpty
                                      ? widget.project.bankAccountId
                                      : 'default_account');

                              final record = IncomeRecord(
                                id: 'inc_${DateTime.now().millisecondsSinceEpoch}',
                                date: DateTime.now().toIso8601String(),
                                clientId: widget.project.clientId,
                                clientName: widget.project.clientName,
                                amount: paymentAmount,
                                accountId: accId,
                                invoiceNumber: 'ADDON-$addonId',
                                description:
                                    'Add-On Payment: ${newAddon.title} - ${widget.project.name}',
                                status: 'Received',
                                projectId: widget.project.id,
                                projectName: widget.project.name,
                                projectPaymentType: 'Add-on',
                              );

                              await ref
                                  .read(incomeProvider.notifier)
                                  .addIncome(record);
                            }

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Add-On "${newAddon.title}" added (+Rs. ${totalAmount.toStringAsFixed(0)}).',
                                  ),
                                  backgroundColor: Colors.purple,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text(
                          'Save Add-On',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormLabel(BuildContext context, String text) {
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

  InputDecoration _buildInputDeco(
    BuildContext context,
    String hint, {
    String? prefixText,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        borderSide: const BorderSide(color: Colors.purple),
      ),
    );
  }
}

// ============================================================================
// MODAL TO RECEIVE PAYMENT FOR AN EXISTING ADD-ON
// ============================================================================

class _ReceiveAddonPaymentDialog extends ConsumerStatefulWidget {
  final Project project;
  final ProjectAddon addon;

  const _ReceiveAddonPaymentDialog({
    required this.project,
    required this.addon,
  });

  @override
  ConsumerState<_ReceiveAddonPaymentDialog> createState() =>
      _ReceiveAddonPaymentDialogState();
}

class _ReceiveAddonPaymentDialogState
    extends ConsumerState<_ReceiveAddonPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  String? _selectedAccountId;
  String? _selectedAccountName;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.addon.remainingAmount > 0
          ? widget.addon.remainingAmount.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).accounts;

    if (_selectedAccountId == null) {
      if (widget.addon.bankAccountId.isNotEmpty) {
        _selectedAccountId = widget.addon.bankAccountId;
        _selectedAccountName = widget.addon.bankAccountName;
      } else if (widget.project.bankAccountId.isNotEmpty) {
        _selectedAccountId = widget.project.bankAccountId;
        _selectedAccountName = widget.project.bankAccountName;
      }
    }

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: Colors.purple,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Receive Add-On Payment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          Text(
                            widget.addon.title,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: context.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 14),

                // Amount Status Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Scope Cost',
                            style: TextStyle(fontSize: 10, color: context.textMuted),
                          ),
                          Text(
                            'Rs. ${widget.addon.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Already Paid',
                            style: TextStyle(fontSize: 10, color: context.textMuted),
                          ),
                          Text(
                            'Rs. ${widget.addon.amountPaid.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.success,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Balance Due',
                            style: TextStyle(fontSize: 10, color: context.textMuted),
                          ),
                          Text(
                            'Rs. ${widget.addon.remainingAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Amount to receive
                Text(
                  'Payment Amount *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    prefixText: 'Rs. ',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.border),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purple),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Enter amount';
                    }
                    final d = double.tryParse(val.trim());
                    if (d == null || d <= 0) return 'Enter a valid amount';
                    if (d > widget.addon.remainingAmount) {
                      return 'Cannot exceed balance due (Rs. ${widget.addon.remainingAmount.toStringAsFixed(0)})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Account Selection
                Text(
                  'Receiving Account *',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedAccountId,
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.border),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purple),
                    ),
                  ),
                  items: accounts.map((a) {
                    return DropdownMenuItem(
                      value: a.id,
                      child: Text('${a.name} (${a.bankName})'),
                    );
                  }).toList(),
                  validator: (val) => val == null ? 'Select an account' : null,
                  onChanged: (val) {
                    if (val != null) {
                      final a = accounts.firstWhere((acc) => acc.id == val);
                      setState(() {
                        _selectedAccountId = val;
                        _selectedAccountName = a.name;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: context.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final amount = double.parse(
                            _amountController.text.trim(),
                          );
                          final accId = _selectedAccountId ??
                              (widget.project.bankAccountId.isNotEmpty
                                  ? widget.project.bankAccountId
                                  : 'default_account');

                          // Record income in Finance
                          final record = IncomeRecord(
                            id: 'inc_${DateTime.now().millisecondsSinceEpoch}',
                            date: DateTime.now().toIso8601String(),
                            clientId: widget.project.clientId,
                            clientName: widget.project.clientName,
                            amount: amount,
                            accountId: accId,
                            invoiceNumber: 'ADDON-${widget.addon.id}',
                            description:
                                'Add-On Payment: ${widget.addon.title} - ${widget.project.name}',
                            status: 'Received',
                            projectId: widget.project.id,
                            projectName: widget.project.name,
                            projectPaymentType: 'Add-on',
                          );
                          await ref.read(incomeProvider.notifier).addIncome(record);

                          // Record payment on Add-on
                          await ref
                              .read(projectAddonsProvider.notifier)
                              .recordPayment(
                                addonId: widget.addon.id,
                                paymentAmount: amount,
                                bankAccountId: accId,
                                bankAccountName: _selectedAccountName ?? '',
                                paymentMethod: 'Bank',
                              );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Add-on payment of Rs. ${amount.toStringAsFixed(0)} recorded successfully.',
                                ),
                                backgroundColor: context.success,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text(
                        'Confirm Payment',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
}
