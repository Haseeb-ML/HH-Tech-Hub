import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/inventory/shared/widgets/inventory_sub_nav.dart';
import '../providers/assets_provider.dart';
import '../../../../finance/accounts/presentation/providers/accounts_provider.dart';
import '../../../../finance/expenses/domain/entities/expense_record.dart';
import '../../../../finance/expenses/presentation/providers/expenses_provider.dart';
import '../../domain/entities/asset.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';


class AssetsScreen extends ConsumerWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(assetsProvider);
    final theme = Theme.of(context);
    final adminState = ref.watch(adminProvider);
    final canCreate = adminState.hasPermission(AppModule.assets, PermissionAction.create);

    // Calculate metrics
    final totalAssets = state.assets.length;
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
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile = constraints.maxWidth < 650;
                            final titleWidget = Column(
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
                                  'Track software licenses and hardware devices.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            );

                            final actionBtn = ElevatedButton.icon(
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
                            );

                            if (isMobile) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  titleWidget,
                                  if (canCreate) ...[
                                    const SizedBox(height: 14),
                                    actionBtn,
                                  ],
                                ],
                              );
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(child: titleWidget),
                                if (canCreate) ...[
                                  const SizedBox(width: 16),
                                  actionBtn,
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Stats Row
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth >= 900 ? 3 : 1;
                            final isMobile = constraints.maxWidth < 600;
                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: isMobile ? 12 : 16,
                              mainAxisSpacing: isMobile ? 12 : 16,
                              childAspectRatio: crossAxisCount == 3 ? 2.0 : (isMobile ? 1.0 : 2.5),
                              children: [
                                StatCard(
                                  title: 'Total Assets',
                                  tooltipMessage: 'Detailed statistics and information regarding Total Assets.',
                                  value: '$totalAssets',
                                  icon: Icons.devices_other_outlined,
                                  iconColor: context.primaryColor,
                                  iconBgColor: context.infoLight,
                                  trendText: tr('Devices & Licenses'),
                                ),
                                StatCard(
                                  title: 'Available',
                                  tooltipMessage: 'Detailed statistics and information regarding Available.',
                                  value: '$availableAssets',
                                  icon: Icons.check_circle_outline,
                                  iconColor: context.info,
                                  iconBgColor: context.infoLight,
                                  trendText: tr('Ready to deploy'),
                                ),
                                StatCard(
                                  title: 'In Maintenance',
                                  tooltipMessage: 'Detailed statistics and information regarding In Maintenance.',
                                  value: '$maintenanceAssets',
                                  icon: Icons.build_circle_outlined,
                                  iconColor: context.warning,
                                  iconBgColor: context.warningLight,
                                  trendText: tr('Repairing / Checking'),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Filters Bar
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isMobile = constraints.maxWidth < 700;
                                final hasActiveFilter = state.typeFilter != 'All' || state.statusFilter != 'All';

                                final searchField = TextField(
                                  onChanged: (val) => ref.read(assetsProvider.notifier).setSearchQuery(val),
                                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: tr('Search by name, serial, or type...'),
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

                                final filterButton = PopupMenuButton<String>(
                                  tooltip: 'Filter Assets',
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: hasActiveFilter
                                          ? context.primaryColor.withValues(alpha: 0.15)
                                          : context.scaffoldBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: hasActiveFilter ? context.primaryColor : context.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.filter_list,
                                          size: 18,
                                          color: hasActiveFilter ? context.primaryColor : context.textPrimary,
                                        ),
                                        if (hasActiveFilter) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: context.primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  onSelected: (val) {
                                    if (val.startsWith('type:')) {
                                      ref.read(assetsProvider.notifier).setTypeFilter(val.replaceFirst('type:', ''));
                                    } else if (val.startsWith('status:')) {
                                      ref.read(assetsProvider.notifier).setStatusFilter(val.replaceFirst('status:', ''));
                                    } else if (val == 'clear') {
                                      ref.read(assetsProvider.notifier).setTypeFilter('All');
                                      ref.read(assetsProvider.notifier).setStatusFilter('All');
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem<String>(
                                      enabled: false,
                                      child: Text('FILTER BY TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    ),
                                    ...['All', 'Hardware', 'Software', 'Other'].map(
                                      (t) => PopupMenuItem<String>(
                                        value: 'type:$t',
                                        child: Row(
                                          children: [
                                            Icon(state.typeFilter == t ? Icons.check : Icons.circle_outlined, size: 14, color: state.typeFilter == t ? context.primaryColor : Colors.transparent),
                                            const SizedBox(width: 8),
                                            Text(t == 'All' ? 'All Types' : t),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem<String>(
                                      enabled: false,
                                      child: Text('FILTER BY STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    ),
                                    ...[
                                      {'val': 'All', 'label': tr('All Statuses')},
                                      {'val': 'Available', 'label': 'Available'},
                                      {'val': 'Assigned', 'label': tr('Assigned')},
                                      {'val': 'Under Maintenance', 'label': 'In Maintenance'},
                                      {'val': 'Retired', 'label': 'Retired'},
                                    ].map(
                                      (s) => PopupMenuItem<String>(
                                        value: 'status:${s['val']}',
                                        child: Row(
                                          children: [
                                            Icon(state.statusFilter == s['val'] ? Icons.check : Icons.circle_outlined, size: 14, color: state.statusFilter == s['val'] ? context.primaryColor : Colors.transparent),
                                            const SizedBox(width: 8),
                                            Text(s['label']!),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (hasActiveFilter) ...[
                                      const PopupMenuDivider(),
                                      PopupMenuItem<String>(
                                        value: 'clear',
                                        child: Row(
                                          children: [
                                            Icon(Icons.clear_all, size: 16, color: context.error),
                                            const SizedBox(width: 8),
                                            Text('Reset Filters', style: TextStyle(color: context.error, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                );

                                final typeField = DropdownButtonFormField<String>(
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
                                );

                                final statusField = DropdownButtonFormField<String>(
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
                                    DropdownMenuItem(value: 'Available', child: Text('Available')),
                                    DropdownMenuItem(value: 'Under Maintenance', child: Text('In Maintenance')),
                                    DropdownMenuItem(value: 'Retired', child: Text('Retired')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      ref.read(assetsProvider.notifier).setStatusFilter(val);
                                    }
                                  },
                                );

                                if (isMobile) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: searchField),
                                          const SizedBox(width: 8),
                                          filterButton,
                                        ],
                                      ),
                                      if (hasActiveFilter) ...[
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            if (state.typeFilter != 'All')
                                              InputChip(
                                                label: Text('Type: ${state.typeFilter}', style: const TextStyle(fontSize: 11)),
                                                onDeleted: () => ref.read(assetsProvider.notifier).setTypeFilter('All'),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                            if (state.statusFilter != 'All')
                                              InputChip(
                                                label: Text('Status: ${state.statusFilter}', style: const TextStyle(fontSize: 11)),
                                                onDeleted: () => ref.read(assetsProvider.notifier).setStatusFilter('All'),
                                                visualDensity: VisualDensity.compact,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(flex: 3, child: searchField),
                                    const SizedBox(width: 16),
                                    Expanded(child: typeField),
                                    const SizedBox(width: 16),
                                    Expanded(child: statusField),
                                  ],
                                );
                              },
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
                                mainAxisExtent: 220,
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
    final adminState = ref.watch(adminProvider);
    final canEdit = adminState.hasPermission(AppModule.assets, PermissionAction.edit);
    final canDelete = adminState.hasPermission(AppModule.assets, PermissionAction.delete);
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
    if (asset.status == 'Under Maintenance') {
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
                  if (canEdit || canDelete)
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
                          if (!canEdit) return;
                          showDialog(
                            context: context,
                            builder: (context) => _EditAssetDialog(asset: asset),
                          );
                        } else if (val == 'delete') {
                          if (!canDelete) return;
                          final messenger = ScaffoldMessenger.of(context);
                          final errorColor = context.error;
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
                        } else if (val == 'maintenance') {
                          if (!canEdit) return;
                          ref.read(assetsProvider.notifier).updateAsset(asset.copyWith(
                                status: 'Under Maintenance',
                              ));
                        } else if (val == 'retire') {
                          if (!canEdit) return;
                          ref.read(assetsProvider.notifier).updateAsset(asset.copyWith(
                                status: 'Retired',
                              ));
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'details',
                          child: Text('View Details', style: TextStyle(color: context.textPrimary, fontSize: 13)),
                        ),
                        if (canEdit) ...[
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
                        ],
                        if (canDelete)
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cost', style: TextStyle(color: context.textMuted, fontSize: 10)),
                        Text(
                          'Rs. ${asset.cost.toStringAsFixed(0)}',
                          style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Condition', style: TextStyle(color: context.textMuted, fontSize: 10)),
                        Text(
                          asset.condition,
                          style: TextStyle(color: conditionColor, fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
                        'Paid from: ${paymentAccount.name} • ${paymentAccount.isPersonal ? "Personal" : "Company"}${paymentAccount.isPersonal && paymentAccount.ownerName.isNotEmpty ? ' (${paymentAccount.ownerName})' : ''}',
                        style: TextStyle(color: context.textMuted, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(),

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
  String _purchaseAssetType = 'Company';
  String _condition = 'None';
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

    final isMobile = MediaQuery.of(context).size.width < 500;

    return Dialog(
      backgroundColor: context.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 480,
        constraints: const BoxConstraints(maxWidth: 480),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: SingleChildScrollView(
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
                if (isMobile) ...[
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
                  const SizedBox(height: 16),
                  _buildLabel(context, 'Serial / License Key (Optional)', isRequired: false),
                  TextFormField(
                    controller: _serialController,
                    style: TextStyle(color: context.textPrimary),
                    decoration: _buildInputDecoration(context, 'e.g. SN-991244 (Optional)'),
                    validator: null,
                  ),
                ] else ...[
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
                              validator: null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Row 3: Purchase Cost & Payment From Bank / Wallet
                if (isMobile) ...[
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
                  const SizedBox(height: 16),
                  _buildLabel(context, 'Payment From Bank / Wallet', isRequired: true),
                  DropdownButtonFormField<String>(
                    value: _selectedAccountId,
                    isExpanded: true,
                    dropdownColor: context.cardBg,
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                    decoration: _buildInputDecoration(context, 'Select account'),
                    items: accounts.map((a) {
                      final scope = a.isPersonal
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
                ] else ...[
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
                                final scope = a.isPersonal
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
                ],
                const SizedBox(height: 16),

                // Asset Condition (Optional)
                _buildLabel(context, 'Asset Condition (Optional)', isRequired: false),
                DropdownButtonFormField<String>(
                  value: _condition,
                  dropdownColor: context.cardBg,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration(context, ''),
                  items: [
                    DropdownMenuItem(value: 'None', child: Text('None')),
                    DropdownMenuItem(value: 'New', child: Text(tr('New'))),
                    DropdownMenuItem(value: 'Good', child: Text('Good')),
                    DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                    DropdownMenuItem(value: 'Damaged', child: Text('Damaged')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _condition = val);
                  },
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
                          purchaseAssetType: _purchaseAssetType,
                          serialNumber: _serialController.text.trim(),
                          purchaseDate: DateTime.now().toIso8601String().substring(0, 10),
                          cost: totalCost,
                          status: 'Available',
                          condition: _condition.isEmpty ? 'None' : _condition,
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
    
    final validConditions = ['None', 'New', 'Good', 'Fair', 'Damaged'];
    _condition = validConditions.contains(widget.asset.condition) ? widget.asset.condition : 'None';

    final validStatuses = ['Available', 'Under Maintenance', 'Retired'];
    _status = validStatuses.contains(widget.asset.status) ? widget.asset.status : 'Available';
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

    final isMobile = MediaQuery.of(context).size.width < 500;

    return Dialog(
      backgroundColor: context.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 480,
        constraints: const BoxConstraints(maxWidth: 480),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: SingleChildScrollView(
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
                if (isMobile) ...[
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
                  const SizedBox(height: 16),
                  _buildLabel(context, 'Serial / License Key (Optional)', isRequired: false),
                  TextFormField(
                    controller: _serialController,
                    style: TextStyle(color: context.textPrimary),
                    decoration: _buildInputDecoration(context, 'e.g. SN-991244 (Optional)'),
                    validator: null,
                  ),
                ] else ...[
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
                              validator: null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Row 3: Cost & Payment Account
                if (isMobile) ...[
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
                  const SizedBox(height: 16),
                  _buildLabel(context, 'Payment From Bank / Wallet', isRequired: true),
                  DropdownButtonFormField<String>(
                    value: _selectedAccountId,
                    isExpanded: true,
                    dropdownColor: context.cardBg,
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                    decoration: _buildInputDecoration(context, 'Select account'),
                    items: accounts.map((a) {
                      final scope = a.isPersonal
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
                ] else ...[
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
                                final scope = a.isPersonal
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
                ],
                const SizedBox(height: 16),

                // Row 4: Condition & Status
                if (isMobile) ...[
                  _buildLabel(context, 'Condition', isRequired: true),
                  DropdownButtonFormField<String>(
                    value: _condition,
                    dropdownColor: context.cardBg,
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                    decoration: _buildInputDecoration(context, ''),
                    items: [
                      DropdownMenuItem(value: 'None', child: Text('None')),
                      DropdownMenuItem(value: 'New', child: Text(tr('New'))),
                      DropdownMenuItem(value: 'Good', child: Text('Good')),
                      DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                      DropdownMenuItem(value: 'Damaged', child: Text('Damaged')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _condition = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLabel(context, tr('Status'), isRequired: true),
                  DropdownButtonFormField<String>(
                    value: _status,
                    dropdownColor: context.cardBg,
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                    decoration: _buildInputDecoration(context, ''),
                    items: [
                      DropdownMenuItem(value: 'Available', child: Text('Available')),
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
                ] else ...[
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
                                DropdownMenuItem(value: 'None', child: Text('None')),
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
                ],
                const SizedBox(height: 24),

                // Dialog Actions
                Consumer(
                  builder: (context, ref, _) {
                    final adminState = ref.watch(adminProvider);
                    final canDelete = adminState.hasPermission(AppModule.assets, PermissionAction.delete);
                    final canEdit = adminState.hasPermission(AppModule.assets, PermissionAction.edit);

                    if (isMobile) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              if (canDelete) ...[
                                Expanded(
                                  child: OutlinedButton.icon(
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
                                    label: Text(tr('Delete'), style: TextStyle(color: context.error, fontSize: 13)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: context.error,
                                      side: BorderSide(color: context.error.withValues(alpha: 0.4)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                                ),
                              ),
                            ],
                          ),
                          if (canEdit) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
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
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(tr('Save Changes')),
                              ),
                            ),
                          ],
                        ],
                      );
                    } else {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (canDelete)
                            TextButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final errorColor = context.error;
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
                              },
                              icon: Icon(Icons.delete_outline, size: 16, color: context.error),
                              label: Text(tr('Delete Asset'), style: TextStyle(color: context.error, fontSize: 13)),
                            )
                          else
                            const SizedBox.shrink(),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                              ),
                              if (canEdit) ...[
                                const SizedBox(width: 12),
                                ElevatedButton(
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
                                ),
                              ],
                            ],
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
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



class _AssetDetailsDialog extends ConsumerWidget {
  final Asset asset;

  const _AssetDetailsDialog({required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveAsset = ref.watch(assetsProvider).assets.where((a) => a.id == asset.id).firstOrNull ?? asset;
    final theme = Theme.of(context);
    final adminState = ref.watch(adminProvider);
    final canEdit = adminState.hasPermission(AppModule.assets, PermissionAction.edit);
    final canDelete = adminState.hasPermission(AppModule.assets, PermissionAction.delete);

    // Status colors
    Color statusColor = context.info;
    Color statusBg = context.infoLight;
    if (liveAsset.status == 'Under Maintenance') {
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

    final isMobile = MediaQuery.of(context).size.width < 550;

    return Dialog(
      backgroundColor: context.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 540,
        constraints: const BoxConstraints(maxWidth: 540),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: SingleChildScrollView(
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
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
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
                  const SizedBox(width: 8),
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
              const SizedBox(height: 8),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAssetInfoTile(
                      context,
                      label: 'Serial Number',
                      value: liveAsset.serialNumber.isNotEmpty ? liveAsset.serialNumber : 'None / N/A',
                      icon: Icons.qr_code_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Actions Row
              if (isMobile) ...[
                Row(
                  children: [
                    if (canDelete) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleDelete(context, ref, liveAsset),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.error,
                            side: BorderSide(color: context.error.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (canEdit) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => _EditAssetDialog(asset: liveAsset),
                            );
                          },
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit Details'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (canDelete)
                      OutlinedButton.icon(
                        onPressed: () => _handleDelete(context, ref, liveAsset),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.error,
                          side: BorderSide(color: context.error.withValues(alpha: 0.4)),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: [
                        if (canEdit) ...[
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
                        ],
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Asset liveAsset) async {
    if (!ref.read(adminProvider).hasPermission(AppModule.assets, PermissionAction.delete)) return;
    await ref.read(assetsProvider.notifier).deleteAsset(liveAsset.id);
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Asset "${liveAsset.name}" deleted.'), backgroundColor: context.error),
      );
    }
  }

  Widget _buildAssetInfoTile(BuildContext context, {required String label, required String value, required IconData icon, Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: context.scaffoldBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(color: context.textMuted, fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: valueColor ?? context.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
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
