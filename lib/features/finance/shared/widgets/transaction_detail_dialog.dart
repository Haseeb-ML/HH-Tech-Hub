import 'package:flutter/material.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:intl/intl.dart';

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
      formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {}

    return Dialog(
      backgroundColor: context.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('Transaction Details'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
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
            const Divider(height: 1),
            const SizedBox(height: 16),

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
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.isNotEmpty ? category : 'General Transaction',
                    style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detail Fields
            _buildDetailRow(context, tr('Date & Time'), formattedDate, Icons.calendar_today_outlined),
            _buildDetailRow(context, tr('Account'), accountName + (accountScope != null ? ' ($accountScope)' : ''), Icons.account_balance_wallet_outlined),
            _buildDetailRow(context, tr('Reference'), reference.isNotEmpty ? reference : id, Icons.tag),
            if (clientOrVendor != null && clientOrVendor!.isNotEmpty)
              _buildDetailRow(context, tr('Party / Client / Vendor'), clientOrVendor!, Icons.person_outline),
            if (description.isNotEmpty)
              _buildDetailRow(context, tr('Description'), description, Icons.notes_outlined, maxLines: 3),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: context.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
