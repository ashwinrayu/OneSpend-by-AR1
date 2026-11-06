import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/enums.dart';
import '../../models/transaction_item.dart';

class PdfStatementResult {
  final bool success;
  final String message;
  final String? filePath;

  const PdfStatementResult({
    required this.success,
    required this.message,
    this.filePath,
  });
}

class PdfStatementService {
  static Future<PdfStatementResult> generateMonthlyStatement({
    required String monthName,
    required int year,
    required String currencySymbol,
    required List<TransactionItem> transactions,
    String? userEmail,
  }) async {
    try {
      final pdf = pw.Document();

      // Compute statistics
      double totalIncome = 0;
      double totalExpense = 0;
      final categoryTotals = <String, double>{};

      for (final tx in transactions) {
        if (tx.type == TransactionType.income) {
          totalIncome += tx.amount;
        } else if (tx.type == TransactionType.expense) {
          totalExpense += tx.amount;
          categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + tx.amount;
        }
      }

      final netSavings = totalIncome - totalExpense;
      final savingsRate = totalIncome > 0 ? (netSavings / totalIncome) * 100 : 0.0;

      // Sort category breakdown
      final sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final primaryColor = PdfColor.fromHex('#10B981'); // Emerald
      final darkBg = PdfColor.fromHex('#13161C');
      final grayText = PdfColor.fromHex('#9CA3AF');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'OneSpend by AR1',
                        style: pw.TextStyle(
                          color: primaryColor,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Monthly Financial Statement',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        '$monthName $year',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                      ),
                      if (userEmail != null && userEmail.isNotEmpty)
                        pw.Text(
                          userEmail,
                          style: pw.TextStyle(color: grayText, fontSize: 10),
                        ),
                      pw.Text(
                        'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                        style: pw.TextStyle(color: grayText, fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: primaryColor),
              pw.SizedBox(height: 16),

              // Executive Summary Cards
              pw.Text(
                'Executive Summary',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  _summaryBox('Total Income', '$currencySymbol ${totalIncome.toStringAsFixed(2)}', primaryColor),
                  pw.SizedBox(width: 10),
                  _summaryBox('Total Expenses', '$currencySymbol ${totalExpense.toStringAsFixed(2)}', PdfColors.red600),
                  pw.SizedBox(width: 10),
                  _summaryBox(
                    'Net Savings',
                    '$currencySymbol ${netSavings.toStringAsFixed(2)}',
                    netSavings >= 0 ? primaryColor : PdfColors.red600,
                  ),
                  pw.SizedBox(width: 10),
                  _summaryBox(
                    'Savings Rate',
                    '${savingsRate.toStringAsFixed(1)}%',
                    savingsRate >= 20 ? primaryColor : PdfColors.amber700,
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Category Breakdown Table
              if (sortedCategories.isNotEmpty) ...[
                pw.Text(
                  'Top Expense Categories',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Table.fromTextArray(
                  headers: ['Category', 'Amount', '% of Total Expense'],
                  data: sortedCategories.take(8).map((cat) {
                    final pct = totalExpense > 0 ? (cat.value / totalExpense) * 100 : 0.0;
                    return [
                      cat.key,
                      '$currencySymbol ${cat.value.toStringAsFixed(2)}',
                      '${pct.toStringAsFixed(1)}%',
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                  headerDecoration: pw.BoxDecoration(color: darkBg),
                  cellHeight: 22,
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
                pw.SizedBox(height: 20),
              ],

              // Itemized Transactions Table
              pw.Text(
                'Itemized Transactions (${transactions.length} records)',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: ['Date', 'Title', 'Category', 'Method', 'Type', 'Amount'],
                data: transactions.map((tx) {
                  final isIncome = tx.type == TransactionType.income;
                  return [
                    DateFormat('dd MMM').format(tx.timestamp),
                    tx.title,
                    tx.category,
                    tx.paymentMethod.displayName,
                    isIncome ? 'Income' : 'Expense',
                    '${isIncome ? '+' : '-'} $currencySymbol ${tx.amount.toStringAsFixed(2)}',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                headerDecoration: pw.BoxDecoration(color: darkBg),
                cellHeight: 20,
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.centerLeft,
              ),

              pw.SizedBox(height: 24),
              pw.Center(
                child: pw.Text(
                  'OneSpend by AR1 — Generated offline & confidential on device',
                  style: pw.TextStyle(color: grayText, fontSize: 8, fontStyle: pw.FontStyle.italic),
                ),
              ),
            ];
          },
        ),
      );

      // Save PDF to Documents or Downloads directory
      Directory? outputDir;
      try {
        outputDir = await getDownloadsDirectory();
      } catch (_) {}
      outputDir ??= await getApplicationDocumentsDirectory();

      final fileName = 'OneSpend_Statement_${year}_${monthName.replaceAll(' ', '_')}.pdf';
      final file = File(p.join(outputDir.path, fileName));
      await file.writeAsBytes(await pdf.save());

      return PdfStatementResult(
        success: true,
        message: 'PDF Statement saved successfully',
        filePath: file.path,
      );
    } catch (e) {
      return PdfStatementResult(
        success: false,
        message: 'Failed to generate PDF statement: $e',
      );
    }
  }

  static pw.Widget _summaryBox(String label, String value, PdfColor highlightColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: highlightColor),
            ),
          ],
        ),
      ),
    );
  }
}
