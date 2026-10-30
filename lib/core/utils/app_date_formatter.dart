import 'package:intl/intl.dart';

class AppDateFormatter {
  static final DateFormat _dateFormat = DateFormat('dd-MM-yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd-MM-yyyy, hh:mm a');

  /// Formats a DateTime object into 'dd-MM-yyyy' (e.g. 30-10-2026)
  static String format(DateTime? date) {
    if (date == null) return '';
    return _dateFormat.format(date);
  }

  /// Formats a DateTime object into 'dd-MM-yyyy, hh:mm a'
  static String formatWithTime(DateTime? date) {
    if (date == null) return '';
    return _dateTimeFormat.format(date);
  }

  /// Formats any string date representation (ISO 8601, yyyy-MM-dd, dd/MM/yyyy, etc.) into 'dd-MM-yyyy'
  static String formatString(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return '';
    final trimmed = dateStr.trim();
    try {
      // If already in dd-MM-yyyy format
      final ddMmYyyyRegex = RegExp(r'^(\d{2})-(\d{2})-(\d{4})');
      final match = ddMmYyyyRegex.firstMatch(trimmed);
      if (match != null) {
        return '${match.group(1)}-${match.group(2)}-${match.group(3)}';
      }

      // Try DateTime.tryParse (handles ISO strings like 2026-10-30T12:00:00Z and 2026-10-30)
      final parsed = DateTime.tryParse(trimmed);
      if (parsed != null) {
        return _dateFormat.format(parsed);
      }

      // Handle slash separated formats
      final partsSlash = trimmed.split('/');
      if (partsSlash.length == 3) {
        if (partsSlash[0].length == 4) {
          // yyyy/MM/dd
          final y = int.parse(partsSlash[0]);
          final m = int.parse(partsSlash[1]);
          final d = int.parse(partsSlash[2].split(' ')[0]);
          return _dateFormat.format(DateTime(y, m, d));
        } else {
          // dd/MM/yyyy
          final d = int.parse(partsSlash[0]);
          final m = int.parse(partsSlash[1]);
          final y = int.parse(partsSlash[2].split(' ')[0]);
          return _dateFormat.format(DateTime(y, m, d));
        }
      }

      // Handle dash separated formats
      final partsDash = trimmed.split('-');
      if (partsDash.length == 3 && partsDash[0].length == 4) {
        // yyyy-MM-dd
        final y = int.parse(partsDash[0]);
        final m = int.parse(partsDash[1]);
        final d = int.parse(partsDash[2].split('T')[0].split(' ')[0]);
        return _dateFormat.format(DateTime(y, m, d));
      }
    } catch (_) {}
    return trimmed;
  }
}
