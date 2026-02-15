import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../shared/constants/app_constants.dart';
import '../models/expense_group_with_items.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Formats a [DateTime] as `yyyy-MM-dd`.
  String _formatDate(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Formats a [DateTime] as `yyyy-MM-dd HH:mm`.
  String _formatDateTime(DateTime dt) {
    final date = _formatDate(dt);
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$date $h:$min';
  }

  /// Exports a list of expense groups to a CSV file.
  ///
  /// Returns the generated [File] containing CSV data with headers:
  /// Date, Store, Description, Category, Amount, Currency.
  Future<File> exportToCSV(
    List<ExpenseGroupWithItems> groups, {
    String currency = 'MYR',
  }) async {
    final currencySymbol =
        AppConstants.currencySymbols[currency] ?? currency;

    // Build CSV rows
    final List<List<dynamic>> rows = [
      // Header row
      ['Date', 'Store', 'Description', 'Category', 'Amount', 'Currency'],
    ];

    double total = 0.0;
    for (final group in groups) {
      for (final item in group.items) {
        final itemTotal = item.amount * item.quantity;
        total += itemTotal;
        rows.add([
          _formatDate(group.group.date),
          group.group.storeName ?? '',
          item.description,
          item.category,
          itemTotal.toStringAsFixed(2),
          currencySymbol,
        ]);
      }
    }

    rows.add([]);
    rows.add(['', '', '', 'Total', total.toStringAsFixed(2), currencySymbol]);

    // Convert to CSV string
    final csvData = const ListToCsvConverter().convert(rows);

    // Write to file
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory(path.join(directory.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(path.join(exportDir.path, 'expenses_$timestamp.csv'));
    await file.writeAsString(csvData);

    return file;
  }

  /// Exports a list of expense groups to a formatted PDF report.
  ///
  /// The PDF includes a title, date range, an expenses table, and a total.
  /// Returns the generated [File].
  Future<File> exportToPDF(
    List<ExpenseGroupWithItems> groups, {
    String title = 'Expense Report',
    String currency = 'MYR',
  }) async {
    final currencySymbol =
        AppConstants.currencySymbols[currency] ?? currency;

    final pdf = pw.Document();

    // Flatten groups into rows for the PDF
    final List<_PdfRow> allRows = [];
    double total = 0.0;
    for (final group in groups) {
      for (final item in group.items) {
        final itemTotal = item.amount * item.quantity;
        total += itemTotal;
        allRows.add(_PdfRow(
          date: group.group.date,
          storeName: group.group.storeName ?? '',
          description: item.description,
          category: item.category,
          amount: itemTotal,
        ));
      }
    }

    // Determine date range
    String dateRangeText = 'No expenses';
    if (groups.isNotEmpty) {
      final sortedByDate = List<ExpenseGroupWithItems>.from(groups)
        ..sort((a, b) => a.group.date.compareTo(b.group.date));
      final earliest = sortedByDate.first.group.date;
      final latest = sortedByDate.last.group.date;
      dateRangeText =
          '${_formatDate(earliest)} to ${_formatDate(latest)}';
    }

    // Split rows into pages (limit rows per page to avoid overflow)
    const int rowsPerPage = 25;
    final int pageCount = allRows.isEmpty
        ? 1
        : (allRows.length / rowsPerPage).ceil();

    for (int page = 0; page < pageCount; page++) {
      final startIndex = page * rowsPerPage;
      final endIndex = (startIndex + rowsPerPage) < allRows.length
          ? startIndex + rowsPerPage
          : allRows.length;
      final pageRows = allRows.sublist(startIndex, endIndex);
      final isFirstPage = page == 0;
      final isLastPage = page == pageCount - 1;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Title and date range (first page only)
                if (isFirstPage) ...[
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Period: $dateRangeText',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Generated: ${_formatDateTime(DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey500,
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 16),
                ],

                // Expenses table
                if (pageRows.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    cellHeight: 28,
                    cellAlignments: {
                      0: pw.Alignment.centerLeft,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.centerLeft,
                      3: pw.Alignment.centerLeft,
                      4: pw.Alignment.centerRight,
                    },
                    headers: ['Date', 'Store', 'Description', 'Category', 'Amount ($currencySymbol)'],
                    data: pageRows.map((row) {
                      return [
                        _formatDate(row.date),
                        row.storeName,
                        row.description,
                        row.category,
                        row.amount.toStringAsFixed(2),
                      ];
                    }).toList(),
                  ),

                // Total (last page only)
                if (isLastPage) ...[
                  pw.SizedBox(height: 16),
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Total: $currencySymbol${total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        '${allRows.length} item${allRows.length == 1 ? '' : 's'} in ${groups.length} group${groups.length == 1 ? '' : 's'}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],

                pw.Spacer(),

                // Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      AppConstants.appName,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey400,
                      ),
                    ),
                    pw.Text(
                      'Page ${page + 1} of $pageCount',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey400,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    // Write to file
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory(path.join(directory.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(path.join(exportDir.path, 'expenses_$timestamp.pdf'));
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Shares the given file using the system share dialog.
  Future<void> shareFile(File file) async {
    final xFile = XFile(file.path);
    await Share.shareXFiles(
      [xFile],
      subject: 'Expense Report',
    );
  }
}

class _PdfRow {
  final DateTime date;
  final String storeName;
  final String description;
  final String category;
  final double amount;

  const _PdfRow({
    required this.date,
    required this.storeName,
    required this.description,
    required this.category,
    required this.amount,
  });
}
