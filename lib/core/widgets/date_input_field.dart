import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Automatically inserts `-` separators as the user types a `dd-mm-yyyy` date.
class AutoDateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) {
      if ((oldValue.text.endsWith('-') || oldValue.text.endsWith('/')) &&
          newValue.text.length == oldValue.text.length - 1) {
        final text = newValue.text.substring(0, newValue.text.length - 1);
        return TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
      return newValue;
    }

    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final limited = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();

    for (int i = 0; i < limited.length; i++) {
      buffer.write(limited[i]);
      if ((i == 1 || i == 3) && i != limited.length - 1) {
        buffer.write('-');
      }
    }

    if (limited.length == 2 || limited.length == 4) {
      buffer.write('-');
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// A reusable date form field supporting both auto-dashed `dd-mm-yyyy` typing
/// and a calendar date picker button.
class DateInputField extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateChanged;
  final String labelText;

  const DateInputField({
    super.key,
    required this.initialDate,
    required this.onDateChanged,
    this.labelText = 'Date (dd-mm-yyyy)',
  });

  @override
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  static final DateFormat _displayFormat = DateFormat('dd-MM-yyyy');
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _displayFormat.format(widget.initialDate),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime? _parseStrictDate(String raw) {
    final normalized = raw.trim().replaceAll('/', '-');
    final match = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(normalized);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (year < 2000 || year > 2100) return null;

    final candidate = DateTime(year, month, day);
    if (candidate.year != year || candidate.month != month || candidate.day != day) {
      return null;
    }

    final now = DateTime.now();
    final isToday = year == now.year && month == now.month && day == now.day;
    return DateTime(
      year,
      month,
      day,
      isToday ? now.hour : 12,
      isToday ? now.minute : 0,
      isToday ? now.second : 0,
    );
  }

  Future<void> _pickDate() async {
    final current = _parseStrictDate(_controller.text) ?? widget.initialDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      final now = DateTime.now();
      final isToday =
          picked.year == now.year && picked.month == now.month && picked.day == now.day;
      final fullDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        isToday ? now.hour : 12,
        isToday ? now.minute : 0,
        isToday ? now.second : 0,
      );
      setState(() {
        _controller.text = _displayFormat.format(fullDate);
      });
      widget.onDateChanged(fullDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.datetime,
      inputFormatters: [AutoDateTextFormatter()],
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: 'dd-mm-yyyy (e.g. 13-11-2026)',
        suffixIcon: IconButton(
          tooltip: 'Pick Date from Calendar',
          icon: const Icon(Icons.calendar_month_outlined, size: 20),
          onPressed: _pickDate,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter date in dd-mm-yyyy format';
        }
        if (_parseStrictDate(value) == null) {
          return 'Enter valid date (dd-mm-yyyy)';
        }
        return null;
      },
      onChanged: (value) {
        final parsed = _parseStrictDate(value);
        if (parsed != null) {
          widget.onDateChanged(parsed);
        }
      },
    );
  }
}
