import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import '../providers/expense_categories_provider.dart';
import '../providers/expenses_provider.dart';

class ManageExpenseCategoriesDialog extends ConsumerStatefulWidget {
  final String? currentCategory;
  final ValueChanged<String>? onCategorySelected;

  const ManageExpenseCategoriesDialog({
    super.key,
    this.currentCategory,
    this.onCategorySelected,
  });

  static Future<void> show(
    BuildContext context, {
    String? currentCategory,
    ValueChanged<String>? onCategorySelected,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ManageExpenseCategoriesDialog(
        currentCategory: currentCategory,
        onCategorySelected: onCategorySelected,
      ),
    );
  }

  @override
  ConsumerState<ManageExpenseCategoriesDialog> createState() =>
      _ManageExpenseCategoriesDialogState();
}

class _ManageExpenseCategoriesDialogState
    extends ConsumerState<ManageExpenseCategoriesDialog> {
  final _addController = TextEditingController();
  final _searchController = TextEditingController();
  String? _editingCategory;
  final _editController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    _searchController.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _handleAdd() async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;

    final success = await ref
        .read(expenseCategoriesProvider.notifier)
        .addCategory(text);
    if (!mounted) return;

    if (success) {
      _addController.clear();
      widget.onCategorySelected?.call(text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "$text" added successfully'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "$text" already exists'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _startEdit(String category) {
    setState(() {
      _editingCategory = category;
      _editController.text = category;
    });
  }

  void _saveEdit(String oldName) async {
    final newName = _editController.text.trim();
    if (newName.isEmpty || newName == oldName) {
      setState(() => _editingCategory = null);
      return;
    }

    final success = await ref
        .read(expenseCategoriesProvider.notifier)
        .updateCategory(oldName, newName);
    if (!mounted) return;

    if (success) {
      // Also update any existing expenses using oldName to newName
      await ref.read(expensesProvider.notifier).renameCategory(oldName, newName);
      if (widget.currentCategory == oldName) {
        widget.onCategorySelected?.call(newName);
      }
      if (!mounted) return;
      setState(() => _editingCategory = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category updated to "$newName"'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "$newName" already exists'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmDelete(String category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Category',
          style: TextStyle(color: ctx.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "$category"? Existing expenses with this category will not be lost.',
          style: TextStyle(color: ctx.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: ctx.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(expenseCategoriesProvider.notifier)
          .deleteCategory(category);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Category "$category" deleted'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(expenseCategoriesProvider);
    final searchQuery = _searchController.text.trim().toLowerCase();
    final filteredCategories = searchQuery.isEmpty
        ? categories
        : categories
            .where((c) => c.toLowerCase().contains(searchQuery))
            .toList();

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 650),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.category_outlined,
                        color: context.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expense Categories',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          'Add, edit, or delete categories',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
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

            // Add new category row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _addController,
                    style: TextStyle(color: context.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter new category name',
                      hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
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
                        borderSide: BorderSide(
                          color: context.primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onFieldSubmitted: (_) => _handleAdd(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _handleAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search / filter categories
            if (categories.length > 6)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: context.textMuted,
                    ),
                    hintText: 'Filter categories...',
                    hintStyle: TextStyle(color: context.textMuted, fontSize: 12),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.border),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

            // Categories list
            Expanded(
              child: filteredCategories.isEmpty
                  ? Center(
                      child: Text(
                        'No categories found',
                        style: TextStyle(color: context.textMuted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredCategories.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: context.border.withValues(alpha: 0.5)),
                      itemBuilder: (context, index) {
                        final cat = filteredCategories[index];
                        final isEditing = _editingCategory == cat;

                        if (isEditing) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _editController,
                                    autofocus: true,
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 13,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onFieldSubmitted: (_) => _saveEdit(cat),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  tooltip: 'Save',
                                  onPressed: () => _saveEdit(cat),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: context.textMuted,
                                    size: 20,
                                  ),
                                  tooltip: 'Cancel',
                                  onPressed: () =>
                                      setState(() => _editingCategory = null),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 0,
                          ),
                          dense: true,
                          leading: Icon(
                            Icons.label_outline,
                            size: 16,
                            color: context.primaryColor,
                          ),
                          title: Text(
                            cat,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: context.primaryColor,
                                ),
                                tooltip: 'Edit Category',
                                onPressed: () => _startEdit(cat),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete Category',
                                onPressed: () => _confirmDelete(cat),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
