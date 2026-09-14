import 'dart:core';
class LedgerEntry {
  final String id;
  final String date;
  final String type;
  LedgerEntry({required this.id, required this.date, required this.type});
}

void main() {
  final uniqueStaticEntries = <LedgerEntry>[];
  final realIncomeEntries = [
    LedgerEntry(id: 'led_inc_inc_1725000000001', date: '2026-09-04', type: 'Debit'),
    LedgerEntry(id: 'led_inc_inc_1725000000002', date: '2026-09-04', type: 'Debit'),
  ];
  final realExpenseEntries = [
    LedgerEntry(id: 'led_exp_exp_1725000000003', date: '2026-09-04', type: 'Credit'),
    LedgerEntry(id: 'led_exp_exp_1725000000004', date: '2026-09-04', type: 'Credit'),
  ];

  final allEntries = [...uniqueStaticEntries, ...realIncomeEntries, ...realExpenseEntries];

  allEntries.sort((a, b) {
    try {
      final dateA = DateTime.parse(a.date);
      final dateB = DateTime.parse(b.date);
      final cmp = dateB.compareTo(dateA);
      if (cmp != 0) return cmp;
    } catch (_) {
      final cmp = b.date.compareTo(a.date);
      if (cmp != 0) return cmp;
    }
    final aStr = a.id.replaceAll(RegExp(r'[^0-9]'), '');
    final bStr = b.id.replaceAll(RegExp(r'[^0-9]'), '');
    final aNum = BigInt.tryParse(aStr) ?? BigInt.zero;
    final bNum = BigInt.tryParse(bStr) ?? BigInt.zero;
    return bNum.compareTo(aNum);
  });

  for (var e in allEntries) {
    print('${e.type} - ${e.id}');
  }
}
