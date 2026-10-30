import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/features/finance/accounts/presentation/providers/accounts_provider.dart';
import 'package:software_house_erp/features/finance/ledger/domain/entities/ledger_entry.dart';
import 'package:software_house_erp/features/finance/ledger/presentation/providers/ledger_provider.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

enum CompanyTransactionType { deposit, transfer, expense }
enum CompanyTransferDirection { transferOut, transferIn }

class CompanyAccountTransaction {
  final CompanyTransactionType type;
  final CompanyTransferDirection direction;
  final String companyAccountId;
  final String? targetAccountId;
  final double amount;
  final DateTime date;
  final String description;

  const CompanyAccountTransaction({
    required this.type,
    required this.direction,
    required this.companyAccountId,
    required this.targetAccountId,
    required this.amount,
    required this.date,
    required this.description,
  });
}

Future<void> recordCompanyAccountTransaction(
  WidgetRef ref,
  CompanyAccountTransaction transaction,
) async {
  final adminState = ref.read(adminProvider);
  if (!adminState.hasPermission(AppModule.accounts, PermissionAction.create)) {
    throw StateError('Access Denied: You do not have permission to add transactions.');
  }

  final accounts = ref.read(accountsProvider).accounts;
  final company = accounts.firstWhere((a) => a.id == transaction.companyAccountId);
  final accountNotifier = ref.read(accountsProvider.notifier);
  final ledgerNotifier = ref.read(ledgerProvider.notifier);
  final reference = transaction.type == CompanyTransactionType.deposit
      ? 'DEP-${DateTime.now().millisecondsSinceEpoch}'
      : (transaction.type == CompanyTransactionType.expense
          ? 'EXP-${DateTime.now().millisecondsSinceEpoch}'
          : 'TRF-${DateTime.now().millisecondsSinceEpoch}');
  final date = transaction.date.toIso8601String();

  if (transaction.type == CompanyTransactionType.deposit) {
    await accountNotifier.adjustBalance(company.id, transaction.amount);
    await ledgerNotifier.addLedgerEntry(LedgerEntry(
      id: 'led_company_deposit_${DateTime.now().millisecondsSinceEpoch}',
      date: date,
      accountId: company.id,
      accountName: company.name,
      type: 'Debit',
      category: 'Company Deposit',
      amount: transaction.amount,
      reference: reference,
      description: transaction.description.isEmpty
          ? 'Funds deposited to ${company.name}'
          : transaction.description,
    ));
    return;
  }

  if (transaction.type == CompanyTransactionType.expense) {
    if (company.balance < transaction.amount) {
      throw StateError('Insufficient balance in ${company.name}.');
    }
    await accountNotifier.adjustBalance(company.id, -transaction.amount);
    await ledgerNotifier.addLedgerEntry(LedgerEntry(
      id: 'led_company_expense_${DateTime.now().millisecondsSinceEpoch}',
      date: date,
      accountId: company.id,
      accountName: company.name,
      type: 'Credit',
      category: 'Other Expense',
      amount: transaction.amount,
      reference: reference,
      description: transaction.description.isEmpty
          ? 'Other expense from ${company.name}'
          : transaction.description,
    ));
    return;
  }

  final targetId = transaction.targetAccountId!;
  final target = accounts.firstWhere((a) => a.id == targetId);
  final transferOut = transaction.direction == CompanyTransferDirection.transferOut;
  final source = transferOut ? company : target;
  final destination = transferOut ? target : company;

  if (source.balance < transaction.amount) {
    throw StateError('Insufficient balance in ${source.name}.');
  }

  await accountNotifier.adjustBalance(source.id, -transaction.amount);
  await accountNotifier.adjustBalance(destination.id, transaction.amount);

  final sourceLabel = source.isPersonal
      ? '${source.ownerName.isNotEmpty ? source.ownerName : source.name} Personal Account'
      : source.name;
  final destinationLabel = destination.isPersonal
      ? '${destination.ownerName.isNotEmpty ? destination.ownerName : destination.name} Personal Account'
      : destination.name;
  final sourceDescription = transaction.description.isEmpty
      ? 'Transferred to $destinationLabel'
      : 'Transferred to $destinationLabel • ${transaction.description}';
  final destinationDescription = transaction.description.isEmpty
      ? 'Received from $sourceLabel'
      : 'Received from $sourceLabel • ${transaction.description}';

  await ledgerNotifier.addLedgerEntry(LedgerEntry(
    id: 'led_transfer_out_$reference',
    date: date,
    accountId: source.id,
    accountName: source.name,
    type: 'Credit',
    category: 'Account Transfer',
    amount: transaction.amount,
    reference: reference,
    description: sourceDescription,
  ));
  await ledgerNotifier.addLedgerEntry(LedgerEntry(
    id: 'led_transfer_in_$reference',
    date: date,
    accountId: destination.id,
    accountName: destination.name,
    type: 'Debit',
    category: 'Account Transfer',
    amount: transaction.amount,
    reference: reference,
    description: destinationDescription,
  ));
}

Future<CompanyAccountTransaction?> showCompanyAccountTransactionDialog(
  BuildContext context, {
  required String companyAccountId,
}) {
  return showDialog<CompanyAccountTransaction>(
    context: context,
    builder: (context) => _CompanyAccountTransactionDialog(
      companyAccountId: companyAccountId,
    ),
  );
}

class _CompanyAccountTransactionDialog extends ConsumerStatefulWidget {
  final String companyAccountId;

  const _CompanyAccountTransactionDialog({required this.companyAccountId});

  @override
  ConsumerState<_CompanyAccountTransactionDialog> createState() =>
      _CompanyAccountTransactionDialogState();
}

class _CompanyAccountTransactionDialogState
    extends ConsumerState<_CompanyAccountTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  CompanyTransactionType _type = CompanyTransactionType.deposit;
  CompanyTransferDirection _direction = CompanyTransferDirection.transferOut;
  String? _targetAccountId;
  final DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).accounts.where((a) => a.status == 'Active').toList();
    final currentCompanyAccount = accounts.firstWhere((a) => a.id == widget.companyAccountId);
    final targetAccounts = accounts.where((a) => a.id != widget.companyAccountId).toList();
    final dialogTitle = '${currentCompanyAccount.name} Transaction';

    return AlertDialog(
      title: Text(dialogTitle),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<CompanyTransactionType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Transaction Type'),
                  items: const [
                    DropdownMenuItem(
                        value: CompanyTransactionType.deposit,
                        child: Text('Deposit / Cash In')),
                    DropdownMenuItem(
                        value: CompanyTransactionType.transfer,
                        child: Text('Account Transfer')),
                    DropdownMenuItem(
                        value: CompanyTransactionType.expense,
                        child: Text('Other')),
                  ],
                  onChanged: (value) => setState(() => _type = value!),
                ),
                if (_type == CompanyTransactionType.transfer) ...[
                  const SizedBox(height: 12),
                  SegmentedButton<CompanyTransferDirection>(
                    segments: const [
                      ButtonSegment(
                          value: CompanyTransferDirection.transferOut,
                          label: Text('Transfer Out')),
                      ButtonSegment(
                          value: CompanyTransferDirection.transferIn,
                          label: Text('Transfer In')),
                    ],
                    selected: {_direction},
                    onSelectionChanged: (value) =>
                        setState(() => _direction = value.first),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: targetAccounts.any((a) => a.id == _targetAccountId)
                        ? _targetAccountId
                        : null,
                    decoration:
                        const InputDecoration(labelText: 'Target Account'),
                    items: targetAccounts
                        .map((account) {
                          final label = account.isPersonal
                              ? '${account.ownerName.isNotEmpty ? account.ownerName : account.name} Personal Account'
                              : account.name;
                          return DropdownMenuItem(
                              value: account.id, child: Text(label));
                        })
                        .toList(),
                    validator: (value) =>
                        _type == CompanyTransactionType.transfer &&
                                value == null
                            ? 'Select target account'
                            : null,
                    onChanged: (value) =>
                        setState(() => _targetAccountId = value),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (Rs.)'),
                  validator: (value) {
                    final amount = double.tryParse(value ?? '');
                    return amount == null || amount <= 0
                        ? 'Enter a valid positive amount'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: _type == CompanyTransactionType.expense
                        ? 'Description / Category Notes (optional)'
                        : 'Description (optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              CompanyAccountTransaction(
                type: _type,
                direction: _direction,
                companyAccountId: widget.companyAccountId,
                targetAccountId: _targetAccountId,
                amount: double.parse(_amountController.text),
                date: _date,
                description: _descriptionController.text.trim(),
              ),
            );
          },
          child: const Text('Save Transaction'),
        ),
      ],
    );
  }
}
