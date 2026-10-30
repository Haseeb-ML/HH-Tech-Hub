import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _commaFormatter = NumberFormat('#,##0');
  static final NumberFormat _decimalFormatter = NumberFormat('#,##0.00');

  /// Formats an amount with commas, e.g. 20,130
  static String formatAmount(num amount, {bool withDecimals = false}) {
    if (withDecimals) {
      return _decimalFormatter.format(amount);
    }
    return _commaFormatter.format(amount.round());
  }

  /// Formats an amount with 'Rs. ' prefix and commas, e.g. 'Rs. 20,130'
  static String formatCurrency(num amount, {bool withDecimals = false}) {
    return 'Rs. ${formatAmount(amount, withDecimals: withDecimals)}';
  }

  /// Formats an accounting balance without minus sign:
  /// - Positive (> 0): "Rs. 6,789 (Dr)"
  /// - Negative (< 0): "Rs. 6,789 (Cr)"
  /// - Zero (= 0): "Rs. 0"
  static String formatAccountingBalance(double balance, {bool showDr = true, bool withDecimals = false}) {
    if (balance == 0) return withDecimals ? 'Rs. 0.00' : 'Rs. 0';
    final absVal = formatAmount(balance.abs(), withDecimals: withDecimals);
    if (balance < 0) {
      return 'Rs. $absVal (Cr)';
    } else {
      return showDr ? 'Rs. $absVal (Dr)' : 'Rs. $absVal';
    }
  }

  /// Returns '(Cr)' if negative, '(Dr)' if positive, and '' if zero
  static String getDrCrTag(double balance) {
    if (balance == 0) return '';
    return balance < 0 ? '(Cr)' : '(Dr)';
  }
}
