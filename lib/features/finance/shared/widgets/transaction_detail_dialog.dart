import 'package:flutter/material.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:intl/intl.dart';
import 'package:software_house_erp/core/utils/app_date_formatter.dart';

class TransactionDetailDialog extends StatelessWidget {
  final String id;
  final String title;
  final String category;
  final String description;
  final double amount;
  final String date;
  final String type; // 'Debit' / 'Credit' or 'Income' / 'Expense' or 'Inflow' / 'Outflow'
  final String accountName;
  final String? accountScope; // 'Company', 'Personal'
  final String reference;
  final String? clientOrVendor;
  final VoidCallback? onDelete;

  const TransactionDetailDialog({
    super.key,
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.accountName,
    this.accountScope,
    required this.reference,
    this.clientOrVendor,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    String? id,
    String? title,
    String? category,
    String? description,
    double? amount,
    String? date,
    String? type,
    String? accountName,
    String? accountScope,
    String? reference,
    String? clientOrVendor,
    VoidCallback? onDelete,
    Map<String, dynamic>? data,
  }) {
    final map = data ?? {};
    return showDialog(
      context: context,
      builder: (context) => TransactionDetailDialog(
        id: id ?? map['id']?.toString() ?? '',
        title: title ?? map['title']?.toString() ?? map['category']?.toString() ?? 'Transaction',
        category: category ?? map['category']?.toString() ?? 'General',
        description: description ?? map['description']?.toString() ?? '',
        amount: amount ?? (map['amount'] as num?)?.toDouble() ?? 0.0,
        date: date ?? map['date']?.toString() ?? '',
        type: type ?? map['type']?.toString() ?? 'Income',
        accountName: accountName ?? map['accountName']?.toString() ?? 'Account',
        accountScope: accountScope ?? map['accountScope']?.toString(),
        reference: reference ?? map['reference']?.toString() ?? map['invoiceNumber']?.toString() ?? map['id']?.toString() ?? '',
        clientOrVendor: clientOrVendor ?? map['clientOrVendor']?.toString() ?? map['clientName']?.toString() ?? map['vendorName']?.toString(),
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String tr(String key) => AppLocalization.translate(key, 'en');
    final theme = Theme.of(context);

    final isInflow = type == 'Debit' || type == 'Income' || type == 'Inflow';
    final primaryColor = isInflow ? context.success : context.error;
    final bgColor = isInflow ? context.successLight : context.errorLight;
    final typeLabel = isInflow ? 'Inflow (Debit)' : 'Outflow (Credit)';

    String formattedDate = date;
    try {
      final dt = DateTime.parse(date);
      formattedDate = AppDateFormatter.formatWithTime(dt);
    } catch (_) {
      formattedDate = AppDateFormatter.formatString(date);
    }

    final isOutflow = !isInflow;
    final prefix = isOutflow ? 'exp_' : 'inv_';
    String formattedId = id;
    final idUpper = id.toUpperCase();
    final refUpper = reference.toUpperCase();

    if (idUpper.startsWith('EXP_') ||
        idUpper.startsWith('INV_') ||
        idUpper.startsWith('SAL_') ||
        idUpper.startsWith('REC_') ||
        idUpper.startsWith('INV-') ||
        id.startsWith('exp_') ||
        id.startsWith('inv_') ||
        id.startsWith('sal_') ||
        id.startsWith('rec_')) {
      formattedId = id;
    } else if (refUpper.startsWith('EXP_') ||
        refUpper.startsWith('INV_') ||
        refUpper.startsWith('SAL_') ||
        refUpper.startsWith('REC_') ||
        refUpper.startsWith('INV-') ||
        reference.startsWith('exp_') ||
        reference.startsWith('inv_') ||
        reference.startsWith('sal_') ||
        reference.startsWith('rec_')) {
      formattedId = reference;
    } else {
      final digits = id.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isNotEmpty) {
        final numVal = int.tryParse(digits.length > 4 ? digits.substring(digits.length - 4) : digits) ?? 1;
        formattedId = '$prefix${numVal.toString().padLeft(4, '0')}';
      }
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: context.cardBg,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 480,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: EdgeInsets.all(isMobile ? 18 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isInflow ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Transaction Details'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                                fontSize: isMobile ? 15 : 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                typeLabel,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
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
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Banner Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.scaffoldBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            tr('Total Amount'),
                            style: TextStyle(color: context.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${isInflow ? '+' : '-'} Rs. ${amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: isMobile ? 22 : 24,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.isNotEmpty ? category : 'General Transaction',
                            style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Detail Fields
                    _buildDetailRow(context, tr('Invoice / Ref ID'), formattedId, Icons.receipt_long_outlined, isMobile: isMobile),
                    _buildDetailRow(context, tr('Date & Time'), formattedDate, Icons.calendar_today_outlined, isMobile: isMobile),
                    _buildDetailRow(context, tr('Account'), accountName + (accountScope != null ? ' ($accountScope)' : ''), Icons.account_balance_wallet_outlined, isMobile: isMobile),
                    _buildDetailRow(context, tr('Reference'), reference.isNotEmpty ? reference : id, Icons.tag, isMobile: isMobile),
                    if (clientOrVendor != null && clientOrVendor!.isNotEmpty)
                      _buildDetailRow(context, tr('Party / Client / Vendor'), clientOrVendor!, Icons.person_outline, isMobile: isMobile),
                    if (description.isNotEmpty)
                      _buildDetailRow(context, tr('Description'), description, Icons.notes_outlined, isMobile: isMobile),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: onDelete != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
              children: [
                if (onDelete != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDelete!();
                    },
                    icon: Icon(Icons.delete_outline, size: 16, color: context.error),
                    label: Text(
                      tr('Delete'),
                      style: TextStyle(color: context.error, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.error,
                      side: BorderSide(color: context.error.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(tr('Close')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isMobile = false,
  }) {
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: context.textMuted),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: context.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: SelectableText(
                value,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
