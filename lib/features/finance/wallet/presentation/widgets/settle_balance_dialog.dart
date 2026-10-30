import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/services/cloud_sync_service.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/utils/app_date_formatter.dart';
import 'package:software_house_erp/core/utils/currency_formatter.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';
import 'package:software_house_erp/features/finance/accounts/domain/entities/bank_account.dart';
import 'package:software_house_erp/features/finance/accounts/presentation/providers/accounts_provider.dart';
import 'package:software_house_erp/features/finance/ledger/domain/entities/ledger_entry.dart';
import 'package:software_house_erp/features/finance/ledger/presentation/providers/ledger_provider.dart';

Future<bool?> showSettleAccountBalanceDialog(
  BuildContext context, {
  required WidgetRef ref,
  required BankAccount account,
  required double currentBalance,
}) {
  if (currentBalance.abs() < 0.01) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${account.name} balance is already zero (Rs. 0).'),
        backgroundColor: Colors.blueGrey,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return Future.value(false);
  }

  return showDialog<bool>(
    context: context,
    builder: (context) => _SettleAccountBalanceDialog(
      account: account,
      currentBalance: currentBalance,
    ),
  );
}

class _SettleAccountBalanceDialog extends ConsumerStatefulWidget {
  final BankAccount account;
  final double currentBalance;

  const _SettleAccountBalanceDialog({
    required this.account,
    required this.currentBalance,
  });

  @override
  ConsumerState<_SettleAccountBalanceDialog> createState() =>
      _SettleAccountBalanceDialogState();
}

class _SettleAccountBalanceDialogState
    extends ConsumerState<_SettleAccountBalanceDialog> {
  final _noteController = TextEditingController();
  bool _isSubmitting = false;
  final DateTime _settleDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final isDr = widget.currentBalance > 0;
    _noteController.text = isDr
        ? 'Personal account balance settled to zero (Outflow Settlement)'
        : 'Personal account balance cleared to zero (Inflow Clearance)';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSettle() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final isDr = widget.currentBalance > 0;
      final settleAmount = widget.currentBalance.abs();
      final now = DateTime.now();
      final dateStr = now.toIso8601String();
      final refCode = 'SETTLE-${now.millisecondsSinceEpoch}';
      final noteText = _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : (isDr
              ? 'Personal account balance settled to zero'
              : 'Personal account balance cleared to zero');

      // Create balancing ledger entry:
      // If current balance is Dr (Debit / Positive), record Credit (Outflow)
      // If current balance is Cr (Credit / Negative), record Debit (Inflow)
      final ledgerEntry = LedgerEntry(
        id: 'led_settle_${now.millisecondsSinceEpoch}',
        date: dateStr,
        accountId: widget.account.id,
        accountName: widget.account.name,
        type: isDr ? 'Credit' : 'Debit',
        category: 'Balance Settlement',
        amount: settleAmount,
        reference: refCode,
        description: noteText,
      );

      final ledgerNotifier = ref.read(ledgerProvider.notifier);
      final accountsNotifier = ref.read(accountsProvider.notifier);

      await ledgerNotifier.addLedgerEntry(ledgerEntry);
      await accountsNotifier.adjustBalance(
        widget.account.id,
        isDr ? -settleAmount : settleAmount,
      );

      ref.read(adminProvider.notifier).logAction(
            action:
                'Zeroed balance for personal account "${widget.account.name}" (Previous: ${CurrencyFormatter.formatAccountingBalance(widget.currentBalance)})',
            module: 'Finance',
          );

      await accountsNotifier.loadAccounts();
      try {
        await ref.read(cloudSyncServiceProvider).pushChangesOnly();
      } catch (_) {}

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.account.name} balance successfully settled to Rs. 0',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to settle balance: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 550;
    final isDr = widget.currentBalance > 0;
    final settleAmount = widget.currentBalance.abs();

    return Dialog(
      backgroundColor: context.cardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 500,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.all(isMobile ? 18 : 24),
        child: SingleChildScrollView(
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
                          color: (isDr ? Colors.blue : Colors.red)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.restart_alt_rounded,
                          color: isDr
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFDC2626),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settle & Zero Balance',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          Text(
                            widget.account.name,
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
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close, size: 20),
                    color: context.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Current Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? const Color(0xFF1E293B)
                      : (isDr
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFFEF2F2)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.isDarkMode
                        ? const Color(0xFF334155)
                        : (isDr
                            ? const Color(0xFFBFDBFE)
                            : const Color(0xFFFECACA)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Account Balance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          CurrencyFormatter.formatAccountingBalance(
                              widget.currentBalance),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDr
                                ? (context.isDarkMode
                                    ? const Color(0xFF60A5FA)
                                    : const Color(0xFF2563EB))
                                : (context.isDarkMode
                                    ? const Color(0xFFF87171)
                                    : const Color(0xFFDC2626)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDr
                                ? Colors.blue.withValues(alpha: 0.15)
                                : Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isDr ? 'Debit (Dr)' : 'Credit (Cr)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDr
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // How it works info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: context.primaryColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isDr
                            ? 'An offsetting Outflow settlement entry of Rs. ${CurrencyFormatter.formatAmount(settleAmount)} will be logged in the ledger to bring this account balance to Rs. 0 without erasing past records.'
                            : 'An offsetting Inflow clearance entry of Rs. ${CurrencyFormatter.formatAmount(settleAmount)} will be logged in the ledger to clear the pending debit and bring this account balance to Rs. 0 without erasing past records.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Settlement Date:',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    AppDateFormatter.format(_settleDate),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Note / Description
              Text(
                'Note / Description',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _noteController,
                style: TextStyle(color: context.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Enter reason or settlement details',
                  filled: true,
                  fillColor: context.isDarkMode
                      ? const Color(0xFF1E293B)
                      : context.scaffoldBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    borderSide: BorderSide(color: context.primaryColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: context.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSettle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Confirm & Zero Balance',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
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
