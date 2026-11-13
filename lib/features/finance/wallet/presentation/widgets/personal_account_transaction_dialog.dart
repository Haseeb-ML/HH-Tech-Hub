import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/features/finance/accounts/presentation/providers/accounts_provider.dart';
import 'package:software_house_erp/features/finance/ledger/domain/entities/ledger_entry.dart';
import 'package:software_house_erp/features/finance/ledger/presentation/providers/ledger_provider.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

enum PersonalTransactionType { deposit, transfer, personalTransfer, expense }
enum PersonalTransferDirection { companyToPersonal, personalToCompany }
enum PersonalToPersonalDirection { sendTo, receiveFrom }

class PersonalAccountTransaction {
  final PersonalTransactionType type;
  final PersonalTransferDirection direction;
  final PersonalToPersonalDirection personalToPersonalDirection;
  final String personalAccountId;
  final String? companyAccountId;
  final String? targetPersonalAccountId;
  final double amount;
  final DateTime date;
  final String description;

  const PersonalAccountTransaction({
    required this.type,
    required this.direction,
    this.personalToPersonalDirection = PersonalToPersonalDirection.sendTo,
    required this.personalAccountId,
    required this.companyAccountId,
    this.targetPersonalAccountId,
    required this.amount,
    required this.date,
    required this.description,
  });
}

Future<void> recordPersonalAccountTransaction(
  WidgetRef ref,
  PersonalAccountTransaction transaction,
) async {
  final adminState = ref.read(adminProvider);
  if (!adminState.hasPermission(AppModule.accounts, PermissionAction.create)) {
    throw StateError('Access Denied: You do not have permission to add transactions.');
  }

  final accounts = ref.read(accountsProvider).accounts;
  final personal = accounts.firstWhere((a) => a.id == transaction.personalAccountId);
  final accountNotifier = ref.read(accountsProvider.notifier);
  final ledgerNotifier = ref.read(ledgerProvider.notifier);
  final reference = transaction.type == PersonalTransactionType.deposit
      ? 'DEP-${DateTime.now().millisecondsSinceEpoch}'
      : (transaction.type == PersonalTransactionType.expense
          ? 'EXP-${DateTime.now().millisecondsSinceEpoch}'
          : 'TRF-${DateTime.now().millisecondsSinceEpoch}');
  final date = transaction.date.toIso8601String();

  if (transaction.type == PersonalTransactionType.personalTransfer) {
    final targetId = transaction.targetPersonalAccountId!;
    final targetPersonal = accounts.firstWhere((a) => a.id == targetId);
    final isSend = transaction.personalToPersonalDirection == PersonalToPersonalDirection.sendTo;
    final source = isSend ? personal : targetPersonal;
    final destination = isSend ? targetPersonal : personal;

// Overdraft allowed for personal accounts

    await accountNotifier.adjustBalance(source.id, -transaction.amount);
    await accountNotifier.adjustBalance(destination.id, transaction.amount);

    final sourceLabel = source.ownerName.isNotEmpty ? '${source.ownerName} Personal Account' : source.name;
    final destinationLabel = destination.ownerName.isNotEmpty ? '${destination.ownerName} Personal Account' : destination.name;
    final sourceDescription = transaction.description.isEmpty
        ? 'Transferred to $destinationLabel'
        : 'Transferred to $destinationLabel • ${transaction.description}';
    final destinationDescription = transaction.description.isEmpty
        ? 'Received from $sourceLabel'
        : 'Received from $sourceLabel • ${transaction.description}';

    final ptrfRef = 'PTRF-${DateTime.now().millisecondsSinceEpoch}';

    await ledgerNotifier.addLedgerEntry(LedgerEntry(
      id: 'led_transfer_out_$ptrfRef',
      date: date,
      accountId: source.id,
      accountName: source.name,
      type: 'Credit',
      category: 'Account Transfer',
      amount: transaction.amount,
      reference: ptrfRef,
      description: sourceDescription,
    ));
    await ledgerNotifier.addLedgerEntry(LedgerEntry(
      id: 'led_transfer_in_$ptrfRef',
      date: date,
      accountId: destination.id,
      accountName: destination.name,
      type: 'Debit',
      category: 'Account Transfer',
      amount: transaction.amount,
      reference: ptrfRef,
      description: destinationDescription,
    ));
    return;
  }

  if (transaction.type == PersonalTransactionType.deposit) {
    await accountNotifier.adjustBalance(personal.id, transaction.amount);
    await ledgerNotifier.addLedgerEntry(LedgerEntry(
      id: 'led_personal_deposit_${DateTime.now().millisecondsSinceEpoch}',
      date: date,
      accountId: personal.id,
      accountName: personal.name,
      type: 'Debit',
      category: 'Personal Deposit',
      amount: transaction.amount,
      reference: reference,
      description: transaction.description.isEmpty
          ? 'Owner personal funds deposited'
          : transaction.description,
    ));
    return;
  }

  if (transaction.type == PersonalTransactionType.expense) {
    await accountNotifier.adjustBalance(personal.id, -transaction.amount);
    await ledgerNotifier.addLedgerEntry(LedgerEntry(
      id: 'led_personal_expense_${DateTime.now().millisecondsSinceEpoch}',
      date: date,
      accountId: personal.id,
      accountName: personal.name,
      type: 'Credit',
      category: 'Other Expense',
      amount: transaction.amount,
      reference: reference,
      description: transaction.description.isEmpty
          ? 'Other personal expense logged'
          : transaction.description,
    ));
    return;
  }

  final companyId = transaction.companyAccountId!;
  final company = accounts.firstWhere((a) => a.id == companyId);
  final personalToCompany = transaction.direction == PersonalTransferDirection.personalToCompany;
  final source = personalToCompany ? personal : company;
  final destination = personalToCompany ? company : personal;

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

Future<PersonalAccountTransaction?> showPersonalAccountTransactionDialog(
  BuildContext context, {
  String? personalAccountId,
}) {
  return showDialog<PersonalAccountTransaction>(
    context: context,
    builder: (context) => _PersonalAccountTransactionDialog(
      personalAccountId: personalAccountId,
    ),
  );
}

class _PersonalAccountTransactionDialog extends ConsumerStatefulWidget {
  final String? personalAccountId;

  const _PersonalAccountTransactionDialog({this.personalAccountId});

  @override
  ConsumerState<_PersonalAccountTransactionDialog> createState() => _PersonalAccountTransactionDialogState();
}

class _PersonalAccountTransactionDialogState extends ConsumerState<_PersonalAccountTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  PersonalTransactionType _type = PersonalTransactionType.deposit;
  PersonalTransferDirection _direction = PersonalTransferDirection.companyToPersonal;
  PersonalToPersonalDirection _personalTransferDirection = PersonalToPersonalDirection.sendTo;
  String? _personalAccountId;
  String? _companyAccountId;
  String? _targetPersonalAccountId;
  final DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _personalAccountId = widget.personalAccountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).accounts.where((a) => a.status == 'Active').toList();
    final personalAccounts = accounts.where((a) => a.isPersonal).toList();
    final companyAccounts = accounts.where((a) => a.isCompany).toList();
    final personalId = personalAccounts.any((a) => a.id == _personalAccountId)
        ? _personalAccountId
        : personalAccounts.firstOrNull?.id;
    final selectedAccount = personalAccounts.where((a) => a.id == personalId).firstOrNull;
    final otherPersonalAccounts = personalAccounts.where((a) => a.id != personalId).toList();
    final dialogTitle = selectedAccount != null
        ? (selectedAccount.ownerName.isNotEmpty && selectedAccount.ownerName != selectedAccount.name
            ? '${selectedAccount.ownerName} Personal Account'
            : (selectedAccount.name.toLowerCase().contains('personal account')
                ? selectedAccount.name
                : '${selectedAccount.name} Personal Account'))
        : 'Personal Account Transaction';

    return AlertDialog(
      title: Text(dialogTitle),
      content: Container(
        width: MediaQuery.of(context).size.width < 500 ? double.infinity : 480,
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<PersonalTransactionType>(
                  isExpanded: true,
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Transaction Type'),
                  items: [
                    const DropdownMenuItem(
                        value: PersonalTransactionType.deposit,
                        child: Text('Personal Deposit')),
                    const DropdownMenuItem(
                        value: PersonalTransactionType.transfer,
                        child: Text('Company / Personal Transfer')),
                    const DropdownMenuItem(
                        value: PersonalTransactionType.personalTransfer,
                        child: Text('Personal Account Transfer')),
                  ],
                  onChanged: (value) => setState(() => _type = value!),
                ),
                if (_type == PersonalTransactionType.personalTransfer) ...[
                  const SizedBox(height: 12),
                  if (otherPersonalAccounts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.warningLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.warning),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: context.warning),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'No other personal accounts found. Create another personal account in Finance > Accounts first.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SegmentedButton<PersonalToPersonalDirection>(
                        segments: const [
                          ButtonSegment(
                            value: PersonalToPersonalDirection.sendTo,
                            icon: Icon(Icons.arrow_upward, size: 16),
                            label: Text('Transfer To'),
                          ),
                          ButtonSegment(
                            value: PersonalToPersonalDirection.receiveFrom,
                            icon: Icon(Icons.arrow_downward, size: 16),
                            label: Text('Receive From'),
                          ),
                        ],
                        selected: {_personalTransferDirection},
                        onSelectionChanged: (value) =>
                            setState(() => _personalTransferDirection = value.first),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: otherPersonalAccounts.any((a) => a.id == _targetPersonalAccountId)
                          ? _targetPersonalAccountId
                          : null,
                      decoration: InputDecoration(
                        labelText: _personalTransferDirection == PersonalToPersonalDirection.sendTo
                            ? 'Transfer to Personal Account'
                            : 'Receive from Personal Account',
                      ),
                      items: otherPersonalAccounts.map((account) {
                        final label = account.ownerName.isNotEmpty && account.ownerName != account.name
                            ? '${account.ownerName} (${account.name})'
                            : account.name;
                        return DropdownMenuItem(value: account.id, child: Text(label));
                      }).toList(),
                      validator: (value) => _type == PersonalTransactionType.personalTransfer && value == null
                          ? (_personalTransferDirection == PersonalToPersonalDirection.sendTo
                              ? 'Select recipient personal account'
                              : 'Select source personal account')
                          : null,
                      onChanged: (value) => setState(() => _targetPersonalAccountId = value),
                    ),
                  ],
                ],
                if (_type == PersonalTransactionType.transfer) ...[
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SegmentedButton<PersonalTransferDirection>(
                      segments: const [
                        ButtonSegment(
                            value: PersonalTransferDirection.companyToPersonal,
                            label: Text('Company to Personal')),
                        ButtonSegment(
                            value: PersonalTransferDirection.personalToCompany,
                            label: Text('Personal to Company')),
                      ],
                      selected: {_direction},
                      onSelectionChanged: (value) =>
                          setState(() => _direction = value.first),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: companyAccounts
                            .any((a) => a.id == _companyAccountId)
                        ? _companyAccountId
                        : null,
                    decoration:
                        const InputDecoration(labelText: 'Company Account'),
                    items: companyAccounts
                        .map((account) => DropdownMenuItem(
                            value: account.id, child: Text(account.name)))
                        .toList(),
                    validator: (value) =>
                        _type == PersonalTransactionType.transfer &&
                                value == null
                            ? 'Select company account'
                            : null,
                    onChanged: (value) =>
                        setState(() => _companyAccountId = value),
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
                    labelText: _type == PersonalTransactionType.expense
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
              PersonalAccountTransaction(
                type: _type,
                direction: _direction,
                personalToPersonalDirection: _personalTransferDirection,
                personalAccountId: personalId ?? _personalAccountId!,
                companyAccountId: _companyAccountId,
                targetPersonalAccountId: _targetPersonalAccountId,
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