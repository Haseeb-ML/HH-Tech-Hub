import 'dart:io';
import 'package:excel/excel.dart' as ex;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../features/hr/employees/domain/entities/employee.dart';
import '../../features/hr/salaries/domain/entities/salary_record.dart';
import '../../features/hr/attendance/domain/entities/attendance_record.dart';
import '../../features/finance/accounts/domain/entities/bank_account.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class ExportHelper {
  static List<Map<String, dynamic>> sortTransactionsNewestFirst(
    List<Map<String, dynamic>> transactions,
  ) {
    final sorted = List<Map<String, dynamic>>.from(transactions);
    sorted.sort((a, b) {
      final dateA = _effectiveSortDate(a['date'], a['sortKey'] ?? a['id']);
      final dateB = _effectiveSortDate(b['date'], b['sortKey'] ?? b['id']);
      final dateCmp = dateB.compareTo(dateA);
      if (dateCmp != 0) return dateCmp;

      final aKey = (a['sortKey'] ?? a['id'] ?? a['ref'] ?? '').toString();
      final bKey = (b['sortKey'] ?? b['id'] ?? b['ref'] ?? '').toString();
      final aNum = _numericKey(aKey);
      final bNum = _numericKey(bKey);
      final numericCmp = bNum.compareTo(aNum);
      if (numericCmp != 0) return numericCmp;
      return bKey.compareTo(aKey);
    });
    return sorted;
  }

  static List<Map<String, dynamic>> sortTransactionsOldestFirst(
    List<Map<String, dynamic>> transactions,
  ) {
    final sorted = List<Map<String, dynamic>>.from(transactions);
    sorted.sort((a, b) {
      final dateA = _effectiveSortDate(a['date'], a['sortKey'] ?? a['id']);
      final dateB = _effectiveSortDate(b['date'], b['sortKey'] ?? b['id']);
      final dateCmp = dateA.compareTo(dateB);
      if (dateCmp != 0) return dateCmp;

      final aKey = (a['sortKey'] ?? a['id'] ?? a['ref'] ?? '').toString();
      final bKey = (b['sortKey'] ?? b['id'] ?? b['ref'] ?? '').toString();
      final aNum = _numericKey(aKey);
      final bNum = _numericKey(bKey);
      final numericCmp = aNum.compareTo(bNum);
      if (numericCmp != 0) return numericCmp;
      return aKey.compareTo(bKey);
    });
    return sorted;
  }

  static BigInt _numericKey(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return BigInt.zero;
    return BigInt.tryParse(digits) ?? BigInt.zero;
  }

  static DateTime _normalizeDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        final normalized = value.replaceFirst(' ', 'T');
        try {
          return DateTime.parse(normalized);
        } catch (_) {
          return DateTime.fromMillisecondsSinceEpoch(0);
        }
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime _effectiveSortDate(dynamic dateValue, dynamic keyValue) {
    final baseDate = _normalizeDate(dateValue);
    final key = (keyValue ?? '').toString();
    final digits = key.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 13) {
      final parsedEpoch = int.tryParse(digits.substring(digits.length - 13));
      if (parsedEpoch != null) {
        final derived = DateTime.fromMillisecondsSinceEpoch(parsedEpoch);
        if (derived.year > 1970) {
          return derived;
        }
      }
    }
    return baseDate;
  }

  /// Save Excel workbook with automatic total calculation for numeric columns
  static Future<String> exportToExcel({
    required String fileName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    final excel = ex.Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];

    // Elegant header style: bold, dark indigo text, light lavender/indigo background, thin borders
    final headerStyle = ex.CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ex.ExcelColor.fromHexString('#312E81'), // Dark Indigo
      backgroundColorHex: ex.ExcelColor.fromHexString('#E0E7FF'), // Indigo 100
      horizontalAlign: ex.HorizontalAlign.Left,
      leftBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#CBD5E1'),
      ),
      rightBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#CBD5E1'),
      ),
      topBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#CBD5E1'),
      ),
      bottomBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#CBD5E1'),
      ),
    );

    // Elegant odd row style: slate 800 text, white background, very light borders
    final oddRowStyle = ex.CellStyle(
      fontSize: 10,
      fontColorHex: ex.ExcelColor.fromHexString('#1E293B'), // Slate 800
      backgroundColorHex: ex.ExcelColor.fromHexString('#FFFFFF'),
      leftBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#E2E8F0'),
      ),
      rightBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#E2E8F0'),
      ),
      topBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#E2E8F0'),
      ),
      bottomBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#E2E8F0'),
      ),
    );

    // Elegant even row style: slate 800 text, very light violet background, very light borders
    final evenRowStyle = ex.CellStyle(
      fontSize: 10,
      fontColorHex: ex.ExcelColor.fromHexString('#1E293B'), // Slate 800
      backgroundColorHex: ex.ExcelColor.fromHexString(
        '#F5F3FF',
      ), // Purple 50 (light colorful layout)
      leftBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#E2E8F0'),
      ),
      rightBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#E2E8F0'),
      ),
      topBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#E2E8F0'),
      ),
      bottomBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#E2E8F0'),
      ),
    );

    // Elegant total row style: bold, slate 800 text, slate 100 background, double bottom border (accounting standard)
    final totalsRowStyle = ex.CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ex.ExcelColor.fromHexString('#1F2937'), // Slate 900
      backgroundColorHex: ex.ExcelColor.fromHexString('#F1F5F9'), // Slate 100
      leftBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#CBD5E1'),
      ),
      rightBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#CBD5E1'),
      ),
      topBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#94A3B8'),
      ), // Darker top border
      bottomBorder: ex.Border(
        borderStyle: ex.BorderStyle.Double,
        borderColorHex: ex.ExcelColor.fromHexString('#94A3B8'),
      ), // Double underline bottom border
    );

    // Write headers
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(
        ex.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.value = ex.TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    // Write rows
    for (var rowIdx = 0; rowIdx < rows.length; rowIdx++) {
      final rowData = rows[rowIdx];
      final rowStyle = (rowIdx % 2 == 0) ? evenRowStyle : oddRowStyle;
      for (var colIdx = 0; colIdx < rowData.length; colIdx++) {
        final cell = sheet.cell(
          ex.CellIndex.indexByColumnRow(
            columnIndex: colIdx,
            rowIndex: rowIdx + 1,
          ),
        );
        cell.value = ex.TextCellValue(rowData[colIdx]?.toString() ?? '');
        cell.cellStyle = rowStyle;
      }
    }

    // Calculate and write totals row
    final totalsRow = _calculateTotalsRow(headers, rows);
    final hasTotals = totalsRow.any(
      (val) =>
          val != null && val.toString().isNotEmpty && val.toString() != 'TOTAL',
    );

    if (hasTotals) {
      final totalRowIdx = rows.length + 1;
      for (var colIdx = 0; colIdx < totalsRow.length; colIdx++) {
        final cell = sheet.cell(
          ex.CellIndex.indexByColumnRow(
            columnIndex: colIdx,
            rowIndex: totalRowIdx,
          ),
        );
        cell.value = ex.TextCellValue(totalsRow[colIdx]?.toString() ?? '');
        cell.cellStyle = totalsRowStyle;
      }
    }

    // Set custom column widths based on longest cell content
    for (var colIdx = 0; colIdx < headers.length; colIdx++) {
      var maxLen = headers[colIdx].length;
      for (var rowIdx = 0; rowIdx < rows.length; rowIdx++) {
        final valLen = rows[rowIdx][colIdx]?.toString().length ?? 0;
        if (valLen > maxLen) maxLen = valLen;
      }
      if (hasTotals) {
        final totalValLen = totalsRow[colIdx]?.toString().length ?? 0;
        if (totalValLen > maxLen) maxLen = totalValLen;
      }
      sheet.setColumnWidth(colIdx, (maxLen + 4).toDouble());
    }

    final downloadsDir =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final filePath = p.join(downloadsDir.path, '$fileName.xlsx');
    final fileBytes = excel.save();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
    }
    return filePath;
  }

  /// Save PDF document with automatic total calculation for numeric columns
  static Future<String> exportToPdf({
    required String title,
    required String fileName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    final pdf = pw.Document();

    final primaryColor = PdfColor.fromHex('#4F46E5'); // Indigo 600
    final textColor = PdfColor.fromHex('#1E293B'); // Slate 800
    final headerBg = PdfColor.fromHex('#4338CA'); // Indigo 700
    final accentColor = PdfColor.fromHex('#6366F1'); // Indigo 500
    final lightBg = PdfColor.fromHex('#F8FAFC'); // Slate 50
    final greyBorder = PdfColor.fromHex('#CBD5E1'); // Slate 300
    final lightBorder = PdfColor.fromHex('#E2E8F0'); // Slate 200

    // Prepare PDF rows and calculate totals
    final pdfRows = rows
        .map((row) => row.map((cell) => cell?.toString() ?? '').toList())
        .toList();
    final totalsRow = _calculateTotalsRow(headers, rows);
    final hasTotals = totalsRow.any(
      (val) =>
          val != null && val.toString().isNotEmpty && val.toString() != 'TOTAL',
    );

    if (hasTotals) {
      pdfRows.add(totalsRow.map((cell) => cell?.toString() ?? '').toList());
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 4,
                      height: 36,
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(2),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          title.toUpperCase(),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                            color: textColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'HH TECH HUB ERP SYSTEM • OFFICIAL REPORT',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            color: accentColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'HH TECH HUB',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: headerBg,
                      ),
                    ),
                    pw.Text(
                      'https://hhtechhub.com',
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: greyBorder, thickness: 0.5),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Column(
            children: [
              pw.Divider(color: lightBorder, thickness: 0.5),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Confidential - Generated via HH Tech Hub ERP System',
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey500,
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        build: (context) => [
          // Elegant Metadata block
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: lightBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: lightBorder, width: 0.5),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'REPORT GENERATED ON',
                      style: pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.grey500,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      '${DateTime.now().toLocal().toString().substring(0, 19)}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: textColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DOCUMENT CLASSIFICATION',
                      style: pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.grey500,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      'Confidential • Internal Use Only',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: textColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TOTAL RECORDS',
                      style: pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.grey500,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      '${rows.length}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: textColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Clean professional table
          pw.Table.fromTextArray(
            headers: headers,
            data: pdfRows,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: headerBg),
            cellStyle: pw.TextStyle(fontSize: 7.5, color: textColor),
            cellHeight: 26,
            cellAlignments: {
              for (var i = 0; i < headers.length; i++)
                i: pw.Alignment.centerLeft,
            },
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
            oddRowDecoration: pw.BoxDecoration(color: lightBg),
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: lightBorder, width: 0.5),
              bottom: pw.BorderSide(color: greyBorder, width: 0.8),
            ),
          ),
        ],
      ),
    );

    final downloadsDir =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final filePath = p.join(downloadsDir.path, '$fileName.pdf');
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return filePath;
  }

  /// Open file natively in Windows
  static Future<void> openFile(String filePath) async {
    if (Platform.isWindows) {
      await Process.run('cmd', [
        '/c',
        'start',
        '""',
        filePath,
      ], runInShell: true);
    }
  }

  /// Calculate totals row automatically for numeric columns
  static List<dynamic> _calculateTotalsRow(
    List<String> headers,
    List<List<dynamic>> rows,
  ) {
    final totals = List<dynamic>.filled(headers.length, '');
    totals[0] = 'TOTAL';

    for (var col = 1; col < headers.length; col++) {
      final header = headers[col].toLowerCase();

      // Determine if this column should be summed
      final shouldSum =
          (header.contains('salary') ||
              header.contains('amount') ||
              header.contains('budget') ||
              header.contains('revenue') ||
              header.contains('value') ||
              header.contains('cost') ||
              header.contains('price') ||
              header.contains('quantity') ||
              header.contains('projects') ||
              header.contains('outflow') ||
              header.contains('inflow')) &&
          !header.contains('id') &&
          !header.contains('phone') &&
          !header.contains('date') &&
          !header.contains('email') &&
          !header.contains('code') &&
          !header.contains('number') &&
          !header.contains('no.') &&
          !header.contains('status') &&
          !header.contains('method') &&
          !header.contains('designation') &&
          !header.contains('department') &&
          !header.contains('name') &&
          !header.contains('industry') &&
          !header.contains('person') &&
          !header.contains('category') &&
          !header.contains('vendor') &&
          !header.contains('type');

      if (!shouldSum) continue;

      double sum = 0;
      bool hasNumeric = false;
      String prefix = '';
      int decimalPlaces = 0;

      for (var r = 0; r < rows.length; r++) {
        final val = rows[r][col];
        if (val == null) continue;

        final valStr = val.toString().trim();
        if (valStr.isEmpty) continue;

        // Detect prefix
        if (prefix.isEmpty) {
          if (valStr.toUpperCase().startsWith('RS.')) {
            prefix = 'Rs. ';
          } else if (valStr.startsWith('\$')) {
            prefix = '\$';
          }
        }

        // Detect decimal places
        if (decimalPlaces == 0 && valStr.contains('.')) {
          final parts = valStr.split('.');
          if (parts.length > 1) {
            final decimalPart = parts[1].replaceAll(RegExp(r'[^\d]'), '');
            decimalPlaces = decimalPart.length;
          }
        }

        // Parse numeric value
        final parsed = _parseNumericValue(valStr);
        if (parsed != null) {
          sum += parsed;
          hasNumeric = true;
        }
      }

      if (hasNumeric) {
        if (decimalPlaces == 0) {
          totals[col] = '$prefix${sum.toStringAsFixed(0)}';
        } else {
          totals[col] =
              '$prefix${sum.toStringAsFixed(decimalPlaces > 2 ? 2 : decimalPlaces)}';
        }
      }
    }

    return totals;
  }

  /// Helper to parse clean double from formatted string (handles RS., $, commas, units like rims/pcs)
  static double? _parseNumericValue(String input) {
    var clean = input.replaceAll(',', '').trim();
    if (clean.toUpperCase().startsWith('RS.')) {
      clean = clean.substring(3).trim();
    } else if (clean.startsWith('\$')) {
      clean = clean.substring(1).trim();
    }
    // Extract first number match
    final match = RegExp(r'^-?\d+(?:\.\d+)?').firstMatch(clean);
    if (match != null) {
      return double.tryParse(match.group(0)!);
    }
    return double.tryParse(clean);
  }

  /// Custom Excel export for an employee's detailed lifecycle history
  static Future<String> exportEmployeeHistoryToExcel({
    required String fileName,
    required Employee employee,
    required List<SalaryRecord> salaries,
    required List<AttendanceRecord> attendance,
    required Map<String, dynamic> attendanceStats,
  }) async {
    final excel = ex.Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];

    // Elegant header styles
    final headerStyle = ex.CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ex.ExcelColor.fromHexString('#312E81'), // Dark Indigo
      backgroundColorHex: ex.ExcelColor.fromHexString('#E0E7FF'), // Indigo 100
      horizontalAlign: ex.HorizontalAlign.Left,
      leftBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#CBD5E1'),
      ),
      rightBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#CBD5E1'),
      ),
      topBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#CBD5E1'),
      ),
      bottomBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#CBD5E1'),
      ),
    );

    final oddRowStyle = ex.CellStyle(
      fontSize: 10,
      fontColorHex: ex.ExcelColor.fromHexString('#1E293B'), // Slate 800
      backgroundColorHex: ex.ExcelColor.fromHexString('#FFFFFF'),
      leftBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#E2E8F0'),
      ),
      rightBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#E2E8F0'),
      ),
      topBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#E2E8F0'),
      ),
      bottomBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#E2E8F0'),
      ),
    );

    final evenRowStyle = ex.CellStyle(
      fontSize: 10,
      fontColorHex: ex.ExcelColor.fromHexString('#1E293B'), // Slate 800
      backgroundColorHex: ex.ExcelColor.fromHexString('#F5F3FF'), // Purple 50
      leftBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#E2E8F0'),
      ),
      rightBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#E2E8F0'),
      ),
      topBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#E2E8F0'),
      ),
      bottomBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#E2E8F0'),
      ),
    );

    final totalsRowStyle = ex.CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ex.ExcelColor.fromHexString('#1F2937'), // Slate 900
      backgroundColorHex: ex.ExcelColor.fromHexString('#F1F5F9'), // Slate 100
      leftBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#CBD5E1'),
      ),
      rightBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#CBD5E1'),
      ),
      topBorder: ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: ex.ExcelColor.fromHexString('#94A3B8'),
      ), // Darker top border
      bottomBorder: ex.Border(
        borderStyle: ex.BorderStyle.Double,
        borderColorHex: ex.ExcelColor.fromHexString('#94A3B8'),
      ), // Double underline bottom border
    );

    final sectionHeaderStyle = ex.CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ex.ExcelColor.fromHexString('#312E81'),
      backgroundColorHex: ex.ExcelColor.fromHexString('#E0E7FF'),
    );

    final labelStyle = ex.CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ex.ExcelColor.fromHexString('#475569'), // Slate 600
    );

    final valueStyle = ex.CellStyle(
      fontSize: 10,
      fontColorHex: ex.ExcelColor.fromHexString('#1E293B'), // Slate 800
    );

    int rowIdx = 0;

    // Report Title
    final titleCell = sheet.cell(
      ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
    );
    titleCell.value = ex.TextCellValue('EMPLOYEE LIFECYCLE & HISTORY REPORT');
    titleCell.cellStyle = ex.CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ex.ExcelColor.fromHexString('#312E81'),
    );
    rowIdx += 2;

    // Helper to write label & value
    void writeLabelValue(
      int r,
      int labelCol,
      String label,
      int valueCol,
      String value,
    ) {
      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: labelCol, rowIndex: r),
        )
        ..value = ex.TextCellValue(label)
        ..cellStyle = labelStyle;

      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: valueCol, rowIndex: r),
        )
        ..value = ex.TextCellValue(value)
        ..cellStyle = valueStyle;
    }

    // 1. Employee Profile Details Section
    sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx))
      ..value = ex.TextCellValue('EMPLOYEE PROFILE DETAILS')
      ..cellStyle = sectionHeaderStyle;
    rowIdx++;

    writeLabelValue(rowIdx, 0, 'Employee ID:', 1, employee.id);
    writeLabelValue(rowIdx, 3, 'Employee Name:', 4, employee.name);
    rowIdx++;
    writeLabelValue(rowIdx, 0, 'Designation:', 1, employee.designation);
    writeLabelValue(rowIdx, 3, 'Department:', 4, employee.department);
    rowIdx++;
    writeLabelValue(rowIdx, 0, 'Joining Date:', 1, employee.joiningDate);
    writeLabelValue(
      rowIdx,
      3,
      'Leaving Date:',
      4,
      employee.leavingDate ?? 'Present / Active',
    );
    rowIdx++;
    writeLabelValue(rowIdx, 0, 'Status:', 1, employee.status);
    writeLabelValue(
      rowIdx,
      3,
      'Base Salary:',
      4,
      'Rs. ${employee.baseSalary.toStringAsFixed(0)}',
    );
    rowIdx++;
    writeLabelValue(rowIdx, 0, 'Payment Method:', 1, employee.paymentMethod);
    writeLabelValue(rowIdx, 3, 'Email Address:', 4, employee.email);
    rowIdx += 2;

    // 2. Salary History Section
    sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx))
      ..value = ex.TextCellValue('SALARY PAYMENT HISTORY')
      ..cellStyle = sectionHeaderStyle;
    rowIdx += 2;

    final salaryHeaders = [
      'Pay Period',
      'Base Salary',
      'Allowances',
      'Deductions',
      'Net Paid',
      'Payment Date',
      'Payment Method',
      'Status',
    ];
    for (int i = 0; i < salaryHeaders.length; i++) {
      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIdx),
        )
        ..value = ex.TextCellValue(salaryHeaders[i])
        ..cellStyle = headerStyle;
    }
    rowIdx++;

    double totalBase = 0;
    double totalAllowances = 0;
    double totalDeductions = 0;
    double totalNetPaid = 0;

    for (var sal in salaries) {
      final rowStyle = (rowIdx % 2 == 0) ? evenRowStyle : oddRowStyle;

      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
        )
        ..value = ex.TextCellValue(sal.payPeriod)
        ..cellStyle = rowStyle;
      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx),
        )
        ..value = ex.TextCellValue('Rs. ${sal.baseSalary.toStringAsFixed(0)}')
        ..cellStyle = rowStyle;
      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx),
        )
        ..value = ex.TextCellValue('Rs. ${sal.allowances.toStringAsFixed(0)}')
        ..cellStyle = rowStyle;
      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx),
        )
        ..value = ex.TextCellValue('Rs. ${sal.deductions.toStringAsFixed(0)}')
        ..cellStyle = rowStyle;
      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx),
        )
        ..value = ex.TextCellValue('Rs. ${sal.netPaid.toStringAsFixed(0)}')
        ..cellStyle = rowStyle;
      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIdx),
        )
        ..value = ex.TextCellValue(sal.paymentDate)
        ..cellStyle = rowStyle;
      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIdx),
        )
        ..value = ex.TextCellValue(sal.paymentMethod)
        ..cellStyle = rowStyle;
      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIdx),
        )
        ..value = ex.TextCellValue(sal.status)
        ..cellStyle = rowStyle;

      totalBase += sal.baseSalary;
      totalAllowances += sal.allowances;
      totalDeductions += sal.deductions;
      totalNetPaid += sal.netPaid;
      rowIdx++;
    }

    // Totals row for salaries
    sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx))
      ..value = ex.TextCellValue('TOTAL PAID')
      ..cellStyle = totalsRowStyle;
    sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx))
      ..value = ex.TextCellValue('Rs. ${totalBase.toStringAsFixed(0)}')
      ..cellStyle = totalsRowStyle;
    sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx))
      ..value = ex.TextCellValue('Rs. ${totalAllowances.toStringAsFixed(0)}')
      ..cellStyle = totalsRowStyle;
    sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx))
      ..value = ex.TextCellValue('Rs. ${totalDeductions.toStringAsFixed(0)}')
      ..cellStyle = totalsRowStyle;
    sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx))
      ..value = ex.TextCellValue('Rs. ${totalNetPaid.toStringAsFixed(0)}')
      ..cellStyle = totalsRowStyle;

    for (int col = 5; col < 8; col++) {
      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx),
        )
        ..value = ex.TextCellValue('')
        ..cellStyle = totalsRowStyle;
    }
    rowIdx += 3;

    // 3. Attendance History Section
    sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx))
      ..value = ex.TextCellValue('ATTENDANCE SUMMARY & LOGS')
      ..cellStyle = sectionHeaderStyle;
    rowIdx += 2;

    writeLabelValue(
      rowIdx,
      0,
      'Total Presents:',
      1,
      '${attendanceStats['present'] ?? 0} Days',
    );
    writeLabelValue(
      rowIdx,
      3,
      'Total Absents:',
      4,
      '${attendanceStats['absent'] ?? 0} Days',
    );
    rowIdx++;
    writeLabelValue(
      rowIdx,
      0,
      'Total Leaves:',
      1,
      '${attendanceStats['leave'] ?? 0} Days',
    );
    writeLabelValue(
      rowIdx,
      3,
      'Attendance %:',
      4,
      '${(attendanceStats['percentage'] ?? 0.0).toStringAsFixed(1)}%',
    );
    rowIdx += 2;

    final attendanceHeaders = [
      'Date',
      'Status',
      'Check-In',
      'Check-Out',
      'Notes',
    ];
    for (int i = 0; i < attendanceHeaders.length; i++) {
      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIdx),
        )
        ..value = ex.TextCellValue(attendanceHeaders[i])
        ..cellStyle = headerStyle;
    }
    rowIdx++;

    for (var att in attendance) {
      final rowStyle = (rowIdx % 2 == 0) ? evenRowStyle : oddRowStyle;

      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
        )
        ..value = ex.TextCellValue(att.date)
        ..cellStyle = rowStyle;
      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx),
        )
        ..value = ex.TextCellValue(att.status)
        ..cellStyle = rowStyle;
      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx),
        )
        ..value = ex.TextCellValue(att.checkIn ?? 'N/A')
        ..cellStyle = rowStyle;
      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx),
        )
        ..value = ex.TextCellValue(att.checkOut ?? 'N/A')
        ..cellStyle = rowStyle;
      sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx),
        )
        ..value = ex.TextCellValue(att.notes ?? '')
        ..cellStyle = rowStyle;

      rowIdx++;
    }

    // Set standard columns width
    for (var colIdx = 0; colIdx < 8; colIdx++) {
      sheet.setColumnWidth(colIdx, 18.0);
    }

    final downloadsDir =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final filePath = p.join(downloadsDir.path, '$fileName.xlsx');
    final fileBytes = excel.save();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
    }
    return filePath;
  }

  /// Custom PDF export matching authentic Pakistani Bank Statement (Allied Bank format)
  static Future<String> exportBankStatementPdf({
    required BankAccount account,
    required List<Map<String, dynamic>> transactions,
    required double openingBalance,
    required double totalInflow,
    required double totalOutflow,
    required double closingBalance,
    required int totalIncomeTx,
    required int totalExpenseTx,
    bool includeVerification = true,
    bool isPersonalStatement = false,
    DateTime? statementStartDate,
    DateTime? statementEndDate,
  }) async {
    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final numFormat = NumberFormat('#,##0.00');
    final dateFormat = DateFormat('dd MMM yy');
    final periodDateFormat = DateFormat('dd MMM yyyy');
    final now = DateTime.now();

    // Chronological sorting (oldest first) so running balance matches real statement progression
    final chronological = sortTransactionsOldestFirst(transactions);

    // Determine statement period
    String statementPeriod;
    if (statementStartDate != null && statementEndDate != null) {
      statementPeriod = '${periodDateFormat.format(statementStartDate).toUpperCase()} TO ${periodDateFormat.format(statementEndDate).toUpperCase()}';
    } else {
      final validDates = chronological
          .map((t) => _normalizeDate(t['date']))
          .where((d) => d.year > 2010)
          .toList();

      final DateTime endDt = statementEndDate ??
          (validDates.isNotEmpty ? validDates.last : now);

      DateTime startDt = statementStartDate ??
          (validDates.isNotEmpty ? validDates.first : now.subtract(const Duration(days: 30)));

      if (startDt.isAfter(endDt)) {
        startDt = endDt;
      }

      if (startDt.year == endDt.year && startDt.month == endDt.month && startDt.day == endDt.day) {
        startDt = DateTime(endDt.year, endDt.month, 1);
      }

      statementPeriod = '${periodDateFormat.format(startDt).toUpperCase()} TO ${periodDateFormat.format(endDt).toUpperCase()}';
    }

    final bankName = isPersonalStatement
      ? 'Personal Account'
      : (account.bankName.isNotEmpty ? account.bankName : 'Allied Bank');
    final branchName = 'HH TECH Hub';
    final accountNumber = account.accountNumber.isNotEmpty ? account.accountNumber : '0010129874530014';
    final accountStatus = account.status == 'Active' ? 'Regular' : account.status;
    final accountHolderName = account.name.isNotEmpty ? account.name.toUpperCase() : 'MUHAMMAD SHAKEEL';

    // Color constants
    final darkText = PdfColor.fromHex('#111827');
    final subText = PdfColor.fromHex('#4B5563');
    final lineDark = PdfColor.fromHex('#374151');

    // Calculate starting balance for period header & running balance
    // If chronological transactions include explicit Opening Balance row,
    // subtract its inflow from openingBalance so starting balance header + row inflow does not double count!
    double periodStartBalance = openingBalance;
    for (final t in chronological) {
      final isOpening = (t['category']?.toString() == 'Opening Balance') ||
          (t['id']?.toString().startsWith('opening_') ?? false) ||
          (t['desc']?.toString().toLowerCase().contains('opening balance') ?? false);
      if (isOpening) {
        final inflow = (t['inflow'] as num?)?.toDouble() ?? 0.0;
        periodStartBalance = periodStartBalance - inflow;
        if (periodStartBalance < 0) periodStartBalance = 0.0;
      }
    }

    // Running balance calculation & row construction
    double runningBalance = periodStartBalance;
    final List<pw.TableRow> tableRows = [];

    // Header TableRow with border top and bottom
    tableRows.add(
      pw.TableRow(
        repeat: true,
        decoration: pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: lineDark, width: 0.8),
            bottom: pw.BorderSide(color: lineDark, width: 0.8),
          ),
        ),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: pw.Text('DATE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkText)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: pw.Text('PARTICULARS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkText)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: pw.Text('VALUE DATE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkText)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: pw.Text('DEBITS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkText), textAlign: pw.TextAlign.right),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: pw.Text('CREDITS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkText), textAlign: pw.TextAlign.right),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: pw.Text('BALANCE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkText), textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );

    // Populate data rows
    final List<pw.TableRow> transactionRows = [];
    for (final t in chronological) {
      final dt = _normalizeDate(t['date']);
      final dateStr = dateFormat.format(dt).toUpperCase();
      final inflow = (t['inflow'] as num?)?.toDouble() ?? 0.0;
      final outflow = (t['outflow'] as num?)?.toDouble() ?? 0.0;

      runningBalance = runningBalance + inflow - outflow;

      final desc = t['desc']?.toString() ?? '';
      final ref = t['ref']?.toString() ?? '';
      final hasRef = ref.isNotEmpty && ref != '-';

      transactionRows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3.5, horizontal: 2),
              child: pw.Text(dateStr, style: pw.TextStyle(fontSize: 7.5, color: darkText)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3.5, horizontal: 2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(desc, style: pw.TextStyle(fontSize: 7.5, color: darkText)),
                  if (hasRef) ...[
                    pw.SizedBox(height: 1),
                    pw.Text(ref, style: pw.TextStyle(fontSize: 6.5, color: subText)),
                  ],
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3.5, horizontal: 2),
              child: pw.Text(dateStr, style: pw.TextStyle(fontSize: 7.5, color: darkText)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3.5, horizontal: 2),
              child: pw.Text(
                outflow > 0 ? numFormat.format(outflow) : '',
                style: pw.TextStyle(fontSize: 7.5, color: darkText),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3.5, horizontal: 2),
              child: pw.Text(
                inflow > 0 ? numFormat.format(inflow) : '',
                style: pw.TextStyle(fontSize: 7.5, color: darkText),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3.5, horizontal: 2),
              child: pw.Text(
                numFormat.format(runningBalance),
                style: pw.TextStyle(fontSize: 7.5, color: darkText),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }

    tableRows.addAll(transactionRows.reversed);

    // Spacing before summary
    tableRows.add(
      pw.TableRow(
        children: [
          pw.SizedBox(height: 8),
          pw.SizedBox(height: 8),
          pw.SizedBox(height: 8),
          pw.SizedBox(height: 8),
          pw.SizedBox(height: 8),
          pw.SizedBox(height: 8),
        ],
      ),
    );

    // Row 1: TOTAL DEBIT / CREDIT
    tableRows.add(
      pw.TableRow(
        children: [
          pw.Container(),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('TOTAL DEBIT / CREDIT', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkText)),
            ),
          ),
          pw.Container(),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            child: pw.Text(
              numFormat.format(totalOutflow),
              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkText),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            child: pw.Text(
              numFormat.format(totalInflow),
              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkText),
              textAlign: pw.TextAlign.right,
            ),
          ),
          pw.Container(),
        ],
      ),
    );

    // Row 2: CLOSING BALANCE
    tableRows.add(
      pw.TableRow(
        children: [
          pw.Container(),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('CLOSING BALANCE', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkText)),
            ),
          ),
          pw.Container(),
          pw.Container(),
          pw.Container(),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            child: pw.Text(
              numFormat.format(closingBalance),
              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkText),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );

    // Row 3: TOTAL WITHHOLDING TAX DEDUCTED
    tableRows.add(
      pw.TableRow(
        children: [
          pw.Container(),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('TOTAL WITHHOLDING TAX DEDUCTED', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkText)),
            ),
          ),
          pw.Container(),
          pw.Container(),
          pw.Container(),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            child: pw.Text(
              '0.00',
              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: darkText),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );

    // Build statement MultiPage
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (context) {
          if (context.pageNumber == 1) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left: Bank Logo & Customer Details
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            if (logoImage != null)
                              pw.Container(
                                width: 28,
                                height: 28,
                                margin: const pw.EdgeInsets.only(right: 6),
                                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                              )
                            else
                              pw.Container(
                                width: 22,
                                height: 22,
                                decoration: pw.BoxDecoration(
                                  color: PdfColor.fromHex('#1A1A1A'),
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                                ),
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  'A',
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontSize: 15,
                                    fontWeight: pw.FontWeight.bold,
                                    fontStyle: pw.FontStyle.italic,
                                  ),
                                ),
                              ),
                            pw.SizedBox(width: 7),
                            pw.Text(
                              bankName,
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                                color: darkText,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 12),
                        pw.Text(
                          accountHolderName,
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                      ],
                    ),
                    // Right: Account & Branch Details
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(height: 10),
                        _buildStatementMeta('Branch Name:', branchName),
                        pw.SizedBox(height: 2.5),
                        _buildStatementMeta('Statement Period:', statementPeriod),
                        pw.SizedBox(height: 2.5),
                        _buildStatementMeta('Account Number:', accountNumber),
                        pw.SizedBox(height: 2.5),
                        _buildStatementMeta('Account Status:', accountStatus),
                        pw.SizedBox(height: 2.5),
                        pw.Text(
                          'Pakistan Rupees',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),
                // BALANCE AT PERIOD START (Right aligned above table)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      'BALANCE AT PERIOD START : ',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    pw.SizedBox(width: 24),
                    pw.Text(
                      numFormat.format(periodStartBalance),
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    pw.SizedBox(width: 4),
                  ],
                ),
                pw.SizedBox(height: 6),
              ],
            );
          } else {
            // Page 2+ compact header
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (logoImage != null) ...[
                          pw.Container(
                            width: 16,
                            height: 16,
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          ),
                          pw.SizedBox(width: 5),
                        ],
                        pw.Text(
                          bankName,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      'Statement Period: $statementPeriod   A/C: $accountNumber',
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                        color: subText,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
              ],
            );
          }
        },
        footer: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  '${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkText),
                ),
              ],
            ),
          );
        },
        build: (context) {
          return [
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(1.1), // DATE
                1: const pw.FlexColumnWidth(3.0), // PARTICULARS
                2: const pw.FlexColumnWidth(1.1), // VALUE DATE
                3: const pw.FlexColumnWidth(1.4), // DEBITS
                4: const pw.FlexColumnWidth(1.4), // CREDITS
                5: const pw.FlexColumnWidth(1.5), // BALANCE
              },
              children: tableRows,
            ),
            pw.SizedBox(height: 14),
            if (includeVerification)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Verification/Confirmed can be obtained from:',
                        style: pw.TextStyle(fontSize: 6, color: PdfColor.fromHex('#9CA3AF')),
                      ),
                      pw.Text(
                        'Incharge Verification Desk',
                        style: pw.TextStyle(fontSize: 6, color: PdfColor.fromHex('#9CA3AF')),
                      ),
                      pw.Text(
                        'Allied Bank Building, Blue Area Islamabad',
                        style: pw.TextStyle(fontSize: 6, color: PdfColor.fromHex('#9CA3AF')),
                      ),
                      pw.Text(
                        'ABL.VerificationDesk@abl.com',
                        style: pw.TextStyle(fontSize: 6, color: PdfColor.fromHex('#9CA3AF')),
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 6),
                ],
              ),
          ];
        },
      ),
    );

    final downloadsDir =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final fileNameClean =
        '${account.name.replaceAll(" ", "_")}_BankStatement_${DateFormat('yyyyMMdd_HHmm').format(now)}';
    final filePath = p.join(downloadsDir.path, '$fileNameClean.pdf');
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return filePath;
  }

  static pw.Widget _buildStatementMeta(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$label ',
          style: pw.TextStyle(
            fontSize: 8.5,
            color: PdfColor.fromHex('#111827'),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#111827'),
          ),
        ),
      ],
    );
  }


  /// Custom PDF export for Attendance Dashboard (Matches UI Design)
  static Future<String> exportAttendanceDashboardPdf({
    required List<AttendanceRecord> records,
    required String fileName,
    required String title,
    required String subtitle,
    Employee? employee,
  }) async {
    final pdf = pw.Document();

    final textColor = PdfColor.fromHex('#1E293B'); // Slate 800
    final secondaryTextColor = PdfColor.fromHex('#64748B'); // Slate 500
    final lightBg = PdfColor.fromHex('#F8FAFC'); // Slate 50
    final borderColor = PdfColor.fromHex('#E2E8F0'); // Slate 200

    // Status Colors matching the UI exactly
    final presentColor = PdfColor.fromHex('#10B981'); // Green
    final presentBgColor = PdfColor.fromHex('#F0FDF4');
    final lateColor = PdfColor.fromHex('#F59E0B'); // Orange
    final lateBgColor = PdfColor.fromHex('#FFFBEB');
    final absentColor = PdfColor.fromHex('#EF4444'); // Red
    final absentBgColor = PdfColor.fromHex('#FEF2F2');
    final leaveColor = PdfColor.fromHex('#3B82F6'); // Blue
    final leaveBgColor = PdfColor.fromHex('#EFF6FF');
    final offColor = PdfColor.fromHex('#94A3B8'); // Slate 400
    final offBgColor = PdfColor.fromHex('#F8FAFC');

    // Calculate Stats
    int present = 0, lateCount = 0, absent = 0, leave = 0, off = 0;
    int halfDay = 0, workFromHome = 0, notMarked = 0;
    for (var r in records) {
      if (r.status == 'Present')
        present++;
      else if (r.status == 'Late')
        lateCount++;
      else if (r.status == 'Absent')
        absent++;
      else if (r.status == 'Leave')
        leave++;
      else if (r.status == 'Off')
        off++;
      else if (r.status == 'Half Day')
        halfDay++;
      else if (r.status == 'Work From Home')
        workFromHome++;
      else if (r.status == 'Not Marked')
        notMarked++;
    }
    final totalDays = records.length;

    // Stat Card Widget
    pw.Widget statCard(
      String title,
      String count,
      PdfColor iconColor,
      PdfColor bgColor,
    ) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: bgColor,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                width: 24,
                height: 24,
                decoration: pw.BoxDecoration(
                  color: iconColor,
                  shape: pw.BoxShape.circle,
                ),
                alignment: pw.Alignment.center,
                // Using a simple letter or dot inside the circle for PDF since icons require fonts
                child: pw.Text(
                  title[0],
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    count,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'out of $totalDays days',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: secondaryTextColor,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Status Badge Widget for Table
    pw.Widget statusBadge(String status) {
      PdfColor color, bg;
      if (status == 'Present') {
        color = presentColor;
        bg = presentBgColor;
      } else if (status == 'Late') {
        color = lateColor;
        bg = lateBgColor;
      } else if (status == 'Absent') {
        color = absentColor;
        bg = absentBgColor;
      } else if (status == 'Off') {
        color = offColor;
        bg = offBgColor;
      } else if (status == 'Half Day') {
        color = lateColor;
        bg = lateBgColor;
      } else if (status == 'Work From Home') {
        color = PdfColor.fromHex('#2563EB');
        bg = PdfColor.fromHex('#EFF6FF');
      } else if (status == 'Not Marked') {
        color = secondaryTextColor;
        bg = lightBg;
      } else if (status == 'Holiday') {
        color = PdfColor.fromHex('#7C3AED');
        bg = PdfColor.fromHex('#F5F3FF');
      } else {
        color = leaveColor;
        bg = leaveBgColor;
      }

      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        ),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Container(
              width: 6,
              height: 6,
              decoration: pw.BoxDecoration(
                color: color,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.SizedBox(width: 6),
            pw.Text(
              status,
              style: pw.TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Prepare Table Rows
    final headers = [
      'Date',
      'Day',
      'Check-In',
      'Check-Out',
      'Total Hours',
      'Status',
    ];
    List<pw.TableRow> tableRows = [];

    // Header Row
    tableRows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(
          color: lightBg,
          border: pw.Border(
            bottom: pw.BorderSide(color: borderColor, width: 1),
          ),
        ),
        children: headers
            .map(
              (h) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: pw.Text(
                  h,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );

    String formatDuration(AttendanceRecord record) {
      if (record.checkIn == null || record.checkOut == null) return '-';

      int? parseTime(String value) {
        final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false).firstMatch(value.trim());
        if (match == null) return null;
        var hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final period = match.group(3)!.toUpperCase();
        if (period == 'AM' && hour == 12) hour = 0;
        if (period == 'PM' && hour != 12) hour += 12;
        return hour * 60 + minute;
      }

      final start = parseTime(record.checkIn!);
      final end = parseTime(record.checkOut!);
      if (start == null || end == null || end < start) return '-';
      final minutes = end - start;
      return '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';
    }

    // Data Rows
    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      final dateObj = DateTime.tryParse(r.date);
      final dayName = dateObj != null
          ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dateObj.weekday -
                1]
          : '';

      final totalHours = formatDuration(r);

      tableRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: borderColor, width: 0.5),
            ),
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              child: pw.Text(
                r.date,
                style: pw.TextStyle(fontSize: 10, color: textColor),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              child: pw.Text(
                dayName,
                style: pw.TextStyle(fontSize: 10, color: textColor),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              child: pw.Text(
                r.checkIn ?? '-',
                style: pw.TextStyle(fontSize: 10, color: textColor),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              child: pw.Text(
                r.checkOut ?? '-',
                style: pw.TextStyle(fontSize: 10, color: textColor),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              child: pw.Text(
                totalHours,
                style: pw.TextStyle(fontSize: 10, color: secondaryTextColor),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              child: pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: statusBadge(r.status),
              ),
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(32),
        header: (context) {
          if (context.pageNumber == 1) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (employee != null)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 16),
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: lightBg,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                      border: pw.Border.all(color: borderColor),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'EMPLOYEE DETAILS',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: secondaryTextColor,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              employee.name,
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              employee.designation,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            pw.Text(
                              employee.department,
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 16),
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: lightBg,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                      border: pw.Border.all(color: borderColor),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Text(
                          'All employee record',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          title,
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          subtitle,
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      'HH TECH HUB',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#4B55E5'),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                // Stat Cards
                pw.Row(
                  children: [
                    statCard(
                      'Present',
                      present.toString(),
                      presentColor,
                      presentBgColor,
                    ),
                    pw.SizedBox(width: 16),
                    statCard(
                      'Late',
                      lateCount.toString(),
                      lateColor,
                      lateBgColor,
                    ),
                    pw.SizedBox(width: 16),
                    statCard(
                      'Absent',
                      absent.toString(),
                      absentColor,
                      absentBgColor,
                    ),
                    pw.SizedBox(width: 16),
                    statCard(
                      'On Leave',
                      leave.toString(),
                      leaveColor,
                      leaveBgColor,
                    ),
                    pw.SizedBox(width: 16),
                    statCard(
                      'Half Day',
                      halfDay.toString(),
                      lateColor,
                      lateBgColor,
                    ),
                    pw.SizedBox(width: 16),
                    statCard(
                      'Work From Home',
                      workFromHome.toString(),
                      PdfColor.fromHex('#2563EB'),
                      PdfColor.fromHex('#EFF6FF'),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
              ],
            );
          }
          return pw.SizedBox();
        },
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
        ),
        build: (context) => [
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderColor),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.ClipRRect(
              horizontalRadius: 8,
              verticalRadius: 8,
              child: pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.2),
                  1: const pw.FlexColumnWidth(0.8),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(1.0),
                  5: const pw.FlexColumnWidth(1.5),
                },
                children: tableRows,
              ),
            ),
          ),
        ],
      ),
    );

    final downloadsDir =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final filePath = p.join(downloadsDir.path, '$fileName.pdf');
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return filePath;
  }
}
