import 'package:sqflite/sqflite.dart';
import '../../models/budget_item.dart';
import '../../models/category_item.dart';
import '../../models/enums.dart';
import '../../models/transaction_item.dart';
import '../database/app_database.dart';

class MonthlySummary {
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final double monthlyBudget;
  final double budgetRemaining;
  final double budgetBurnPercentage;

  MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.monthlyBudget,
    required this.budgetRemaining,
    required this.budgetBurnPercentage,
  });
}

class ExpenseRepository {
  final AppDatabase _dbHelper;

  ExpenseRepository([AppDatabase? dbHelper])
      : _dbHelper = dbHelper ?? AppDatabase.instance;

  Future<Database> get _db async => await _dbHelper.database;

  // Transactions CRUD
  Future<List<TransactionItem>> getAllTransactions() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => TransactionItem.fromMap(map)).toList();
  }

  Future<List<TransactionItem>> getTransactionsByMonth(int month, int year) async {
    final db = await _db;
    final startOfMonth = DateTime(year, month, 1).millisecondsSinceEpoch;
    final endOfMonth = (month == 12)
        ? DateTime(year + 1, 1, 1).millisecondsSinceEpoch
        : DateTime(year, month + 1, 1).millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [startOfMonth, endOfMonth],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => TransactionItem.fromMap(map)).toList();
  }

  Future<void> insertTransaction(TransactionItem item) async {
    final db = await _db;
    await db.insert(
      'transactions',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTransaction(TransactionItem item) async {
    final db = await _db;
    await db.update(
      'transactions',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await _db;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Categories CRUD
  Future<List<CategoryItem>> getAllCategories() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return maps.map((map) => CategoryItem.fromMap(map)).toList();
  }

  Future<void> insertCategory(CategoryItem item) async {
    final db = await _db;
    await db.insert(
      'categories',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Budget CRUD
  Future<BudgetItem?> getBudget(int month, int year) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return BudgetItem.fromMap(maps.first);
    }
    return null;
  }

  Future<void> setBudget(BudgetItem budget) async {
    final db = await _db;
    await db.insert(
      'budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Summary Calculations
  Future<MonthlySummary> getMonthlySummary(int month, int year) async {
    final transactions = await getTransactionsByMonth(month, year);
    final budget = await getBudget(month, year);

    double totalIncome = 0;
    double totalExpense = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }

    final double netSavings = totalIncome - totalExpense;
    final double monthlyLimit = budget?.monthlyLimit ?? 45000.0;
    final double budgetRemaining = monthlyLimit - totalExpense;
    final double burnPercentage = monthlyLimit > 0
        ? (totalExpense / monthlyLimit).clamp(0.0, 1.5)
        : 0.0;

    return MonthlySummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netSavings: netSavings,
      monthlyBudget: monthlyLimit,
      budgetRemaining: budgetRemaining,
      budgetBurnPercentage: burnPercentage,
    );
  }
}

