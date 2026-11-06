import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/database/app_database.dart';
import '../../models/budget_item.dart';
import '../../models/category_item.dart';
import '../../models/mock_data.dart';
import '../../models/transaction_item.dart';

class BackupResult {
  final bool success;
  final String message;
  final String? filePath;
  final int? transactionCount;

  const BackupResult({
    required this.success,
    required this.message,
    this.filePath,
    this.transactionCount,
  });
}

class BackupService {
  /// Exports all database tables (transactions, categories, budgets) into a validated JSON backup
  static Future<BackupResult> exportBackup() async {
    try {
      final db = await AppDatabase.instance.database;

      final transactionsMap = await db.query('transactions');
      final categoriesMap = await db.query('categories');
      final budgetsMap = await db.query('budgets');

      final backupPayload = {
        'version': 1,
        'app': 'OneSpend by AR1',
        'exportedAt': DateTime.now().toIso8601String(),
        'transactions': transactionsMap,
        'categories': categoriesMap,
        'budgets': budgetsMap,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupPayload);
      final bytes = utf8.encode(jsonString);

      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final defaultFileName = 'onespend_backup_$dateStr.json';

      // Windows Desktop: Native file picker
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        String? selectedPath;
        try {
          selectedPath = await FilePicker.platform.saveFile(
            dialogTitle: 'Save OneSpend Vault Backup',
            fileName: defaultFileName,
            type: FileType.custom,
            allowedExtensions: ['json'],
          );
        } catch (e) {
          debugPrint('FilePicker error: $e');
        }

        if (selectedPath == null || selectedPath.isEmpty) {
          final docDir = await getApplicationDocumentsDirectory();
          selectedPath = p.join(docDir.path, defaultFileName);
        }

        if (!selectedPath.toLowerCase().endsWith('.json')) {
          selectedPath = '$selectedPath.json';
        }

        final file = File(selectedPath);
        await file.writeAsBytes(bytes);

        return BackupResult(
          success: true,
          message: 'Backup successfully saved to desktop',
          filePath: selectedPath,
          transactionCount: transactionsMap.length,
        );
      }

      // Android / Mobile: Downloads or Documents
      Directory? targetDir;
      try {
        targetDir = await getDownloadsDirectory();
      } catch (_) {}
      targetDir ??= await getApplicationDocumentsDirectory();

      final targetPath = p.join(targetDir.path, defaultFileName);
      final file = File(targetPath);
      await file.writeAsBytes(bytes);

      return BackupResult(
        success: true,
        message: 'Backup saved to device storage',
        filePath: targetPath,
        transactionCount: transactionsMap.length,
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Failed to create backup: $e',
      );
    }
  }

  /// Restores data from a JSON backup file with integrity verification
  static Future<BackupResult> importBackup() async {
    try {
      final pickerResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (pickerResult == null || pickerResult.files.isEmpty) {
        return const BackupResult(
          success: false,
          message: 'Restore cancelled (no file selected)',
        );
      }

      final path = pickerResult.files.single.path;
      if (path == null) {
        return const BackupResult(
          success: false,
          message: 'Unable to read selected file path',
        );
      }

      final file = File(path);
      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);

      // Schema Integrity Check
      if (!data.containsKey('app') ||
          !data.containsKey('transactions') ||
          !data.containsKey('categories')) {
        return const BackupResult(
          success: false,
          message: 'Invalid backup file: missing required OneSpend schema fields',
        );
      }

      final transactionsList = data['transactions'] as List<dynamic>;
      final categoriesList = data['categories'] as List<dynamic>;
      final budgetsList = (data['budgets'] as List<dynamic>?) ?? [];

      final db = await AppDatabase.instance.database;

      await db.transaction((txn) async {
        // Clear existing records
        await txn.delete('transactions');
        await txn.delete('categories');
        await txn.delete('budgets');

        // Restore Categories
        final catBatch = txn.batch();
        for (final item in categoriesList) {
          catBatch.insert('categories', Map<String, dynamic>.from(item as Map));
        }
        await catBatch.commit(noResult: true);

        // Restore Budgets
        final budgetBatch = txn.batch();
        for (final item in budgetsList) {
          budgetBatch.insert('budgets', Map<String, dynamic>.from(item as Map));
        }
        await budgetBatch.commit(noResult: true);

        // Restore Transactions
        final txBatch = txn.batch();
        for (final item in transactionsList) {
          txBatch.insert('transactions', Map<String, dynamic>.from(item as Map));
        }
        await txBatch.commit(noResult: true);
      });

      return BackupResult(
        success: true,
        message: 'Successfully restored ${transactionsList.length} transactions',
        transactionCount: transactionsList.length,
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Failed to restore backup: $e',
      );
    }
  }

  /// Erases all transactions and resets to fresh vault
  static Future<void> factoryReset() async {
    final db = await AppDatabase.instance.database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('subscriptions');
      await txn.delete('categories');
      await txn.delete('budgets');

      // Re-seed default categories & budget
      for (final cat in MockData.defaultCategories) {
        await txn.insert('categories', cat.toMap());
      }
      await txn.insert('budgets', MockData.defaultBudget.toMap());
    });
  }
}

