import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/inventory/shared/widgets/inventory_sub_nav.dart';
import 'package:software_house_erp/core/widgets/export_button.dart';
import '../providers/inventory_provider.dart';
import '../../../../finance/accounts/presentation/providers/accounts_provider.dart';
import '../../../../finance/expenses/domain/entities/expense_record.dart';
import '../../../../finance/expenses/presentation/providers/expenses_provider.dart';
import '../../domain/entities/inventory_item.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(inventoryProvider);
    final theme = Theme.of(context);

    // Calculate metrics
    final totalItems = state.items.length;
    final lowStockItems = state.items.where((i) => i.quantity <= i.minQuantity && i.quantity > 0).length;
    final outOfStockItems = state.items.where((i) => i.quantity == 0).length;
    final totalValue = state.items.fold<double>(0, (sum, item) => sum + (item.quantity * item.pricePerUnit));

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Sub Navigation Tab
                const InventorySubNav(activeRoute: '/inventory/list'),
                
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
                                  'Office Inventory & Supplies',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Manage company consumables, stationery, kitchen pantry, and merchandise.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                ExportButton(
                                  title: tr('Office Inventory Report'),
                                  fileName: 'office_inventory_report',
                                  headers: [
                                    'Item ID',
                                    'Item Name',
                                    tr('Category'),
                                    tr('Quantity'),
                                    'Min Alert Qty',
                                    'Unit Cost',
                                    'Total Value',
                                    'Last Restocked',
                                  ],
                                  rows: state.filteredItems.map((item) => [
                                    item.id,
                                    item.name,
                                    item.category,
                                    '${item.quantity} ${item.unit}',
                                    '${item.minQuantity} ${item.unit}',
                                    'Rs. ${item.pricePerUnit.toStringAsFixed(0)}',
                                    'Rs. ${(item.quantity * item.pricePerUnit).toStringAsFixed(0)}',
                                    item.lastRestockedDate,
                                  ]).toList(),
                                ),
                                const SizedBox(width: 12),

                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final successColor = context.success;
                                    final result = await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      builder: (context) => const _AddInventoryDialog(),
                                    );
                                    if (result != null) {
                                      final item = result['item'] as InventoryItem;
                                      final accountId = result['accountId'] as String;
                                      final totalCost = (result['totalCost'] as num).toDouble();

                                      await ref.read(inventoryProvider.notifier).addInventoryItem(item);
                                      await ref.read(expensesProvider.notifier).addExpense(
                                        ExpenseRecord(
                                          id: 'INV-EXP-${item.id}',
                                          date: DateTime.now().toIso8601String(),
                                          amount: totalCost,
                                          accountId: accountId,
                                          category: ExpenseRecord.inventoryCategory(),
                                          vendorName: 'Inventory Purchase',
                                          description: 'Inventory purchase - ${item.name}',
                                        ),
                                      );

                                      if (!context.mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('${tr("Item")} "${item.name}" ${tr("added successfully.")}'),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: successColor,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add Item'),
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

                        // Stats Cards
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: tr('Total Items'),
                                tooltipMessage: "Detailed statistics and information regarding ${tr('Total Items')}.",
                                value: '$totalItems',
                                icon: Icons.inventory_2_outlined,
                                iconColor: context.primaryColor,
                                iconBgColor: context.infoLight,
                                trendText: tr('Tracked supplies'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StatCard(
                                title: 'Low Stock',
                                tooltipMessage: 'Detailed statistics and information regarding Low Stock.',
                                value: '$lowStockItems',
                                icon: Icons.warning_amber_outlined,
                                iconColor: context.warning,
                                iconBgColor: context.warningLight,
                                trendText: tr('Needs restocking'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StatCard(
                                title: 'Out of Stock',
                                tooltipMessage: 'Detailed statistics and information regarding Out of Stock.',
                                value: '$outOfStockItems',
                                icon: Icons.error_outline,
                                iconColor: context.error,
                                iconBgColor: context.errorLight,
                                trendText: tr('Immediate order required'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StatCard(
                                title: 'Total Value',
                                tooltipMessage: 'Detailed statistics and information regarding Total Value.',
                                value: 'Rs. ${(totalValue / 1000).toStringAsFixed(1)}k',
                                icon: Icons.monetization_on_outlined,
                                iconColor: context.success,
                                iconBgColor: context.successLight,
                                trendText: tr('Current asset value'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Filter Bar
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Search bar
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    onChanged: (val) => ref.read(inventoryProvider.notifier).setSearchQuery(val),
                                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: tr('Search by item name or category...'),
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

                                // Category Filter
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: state.categoryFilter,
                                    dropdownColor: context.cardBg,
                                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                                    decoration: InputDecoration(
                                      labelText: tr('Category'),
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
                                      DropdownMenuItem(value: 'All', child: Text('All Categories')),
                                      DropdownMenuItem(value: 'Stationery', child: Text('Stationery')),
                                      DropdownMenuItem(value: 'Pantry', child: Text(tr('Pantry'))),
                                      DropdownMenuItem(value: 'Merchandise', child: Text('Merchandise')),
                                      DropdownMenuItem(value: 'Office Supplies', child: Text('Office Supplies')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        ref.read(inventoryProvider.notifier).setCategoryFilter(val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Inventory Grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            int crossAxisCount = width >= 1200 ? 3 : (width >= 800 ? 2 : 1);
                            
                            if (state.filteredItems.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: Text(
                                    'No inventory items found matching the criteria.',
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
                              itemCount: state.filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = state.filteredItems[index];
                                return _InventoryCard(item: item);
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

class _InventoryCard extends ConsumerWidget {
  final InventoryItem item;

  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);

    // Stock Status
    String statusText = 'In Stock';
    Color statusColor = context.success;
    Color statusBg = context.successLight;
    
    if (item.quantity == 0) {
      statusText = 'Out of Stock';
      statusColor = context.error;
      statusBg = context.errorLight;
    } else if (item.quantity <= item.minQuantity) {
      statusText = 'Low Stock';
      statusColor = context.warning;
      statusBg = context.warningLight;
    }

    // Category Icon
    IconData categoryIcon = Icons.inventory;
    if (item.category == 'Stationery') {
      categoryIcon = Icons.edit_note;
    } else if (item.category == 'Pantry') {
      categoryIcon = Icons.local_cafe_outlined;
    } else if (item.category == 'Merchandise') {
      categoryIcon = Icons.checkroom_outlined;
    } else if (item.category == 'Office Supplies') {
      categoryIcon = Icons.clean_hands_outlined;
    }

    final totalValuation = item.quantity * item.pricePerUnit;

    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => _EditInventoryDialog(item: item),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category Icon + Item Name & Category Label + Action Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(categoryIcon, color: context.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
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
                          '${item.category} • Min Alert: ${item.minQuantity} ${item.unit}',
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
                      if (val == 'edit') {
                        showDialog(
                          context: context,
                          builder: (context) => _EditInventoryDialog(item: item),
                        );
                      } else if (val == 'delete') {
                        final messenger = ScaffoldMessenger.of(context);
                        final errorColor = context.error;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(tr('Delete Item')),
                            content: Text('${tr("Are you sure you want to delete")} "${item.name}" ${tr("from inventory?")}'),
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
                            await ref.read(inventoryProvider.notifier).deleteInventoryItem(item.id);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('${tr("Item")} "${item.name}" ${tr("deleted.")}'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: errorColor,
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete item: $e'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: errorColor,
                              ),
                            );
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Item', style: TextStyle(color: context.textPrimary, fontSize: 13)),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(tr('Delete Item'), style: TextStyle(color: context.error, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Details Grid: Unit Cost, Stock Level, Total Value & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unit Price', style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        'Rs. ${item.pricePerUnit.toStringAsFixed(0)}',
                        style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stock Level', style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        '${item.quantity} ${item.unit}',
                        style: TextStyle(
                          color: item.quantity == 0 ? context.error : context.textPrimary, 
                          fontSize: 13, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Value', style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        'Rs. ${totalValuation.toStringAsFixed(0)}',
                        style: TextStyle(color: context.primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (item.lastRestockedDate.isNotEmpty)
                    Text(
                      'Restocked: ${item.lastRestockedDate.split("T").first}',
                      style: TextStyle(color: context.textMuted, fontSize: 11),
                    ),
                ],
              ),

              const Spacer(),

              // Actions: Restock and Consume Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => _AdjustStockDialog(item: item, isRestock: true),
                        );
                      },
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Restock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        foregroundColor: context.success,
                        side: BorderSide(color: context.success.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: item.quantity == 0
                          ? null
                          : () {
                              showDialog(
                                context: context,
                                builder: (context) => _AdjustStockDialog(item: item, isRestock: false),
                              );
                            },
                      icon: const Icon(Icons.remove, size: 14),
                      label: const Text('Consume', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        foregroundColor: context.error,
                        side: BorderSide(color: context.error.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddInventoryDialog extends ConsumerStatefulWidget {
  const _AddInventoryDialog();

  @override
  ConsumerState<_AddInventoryDialog> createState() => _AddInventoryDialogState();
}

class _AddInventoryDialogState extends ConsumerState<_AddInventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _fullCostController = TextEditingController();
  String _category = 'Office Supplies';
  String _inventoryType = 'Company';
  String? _selectedAccountId;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _unitController.dispose();
    _fullCostController.dispose();
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
                    'Add Inventory Item',
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

              // Row 1: Item Name
              _buildLabel(context, 'Item Name', isRequired: true),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: context.textPrimary),
                decoration: _buildInputDecoration(context, 'e.g. A4 Paper Rims, Coffee Beans'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter item name' : null,
              ),
              const SizedBox(height: 16),

              // Row 2: Category & Full Cost
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, tr('Category'), isRequired: true),
                        DropdownButtonFormField<String>(
                          value: _category,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13),
                          decoration: _buildInputDecoration(context, ''),
                          items: [
                            DropdownMenuItem(value: 'Stationery', child: Text('Stationery')),
                            DropdownMenuItem(value: 'Pantry', child: Text(tr('Pantry'))),
                            DropdownMenuItem(value: 'Merchandise', child: Text('Merchandise')),
                            DropdownMenuItem(value: 'Office Supplies', child: Text('Office Supplies')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _category = val);
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
                        _buildLabel(context, 'Full Cost (Rs.)', isRequired: true),
                        TextFormField(
                          controller: _fullCostController,
                          style: TextStyle(color: context.textPrimary),
                          keyboardType: TextInputType.number,
                          decoration: _buildInputDecoration(context, 'e.g. 5000'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter full cost';
                            if (double.tryParse(val) == null) return 'Enter valid number';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 4: Payment Account
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
              const SizedBox(height: 16),

              // Row 5: Initial Stock & Min Alert Qty
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, 'Initial Stock', isRequired: true),
                        TextFormField(
                          controller: _quantityController,
                          style: TextStyle(color: context.textPrimary),
                          keyboardType: TextInputType.number,
                          decoration: _buildInputDecoration(context, '0'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter quantity';
                            if (int.tryParse(val) == null) return 'Enter valid integer';
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
                        _buildLabel(context, 'Min Alert Qty', isRequired: true),
                        TextFormField(
                          controller: _minQuantityController,
                          style: TextStyle(color: context.textPrimary),
                          keyboardType: TextInputType.number,
                          decoration: _buildInputDecoration(context, '5'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter alert level';
                            if (int.tryParse(val) == null) return 'Enter valid integer';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
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
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final selectedAccount = accounts.firstWhere(
                          (a) => a.id == _selectedAccountId,
                          orElse: () => accounts.first,
                        );
                        final quantity = int.parse(_quantityController.text);
                        final fullCost = double.parse(_fullCostController.text);
                        final unitCost = quantity > 0 ? (fullCost / quantity) : fullCost;
                        final totalCost = fullCost;

                        if (selectedAccount.balance < totalCost) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Note: Account balance is lower than total inventory cost of Rs. ${totalCost.toStringAsFixed(2)}'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.orange.shade800,
                            ),
                          );
                        }

                        final newItem = InventoryItem(
                          id: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                          name: _nameController.text.trim(),
                          category: _category,
                          inventoryType: _inventoryType,
                          quantity: quantity,
                          minQuantity: int.parse(_minQuantityController.text),
                          unit: _unitController.text.trim().isNotEmpty ? _unitController.text.trim() : 'Units',
                          pricePerUnit: unitCost,
                          lastRestockedDate: DateTime.now().toIso8601String().substring(0, 10),
                        );

                        Navigator.pop(context, {
                          'item': newItem,
                          'accountId': selectedAccount.id,
                          'totalCost': totalCost,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Item'),
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

class _EditInventoryDialog extends ConsumerStatefulWidget {
  final InventoryItem item;
  const _EditInventoryDialog({required this.item});

  @override
  ConsumerState<_EditInventoryDialog> createState() => _EditInventoryDialogState();
}

class _EditInventoryDialogState extends ConsumerState<_EditInventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _minQuantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _priceController;
  late String _category;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _minQuantityController = TextEditingController(text: widget.item.minQuantity.toString());
    _unitController = TextEditingController(text: widget.item.unit);
    _priceController = TextEditingController(text: widget.item.pricePerUnit.toStringAsFixed(0));
    _category = widget.item.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minQuantityController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final accounts = ref.watch(accountsProvider).accounts.where((a) => a.status == 'Active').toList();
    final linkedExpense = ref.watch(expensesProvider).expenses.where((e) => e.id == 'INV-EXP-${widget.item.id}').firstOrNull;

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
                    'Edit Stock Item',
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

              // Row 1: Item Name
              _buildLabel(context, 'Item Name', isRequired: true),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: context.textPrimary),
                decoration: _buildInputDecoration(context, 'Item name'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter item name' : null,
              ),
              const SizedBox(height: 16),

              // Row 2: Category & Unit Cost
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, tr('Category'), isRequired: true),
                        DropdownButtonFormField<String>(
                          value: _category,
                          dropdownColor: context.cardBg,
                          style: TextStyle(color: context.textPrimary, fontSize: 13),
                          decoration: _buildInputDecoration(context, ''),
                          items: [
                            DropdownMenuItem(value: 'Stationery', child: Text('Stationery')),
                            DropdownMenuItem(value: 'Pantry', child: Text(tr('Pantry'))),
                            DropdownMenuItem(value: 'Merchandise', child: Text('Merchandise')),
                            DropdownMenuItem(value: 'Office Supplies', child: Text('Office Supplies')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _category = val);
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
                        _buildLabel(context, 'Unit Cost (Rs.)', isRequired: true),
                        TextFormField(
                          controller: _priceController,
                          style: TextStyle(color: context.textPrimary),
                          keyboardType: TextInputType.number,
                          decoration: _buildInputDecoration(context, '350'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter cost';
                            if (double.tryParse(val) == null) return 'Enter valid number';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 3: Payment Account & Min Alert Qty
              Row(
                children: [
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
                          items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedAccountId = val);
                          },
                          validator: (val) => val == null || val.isEmpty ? 'Select payment account' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(context, 'Min Alert Qty', isRequired: true),
                        TextFormField(
                          controller: _minQuantityController,
                          style: TextStyle(color: context.textPrimary),
                          keyboardType: TextInputType.number,
                          decoration: _buildInputDecoration(context, '5'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter alert level';
                            if (int.tryParse(val) == null) return 'Enter valid integer';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Actions
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
                            title: Text(tr('Delete Item')),
                            content: Text('${tr("Are you sure you want to delete")} "${widget.item.name}"? ${tr("This action cannot be undone.")}'),
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
                            await ref.read(inventoryProvider.notifier).deleteInventoryItem(widget.item.id);
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('${tr("Item")} "${widget.item.name}" ${tr("deleted.")}'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: errorColor,
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete item: $e'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: errorColor,
                              ),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.delete_outline, size: 16, color: context.error),
                      label: Text(tr('Delete Item'), style: TextStyle(color: context.error, fontSize: 13)),
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
                                final updatedItem = widget.item.copyWith(
                                  name: _nameController.text.trim(),
                                  category: _category,
                                  minQuantity: int.parse(_minQuantityController.text),
                                  unit: widget.item.unit,
                                  pricePerUnit: double.parse(_priceController.text),
                                );

                                final linkedExpense = ref.read(expensesProvider).expenses.where((e) => e.id == 'INV-EXP-${widget.item.id}').firstOrNull;
                                final updatedCost = widget.item.quantity * updatedItem.pricePerUnit;
                                final updatedExpense = ExpenseRecord(
                                  id: 'INV-EXP-${widget.item.id}',
                                  date: linkedExpense?.date ?? DateTime.now().toIso8601String(),
                                  amount: updatedCost,
                                  accountId: selectedAccount.id,
                                  category: ExpenseRecord.inventoryCategory(),
                                  vendorName: 'Inventory Purchase',
                                  description: 'Inventory purchase - ${updatedItem.name}',
                                );

                                if (linkedExpense != null) {
                                  await ref.read(expensesProvider.notifier).updateExpense(linkedExpense, updatedExpense);
                                } else {
                                  await ref.read(expensesProvider.notifier).addExpense(updatedExpense);
                                }

                                await ref.read(inventoryProvider.notifier).updateInventoryItem(updatedItem);
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(tr('Item updated successfully.')),
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

class _AdjustStockDialog extends ConsumerStatefulWidget {
  final InventoryItem item;
  final bool isRestock; // true if adding, false if consuming

  const _AdjustStockDialog({required this.item, required this.isRestock});

  @override
  ConsumerState<_AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends ConsumerState<_AdjustStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _adjustController = TextEditingController();

  @override
  void dispose() {
    _adjustController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final title = widget.isRestock ? 'Restock Item' : 'Consume Item';
    final actionLabel = widget.isRestock ? 'Add to Stock' : 'Deduct from Stock';

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: context.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Current quantity: ${widget.item.quantity} ${widget.item.unit}',
                style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              _buildLabel(context, widget.isRestock ? 'Quantity to Add' : 'Quantity to Consume'),
              TextFormField(
                controller: _adjustController,
                style: TextStyle(color: context.textPrimary),
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration(context, 'e.g. 5'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Enter quantity';
                  final qty = int.tryParse(val);
                  if (qty == null || qty <= 0) return 'Enter positive integer';
                  if (!widget.isRestock && qty > widget.item.quantity) {
                    return 'Cannot consume more than current stock';
                  }
                  return null;
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
                  Consumer(
                    builder: (context, ref, child) {
                      return ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final adjustment = int.parse(_adjustController.text);
                            final finalQty = widget.isRestock
                                ? widget.item.quantity + adjustment
                                : widget.item.quantity - adjustment;
                            
                            final updatedItem = widget.item.copyWith(
                              quantity: finalQty,
                              lastRestockedDate: widget.isRestock
                                  ? DateTime.now().toIso8601String().substring(0, 10)
                                  : widget.item.lastRestockedDate,
                            );

                            ref.read(inventoryProvider.notifier).updateInventoryItem(updatedItem);

                            if (widget.isRestock) {
                              final restockCost = adjustment * widget.item.pricePerUnit;
                              if (restockCost > 0) {
                                final accounts = ref.read(accountsProvider).accounts;
                                final linkedExpense = ref.read(expensesProvider).expenses.where((e) => e.id == 'INV-EXP-${widget.item.id}').firstOrNull;
                                final accountId = linkedExpense?.accountId ?? (accounts.isNotEmpty ? accounts.first.id : '');
                                ref.read(expensesProvider.notifier).addExpense(
                                  ExpenseRecord(
                                    id: 'INV-RESTOCK-${widget.item.id}-${DateTime.now().millisecondsSinceEpoch}',
                                    date: DateTime.now().toIso8601String(),
                                    amount: restockCost,
                                    accountId: accountId,
                                    category: ExpenseRecord.inventoryCategory(),
                                    vendorName: 'Inventory Restock',
                                    description: 'Inventory restock - ${widget.item.name} (+$adjustment ${widget.item.unit})',
                                  ),
                                );
                              }
                            }

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Stock adjusted successfully.'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: context.success,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.isRestock ? context.success : context.error,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(actionLabel),
                      );
                    },
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
