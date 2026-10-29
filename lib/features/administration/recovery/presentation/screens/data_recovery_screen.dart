import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/features/administration/recovery/data/models/recycle_bin_item.dart';
import 'package:software_house_erp/features/administration/recovery/presentation/providers/recovery_provider.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/features/administration/shared/widgets/admin_sub_nav.dart';

class DataRecoveryScreen extends ConsumerStatefulWidget {
  const DataRecoveryScreen({super.key});

  @override
  ConsumerState<DataRecoveryScreen> createState() => _DataRecoveryScreenState();
}

class _DataRecoveryScreenState extends ConsumerState<DataRecoveryScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Account',
    'LedgerEntry',
    'Employee',
    'Client',
    'Invoice',
    'Expense',
    'Income',
    'Project',
    'Task',
    'Product',
    'Asset',
    'Loan',
  ];

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final isSuperAdmin = adminState.currentUser?.isSuperAdmin == true ||
        adminState.currentUser?.role.trim().toLowerCase() == 'super admin' ||
        adminState.currentUser?.role.trim().toLowerCase() == 'system admin';

    if (!isSuperAdmin) {
      return Scaffold(
        backgroundColor: context.scaffoldBg,
        body: SafeArea(
          child: Column(
            children: [
              const AdminSubNav(activeRoute: '/administration/recovery'),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Access Restricted',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Data Recovery & Recycle Bin is restricted to Super Admin only.',
                        style: TextStyle(color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = ref.watch(recoveryProvider);
    final filteredItems = items.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item.itemType == _selectedCategory;
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query) ||
          item.deletedBy.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();

    filteredItems.sort((a, b) {
      final dtA = DateTime.tryParse(a.deletedAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dtB = DateTime.tryParse(b.deletedAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dtB.compareTo(dtA);
    });

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            const AdminSubNav(activeRoute: '/administration/recovery'),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final double horizontalPadding = isMobile ? 12.0 : 20.0;

                  return Padding(
                    padding: EdgeInsets.all(horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header Section ──
                        if (isMobile) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: context.primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.restore_from_trash_outlined,
                                  color: context.primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Data Recovery & Recycle Bin',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: context.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Restore accidentally deleted records',
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
                            ],
                          ),
                          if (items.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _confirmClearAll(context),
                                icon: const Icon(Icons.delete_forever, size: 18),
                                label: const Text('Empty Recycle Bin'),
                              ),
                            ),
                          ],
                        ] else ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: context.primaryColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.restore_from_trash_outlined,
                                        color: context.primaryColor,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Data Recovery & Recycle Bin',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            'Restore accidentally deleted records back into active system',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: context.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (items.isNotEmpty)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _confirmClearAll(context),
                                  icon: const Icon(Icons.delete_forever, size: 18),
                                  label: const Text('Empty Recycle Bin'),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),

                        // ── Filter & Search Controls ──
                        if (isMobile) ...[
                          Column(
                            children: [
                              TextField(
                                onChanged: (val) => setState(() => _searchQuery = val),
                                decoration: InputDecoration(
                                  hintText: 'Search deleted records...',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  filled: true,
                                  fillColor: context.cardBg,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: context.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: context.border),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: context.cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: context.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCategory,
                                    isExpanded: true,
                                    dropdownColor: context.cardBg,
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedCategory = val);
                                    },
                                    items: _categories
                                        .map((cat) => DropdownMenuItem(
                                              value: cat,
                                              child: Text(cat == 'All' ? 'All Types (${items.length})' : cat),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              // Search box
                              Expanded(
                                child: TextField(
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                  decoration: InputDecoration(
                                    hintText: 'Search deleted records...',
                                    prefixIcon: const Icon(Icons.search, size: 20),
                                    filled: true,
                                    fillColor: context.cardBg,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: context.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: context.border),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Category Dropdown
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: context.cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: context.border),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCategory,
                                    dropdownColor: context.cardBg,
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedCategory = val);
                                    },
                                    items: _categories
                                        .map((cat) => DropdownMenuItem(
                                              value: cat,
                                              child: Text(cat == 'All' ? 'All Types (${items.length})' : cat),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),

                        // ── Items List / Empty State ──
                        Expanded(
                          child: filteredItems.isEmpty
                              ? Center(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.cleaning_services_outlined,
                                          size: 64,
                                          color: context.textSecondary.withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Recycle Bin is Empty',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Deleted items will appear here and can be restored anytime.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: context.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: filteredItems.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                                  itemBuilder: (ctx, idx) {
                                    final item = filteredItems[idx];
                                    return _buildRecycleItemCard(ctx, item, isMobile);
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecycleItemCard(BuildContext context, RecycleBinItem item, bool isMobile) {
    IconData icon;
    Color iconColor;

    switch (item.itemType) {
      case 'Account':
        icon = Icons.account_balance_wallet_outlined;
        iconColor = Colors.teal;
        break;
      case 'LedgerEntry':
        icon = Icons.menu_book_outlined;
        iconColor = Colors.blueGrey;
        break;
      case 'Employee':
        icon = Icons.badge_outlined;
        iconColor = Colors.blue;
        break;
      case 'Client':
        icon = Icons.business_outlined;
        iconColor = Colors.purple;
        break;
      case 'Invoice':
        icon = Icons.receipt_long_outlined;
        iconColor = Colors.green;
        break;
      case 'Expense':
        icon = Icons.shopping_bag_outlined;
        iconColor = Colors.red;
        break;
      case 'Income':
        icon = Icons.attach_money;
        iconColor = Colors.teal;
        break;
      case 'Project':
        icon = Icons.folder_special_outlined;
        iconColor = Colors.amber.shade800;
        break;
      case 'Task':
        icon = Icons.task_alt;
        iconColor = Colors.orange;
        break;
      case 'Product':
        icon = Icons.inventory_2_outlined;
        iconColor = Colors.indigo;
        break;
      case 'Asset':
        icon = Icons.devices_outlined;
        iconColor = Colors.cyan;
        break;
      default:
        icon = Icons.delete_outline;
        iconColor = Colors.grey;
    }

    String formattedDate = item.deletedAt;
    try {
      final dt = DateTime.parse(item.deletedAt);
      formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {}

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.itemType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: iconColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Deleted by ${item.deletedBy}',
                              style: TextStyle(fontSize: 10, color: context.textSecondary),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          style: TextStyle(fontSize: 11, color: context.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 10, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: context.border.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _restoreItem(item),
                  icon: const Icon(Icons.settings_backup_restore, size: 14),
                  label: const Text('Restore', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _confirmPermanentDelete(item),
                  icon: const Icon(Icons.delete_forever, size: 14, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.itemType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Deleted by ${item.deletedBy} • $formattedDate',
                        style: TextStyle(fontSize: 11, color: context.textSecondary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action Buttons: Restore & Permanent Delete
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _restoreItem(item),
                icon: const Icon(Icons.settings_backup_restore, size: 16),
                label: const Text('Restore'),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Permanently Delete',
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed: () => _confirmPermanentDelete(item),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _restoreItem(RecycleBinItem item) async {
    final success = await ref.read(recoveryProvider.notifier).restoreItem(item);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (success) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text('${item.itemType} "${item.title}" successfully restored!'),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to restore item. Please try again.'),
        ),
      );
    }
  }

  void _confirmPermanentDelete(RecycleBinItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanent Delete?'),
        content: Text('Are you sure you want to permanently delete "${item.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(recoveryProvider.notifier).permanentlyDeleteItem(item);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.grey.shade800,
                  content: Text('${item.title} permanently deleted.'),
                ),
              );
            },
            child: const Text('Permanently Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Recycle Bin?'),
        content: const Text('All deleted records will be permanently purged. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(recoveryProvider.notifier).clearAll();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.grey,
                  content: Text('Recycle bin cleared.'),
                ),
              );
            },
            child: const Text('Empty All'),
          ),
        ],
      ),
    );
  }
}
