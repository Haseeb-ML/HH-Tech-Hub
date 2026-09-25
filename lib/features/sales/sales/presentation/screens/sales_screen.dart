import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/sales/shared/widgets/sales_sub_nav.dart';
import 'package:software_house_erp/features/clients/clients/presentation/providers/clients_provider.dart';
import '../providers/products_provider.dart';
import '../providers/sales_invoices_provider.dart';
import '../../domain/entities/sales_invoice.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'Rs. ${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return 'Rs. ${(amount / 1000).toStringAsFixed(1)}k';
    }
    return 'Rs. ${amount.toStringAsFixed(0)}';
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'Paid':
        return context.success;
      case 'Pending':
        return context.warning;
      case 'Overdue':
        return context.error;
      default:
        return context.textSecondary;
    }
  }

  Color _getStatusBg(BuildContext context, String status) {
    switch (status) {
      case 'Paid':
        return context.successLight;
      case 'Pending':
        return context.warningLight;
      case 'Overdue':
        return context.errorLight;
      default:
        return context.scaffoldBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(salesInvoicesProvider);
    final theme = Theme.of(context);

    // Calculate invoice stats
    double totalInvoiced = 0;
    double totalPaid = 0;
    double totalPending = 0;

    for (final inv in state.invoices) {
      totalInvoiced += inv.total;
      if (inv.status == 'Paid') {
        totalPaid += inv.total;
      } else {
        totalPending += inv.total;
      }
    }

    // Filter invoices
    final query = _searchController.text.trim().toLowerCase();
    final filteredInvoices = state.invoices.where((inv) {
      final matchesSearch = inv.id.toLowerCase().contains(query) ||
          inv.clientName.toLowerCase().contains(query);
      final matchesStatus = _selectedStatus == 'All' || inv.status == _selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: state.isLoading && state.invoices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Sub Navigation ───────────────────────
                const SalesSubNav(activeRoute: '/sales/list'),

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
                                  'Sales Invoices Ledger',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Generate invoice estimates, track due balances, and log client payouts.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await showDialog<SalesInvoice>(
                                  context: context,
                                  builder: (context) => const _AddEditInvoiceDialog(),
                                );
                                if (result != null) {
                                  ref.read(salesInvoicesProvider.notifier).addInvoice(result);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${tr("Invoice")} "${result.id}" ${tr("created successfully.")}'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: context.success,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('New Sales Invoice'),
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
                                    title: 'Total Invoiced',
                                    tooltipMessage: 'Detailed statistics and information regarding Total Invoiced.',
                                    value: _formatCurrency(totalInvoiced),
                                    icon: Icons.receipt_long,
                                    iconColor: context.primaryColor,
                                    iconBgColor: context.infoLight,
                                    trendText: tr('Lifetime billed amount'),
                                  ),
                                  const SizedBox(height: 12),
                                  StatCard(
                                    title: tr('Total Received (Paid)'),
                                    tooltipMessage: "Detailed statistics and information regarding ${tr('Total Received (Paid)')}.",
                                    value: _formatCurrency(totalPaid),
                                    icon: Icons.check_circle_outline,
                                    iconColor: context.success,
                                    iconBgColor: context.successLight,
                                    trendText: tr('Cleared earnings'),
                                  ),
                                  const SizedBox(height: 12),
                                  StatCard(
                                    title: 'Outstanding Balance',
                                    tooltipMessage: 'Detailed statistics and information regarding Outstanding Balance.',
                                    value: _formatCurrency(totalPending),
                                    icon: Icons.pending_actions,
                                    iconColor: context.warning,
                                    iconBgColor: context.warningLight,
                                    trendText: tr('Pending & overdue totals'),
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: StatCard(
                                    title: tr('Total Billed'),
                                    tooltipMessage: "Detailed statistics and information regarding ${tr('Total Billed')}.",
                                    value: _formatCurrency(totalInvoiced),
                                    icon: Icons.receipt_long,
                                    iconColor: context.primaryColor,
                                    iconBgColor: context.infoLight,
                                    trendText: tr('Lifetime billed amount'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: StatCard(
                                    title: 'Collected Revenue',
                                    tooltipMessage: 'Detailed statistics and information regarding Collected Revenue.',
                                    value: _formatCurrency(totalPaid),
                                    icon: Icons.check_circle_outline,
                                    iconColor: context.success,
                                    iconBgColor: context.successLight,
                                    trendText: tr('Cleared earnings'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: StatCard(
                                    title: 'Accounts Receivable',
                                    tooltipMessage: 'Detailed statistics and information regarding Accounts Receivable.',
                                    value: _formatCurrency(totalPending),
                                    icon: Icons.pending_actions,
                                    iconColor: context.warning,
                                    iconBgColor: context.warningLight,
                                    trendText: tr('Pending & overdue totals'),
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
                                      hintText: tr('Search by invoice number or client name...'),
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
                                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                                      fillColor: context.scaffoldBg,
                                      filled: true,
                                    ),
                                    dropdownColor: context.cardBg,
                                    items: [
                                      DropdownMenuItem(value: 'All', child: Text(tr('All Statuses'))),
                                      DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                                      DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                      DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
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
                                  'Recent Invoices Ledger',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),
                                filteredInvoices.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(40.0),
                                          child: Text(
                                            'No sales invoices found.',
                                            style: TextStyle(color: context.textSecondary),
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: filteredInvoices.length,
                                        separatorBuilder: (context, index) => const Divider(),
                                        itemBuilder: (context, index) {
                                          final invoice = filteredInvoices[index];
                                          return _InvoiceRow(
                                            invoice: invoice,
                                            statusColor: _getStatusColor(context, invoice.status),
                                            statusBg: _getStatusBg(context, invoice.status),
                                            onEdit: () async {
                                              final result = await showDialog<SalesInvoice>(
                                                context: context,
                                                builder: (context) => _AddEditInvoiceDialog(invoice: invoice),
                                              );
                                              if (result != null) {
                                                ref.read(salesInvoicesProvider.notifier).updateInvoice(result);
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('${tr("Invoice")} "${result.id}" ${tr("updated.")}'),
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
                                                  title: Text(tr('Delete Invoice')),
                                                  content: Text('${tr("Delete")} "${invoice.id}"? ${tr("This cannot be undone.")}'),
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
                                                ref.read(salesInvoicesProvider.notifier).deleteInvoice(invoice.id);
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('${tr("Invoice")} "${invoice.id}" ${tr("deleted.")}'),
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
//  Invoice Ledger Row Widget
// ─────────────────────────────────────────────
class _InvoiceRow extends ConsumerWidget {
  final SalesInvoice invoice;
  final Color statusColor;
  final Color statusBg;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InvoiceRow({
    required this.invoice,
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
          // Icon & invoice number
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.infoLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.receipt_outlined, color: context.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),

          // Code & client info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.id,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  invoice.clientName,
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
                    'Billed: ${invoice.date}',
                    style: TextStyle(color: context.textSecondary, fontSize: 11),
                  ),
                  Text(
                    'Due: ${invoice.dueDate}',
                    style: TextStyle(color: context.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),

          // Total PKR
          Expanded(
            flex: 1,
            child: Text(
              'Rs. ${invoice.total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
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
              invoice.status,
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
                    Text(tr('Edit Invoice')),
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
//  Create / Edit Invoice Dialog Form
// ─────────────────────────────────────────────
class _AddEditInvoiceDialog extends ConsumerStatefulWidget {
  final SalesInvoice? invoice;

  const _AddEditInvoiceDialog({this.invoice});

  @override
  ConsumerState<_AddEditInvoiceDialog> createState() => _AddEditInvoiceDialogState();
}

class _AddEditInvoiceDialogState extends ConsumerState<_AddEditInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _id;
  late String _clientId;
  late String _clientName;
  late String _date;
  late String _dueDate;
  late List<InvoiceItem> _items;
  late double _taxRate; // e.g. 5%
  late String _status;

  @override
  void initState() {
    super.initState();
    final inv = widget.invoice;
    _id = inv?.id ?? 'INV-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
    _clientId = inv?.clientId ?? '';
    _clientName = inv?.clientName ?? '';
    _date = inv?.date ?? DateTime.now().toIso8601String().substring(0, 10);
    _dueDate = inv?.dueDate ?? DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10);
    _items = inv != null ? List.from(inv.items) : [];
    _taxRate = inv != null ? (inv.tax / (inv.subtotal > 0 ? inv.subtotal : 1) * 100) : 5.0;
    _status = inv?.status ?? 'Pending';
  }


  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final contextTheme = Theme.of(context);
    final isEdit = widget.invoice != null;

    // Fetch active clients from Clients module — deduplicate by id
    final clientsState = ref.watch(clientsProvider);
    final seenClientIds = <String>{};
    final activeClients = clientsState.clients
        .where((c) => c.status == 'Active' && seenClientIds.add(c.id))
        .toList();

    // Fetch products catalog — deduplicate by id
    final productsState = ref.watch(productsProvider);
    final seenProductIds = <String>{};
    final activeProducts = productsState.products
        .where((p) => p.status == 'Active' && seenProductIds.add(p.id))
        .toList();

    // Calculate subtotal and tax
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
                isEdit ? 'Modify Invoice #$_id' : 'Generate New Sales Invoice',
                style: contextTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 20),

              // Form fields section
              Expanded(
                child: ListView(
                  children: [
                    // Client Selector Row
                    Row(
                      children: [
                        Expanded(
                          child: activeClients.isEmpty
                              ? Text(
                                  'Warning: No active clients found! Please add a client first.',
                                  style: TextStyle(color: context.error, fontSize: 12),
                                )
                              : DropdownButtonFormField<String>(
                                  value: _clientId.isEmpty ? null : _clientId,
                                  decoration: const InputDecoration(
                                    labelText: 'Billed To (Client Name)',
                                    border: OutlineInputBorder(),
                                  ),
                                  dropdownColor: context.cardBg,
                                  items: activeClients.map((c) {
                                    return DropdownMenuItem(value: c.id, child: Text(c.name));
                                  }).toList(),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'Select client';
                                    return null;
                                  },
                                  onChanged: (val) {
                                    if (val != null) {
                                      final cl = activeClients.firstWhere((c) => c.id == val);
                                      setState(() {
                                        _clientId = val;
                                        _clientName = cl.name;
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
                            items: const [
                              DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                              DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
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
                            controller: TextEditingController(text: _date),
                            decoration: const InputDecoration(
                              labelText: 'Invoice Date',
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
                            controller: TextEditingController(text: _dueDate),
                            decoration: InputDecoration(
                              labelText: tr('Due Date'),
                              suffixIcon: Icon(Icons.calendar_today, size: 16),
                              border: OutlineInputBorder(),
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.tryParse(_dueDate) ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setState(() {
                                  _dueDate = picked.toIso8601String().substring(0, 10);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Multi-Items Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Invoice Items List',
                          style: contextTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            if (activeProducts.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(tr('No active services in catalog.'))),
                              );
                              return;
                            }
                            // Add a blank row
                            final prod = activeProducts.first;
                            setState(() {
                              _items.add(InvoiceItem(
                                productId: prod.id,
                                productName: prod.name,
                                quantity: 1,
                                unitPrice: prod.price,
                                totalPrice: prod.price,
                              ));
                            });
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(tr('Add Service Line')),
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
                            'Please add at least one product or service.',
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
                              child: Row(
                                children: [
                                  // Product selector
                                  Expanded(
                                    flex: 3,
                                    child: DropdownButtonFormField<String>(
                                      value: item.productId,
                                      decoration: InputDecoration(
                                        labelText: tr('Product / Service'),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                        border: InputBorder.none,
                                      ),
                                      dropdownColor: context.cardBg,
                                      items: activeProducts.map((p) {
                                        return DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          final selectedProd = activeProducts.firstWhere((p) => p.id == val);
                                          setState(() {
                                            _items[index] = item.copyWith(
                                              productId: val,
                                              productName: selectedProd.name,
                                              unitPrice: selectedProd.price,
                                              totalPrice: selectedProd.price * item.quantity,
                                            );
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Quantity
                                  SizedBox(
                                    width: 60,
                                    child: TextFormField(
                                      initialValue: item.quantity.toString(),
                                      decoration: const InputDecoration(
                                        labelText: 'Qty',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 5),
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

                                  // Unit Price Display
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Rs. ${item.totalPrice.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: context.textPrimary,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),

                                  // Delete button
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
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),

                    // Totals display
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
                        Text('GST / Tax ($_taxRate%)', style: TextStyle(color: context.textSecondary)),
                        Text('Rs. ${tax.toStringAsFixed(0)}', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Invoice Total',
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

              // Action buttons
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

                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        Navigator.pop(
                          context,
                          SalesInvoice(
                            id: _id,
                            clientId: _clientId,
                            clientName: _clientName,
                            date: _date,
                            dueDate: _dueDate,
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
                    child: Text(isEdit ? tr('Save Changes') : 'Generate Invoice'),
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
