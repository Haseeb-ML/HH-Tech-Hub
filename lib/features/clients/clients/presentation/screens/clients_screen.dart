import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/core/widgets/export_button.dart';
import '../providers/clients_provider.dart';
import '../../domain/entities/client.dart';
import '../../../../projects/projects/presentation/providers/projects_provider.dart';
import '../../../../finance/income/presentation/providers/income_provider.dart';
import '../../../../finance/accounts/presentation/providers/accounts_provider.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(clientsProvider);
    final projects = ref.watch(projectsProvider).projects;
    final theme = Theme.of(context);
    final adminState = ref.watch(adminProvider);
    final canCreate = adminState.hasPermission(AppModule.clients, PermissionAction.create);
    final canExport = adminState.hasPermission(AppModule.clients, PermissionAction.export);

    // Calculate metrics
    final totalClients = state.clients.length;
    final activeClients = state.clients.where((c) => c.status == 'Active').length;
    final leadClients = state.clients.where((c) => c.status == 'Lead').length;
    final allIncomes = ref.watch(incomeProvider).incomes;
    final totalRevenue = state.clients.fold<double>(0, (sum, c) {
      final cProjects = projects.where((p) => p.clientId == c.id).toList();
      final clientIncomes = allIncomes.where((i) => i.clientId == c.id || (i.projectId != null && cProjects.any((p) => p.id == i.projectId))).toList();
      final advanced = clientIncomes.isNotEmpty
          ? clientIncomes.fold<double>(0.0, (s, i) => s + i.amount)
          : (cProjects.isNotEmpty
              ? cProjects.fold<double>(0.0, (s, p) => s + (p.advancedPayment + p.partialPayments + p.finalPayment))
              : c.advancedPayment);
      return sum + advanced;
    });

    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = width >= 1400 ? 4 : (width >= 1000 ? 3 : (width >= 650 ? 2 : 1));

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: state.isLoading && state.clients.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(width < 600 ? 12 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Add Button Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 650;
                      final titleCol = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('Clients & Relations'),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage business relations, clients pipeline, and revenue billing.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      );

                      final actionButtons = Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (canExport)
                            ExportButton(
                            title: 'Clients & Relations Report',
                            fileName: 'clients_report',
                            headers: [
                              'Client ID',
                              'Company Name',
                              'Contact Person',
                              tr('Email Address'),
                              'Phone Number',
                              tr('Status'),
                              'Industry',
                              tr('Active Projects'),
                              tr('Advanced Payment'),
                              tr('Full Payment'),
                            ],
                            rows: state.filteredClients.map((client) {
                              final cProjects = projects.where((p) => p.clientId == client.id).toList();
                              final clientIncomes = allIncomes.where((i) => i.clientId == client.id || (i.projectId != null && cProjects.any((p) => p.id == i.projectId))).toList();
                              final advanced = clientIncomes.isNotEmpty
                                  ? clientIncomes.fold<double>(0.0, (s, i) => s + i.amount)
                                  : (cProjects.isNotEmpty
                                      ? cProjects.fold<double>(0.0, (s, p) => s + (p.advancedPayment + p.partialPayments + p.finalPayment))
                                      : client.advancedPayment);
                              final full = cProjects.isNotEmpty
                                  ? cProjects.fold<double>(0.0, (sum, p) => sum + p.budget)
                                  : client.fullPayment;
                              final pCount = cProjects.isNotEmpty ? cProjects.length : client.totalProjects;
                              return [
                                client.id,
                                client.name,
                                client.contactPerson,
                                client.email,
                                client.phone,
                                client.status,
                                client.industry,
                                '$pCount',
                                'Rs. ${advanced.toStringAsFixed(0)}',
                                'Rs. ${full.toStringAsFixed(0)}',
                              ];
                            }).toList(),
                          ),
                          if (canCreate)
                            ElevatedButton.icon(
                            onPressed: () async {
                              final newClient = await showDialog<Client>(
                                context: context,
                                builder: (context) => const AddClientDialog(),
                              );
                              if (newClient != null) {
                                ref.read(clientsProvider.notifier).addClient(newClient);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${tr("Client")} "${newClient.name}" ${tr("added successfully.")}'),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: context.success,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Client'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleCol,
                            const SizedBox(height: 14),
                            actionButtons,
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(child: titleCol),
                          const SizedBox(width: 16),
                          actionButtons,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Metrics Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      final gridCrossCount = constraints.maxWidth >= 1200 ? 4 : 2;
                      return GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridCrossCount,
                          crossAxisSpacing: isMobile ? 12 : 16,
                          mainAxisSpacing: isMobile ? 12 : 16,
                          childAspectRatio: gridCrossCount == 4 ? 1.6 : (isMobile ? 0.85 : 2.2),
                        ),
                        children: [
                          StatCard(
                            title: 'Total Clients',
                            tooltipMessage: 'Detailed statistics and information regarding Total Clients.',
                            value: '$totalClients',
                            icon: Icons.business,
                            iconColor: context.primaryColor,
                            iconBgColor: context.infoLight,
                          ),
                          StatCard(
                            title: 'Active Clients',
                            tooltipMessage: 'Detailed statistics and information regarding Active Clients.',
                            value: '$activeClients',
                            icon: Icons.check_circle_outline,
                            iconColor: context.success,
                            iconBgColor: context.successLight,
                          ),
                          StatCard(
                            title: 'Leads Pipeline',
                            tooltipMessage: 'Detailed statistics and information regarding Leads Pipeline.',
                            value: '$leadClients',
                            icon: Icons.star_border,
                            iconColor: Colors.purple,
                            iconBgColor: context.isDarkMode ? Colors.purple.withValues(alpha: 0.2) : const Color(0xFFF3E8FF),
                          ),
                          StatCard(
                            title: 'Total Invoiced',
                            tooltipMessage: 'Detailed statistics and information regarding Total Invoiced.',
                            value: 'Rs. ${totalRevenue.toStringAsFixed(0)}',
                            icon: Icons.monetization_on_outlined,
                            iconColor: context.warning,
                            iconBgColor: context.warningLight,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Filters & Search Box Card
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 600;
                        final searchWidget = Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.isDarkMode ? const Color(0xFF111827) : context.scaffoldBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.border, width: 1),
                          ),
                          child: TextField(
                            onChanged: (val) => ref.read(clientsProvider.notifier).setSearchQuery(val),
                            style: TextStyle(color: context.textPrimary),
                            decoration: InputDecoration(
                              hintText: tr('Search by client name, contact, industry or email...'),
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: context.textMuted,
                              ),
                              prefixIcon: Icon(Icons.search, size: 18, color: context.textMuted),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        );

                        final statusWidget = Container(
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
                              icon: Icon(Icons.keyboard_arrow_down, color: context.textSecondary, size: 18),
                              style: TextStyle(color: context.textPrimary, fontSize: 13),
                              items: ['All', 'Active', 'Inactive', 'Lead'].map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text(s == 'All' ? tr('All Statuses') : (s == 'Active' ? tr('Active') : (s == 'Inactive' ? tr('Inactive' ) : tr('Lead')))),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  ref.read(clientsProvider.notifier).setStatusFilter(val);
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
                  const SizedBox(height: 24),

                  // Clients List Grid
                  state.filteredClients.isEmpty
                      ? _buildEmptyState(context)
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: width < 650 ? 12 : 16,
                            mainAxisSpacing: width < 650 ? 12 : 16,
                            childAspectRatio: width < 650 ? 1.6 : (width < 1100 ? 1.25 : 0.85),
                          ),
                          itemCount: state.filteredClients.length,
                          itemBuilder: (context, index) {
                            final client = state.filteredClients[index];
                            return _buildClientCard(context, ref, client);
                          },
                        ),
                ],
              ),
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
            Icon(Icons.business_center_outlined, size: 48, color: context.textMuted),
            const SizedBox(height: 16),
            Text(
              'No Clients Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search query, or add a new client.',
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, WidgetRef ref, Client client) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final isMob = MediaQuery.of(context).size.width < 600;
    final adminState = ref.watch(adminProvider);
    final canEdit = adminState.hasPermission(AppModule.clients, PermissionAction.edit);
    final canDelete = adminState.hasPermission(AppModule.clients, PermissionAction.delete);
    final projects = ref.watch(projectsProvider).projects;
    final cProjects = projects.where((p) => p.clientId == client.id).toList();
    final pCount = cProjects.isNotEmpty ? cProjects.length : client.totalProjects;
    final allIncomes = ref.watch(incomeProvider).incomes;
    final clientIncomes = allIncomes.where((i) => i.clientId == client.id || (i.projectId != null && cProjects.any((p) => p.id == i.projectId))).toList();
    final advanced = clientIncomes.isNotEmpty
        ? clientIncomes.fold<double>(0.0, (sum, i) => sum + i.amount)
        : (cProjects.isNotEmpty
            ? cProjects.fold<double>(0.0, (sum, p) => sum + (p.advancedPayment + p.partialPayments + p.finalPayment))
            : client.advancedPayment);
    final full = cProjects.isNotEmpty
        ? cProjects.fold<double>(0.0, (sum, p) => sum + p.budget)
        : client.fullPayment;
    final remaining = (full - advanced).abs();
    
    // Status color mapping
    Color statusColor;
    Color statusBg;
    if (client.status == 'Active') {
      statusColor = context.success;
      statusBg = context.successLight;
    } else if (client.status == 'Lead') {
      statusColor = Colors.purple;
      statusBg = context.isDarkMode ? Colors.purple.withValues(alpha: 0.2) : const Color(0xFFF3E8FF);
    } else {
      statusColor = context.textSecondary;
      statusBg = context.isDarkMode ? const Color(0xFF374151) : const Color(0xFFF3F4F6);
    }

    // Initials for avatar
    final initials = client.name.split(' ').map((e) => e.substring(0, 1)).take(2).join('').toUpperCase();

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => _ViewClientDetailsDialog(client: client),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(isMob ? 10 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Initials & Status badge & Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: isMob ? 28 : 36,
                        height: isMob ? 28 : 36,
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
                            fontSize: isMob ? 10 : 12,
                          ),
                        ),
                      ),
                      SizedBox(width: isMob ? 6 : 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                                fontSize: isMob ? 13 : 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              client.industry,
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: isMob ? 10 : 11,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: isMob ? 5 : 8, vertical: isMob ? 2 : 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        client.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: isMob ? 9 : 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (canEdit || canDelete) ...[
                      const SizedBox(width: 2),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, size: isMob ? 16 : 18, color: context.textSecondary),
                        color: context.cardBg,
                        padding: EdgeInsets.zero,
                        onSelected: (val) async {
                          if (val == 'delete' && canDelete) {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Client'),
                                content: Text('${tr("Are you sure you want to delete client")} "${client.name}"? ${tr("This action cannot be undone.")}'),
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
                              ref.read(clientsProvider.notifier).deleteClient(client.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${tr("Client")} "${client.name}" ${tr("removed.")}'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: context.error,
                                ),
                              );
                            }
                          } else if (val == 'toggle_status' && canEdit) {
                            final nextStatus = client.status == 'Active' ? 'Inactive' : (client.status == 'Inactive' ? 'Lead' : tr('Active'));
                            ref.read(clientsProvider.notifier).updateClient(client.copyWith(status: nextStatus));
                          } else if (val == 'edit' && canEdit) {
                            showDialog(
                              context: context,
                              builder: (context) => _EditClientDialog(client: client),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          if (canEdit)
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(tr('Edit Details'), style: TextStyle(color: context.textPrimary, fontSize: 13)),
                            ),
                          if (canEdit)
                            PopupMenuItem(
                              value: 'toggle_status',
                              child: Text('Change Status', style: TextStyle(color: context.textPrimary, fontSize: 13)),
                            ),
                          if (canDelete)
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete Client', style: TextStyle(color: context.error, fontSize: 13)),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
            SizedBox(height: isMob ? 8 : 14),
            
            // Row 2: Contact Person Info
            Row(
              children: [
                Icon(Icons.person_outline, size: isMob ? 12 : 14, color: context.textMuted),
                SizedBox(width: isMob ? 5 : 8),
                Expanded(
                  child: Text(
                    client.contactPerson,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: isMob ? 11 : 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMob ? 3 : 6),

            // Row 3: Contact Email
            Row(
              children: [
                Icon(Icons.email_outlined, size: isMob ? 12 : 14, color: context.textMuted),
                SizedBox(width: isMob ? 5 : 8),
                Expanded(
                  child: Text(
                    client.email,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: isMob ? 11 : 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMob ? 3 : 6),

            // Row 4: Phone Info
            Row(
              children: [
                Icon(Icons.phone_outlined, size: isMob ? 12 : 14, color: context.textMuted),
                SizedBox(width: isMob ? 5 : 8),
                Expanded(
                  child: Text(
                    client.phone,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: isMob ? 11 : 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isMob ? 6 : 10),
            const Divider(),
            SizedBox(height: isMob ? 4 : 8),

            // Row 5: Stats (Projects & Payments)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Projects',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$pCount Active',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      tr('Full Payment'),
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rs. ${full.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: context.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      tr('Advanced Payment'),
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rs. ${advanced.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: context.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tr('Remaining'),
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rs. ${remaining.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: context.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddClientDialog extends ConsumerStatefulWidget {
  final Client? client;

  const AddClientDialog({super.key, this.client});

  @override
  ConsumerState<AddClientDialog> createState() => AddClientDialogState();
}

class AddClientDialogState extends ConsumerState<AddClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _industryController = TextEditingController();
  String _status = 'Active';
  final _projectsController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    final client = widget.client;
    if (client != null) {
      _nameController.text = client.name;
      _contactController.text = client.contactPerson;
      _emailController.text = client.email;
      _phoneController.text = client.phone;
      _industryController.text = client.industry;
      _status = client.status;
      _projectsController.text = client.totalProjects.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _industryController.dispose();
    _projectsController.dispose();
    super.dispose();
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
        constraints: const BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                      widget.client == null ? 'Add New Client' : 'Edit Client Details',
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
                
                // Client Name
                _buildLabel('Client / Company Name', isRequired: true),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration('Enter company name'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter company name' : null,
                ),
                const SizedBox(height: 16),

                if (isMobile) ...[
                  _buildLabel('Contact Person (Optional)'),
                  TextFormField(
                    controller: _contactController,
                    style: TextStyle(color: context.textPrimary),
                    decoration: _buildInputDecoration('Enter full name'),
                    validator: null,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Industry', isRequired: true),
                  TextFormField(
                    controller: _industryController,
                    style: TextStyle(color: context.textPrimary),
                    decoration: _buildInputDecoration('e.g. E-Commerce, Tech'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter industry' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(tr('Email Address')),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: context.textPrimary),
                    decoration: _buildInputDecoration('email@company.com'),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty && !val.contains('@')) {
                        return 'Please enter valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Phone Number', isRequired: true),
                  TextFormField(
                    controller: _phoneController,
                    style: TextStyle(color: context.textPrimary),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                      LengthLimitingTextInputFormatter(15),
                    ],
                    decoration: _buildInputDecoration('+923001234567'),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter phone number';
                      final regex = RegExp(r'^\+?[0-9]{10,15}$');
                      if (!regex.hasMatch(val.trim())) {
                        return 'Enter 10-15 digits (e.g. +923001234567)';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Contact Person (Optional)'),
                            TextFormField(
                              controller: _contactController,
                              style: TextStyle(color: context.textPrimary),
                              decoration: _buildInputDecoration('Enter full name'),
                              validator: null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Industry', isRequired: true),
                            TextFormField(
                              controller: _industryController,
                              style: TextStyle(color: context.textPrimary),
                              decoration: _buildInputDecoration('e.g. E-Commerce, Tech'),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter industry' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(tr('Email Address')),
                            TextFormField(
                              controller: _emailController,
                              style: TextStyle(color: context.textPrimary),
                              decoration: _buildInputDecoration('email@company.com'),
                              validator: (val) {
                                if (val != null && val.trim().isNotEmpty && !val.contains('@')) {
                                  return 'Please enter valid email';
                                }
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
                            _buildLabel('Phone Number', isRequired: true),
                            TextFormField(
                              controller: _phoneController,
                              style: TextStyle(color: context.textPrimary),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                                LengthLimitingTextInputFormatter(15),
                              ],
                              decoration: _buildInputDecoration('+923001234567'),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Please enter phone number';
                                final regex = RegExp(r'^\+?[0-9]{10,15}$');
                                if (!regex.hasMatch(val.trim())) {
                                  return 'Enter 10-15 digits (e.g. +923001234567)';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(tr('Status')),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      dropdownColor: context.cardBg,
                      style: TextStyle(color: context.textPrimary),
                      decoration: _buildInputDecoration('Select status'),
                      items: [tr('Active'), 'Lead', 'Inactive'].map((s) {
                        return DropdownMenuItem<String>(
                          value: s,
                          child: Text(s),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _status = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                        if (_formKey.currentState!.validate()) {
                          final name = _nameController.text.trim();
                          final email = _emailController.text.trim();
                          final phone = _phoneController.text.trim();
                          final clients = ref.read(clientsProvider).clients;
                          final duplicate = clients.where((client) {
                            if (client.id == widget.client?.id) return false;
                            final sameName = client.name.trim().toLowerCase() == name.toLowerCase();
                            final samePhone = client.phone.trim() == phone;
                            final sameEmail = email.isNotEmpty && client.email.trim().toLowerCase() == email.toLowerCase();
                            return sameName || samePhone || sameEmail;
                          }).firstOrNull;
                          if (duplicate != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Client already exists: ${duplicate.name}'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: context.error,
                              ),
                            );
                            return;
                          }

                          final client = Client(
                            id: widget.client?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            name: _nameController.text.trim(),
                            contactPerson: _contactController.text.trim(),
                            email: _emailController.text.trim(),
                            phone: _phoneController.text.trim(),
                            status: _status,
                            industry: _industryController.text.trim(),
                            totalProjects: widget.client?.totalProjects ?? 0,
                            advancedPayment: widget.client?.advancedPayment ?? 0.0,
                            fullPayment: widget.client?.fullPayment ?? 0.0,
                          );
                          Navigator.of(context).pop(client);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(widget.client == null ? 'Add Client' : 'Save Changes'),
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
      child: Text.rich(
        TextSpan(
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

class _EditClientDialog extends ConsumerStatefulWidget {
  final Client client;
  const _EditClientDialog({required this.client});

  @override
  ConsumerState<_EditClientDialog> createState() => _EditClientDialogState();
}

class _EditClientDialogState extends ConsumerState<_EditClientDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _industryController;
  late String _status;
  late final TextEditingController _projectsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client.name);
    _contactController = TextEditingController(text: widget.client.contactPerson);
    _emailController = TextEditingController(text: widget.client.email);
    _phoneController = TextEditingController(text: widget.client.phone);
    _industryController = TextEditingController(text: widget.client.industry);
    _status = widget.client.status;
    _projectsController = TextEditingController(text: widget.client.totalProjects.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _industryController.dispose();
    _projectsController.dispose();
    super.dispose();
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
        constraints: const BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                      'Edit Client Details',
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
                
                // Client Name
                _buildLabel('Client / Company Name', isRequired: true),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: context.textPrimary),
                  decoration: _buildInputDecoration('Enter company name'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter company name' : null,
                ),
                const SizedBox(height: 16),

                if (isMobile) ...[
                  _buildLabel('Contact Person', isRequired: true),
                  TextFormField(
                    controller: _contactController,
                    style: TextStyle(color: context.textPrimary),
                    decoration: _buildInputDecoration('Enter full name'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter contact name' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Industry', isRequired: true),
                  TextFormField(
                    controller: _industryController,
                    style: TextStyle(color: context.textPrimary),
                    decoration: _buildInputDecoration('e.g. E-Commerce, Tech'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter industry' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(tr('Email Address')),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: context.textPrimary),
                    decoration: _buildInputDecoration('email@company.com'),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty && !val.contains('@')) {
                        return 'Please enter valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Phone Number', isRequired: true),
                  TextFormField(
                    controller: _phoneController,
                    style: TextStyle(color: context.textPrimary),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                      LengthLimitingTextInputFormatter(15),
                    ],
                    decoration: _buildInputDecoration('+923001234567'),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter phone number';
                      final regex = RegExp(r'^\+?[0-9]{10,15}$');
                      if (!regex.hasMatch(val.trim())) {
                        return 'Enter 10-15 digits (e.g. +923001234567)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(tr('Status')),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    dropdownColor: context.cardBg,
                    style: TextStyle(color: context.textPrimary),
                    decoration: _buildInputDecoration('Select status'),
                    items: [tr('Active'), 'Lead', 'Inactive'].map((s) {
                      return DropdownMenuItem<String>(
                        value: s,
                        child: Text(s),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _status = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(tr('Total Projects')),
                  TextFormField(
                    controller: _projectsController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: context.textPrimary),
                    decoration: _buildInputDecoration('0'),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Contact Person', isRequired: true),
                            TextFormField(
                              controller: _contactController,
                              style: TextStyle(color: context.textPrimary),
                              decoration: _buildInputDecoration('Enter full name'),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter contact name' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Industry', isRequired: true),
                            TextFormField(
                              controller: _industryController,
                              style: TextStyle(color: context.textPrimary),
                              decoration: _buildInputDecoration('e.g. E-Commerce, Tech'),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter industry' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(tr('Email Address')),
                            TextFormField(
                              controller: _emailController,
                              style: TextStyle(color: context.textPrimary),
                              decoration: _buildInputDecoration('email@company.com'),
                              validator: (val) {
                                if (val != null && val.trim().isNotEmpty && !val.contains('@')) {
                                  return 'Please enter valid email';
                                }
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
                            _buildLabel('Phone Number', isRequired: true),
                            TextFormField(
                              controller: _phoneController,
                              style: TextStyle(color: context.textPrimary),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                                LengthLimitingTextInputFormatter(15),
                              ],
                              decoration: _buildInputDecoration('+923001234567'),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Please enter phone number';
                                final regex = RegExp(r'^\+?[0-9]{10,15}$');
                                if (!regex.hasMatch(val.trim())) {
                                  return 'Enter 10-15 digits (e.g. +923001234567)';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(tr('Status')),
                            DropdownButtonFormField<String>(
                              initialValue: _status,
                              dropdownColor: context.cardBg,
                              style: TextStyle(color: context.textPrimary),
                              decoration: _buildInputDecoration('Select status'),
                              items: [tr('Active'), 'Lead', 'Inactive'].map((s) {
                                return DropdownMenuItem<String>(
                                  value: s,
                                  child: Text(s),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _status = val;
                                  });
                                }
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
                            _buildLabel(tr('Total Projects')),
                            TextFormField(
                              controller: _projectsController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: context.textPrimary),
                              decoration: _buildInputDecoration('0'),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                      child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    Consumer(
                      builder: (context, ref, child) {
                        return ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final updatedClient = widget.client.copyWith(
                                name: _nameController.text.trim(),
                                contactPerson: _contactController.text.trim(),
                                email: _emailController.text.trim(),
                                phone: _phoneController.text.trim(),
                                status: _status,
                                industry: _industryController.text.trim(),
                                totalProjects: int.tryParse(_projectsController.text) ?? 0,
                                advancedPayment: widget.client.advancedPayment,
                                fullPayment: widget.client.fullPayment,
                              );
                              ref.read(clientsProvider.notifier).updateClient(updatedClient);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${tr("Client")} "${updatedClient.name}" ${tr("updated successfully.")}'),
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
                        );
                      }
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
      child: Text.rich(
        TextSpan(
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

class _ViewClientDetailsDialog extends ConsumerWidget {
  final Client client;

  const _ViewClientDetailsDialog({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final projects = ref.watch(projectsProvider).projects;
    final cProjects = projects.where((p) => p.clientId == client.id).toList();
    final pCount = cProjects.isNotEmpty ? cProjects.length : client.totalProjects;
    final allIncomes = ref.watch(incomeProvider).incomes;
    final accounts = ref.watch(accountsProvider).accounts;
    final clientIncomes = allIncomes.where((i) => i.clientId == client.id || (i.projectId != null && cProjects.any((p) => p.id == i.projectId))).toList();
    final received = clientIncomes.isNotEmpty
        ? clientIncomes.fold<double>(0.0, (s, i) => s + i.amount)
        : (cProjects.isNotEmpty
            ? cProjects.fold<double>(0.0, (sum, p) => sum + (p.advancedPayment + p.partialPayments + p.finalPayment))
            : client.advancedPayment);
    final full = cProjects.isNotEmpty
        ? cProjects.fold<double>(0.0, (sum, p) => sum + p.budget)
        : client.fullPayment;
    final remaining = (full - received).abs();
    
    Color statusColor;
    Color statusBg;
    if (client.status == 'Active') {
      statusColor = context.success;
      statusBg = context.successLight;
    } else if (client.status == 'Lead') {
      statusColor = Colors.purple;
      statusBg = context.isDarkMode ? Colors.purple.withValues(alpha: 0.2) : const Color(0xFFF3E8FF);
    } else {
      statusColor = context.textSecondary;
      statusBg = context.isDarkMode ? const Color(0xFF374151) : const Color(0xFFF3F4F6);
    }

    return Dialog(
      backgroundColor: context.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 520),
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
                    tr('Client Details'),
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
              
              // Client Name & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      client.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tr(client.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                client.industry,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              
              _buildDetailRow(context, Icons.person_outline, tr('Contact Person'), client.contactPerson),
              const SizedBox(height: 12),
              _buildDetailRow(context, Icons.email_outlined, tr('Email Address'), client.email.isEmpty ? 'N/A' : client.email),
              const SizedBox(height: 12),
              _buildDetailRow(context, Icons.phone_outlined, tr('Phone Number'), client.phone),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              
              // Stats Row
              if (isMobile)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildStatItem(context, tr('Total Projects'), '$pCount Active')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatItem(context, tr('Remaining Payment'), 'Rs. ${remaining.toStringAsFixed(0)}')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildStatItem(context, tr('Full Payment'), 'Rs. ${full.toStringAsFixed(0)}')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatItem(context, tr('Received Payment'), 'Rs. ${received.toStringAsFixed(0)}')),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(context, tr('Total Projects'), '$pCount Active'),
                    _buildStatItem(context, tr('Full Payment'), 'Rs. ${full.toStringAsFixed(0)}'),
                    _buildStatItem(context, tr('Received Payment'), 'Rs. ${received.toStringAsFixed(0)}'),
                    _buildStatItem(context, tr('Remaining Payment'), 'Rs. ${remaining.toStringAsFixed(0)}'),
                  ],
                ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),

              // Payment History Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, size: 18, color: context.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Payment History',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${clientIncomes.length} ${clientIncomes.length == 1 ? "Payment" : "Payments"}',
                      style: TextStyle(
                        color: context.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (clientIncomes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.border),
                  ),
                  child: Center(
                    child: Text(
                      'No payment transactions recorded yet.',
                      style: TextStyle(color: context.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.border),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: clientIncomes.length,
                    separatorBuilder: (context, idx) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final inc = clientIncomes[idx];
                      final acc = accounts.where((a) => a.id == inc.accountId).firstOrNull;
                      final accLabel = acc != null ? '${acc.name} (${acc.bankName})' : 'Account';
                      final title = (inc.projectName != null && inc.projectName!.isNotEmpty)
                          ? inc.projectName!
                          : inc.incomeType;
                      final dateStr = inc.date.split('T').first;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: context.successLight,
                              child: Icon(Icons.arrow_downward, size: 13, color: context.success),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$dateStr • $accLabel',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: context.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '+Rs. ${inc.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: context.success,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(tr('Close')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: context.textMuted),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
