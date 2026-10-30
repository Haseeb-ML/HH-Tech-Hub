class CurrencyFormatter {
  /// Formats an accounting balance without minus sign:
  /// - Positive (> 0): "Rs. 6789 (Dr)"
  /// - Negative (< 0): "Rs. 6789 (Cr)"
  /// - Zero (= 0): "Rs. 0"
  static String formatAccountingBalance(double balance, {bool showDr = true, bool withDecimals = false}) {
    if (balance == 0) return withDecimals ? 'Rs. 0.00' : 'Rs. 0';
    final absVal = withDecimals
        ? balance.abs().toStringAsFixed(2)
        : balance.abs().toStringAsFixed(0);
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
