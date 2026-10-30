import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/core/utils/app_date_formatter.dart';
import 'package:software_house_erp/core/utils/currency_formatter.dart';
import 'package:software_house_erp/features/sales/shared/widgets/sales_sub_nav.dart';
import '../providers/purchase_orders_provider.dart';
import '../../domain/entities/purchase_order.dart';

class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';

  final List<String> _vendors = [
    'CloudHost Inc',
    'SoftLicence Distributors',
    'Hameed Hardware Store',
    'PakTelecom Services',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return CurrencyFormatter.formatCurrency(amount);
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'Received':
        return context.success;
      case 'Ordered':
        return context.info;
      case 'Pending':
        return context.warning;
      case 'Cancelled':
        return context.error;
      default:
        return context.textSecondary;
    }
  }

  Color _getStatusBg(BuildContext context, String status) {
    switch (status) {
      case 'Received':
        return context.successLight;
      case 'Ordered':
        return context.infoLight;
      case 'Pending':
        return context.warningLight;
      case 'Cancelled':
        return context.errorLight;
      default:
        return context.scaffoldBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(purchaseOrdersProvider);
    final theme = Theme.of(context);

    // Calculate metrics
    double totalBilled = 0;
    double totalReceived = 0;
    double totalPending = 0;

    for (final po in state.orders) {
      totalBilled += po.total;
      if (po.status == 'Received') {
        totalReceived += po.total;
      } else if (po.status != 'Cancelled') {
        totalPending += po.total;
      }
    }

    // Filter purchase orders
    final query = _searchController.text.trim().toLowerCase();
    final filteredOrders = state.orders.where((po) {
      final matchesSearch = po.id.toLowerCase().contains(query) ||
          po.vendorName.toLowerCase().contains(query);
      final matchesStatus = _selectedStatus == 'All' || po.status == _selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: state.isLoading && state.orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Sub Navigation ───────────────────────
                const SalesSubNav(activeRoute: '/sales/purchases'),

                // ── Main Body ────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Create Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vendor Purchase Orders',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Procure hosting, licenses, and office assets and track delivery status.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await showDialog<PurchaseOrder>(
                                  context: context,
                                  builder: (context) => _AddEditPurchaseOrderDialog(vendors: _vendors),
                                );
                                if (result != null) {
                                  ref.read(purchaseOrdersProvider.notifier).addOrder(result);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${tr("Purchase Order")} "${result.id}" ${tr("created successfully.")}'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: context.success,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Create Purchase Order'),
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

                        // Stats Summary Grid
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 700) {
                              return Column(
                                children: [
                                  StatCard(
                                    title: 'Total Procured',
                                    tooltipMessage: 'Detailed statistics and information regarding Total Procured.',
                                    value: _formatCurrency(totalBilled),
                                    icon: Icons.inventory_outlined,
                                    iconColor: context.primaryColor,
                                    iconBgColor: context.infoLight,
                                    trendText: tr('Accumulated spending'),
                                  ),
                                  const SizedBox(height: 12),
                                  StatCard(
                                    title: tr('Asset Received'),
                                    tooltipMessage: "Detailed statistics and information regarding ${tr('Asset Received')}.",
                                    value: _formatCurrency(totalReceived),
                                    icon: Icons.assignment_turned_in,
                                    iconColor: context.success,
                                    iconBgColor: context.successLight,
                                    trendText: tr('Delivered materials'),
                                  ),
                                  const SizedBox(height: 12),
                                  StatCard(
                                    title: 'Pending Delivery',
                                    tooltipMessage: 'Detailed statistics and information regarding Pending Delivery.',
                                    value: _formatCurrency(totalPending),
                                    icon: Icons.local_shipping_outlined,
                                    iconColor: context.warning,
                                    iconBgColor: context.warningLight,
                                    trendText: tr('Awaiting items'),
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: StatCard(
                                    title: 'Total Procured',
                                    tooltipMessage: 'Detailed statistics and information regarding Total Procured.',
                                    value: _formatCurrency(totalBilled),
                                    icon: Icons.inventory_outlined,
                                    iconColor: context.primaryColor,
                                    iconBgColor: context.infoLight,
                                    trendText: tr('Accumulated spending'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: StatCard(
                                    title: tr('Asset Received'),
                                    tooltipMessage: "Detailed statistics and information regarding ${tr('Asset Received')}.",
                                    value: _formatCurrency(totalReceived),
                                    icon: Icons.assignment_turned_in,
                                    iconColor: context.success,
                                    iconBgColor: context.successLight,
                                    trendText: tr('Delivered materials'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: StatCard(
                                    title: 'Pending Delivery',
                                    tooltipMessage: 'Detailed statistics and information regarding Pending Delivery.',
                                    value: _formatCurrency(totalPending),
                                    icon: Icons.local_shipping_outlined,
                                    iconColor: context.warning,
                                    iconBgColor: context.warningLight,
                                    trendText: tr('Awaiting items'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Filters and search
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: tr('Search by order number or vendor name...'),
                                      prefixIcon: const Icon(Icons.search, size: 20),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: context.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: context.border),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                      fillColor: context.scaffoldBg,
                                      filled: true,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedStatus,
                                    decoration: InputDecoration(
                                      labelText: tr('Filter Status'),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: context.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: context.border),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                      fillColor: context.scaffoldBg,
                                      filled: true,
                                    ),
                                    dropdownColor: context.cardBg,
                                    items: [
                                      DropdownMenuItem(value: 'All', child: Text(tr('All Statuses'))),
                                      DropdownMenuItem(value: 'Ordered', child: Text('Ordered')),
                                      DropdownMenuItem(value: 'Received', child: Text(tr('Received'))),
                                      DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                      DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedStatus = val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Ledger Table
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Procurement Ledger',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),
                                filteredOrders.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(40.0),
                                          child: Text(
                                            'No purchase orders found.',
                                            style: TextStyle(color: context.textSecondary),
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: filteredOrders.length,
                                        separatorBuilder: (context, index) => const Divider(),
                                        itemBuilder: (context, index) {
                                          final order = filteredOrders[index];
                                          return _OrderRow(
                                            order: order,
                                            statusColor: _getStatusColor(context, order.status),
                                            statusBg: _getStatusBg(context, order.status),
                                            onEdit: () async {
                                              final result = await showDialog<PurchaseOrder>(
                                                context: context,
                                                builder: (context) => _AddEditPurchaseOrderDialog(
                                                  order: order,
                                                  vendors: _vendors,
                                                ),
                                              );
                                              if (result != null) {
                                                ref.read(purchaseOrdersProvider.notifier).updateOrder(result);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('${tr("Purchase Order")} "${result.id}" ${tr("updated.")}'),
                                                    behavior: SnackBarBehavior.floating,
                                                    backgroundColor: context.success,
                                                  ),
                                                );
                                              }
                                            },
                                            onDelete: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: Text(tr('Delete Purchase Order')),
                                                  content: Text('${tr("Delete")} "${order.id}"? ${tr("This cannot be undone.")}'),
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
                                                ref.read(purchaseOrdersProvider.notifier).deleteOrder(order.id);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('${tr("Purchase Order")} "${order.id}" ${tr("deleted.")}'),
                                                    behavior: SnackBarBehavior.floating,
                                                    backgroundColor: context.error,
                                                  ),
                                                );
                                              }
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
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────
//  Order Row Widget
// ─────────────────────────────────────────────
class _OrderRow extends ConsumerWidget {
  final PurchaseOrder order;
  final Color statusColor;
  final Color statusBg;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OrderRow({
    required this.order,
    required this.statusColor,
    required this.statusBg,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Icon & order number
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.infoLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.shopping_bag_outlined, color: context.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),

          // Code & vendor info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.id,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  order.vendorName,
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          // Dates
          if (width >= 800)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ordered: ${AppDateFormatter.formatString(order.date)}',
                    style: TextStyle(color: context.textSecondary, fontSize: 11),
                  ),
                  Text(
                    'Delivery: ${AppDateFormatter.formatString(order.deliveryDate)}',
                    style: TextStyle(color: context.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),

          // Total PKR
          Expanded(
            flex: 1,
            child: Text(
              'Rs. ${order.total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 24),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: context.cardBg,
            onSelected: (val) {
              if (val == 'edit') onEdit();
              if (val == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_note_outlined, size: 16, color: context.textSecondary),
                    const SizedBox(width: 8),
                    Text(tr('Edit Order')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 16, color: context.error),
                    const SizedBox(width: 8),
                    Text(tr('Delete'), style: TextStyle(color: context.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Create / Edit Purchase Order Dialog
// ─────────────────────────────────────────────
class _AddEditPurchaseOrderDialog extends ConsumerStatefulWidget {
  final PurchaseOrder? order;
  final List<String> vendors;

  const _AddEditPurchaseOrderDialog({this.order, required this.vendors});

  @override
  ConsumerState<_AddEditPurchaseOrderDialog> createState() => _AddEditPurchaseOrderDialogState();
}

class _AddEditPurchaseOrderDialogState extends ConsumerState<_AddEditPurchaseOrderDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _id;
  late String _vendorId;
  late String _vendorName;
  late String _date;
  late String _deliveryDate;
  late List<PurchaseItem> _items;
  late double _taxRate;
  late String _status;

  @override
  void initState() {
    super.initState();
    final po = widget.order;
    _id = po?.id ?? 'PO-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
    _vendorName = po?.vendorName ?? widget.vendors.first;
    _vendorId = po?.vendorId ?? 'VEND-001';
    _date = po?.date ?? DateTime.now().toIso8601String().substring(0, 10);
    _deliveryDate = po?.deliveryDate ?? DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10);
    _items = po != null ? List.from(po.items) : [];
    _taxRate = po != null ? (po.tax / (po.subtotal > 0 ? po.subtotal : 1) * 100) : 5.0;
    _status = po?.status ?? 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final contextTheme = Theme.of(context);
    final isEdit = widget.order != null;

    double subtotal = 0;
    for (final it in _items) {
      subtotal += it.totalPrice;
    }
    double tax = subtotal * (_taxRate / 100);
    double total = subtotal + tax;

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: BoxConstraints(maxWidth: 650, maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Modify Purchase Order #$_id' : 'Create New Purchase Order',
                style: contextTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  children: [
                    // Vendor & Status
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _vendorName,
                            decoration: InputDecoration(
                              labelText: tr('Select Vendor'),
                              border: OutlineInputBorder(),
                            ),
                            dropdownColor: context.cardBg,
                            items: widget.vendors.map((v) {
                              return DropdownMenuItem(value: v, child: Text(v));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _vendorName = val;
                                  _vendorId = 'VEND-${widget.vendors.indexOf(val) + 1}';
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
                            decoration: InputDecoration(
                              labelText: tr('Status'),
                              border: OutlineInputBorder(),
                            ),
                            dropdownColor: context.cardBg,
                            items: [
                              DropdownMenuItem(value: 'Ordered', child: Text('Ordered')),
                              DropdownMenuItem(value: 'Received', child: Text(tr('Received'))),
                              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                              DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _status = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date pickers row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: TextEditingController(text: AppDateFormatter.formatString(_date)),
                            decoration: const InputDecoration(
                              labelText: 'Order Date',
                              suffixIcon: Icon(Icons.calendar_today, size: 16),
                              border: OutlineInputBorder(),
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() {
                                  _date = picked.toIso8601String().substring(0, 10);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: TextEditingController(text: AppDateFormatter.formatString(_deliveryDate)),
                            decoration: const InputDecoration(
                              labelText: 'Expected Delivery Date',
                              suffixIcon: Icon(Icons.calendar_today, size: 16),
                              border: OutlineInputBorder(),
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.tryParse(_deliveryDate) ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() {
                                  _deliveryDate = picked.toIso8601String().substring(0, 10);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Items list title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Purchase Items List',
                          style: contextTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _items.add(PurchaseItem(
                                itemId: 'ITEM-${DateTime.now().millisecondsSinceEpoch.toString().substring(10)}',
                                itemName: '',
                                quantity: 1,
                                unitPrice: 0,
                                totalPrice: 0,
                              ));
                            });
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Item Line'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Items builder list
                    if (_items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(color: context.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Please add at least one line item.',
                            style: TextStyle(color: context.error, fontSize: 12),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Card(
                            color: context.scaffoldBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: context.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      // Item Name field
                                      Expanded(
                                        flex: 3,
                                        child: TextFormField(
                                          initialValue: item.itemName,
                                          decoration: const InputDecoration(
                                            labelText: 'Item Name / Detail',
                                            border: InputBorder.none,
                                          ),
                                          onChanged: (val) {
                                            setState(() {
                                              _items[index] = item.copyWith(itemName: val.trim());
                                            });
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, color: context.error, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            _items.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  Row(
                                    children: [
                                      // Quantity
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: item.quantity.toString(),
                                          decoration: InputDecoration(
                                            labelText: tr('Quantity'),
                                            border: InputBorder.none,
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (val) {
                                            final qty = int.tryParse(val) ?? 1;
                                            setState(() {
                                              _items[index] = item.copyWith(
                                                quantity: qty,
                                                totalPrice: item.unitPrice * qty,
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Unit Price
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: item.unitPrice > 0 ? item.unitPrice.toStringAsFixed(0) : '',
                                          decoration: const InputDecoration(
                                            labelText: 'Unit Price (Rs.)',
                                            border: InputBorder.none,
                                          ),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                                          ],
                                          onChanged: (val) {
                                            final up = double.tryParse(val) ?? 0;
                                            setState(() {
                                              _items[index] = item.copyWith(
                                                unitPrice: up,
                                                totalPrice: up * item.quantity,
                                              );
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Total Price
                                      Text(
                                        'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),

                    // Totals
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: TextStyle(color: context.textSecondary)),
                        Text('Rs. ${subtotal.toStringAsFixed(0)}', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sales Tax / GST ($_taxRate%)', style: TextStyle(color: context.textSecondary)),
                        Text('Rs. ${tax.toStringAsFixed(0)}', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PO Grand Total',
                          style: contextTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          'Rs. ${total.toStringAsFixed(0)}',
                          style: contextTheme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: context.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              const SizedBox(height: 16),
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
                      if (_items.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please add at least one line item.')),
                        );
                        return;
                      }

                      // Ensure all items have names
                      if (_items.any((item) => item.itemName.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please enter name for all items.')),
                        );
                        return;
                      }

                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        Navigator.pop(
                          context,
                          PurchaseOrder(
                            id: _id,
                            vendorId: _vendorId,
                            vendorName: _vendorName,
                            date: _date,
                            deliveryDate: _deliveryDate,
                            items: _items,
                            subtotal: subtotal,
                            tax: tax,
                            total: total,
                            status: _status,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isEdit ? tr('Save Changes') : 'Generate Order'),
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
