import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/inventory/shared/widgets/inventory_sub_nav.dart';
import 'package:software_house_erp/features/hr/employees/presentation/providers/employees_provider.dart';
import '../providers/assets_provider.dart';
import '../../../../finance/accounts/presentation/providers/accounts_provider.dart';
import '../../../../finance/expenses/domain/entities/expense_record.dart';
import '../../../../finance/expenses/presentation/providers/expenses_provider.dart';
import '../../domain/entities/asset.dart';


class AssetsScreen extends ConsumerWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(assetsProvider);
    final theme = Theme.of(context);

    // Calculate metrics
    final totalAssets = state.assets.length;
    final assignedAssets = state.assets.where((a) => a.status == 'Assigned').length;
    final availableAssets = state.assets.where((a) => a.status == 'Available').length;
    final maintenanceAssets = state.assets.where((a) => a.status == 'Under Maintenance').length;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: state.isLoading && state.assets.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Sub navigation
                const InventorySubNav(activeRoute: '/inventory/assets'),
                
                // Screen Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Add Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Asset Management',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Track software licenses and hardware devices assigned to employees.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [

                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final successColor = context.success;
                                    final result = await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      builder: (context) => const _AddAssetDialog(),
                                    );
                                    if (result != null) {
                                      final asset = result['asset'] as Asset;
                                      final accountId = result['accountId'] as String;
                                      final totalCost = (result['totalCost'] as num).toDouble();

                                      await ref.read(assetsProvider.notifier).addAsset(asset);
                                      await ref.read(expensesProvider.notifier).addExpense(
                                        ExpenseRecord(
                                          id: 'AST-EXP-${asset.id}',
                                          date: DateTime.now().toIso8601String(),
                                          amount: totalCost,
                                          accountId: accountId,
                                          category: ExpenseRecord.assetCategory(),
                                          vendorName: 'Asset Purchase',
                                          description: 'Asset purchase - ${asset.name}',
                                        ),
                                      );

                                      if (!context.mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('${tr("Asset")} "${asset.name}" ${tr("added successfully.")}'),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: successColor,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Asset'),
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

                        // Stats Row
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: 'Total Assets',
                                tooltipMessage: 'Detailed statistics and information regarding Total Assets.',
                                value: '$totalAssets',
                                icon: Icons.devices_other_outlined,
                                iconColor: context.primaryColor,
                                iconBgColor: context.infoLight,
                                trendText: tr('Devices & Licenses'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StatCard(
                                title: tr('Assigned'),
                                tooltipMessage: "Detailed statistics and information regarding ${tr('Assigned')}.",
                                value: '$assignedAssets',
                                icon: Icons.person_pin_outlined,
                                iconColor: context.success,
                                iconBgColor: context.successLight,
                                trendText: tr('In active use'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StatCard(
                                title: 'Available',
                                tooltipMessage: 'Detailed statistics and information regarding Available.',
                                value: '$availableAssets',
                                icon: Icons.check_circle_outline,
                                iconColor: context.info,
                                iconBgColor: context.infoLight,
                                trendText: tr('Ready to deploy'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StatCard(
                                title: 'In Maintenance',
                                tooltipMessage: 'Detailed statistics and information regarding In Maintenance.',
                                value: '$maintenanceAssets',
                                icon: Icons.build_circle_outlined,
                                iconColor: context.warning,
                                iconBgColor: context.warningLight,
                                trendText: tr('Repairing / Checking'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Filters Bar
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Search
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    onChanged: (val) => ref.read(assetsProvider.notifier).setSearchQuery(val),
                                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: tr('Search by name, serial, or employee...'),
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
                                const SizedBox(width: 16),

                                // Type Filter
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: state.typeFilter,
                                    dropdownColor: context.cardBg,
                                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: tr('Type'),
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
                                      DropdownMenuItem(value: 'All', child: Text('All Types')),
                                      DropdownMenuItem(value: 'Hardware', child: Text('Hardware')),
                                      DropdownMenuItem(value: 'Software', child: Text('Software')),
                                      DropdownMenuItem(value: 'Other', child: Text(tr('Other'))),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref.read(assetsProvider.notifier).setTypeFilter(val);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Status Filter
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: state.statusFilter,
                                    dropdownColor: context.cardBg,
                                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: tr('Status'),
                                      labelStyle: TextStyle(color: context.textSecondary, fontSize: 11),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                      DropdownMenuItem(value: 'Available', child: Text('Available')),
                                      DropdownMenuItem(value: 'Assigned', child: Text(tr('Assigned'))),
                                      DropdownMenuItem(value: 'Under Maintenance', child: Text('In Maintenance')),
                                      DropdownMenuItem(value: 'Retired', child: Text('Retired')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref.read(assetsProvider.notifier).setStatusFilter(val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Assets Grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            int crossAxisCount = width >= 1200 ? 3 : (width >= 800 ? 2 : 1);
                            
                            if (state.filteredAssets.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Text(
                                    'No assets found matching the criteria.',
                                    style: TextStyle(color: context.textSecondary, fontSize: 14),
                                  ),
                                ),
                              );
                            }

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 280,
                              ),
                              itemCount: state.filteredAssets.length,
                              itemBuilder: (context, index) {
                                final asset = state.filteredAssets[index];
                                return _AssetCard(asset: asset);
                              },
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

class _AssetCard extends ConsumerWidget {
  final Asset asset;

  const _AssetCard({required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final linkedExpense = ref.watch(expensesProvider).expenses
      .where((expense) => expense.id == 'AST-EXP-${asset.id}')
      .firstOrNull;
    final paymentAccount = linkedExpense == null
      ? null
      : ref.watch(accountsProvider).accounts
        .where((account) => account.id == linkedExpense.accountId)
        .firstOrNull;

    // Status colors
    Color statusColor = context.info;
    Color statusBg = context.infoLight;
    if (asset.status == 'Assigned') {
      statusColor = context.success;
      statusBg = context.successLight;
    } else if (asset.status == 'Under Maintenance') {
      statusColor = context.warning;
      statusBg = context.warningLight;
    } else if (asset.status == 'Retired') {
      statusColor = context.error;
      statusBg = context.errorLight;
    }

    // Condition Color
    Color conditionColor = context.textSecondary;
    if (asset.condition == 'New') {
      conditionColor = context.success;
    } else if (asset.condition == 'Damaged') {
      conditionColor = context.error;
    }

    // Asset Icon
    IconData assetIcon = Icons.devices_other;
    if (asset.type == 'Hardware') {
      assetIcon = asset.name.toLowerCase().contains('monitor')
          ? Icons.monitor
          : (asset.name.toLowerCase().contains('keyboard') || asset.name.toLowerCase().contains('mouse')
              ? Icons.keyboard_alt_outlined
              : Icons.laptop_windows_outlined);
    } else if (asset.type == 'Software') {
      assetIcon = Icons.code_rounded;
    }

    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => _AssetDetailsDialog(asset: asset),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon, Name & Type + Menu Action
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(assetIcon, color: context.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
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
                          '${asset.type} • ${asset.serialNumber.isNotEmpty ? 'S/N: ${asset.serialNumber}' : 'No S/N'}',
                          style: TextStyle(color: context.textMuted, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18, color: context.textSecondary),
                    color: context.cardBg,
                    onSelected: (val) async {
                      if (val == 'details') {
                        showDialog(
                          context: context,
                          builder: (context) => _AssetDetailsDialog(asset: asset),
                        );
                      } else if (val == 'edit') {
                        showDialog(
                          context: context,
                          builder: (context) => _EditAssetDialog(asset: asset),
                        );
                      } else if (val == 'delete') {
                        final messenger = ScaffoldMessenger.of(context);
                        final errorColor = context.error;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(tr('Delete Asset')),
                            content: Text('${tr("Are you sure you want to delete asset")} "${asset.name}"? ${tr("This action cannot be undone.")}'),
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
                          try {
                            await ref.read(assetsProvider.notifier).deleteAsset(asset.id);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('${tr("Asset")} "${asset.name}" ${tr("deleted.")}'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: errorColor,
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete asset: $e'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: errorColor,
                              ),
                            );
                          }
                        }
                      } else if (val == 'maintenance') {
                        ref.read(assetsProvider.notifier).updateAsset(asset.copyWith(
                              status: 'Under Maintenance',
                              assignedToId: null,
                              assignedToName: null,
                            ));
                      } else if (val == 'retire') {
                        ref.read(assetsProvider.notifier).updateAsset(asset.copyWith(
                              status: 'Retired',
                              assignedToId: null,
                              assignedToName: null,
                            ));
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'details',
                        child: Text('View Details', style: TextStyle(color: context.textPrimary, fontSize: 13)),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(tr('Edit Details'), style: TextStyle(color: context.textPrimary, fontSize: 13)),
                      ),
                      PopupMenuItem(
                        value: 'maintenance',
                        child: Text('Mark Maintenance', style: TextStyle(color: context.textPrimary, fontSize: 13)),
                      ),
                      PopupMenuItem(
                        value: 'retire',
                        child: Text('Retire Asset', style: TextStyle(color: context.textPrimary, fontSize: 13)),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(tr('Delete Asset'), style: TextStyle(color: context.error, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Details: Cost, Purchase Date, Condition, Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cost', style: TextStyle(color: context.textMuted, fontSize: 10)),
                      Text(
                        'Rs. ${asset.cost.toStringAsFixed(0)}',
                        style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Condition', style: TextStyle(color: context.textMuted, fontSize: 10)),
                      Text(
                        asset.condition,
                        style: TextStyle(color: conditionColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('Status'), style: TextStyle(color: context.textMuted, fontSize: 10)),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          asset.status,
                          style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Purchase Date Row
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 11, color: context.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    'Purchased: ${asset.purchaseDate.split('T').first}',
                    style: TextStyle(color: context.textMuted, fontSize: 11),
                  ),
                ],
              ),
              if (paymentAccount != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 11, color: context.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Paid from: ${paymentAccount.name} • ${paymentAccount.accountScope}${paymentAccount.accountScope == 'Personal' && paymentAccount.ownerName.isNotEmpty ? ' (${paymentAccount.ownerName})' : ''}',
                        style: TextStyle(color: context.textMuted, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(),

              // Assignment Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: context.scaffoldBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: asset.status == 'Assigned'
                          ? Row(
                              children: [
                                Icon(Icons.person_outline, size: 14, color: context.textSecondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    asset.assignedToName ?? 'Employee',
                                    style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              asset.status == 'Available' ? 'Unassigned' : 'Not Deployable',
                              style: TextStyle(color: context.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                    ),
                    if (asset.status == 'Assigned')
                      TextButton(
                        onPressed: () {
                          ref.read(assetsProvider.notifier).updateAsset(asset.copyWith(
                                status: 'Available',
                                assignedToId: null,
                                assignedToName: null,
                              ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Asset returned successfully.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Return', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      )
                    else if (asset.status == 'Available')
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => _AssignAssetDialog(asset: asset),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Assign', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Click to view full specs & history',
                    style: TextStyle(fontSize: 10, color: context.primaryColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_forward, size: 10, color: context.primaryColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddAssetDialog extends ConsumerStatefulWidget {
  const _AddAssetDialog();

  @override
  ConsumerState<_AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends ConsumerState<_AddAssetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _serialController = TextEditingController();
  final _costController = TextEditingController();
  String _type = 'Hardware';
  String _condition = 'Good';
  String? _selectedAccountId;

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final accounts = ref.watch(accountsProvider).accounts.where((a) => a.status == 'Active').toList();

    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add New Asset',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: context.textPrimary),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: context.textSecondary,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Row 1: Asset Name
              _buildLabel(context, 'Asset Name', isRequired: true),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: context.textPrimary),
                decoration: _buildInputDecoration(context, 'e.g. MacBook Pro M3, Adobe CC Suite'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter asset name' : null,
              ),
              const SizedBox(height: 16),

              // Row 2: Asset Type & Serial / License Key (Optional)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, 'Asset Type', isRequired: true),
                        DropdownButtonFormField<String>(
                          value: _type,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13),
                          decoration: _buildInputDecoration(context, ''),
                          items: [
                            DropdownMenuItem(value: 'Hardware', child: Text('Hardware')),
                            DropdownMenuItem(value: 'Software', child: Text('Software')),
                            DropdownMenuItem(value: 'Other', child: Text(tr('Other'))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _type = val);
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
                        _buildLabel(context, 'Serial / License Key (Optional)', isRequired: false),
                        TextFormField(
                          controller: _serialController,
                          style: TextStyle(color: context.textPrimary),
                          decoration: _buildInputDecoration(context, 'e.g. SN-991244 (Optional)'),
                          validator: null, // Optional field - no validation required
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 3: Purchase Cost & Payment From Bank / Wallet
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, 'Purchase Cost (Rs.)', isRequired: true),
                        TextFormField(
                          controller: _costController,
                          style: TextStyle(color: context.textPrimary),
                          keyboardType: TextInputType.number,
                          decoration: _buildInputDecoration(context, 'e.g. 120000'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Please enter cost';
                            if (double.tryParse(val) == null) return 'Please enter a valid number';
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
                        _buildLabel(context, 'Payment From Bank / Wallet', isRequired: true),
                        DropdownButtonFormField<String>(
                          value: _selectedAccountId,
                          isExpanded: true,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13),
                          decoration: _buildInputDecoration(context, 'Select account'),
                          items: accounts.map((a) {
                            final scope = a.accountScope == 'Personal'
                                ? 'Personal${a.ownerName.isNotEmpty ? ' • ${a.ownerName}' : ''}'
                                : 'Company';
                            return DropdownMenuItem(
                              value: a.id,
                              child: Text('${a.name} • $scope', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedAccountId = val);
                            }
                          },
                          validator: (val) => val == null || val.isEmpty ? 'Select payment account' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 4: Asset Condition
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, 'Asset Condition', isRequired: true),
                        DropdownButtonFormField<String>(
                          value: _condition,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13),
                          decoration: _buildInputDecoration(context, ''),
                          items: [
                            DropdownMenuItem(value: 'New', child: Text(tr('New'))),
                            DropdownMenuItem(value: 'Good', child: Text('Good')),
                            DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                            DropdownMenuItem(value: 'Damaged', child: Text('Damaged')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _condition = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Dialog Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final selectedAccount = accounts.firstWhere(
                          (a) => a.id == _selectedAccountId,
                          orElse: () => accounts.first,
                        );
                        final totalCost = double.tryParse(_costController.text) ?? 0.0;

                        if (selectedAccount.balance < totalCost) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Note: Account balance is lower than total asset cost of Rs. ${totalCost.toStringAsFixed(2)}'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.orange.shade800,
                            ),
                          );
                        }

                        final newAsset = Asset(
                          id: 'AST-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                          name: _nameController.text.trim(),
                          type: _type,
                          serialNumber: _serialController.text.trim(),
                          purchaseDate: DateTime.now().toIso8601String().substring(0, 10),
                          cost: totalCost,
                          status: 'Available',
                          condition: _condition,
                        );
                        Navigator.pop(context, {
                          'asset': newAsset,
                          'accountId': selectedAccount.id,
                          'totalCost': totalCost,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Asset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
          children: isRequired
              ? [
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: context.scaffoldBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
    );
  }
}

class _EditAssetDialog extends ConsumerStatefulWidget {
  final Asset asset;
  const _EditAssetDialog({required this.asset});

  @override
  ConsumerState<_EditAssetDialog> createState() => _EditAssetDialogState();
}

class _EditAssetDialogState extends ConsumerState<_EditAssetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _serialController;
  late final TextEditingController _costController;
  late String _type;
  late String _condition;
  late String _status;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.asset.name);
    _serialController = TextEditingController(text: widget.asset.serialNumber);
    _costController = TextEditingController(text: widget.asset.cost.toStringAsFixed(0));
    _type = widget.asset.type;
    _condition = widget.asset.condition;
    _status = widget.asset.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serialController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final accounts = ref.watch(accountsProvider).accounts.where((a) => a.status == 'Active').toList();
    final linkedExpense = ref.watch(expensesProvider).expenses.where((e) => e.id == 'AST-EXP-${widget.asset.id}').firstOrNull;

    if (_selectedAccountId == null) {
      _selectedAccountId = linkedExpense?.accountId ?? (accounts.isNotEmpty ? accounts.first.id : null);
    }

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Asset Details',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: context.textPrimary),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: context.textSecondary,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Row 1: Asset Name
              _buildLabel(context, 'Asset Name', isRequired: true),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: context.textPrimary),
                decoration: _buildInputDecoration(context, 'Enter asset name'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter asset name' : null,
              ),
              const SizedBox(height: 16),

              // Row 2: Asset Type & Serial / License Key (Optional)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, 'Asset Type', isRequired: true),
                        DropdownButtonFormField<String>(
                          value: _type,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13),
                          decoration: _buildInputDecoration(context, ''),
                          items: [
                            DropdownMenuItem(value: 'Hardware', child: Text('Hardware')),
                            DropdownMenuItem(value: 'Software', child: Text('Software')),
                            DropdownMenuItem(value: 'Other', child: Text(tr('Other'))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _type = val);
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
                        _buildLabel(context, 'Serial / License Key (Optional)', isRequired: false),
                        TextFormField(
                          controller: _serialController,
                          style: TextStyle(color: context.textPrimary),
                          decoration: _buildInputDecoration(context, 'e.g. SN-991244 (Optional)'),
                          validator: null, // Optional field
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 3: Cost & Payment Account
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, 'Cost (Rs.)', isRequired: true),
                        TextFormField(
                          controller: _costController,
                          style: TextStyle(color: context.textPrimary),
                          keyboardType: TextInputType.number,
                          decoration: _buildInputDecoration(context, 'e.g. 120000'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Please enter cost';
                            if (double.tryParse(val) == null) return 'Please enter a valid number';
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
                        _buildLabel(context, 'Payment From Bank / Wallet', isRequired: true),
                        DropdownButtonFormField<String>(
                          value: _selectedAccountId,
                          isExpanded: true,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13),
                          decoration: _buildInputDecoration(context, 'Select account'),
                          items: accounts.map((a) {
                            final scope = a.accountScope == 'Personal'
                                ? 'Personal${a.ownerName.isNotEmpty ? ' • ${a.ownerName}' : ''}'
                                : 'Company';
                            return DropdownMenuItem(
                              value: a.id,
                              child: Text('${a.name} • $scope', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedAccountId = val);
                          },
                          validator: (val) => val == null || val.isEmpty ? 'Select payment account' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 4: Condition & Status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, 'Condition', isRequired: true),
                        DropdownButtonFormField<String>(
                          value: _condition,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13),
                          decoration: _buildInputDecoration(context, ''),
                          items: [
                            DropdownMenuItem(value: 'New', child: Text(tr('New'))),
                            DropdownMenuItem(value: 'Good', child: Text('Good')),
                            DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                            DropdownMenuItem(value: 'Damaged', child: Text('Damaged')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _condition = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, tr('Status'), isRequired: true),
                        DropdownButtonFormField<String>(
                          value: _status,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13),
                          decoration: _buildInputDecoration(context, ''),
                          items: [
                            DropdownMenuItem(value: 'Available', child: Text('Available')),
                            DropdownMenuItem(value: 'Assigned', child: Text(tr('Assigned'))),
                            DropdownMenuItem(value: 'Under Maintenance', child: Text('Maintenance')),
                            DropdownMenuItem(value: 'Retired', child: Text('Retired')),
                          ],
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
                ],
              ),
              const SizedBox(height: 24),

              // Dialog Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Consumer(
                    builder: (context, ref, _) => TextButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final errorColor = context.error;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(tr('Delete Asset')),
                            content: Text('${tr("Are you sure you want to delete asset")} "${widget.asset.name}"? ${tr("This action cannot be undone.")}'),
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
                          try {
                            await ref.read(assetsProvider.notifier).deleteAsset(widget.asset.id);
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('${tr("Asset")} "${widget.asset.name}" ${tr("deleted.")}'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: errorColor,
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete asset: $e'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: errorColor,
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.delete_outline, size: 16, color: context.error),
                      label: Text(tr('Delete Asset'), style: TextStyle(color: context.error, fontSize: 13)),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                      ),
                      const SizedBox(width: 12),
                      Consumer(
                        builder: (context, ref, child) {
                          return ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final selectedAccount = accounts.firstWhere(
                                  (a) => a.id == _selectedAccountId,
                                  orElse: () => accounts.first,
                                );
                                final updatedAsset = widget.asset.copyWith(
                                  name: _nameController.text.trim(),
                                  type: _type,
                                  serialNumber: _serialController.text.trim(),
                                  cost: double.tryParse(_costController.text) ?? 0.0,
                                  condition: _condition,
                                  status: _status,
                                  assignedToId: _status == 'Assigned' ? widget.asset.assignedToId : null,
                                  assignedToName: _status == 'Assigned' ? widget.asset.assignedToName : null,
                                );

                                final linkedExpense = ref.read(expensesProvider).expenses.where((e) => e.id == 'AST-EXP-${widget.asset.id}').firstOrNull;
                                final updatedExpense = ExpenseRecord(
                                  id: 'AST-EXP-${widget.asset.id}',
                                  date: linkedExpense?.date ?? DateTime.now().toIso8601String(),
                                  amount: updatedAsset.cost,
                                  accountId: selectedAccount.id,
                                  category: ExpenseRecord.assetCategory(),
                                  vendorName: 'Asset Purchase',
                                  description: 'Asset purchase - ${updatedAsset.name}',
                                );

                                if (linkedExpense != null) {
                                  await ref.read(expensesProvider.notifier).updateExpense(linkedExpense, updatedExpense);
                                } else {
                                  await ref.read(expensesProvider.notifier).addExpense(updatedExpense);
                                }

                                await ref.read(assetsProvider.notifier).updateAsset(updatedAsset);
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(tr('Asset updated successfully.')),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: context.primaryColor,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(tr('Save Changes')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
          children: isRequired
              ? [
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: context.scaffoldBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
    );
  }
}

class _AssignAssetDialog extends ConsumerStatefulWidget {
  final Asset asset;
  const _AssignAssetDialog({required this.asset});

  @override
  ConsumerState<_AssignAssetDialog> createState() => _AssignAssetDialogState();
}

class _AssignAssetDialogState extends ConsumerState<_AssignAssetDialog> {
  String? _selectedEmployeeId;

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final employeesState = ref.watch(employeesProvider);
    final activeEmployees = employeesState.employees.where((e) => e.status == 'Active').toList();
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign Asset',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Select an employee to assign "${widget.asset.name}" to.',
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            _buildLabel(context, 'Active Employee'),
            employeesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedEmployeeId,
                    dropdownColor: context.cardBg,
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                    decoration: _buildInputDecoration(context, tr('Select Employee')),
                    items: activeEmployees.map((emp) {
                      return DropdownMenuItem<String>(
                        value: emp.id,
                        child: Text('${emp.name} (${emp.designation})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedEmployeeId = val);
                    },
                  ),
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedEmployeeId == null
                      ? null
                      : () {
                          final selectedEmp = activeEmployees.firstWhere((e) => e.id == _selectedEmployeeId);
                          ref.read(assetsProvider.notifier).updateAsset(widget.asset.copyWith(
                                status: 'Assigned',
                                assignedToId: selectedEmp.id,
                                assignedToName: selectedEmp.name,
                              ));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${tr("Asset successfully assigned to")} ${selectedEmp.name}.'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: context.success,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Assign Asset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: context.scaffoldBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: context.border)),
    );
  }
}

class _AssetDetailsDialog extends ConsumerWidget {
  final Asset asset;

  const _AssetDetailsDialog({required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAsset = ref.watch(assetsProvider).assets.where((a) => a.id == asset.id).firstOrNull ?? asset;
    final theme = Theme.of(context);

    // Status colors
    Color statusColor = context.info;
    Color statusBg = context.infoLight;
    if (liveAsset.status == 'Assigned') {
      statusColor = context.success;
      statusBg = context.successLight;
    } else if (liveAsset.status == 'Under Maintenance') {
      statusColor = context.warning;
      statusBg = context.warningLight;
    } else if (liveAsset.status == 'Retired') {
      statusColor = context.error;
      statusBg = context.errorLight;
    }

    Color conditionColor = context.textSecondary;
    if (liveAsset.condition == 'New') {
      conditionColor = context.success;
    } else if (liveAsset.condition == 'Damaged') {
      conditionColor = context.error;
    }

    IconData assetIcon = Icons.devices_other;
    if (liveAsset.type == 'Hardware') {
      assetIcon = liveAsset.name.toLowerCase().contains('monitor')
          ? Icons.monitor
          : (liveAsset.name.toLowerCase().contains('keyboard') || liveAsset.name.toLowerCase().contains('mouse')
              ? Icons.keyboard_alt_outlined
              : Icons.laptop_windows_outlined);
    } else if (liveAsset.type == 'Software') {
      assetIcon = Icons.code_rounded;
    }

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(assetIcon, color: context.primaryColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        liveAsset.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              liveAsset.type,
                              style: TextStyle(color: context.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              liveAsset.status,
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
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

            // Key Specs Grid
            Row(
              children: [
                Expanded(
                  child: _buildAssetInfoTile(
                    context,
                    label: 'Purchase Cost',
                    value: 'Rs. ${liveAsset.cost.toStringAsFixed(0)}',
                    icon: Icons.payments_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAssetInfoTile(
                    context,
                    label: 'Purchase Date',
                    value: liveAsset.purchaseDate.split('T').first,
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAssetInfoTile(
                    context,
                    label: 'Condition',
                    value: liveAsset.condition,
                    icon: Icons.health_and_safety_outlined,
                    valueColor: conditionColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAssetInfoTile(
                    context,
                    label: 'Serial Number',
                    value: liveAsset.serialNumber.isNotEmpty ? liveAsset.serialNumber : 'None / Not Provided',
                    icon: Icons.qr_code_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Custody / Assignment Card
            Text(
              'Deployment & Custody',
              style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.scaffoldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: (liveAsset.status == 'Assigned' ? context.success : context.primaryColor).withValues(alpha: 0.1),
                    child: Icon(
                      liveAsset.status == 'Assigned' ? Icons.person : Icons.inventory_2_outlined,
                      size: 20,
                      color: liveAsset.status == 'Assigned' ? context.success : context.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liveAsset.status == 'Assigned'
                              ? 'Assigned to: ${liveAsset.assignedToName ?? 'Employee'}'
                              : (liveAsset.status == 'Available' ? 'Available for Deployment' : liveAsset.status),
                          style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          liveAsset.status == 'Assigned'
                              ? 'Employee ID: ${liveAsset.assignedToId ?? 'N/A'}'
                              : (liveAsset.status == 'Available' ? 'Ready to be assigned to any staff member' : 'Not currently in service'),
                          style: TextStyle(color: context.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (liveAsset.status == 'Assigned')
                    ElevatedButton(
                      onPressed: () {
                        ref.read(assetsProvider.notifier).updateAsset(liveAsset.copyWith(
                          status: 'Available',
                          assignedToId: null,
                          assignedToName: null,
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Asset returned successfully.'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.warning,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Return', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  else if (liveAsset.status == 'Available')
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => _AssignAssetDialog(asset: liveAsset),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Assign', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Asset'),
                        content: Text('Are you sure you want to delete asset "${liveAsset.name}"? This action cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Delete', style: TextStyle(color: context.error))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(assetsProvider.notifier).deleteAsset(liveAsset.id);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Asset "${liveAsset.name}" deleted.'), backgroundColor: context.error),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.error,
                    side: BorderSide(color: context.error.withValues(alpha: 0.4)),
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => _EditAssetDialog(asset: liveAsset),
                        );
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit Details'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Close'),
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

  Widget _buildAssetInfoTile(BuildContext context, {required String label, required String value, required IconData icon, Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: valueColor ?? context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
