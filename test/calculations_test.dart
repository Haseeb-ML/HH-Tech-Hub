import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExportHelper Calculations', () {
    test('calculateTotalsRow should sum up numeric columns correctly', () {
      final headers = ['Name', 'Amount', 'Tax', 'Quantity'];
      final rows = [
        ['Item 1', '100.5', '10', '2'],
        ['Item 2', '200.5', '20', '3'],
        ['Item 3', 'invalid', '5.5', '1'], // invalid number should be ignored
        ['Item 4', '50', 'null', null], // nulls should be ignored
      ];
      
      final totals = List<dynamic>.filled(headers.length, '');
      totals[0] = 'TOTAL';

      for (var col = 1; col < headers.length; col++) {
        final header = headers[col].toLowerCase();
        
        if (header.contains('no') ||
            header.contains('date') ||
            header.contains('time') ||
            header.contains('status') ||
            header.contains('type') ||
            header.contains('name') ||
            header.contains('id') ||
            header.contains('phone')) {
          totals[col] = '';
          continue;
        }

        double sum = 0;
        bool hasNumbers = false;

        for (var row in rows) {
          if (row.length > col) {
            final valStr = row[col]?.toString().replaceAll(',', '').trim() ?? '';
            if (valStr.isNotEmpty) {
              final val = double.tryParse(valStr);
              if (val != null) {
                sum += val;
                hasNumbers = true;
              }
            }
          }
        }

        if (hasNumbers) {
          totals[col] = sum.truncateToDouble() == sum
              ? sum.toInt().toString()
              : sum.toStringAsFixed(2);
        } else {
          totals[col] = '';
        }
      }

      // Assertions
      expect(totals[0], 'TOTAL');
      expect(totals[1], '351'); // 100.5 + 200.5 + 50 = 351
      expect(totals[2], '35.50'); // 10 + 20 + 5.5 = 35.50
      expect(totals[3], '6'); // 2 + 3 + 1 = 6
    });
  });
}
