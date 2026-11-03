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
      version: 3,
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

    // Seed default categories
    final batch = db.batch();
    for (final cat in MockData.defaultCategories) {
      batch.insert('categories', cat.toMap());
    }

    // Seed default budget
    batch.insert('budgets', MockData.defaultBudget.toMap());

    // Seed sample transactions
    for (final tx in MockData.getSampleTransactions()) {
      batch.insert('transactions', tx.toMap());
    }

    // Seed sample subscriptions
    final now = DateTime.now();
    final sampleSubs = [
      {
        'id': 'sub_1',
        'name': 'Netflix Premium 4K',
        'amount': 649.0,
        'billingCycle': 'Monthly',
        'category': 'Entertainment',
        'nextBillingDate': now.add(const Duration(days: 4)).millisecondsSinceEpoch,
        'paymentMethod': 'UPI',
        'isActive': 1,
      },
      {
        'id': 'sub_2',
        'name': 'Spotify Duo',
        'amount': 199.0,
        'billingCycle': 'Monthly',
        'category': 'Entertainment',
        'nextBillingDate': now.add(const Duration(days: 12)).millisecondsSinceEpoch,
        'paymentMethod': 'Card',
        'isActive': 1,
      },
      {
        'id': 'sub_3',
        'name': 'Fiber Broadband (Airtel)',
        'amount': 1199.0,
        'billingCycle': 'Monthly',
        'category': 'Bills',
        'nextBillingDate': now.add(const Duration(days: 7)).millisecondsSinceEpoch,
        'paymentMethod': 'UPI',
        'isActive': 1,
      },
      {
        'id': 'sub_4',
        'name': 'Gym & Fitness Pass',
        'amount': 2200.0,
        'billingCycle': 'Monthly',
        'category': 'Other',
        'nextBillingDate': now.add(const Duration(days: 18)).millisecondsSinceEpoch,
        'paymentMethod': 'UPI',
        'isActive': 1,
      },
    ];
    for (final sub in sampleSubs) {
      batch.insert('subscriptions', sub);
    }

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

        final now = DateTime.now();
        final sampleSubs = [
          {
            'id': 'sub_1',
            'name': 'Netflix Premium 4K',
            'amount': 649.0,
            'billingCycle': 'Monthly',
            'category': 'Entertainment',
            'nextBillingDate': now.add(const Duration(days: 4)).millisecondsSinceEpoch,
            'paymentMethod': 'UPI',
            'isActive': 1,
          },
          {
            'id': 'sub_2',
            'name': 'Spotify Duo',
            'amount': 199.0,
            'billingCycle': 'Monthly',
            'category': 'Entertainment',
            'nextBillingDate': now.add(const Duration(days: 12)).millisecondsSinceEpoch,
            'paymentMethod': 'Card',
            'isActive': 1,
          },
          {
            'id': 'sub_3',
            'name': 'Fiber Broadband (Airtel)',
            'amount': 1199.0,
            'billingCycle': 'Monthly',
            'category': 'Bills',
            'nextBillingDate': now.add(const Duration(days: 7)).millisecondsSinceEpoch,
            'paymentMethod': 'UPI',
            'isActive': 1,
          },
        ];
        final batch = db.batch();
        for (final sub in sampleSubs) {
          batch.insert('subscriptions', sub, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await batch.commit(noResult: true);
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
