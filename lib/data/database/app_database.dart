import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../models/budget_item.dart';
import '../../models/category_item.dart';
import '../../models/mock_data.dart';
import '../../models/transaction_item.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Desktop initialization (Windows, Linux, macOS)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final docDir = await getApplicationDocumentsDirectory();
      final appDir = Directory(p.join(docDir.path, 'OneSpend'));
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      dbPath = p.join(appDir.path, 'onespend_vault.db');
    } else {
      final databasesPath = await getDatabasesPath();
      dbPath = p.join(databasesPath, 'onespend_vault.db');
    }

    return await openDatabase(
      dbPath,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconName TEXT NOT NULL,
        hexColor TEXT NOT NULL,
        isExpense INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        monthlyLimit REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        notes TEXT,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS subscriptions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        billingCycle TEXT NOT NULL,
        category TEXT NOT NULL,
        nextBillingDate INTEGER NOT NULL,
        paymentMethod TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Seed default categories for selection
    final batch = db.batch();
    for (final cat in MockData.defaultCategories) {
      batch.insert('categories', cat.toMap());
    }

    // Seed default budget target
    batch.insert('budgets', MockData.defaultBudget.toMap());

    // NOTE: Production build starts with a pristine, 100% clean vault
    // (zero dummy transactions or subscriptions seeded)
    await batch.commit(noResult: true);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE transactions ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'synced'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE transactions ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0");
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS subscriptions (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            amount REAL NOT NULL,
            billingCycle TEXT NOT NULL,
            category TEXT NOT NULL,
            nextBillingDate INTEGER NOT NULL,
            paymentMethod TEXT NOT NULL,
            isActive INTEGER NOT NULL DEFAULT 1
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        // Clean legacy mock/sample transactions and subscriptions for pristine production state
        await db.delete('transactions', where: "id LIKE 'tx_%'");
        await db.delete('subscriptions', where: "id LIKE 'sub_%'");
      } catch (_) {}
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
