import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/utils/export_helper.dart';

class ExportButton extends StatefulWidget {
  final String title;
  final String fileName;
  final List<String> headers;
  final List<List<dynamic>> rows;
  final Map<int, pw.TableColumnWidth>? columnWidths;
  final Future<String> Function()? customPdfExport;
  final Future<String> Function()? customExcelExport;

  const ExportButton({
    super.key,
    required this.title,
    required this.fileName,
    required this.headers,
    required this.rows,
    this.columnWidths,
    this.customPdfExport,
    this.customExcelExport,
  });

  @override
  State<ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<ExportButton> {
  bool _isLoading = false;

  Future<void> _export(BuildContext context, bool isPdf) async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final successColor = Theme.of(context).primaryColor;

    try {
      String path;
      if (isPdf) {
        if (widget.customPdfExport != null) {
          path = await widget.customPdfExport!();
        } else {
          path = await ExportHelper.exportToPdf(
            title: widget.title,
            fileName: widget.fileName,
            headers: widget.headers,
            rows: widget.rows,
            columnWidths: widget.columnWidths,
          );
        }
      } else {
        if (widget.customExcelExport != null) {
          path = await widget.customExcelExport!();
        } else {
          path = await ExportHelper.exportToExcel(
            fileName: widget.fileName,
            headers: widget.headers,
            rows: widget.rows,
          );
        }
      }

      setState(() => _isLoading = false);

      messenger.showSnackBar(
        SnackBar(
          content: Text('${isPdf ? "PDF" : "Excel"} report generated successfully.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: successColor,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OPEN',
            textColor: Colors.white,
            onPressed: () => ExportHelper.openFile(path),
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Export data',
      onSelected: (val) {
        if (val == 'excel') {
          _export(context, false);
        } else if (val == 'pdf') {
          _export(context, true);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.border),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading) ...[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                ),
                const SizedBox(width: 8),
              ] else ...[
                Icon(Icons.download, size: 16, color: context.textPrimary),
                const SizedBox(width: 8),
              ],
              Text(
                'Export Data',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, size: 16, color: context.textPrimary),
            ],
          ),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'excel',
          child: Row(
            children: [
              const Icon(Icons.table_view, size: 16, color: Colors.green),
              const SizedBox(width: 10),
              Text('Export to Excel', style: TextStyle(color: context.textPrimary, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
              const SizedBox(width: 10),
              Text('Export to PDF', style: TextStyle(color: context.textPrimary, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
