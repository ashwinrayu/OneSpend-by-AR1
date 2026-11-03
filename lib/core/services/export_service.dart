import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/transaction_item.dart';

class ExportResult {
  final bool success;
  final String? filePath;
  final int recordCount;
  final String? message;

  const ExportResult({
    required this.success,
    this.filePath,
    required this.recordCount,
    this.message,
  });
}

class ExportService {
  /// Converts transactions into CSV string with standard headers:
  /// ID, Date, Time, Type, Category, Amount, Payment Method, Note
  static String generateCsvString(List<TransactionItem> transactions) {
    final rows = <List<dynamic>>[];

    // CSV Headers
    rows.add([
      'ID',
      'Date',
      'Time',
      'Type',
      'Category',
      'Amount',
      'Payment Method',
      'Note',
    ]);

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm:ss');

    for (final tx in transactions) {
      rows.add([
        tx.id,
        dateFormat.format(tx.timestamp),
        timeFormat.format(tx.timestamp),
        tx.type.name.toUpperCase(),
        tx.category,
        tx.amount.toStringAsFixed(2),
        tx.paymentMethod.displayName,
        tx.notes ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  /// Exports transaction list to CSV on Android or Windows desktop
  static Future<ExportResult> exportTransactionsToCsv(
    List<TransactionItem> transactions, {
    String? customFileName,
  }) async {
    if (transactions.isEmpty) {
      return const ExportResult(
        success: false,
        recordCount: 0,
        message: 'No transactions to export.',
      );
    }

    try {
      final csvString = generateCsvString(transactions);
      final bytes = utf8.encode(csvString);

      final yearMonthStr = DateFormat('yyyy_MM').format(DateTime.now());
      final defaultFileName = customFileName ?? 'onespend_export_$yearMonthStr.csv';

      // 1. Windows Desktop File Picker ("Save As...")
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        String? selectedPath;
        try {
          selectedPath = await FilePicker.platform.saveFile(
            dialogTitle: 'Save Transactions CSV',
            fileName: defaultFileName,
            type: FileType.custom,
            allowedExtensions: ['csv'],
          );
        } catch (e) {
          debugPrint('FilePicker dialog error, falling back: $e');
        }

        // If user cancelled save dialog
        if (selectedPath == null || selectedPath.isEmpty) {
          // Check if fallback to Documents folder is preferred
          final docsDir = await getApplicationDocumentsDirectory();
          selectedPath = p.join(docsDir.path, defaultFileName);
        }

        // Ensure extension
        if (!selectedPath.toLowerCase().endsWith('.csv')) {
          selectedPath = '$selectedPath.csv';
        }

        final file = File(selectedPath);
        await file.writeAsBytes(bytes);

        return ExportResult(
          success: true,
          filePath: selectedPath,
          recordCount: transactions.length,
          message: 'Saved to $selectedPath',
        );
      }

      // 2. Mobile (Android / iOS)
      Directory? targetDir;
      try {
        targetDir = await getDownloadsDirectory();
      } catch (_) {}
      targetDir ??= await getApplicationDocumentsDirectory();

      final filePath = p.join(targetDir.path, defaultFileName);
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return ExportResult(
        success: true,
        filePath: filePath,
        recordCount: transactions.length,
        message: 'Exported to Downloads ($defaultFileName)',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        recordCount: transactions.length,
        message: 'Failed to export CSV: $e',
      );
    }
  }
}

