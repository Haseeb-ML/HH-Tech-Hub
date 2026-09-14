import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/sales/shared/widgets/sales_sub_nav.dart';
import '../providers/products_provider.dart';
import '../../domain/entities/product.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Software Development',
    'UI/UX Design',
    'DevOps & Cloud',
    'QA Testing',
    'Consulting',
    'Support',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Software Development':
        return Icons.developer_mode;
      case 'UI/UX Design':
        return Icons.design_services;
      case 'DevOps & Cloud':
        return Icons.cloud_done;
      case 'QA Testing':
        return Icons.fact_check;
      case 'Consulting':
        return Icons.support_agent;
      case 'Support':
        return Icons.help_center;
      default:
        return Icons.category;
    }
  }

  String _formatPKR(double amount) {
    if (amount >= 1000000) {
      return 'Rs. ${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return 'Rs. ${(amount / 1000).toStringAsFixed(1)}k';
    }
    return 'Rs. ${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(productsProvider);
    final theme = Theme.of(context);

    // Apply Search and Category Filter
    final query = _searchController.text.trim().toLowerCase();
    final filteredProducts = state.products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          p.id.toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();



    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: state.isLoading && state.products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Sub Navigation ───────────────────────
                const SalesSubNav(activeRoute: '/sales/products'),

                // ── Main Body ────────────────────────────
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
                                  'Product & Services Catalog',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage all software products, service contracts, and hourly consulting rates.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await showDialog<Product>(
                                  context: context,
                                  builder: (context) => _AddEditProductDialog(categories: _categories),
                                );
                                if (result != null) {
                                  ref.read(productsProvider.notifier).addProduct(result);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${tr("Product / Service")} "${result.name}" ${tr("added successfully.")}'),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: context.success,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Product / Service'),
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

                        // Filters Bar
                        GlassCard(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                // Search Input
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: tr('Search by name, description, or code...'),
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

                                // Category Dropdown Filter
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    decoration: InputDecoration(
                                      labelText: tr('Filter Category'),
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
                                    items: _categories.map((c) {
                                      return DropdownMenuItem(value: c, child: Text(c));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedCategory = val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Catalog Grid
                        filteredProducts.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(80.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.inventory_2_outlined, size: 48, color: context.textMuted),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No products or services found matching filters.',
                                        style: TextStyle(color: context.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final gridWidth = constraints.maxWidth;
                                  final crossAxisCount = gridWidth >= 1150
                                      ? 4
                                      : (gridWidth >= 800
                                          ? 3
                                          : (gridWidth >= 500 ? 2 : 1));
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 1.1,
                                    ),
                                    itemCount: filteredProducts.length,
                                    itemBuilder: (context, index) {
                                      final product = filteredProducts[index];
                                      return _ProductCard(
                                        product: product,
                                        categoryIcon: _getCategoryIcon(product.category),
                                        formattedPrice: _formatPKR(product.price),
                                        onEdit: () async {
                                          final result = await showDialog<Product>(
                                            context: context,
                                            builder: (context) => _AddEditProductDialog(
                                              product: product,
                                              categories: _categories,
                                            ),
                                          );
                                          if (result != null) {
                                            ref.read(productsProvider.notifier).updateProduct(result);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${tr("Product")} "${result.name}" ${tr("updated.")}'),
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
                                              title: Text(tr('Delete Product')),
                                              content: Text('${tr("Are you sure you want to delete")} "${product.name}"? ${tr("This action cannot be undone.")}'),
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
                                            ref.read(productsProvider.notifier).deleteProduct(product.id);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${tr("Product")} "${product.name}" ${tr("deleted.")}'),
                                                behavior: SnackBarBehavior.floating,
                                                backgroundColor: context.error,
                                              ),
                                            );
                                          }
                                        },
                                      );
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

// ─────────────────────────────────────────────
//  Product Card Item
// ─────────────────────────────────────────────
class _ProductCard extends ConsumerWidget {
  final Product product;
  final IconData categoryIcon;
  final String formattedPrice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.categoryIcon,
    required this.formattedPrice,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final theme = Theme.of(context);
    final isActive = product.status == 'Active';

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: context.infoLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(categoryIcon, color: context.primaryColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.category,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: context.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        product.id,
                        style: TextStyle(color: context.textMuted, fontSize: 9, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive ? context.successLight : context.warningLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product.status,
                    style: TextStyle(
                      color: isActive ? context.success : context.warning,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 16, color: context.textMuted),
                  padding: EdgeInsets.zero,
                  color: context.cardBg,
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 14, color: context.textSecondary),
                        const SizedBox(width: 8),
                        Text(tr('Edit')),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline, size: 14, color: context.error),
                        const SizedBox(width: 8),
                        Text(tr('Delete'), style: TextStyle(color: context.error)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Product Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              product.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              product.description,
              style: TextStyle(color: context.textSecondary, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const Spacer(),
          const Divider(height: 1),

          // Price Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Price / Rate',
                  style: TextStyle(color: context.textMuted, fontSize: 10),
                ),
                Text(
                  formattedPrice,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Add / Edit Product Dialog
// ─────────────────────────────────────────────
class _AddEditProductDialog extends ConsumerStatefulWidget {
  final Product? product;
  final List<String> categories;

  const _AddEditProductDialog({this.product, required this.categories});

  @override
  ConsumerState<_AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends ConsumerState<_AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _id;
  late String _name;
  late String _description;
  late String _category;
  late double _price;
  late String _status;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _id = p?.id ?? 'PROD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _name = p?.name ?? '';
    _description = p?.description ?? '';
    // Select first category option excluding 'All'
    _category = p?.category ?? widget.categories.firstWhere((c) => c != 'All');
    _price = p?.price ?? 0;
    _status = p?.status ?? 'Active';
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final contextColors = Theme.of(context);
    final isEdit = widget.product != null;

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, minWidth: 400),
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Product / Service' : 'Add New Product / Service',
                  style: contextColors.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),

                // Name
                TextFormField(
                  initialValue: _name,
                  decoration: InputDecoration(
                    labelText: tr('Product / Service Name'),
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter name';
                    return null;
                  },
                  onSaved: (val) => _name = val!.trim(),
                ),
                const SizedBox(height: 16),

                // Category & Status Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _category,
                        decoration: InputDecoration(
                          labelText: tr('Category'),
                          border: OutlineInputBorder(),
                        ),
                        dropdownColor: context.cardBg,
                        items: widget.categories.where((c) => c != 'All').map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: _status,
                        decoration: InputDecoration(
                          labelText: tr('Status'),
                          border: OutlineInputBorder(),
                        ),
                        dropdownColor: context.cardBg,
                        items: [
                          DropdownMenuItem(value: 'Active', child: Text(tr('Active'))),
                          DropdownMenuItem(value: 'Out of Stock', child: Text('Out of Stock')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _status = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price (Rs. / PKR)
                TextFormField(
                  initialValue: _price > 0 ? _price.toStringAsFixed(0) : '',
                  decoration: InputDecoration(
                    labelText: tr('Price / Rate (Rs.)'),
                    prefixText: 'Rs. ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter price';
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null || parsed < 0) return 'Enter a valid positive number';
                    return null;
                  },
                  onSaved: (val) => _price = double.parse(val!.trim()),
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  initialValue: _description,
                  decoration: InputDecoration(
                    labelText: tr('Description'),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter description';
                    return null;
                  },
                  onSaved: (val) => _description = val!.trim(),
                ),
                const SizedBox(height: 24),

                // Dialog Buttons
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
                          _formKey.currentState!.save();
                          Navigator.pop(
                            context,
                            Product(
                              id: _id,
                              name: _name,
                              description: _description,
                              category: _category,
                              price: _price,
                              status: _status,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isEdit ? tr('Save Changes') : 'Add Product'),
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
