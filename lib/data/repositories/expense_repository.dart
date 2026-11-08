import 'package:sqflite/sqflite.dart';
import '../../models/budget_item.dart';
import '../../models/category_item.dart';
import '../../models/enums.dart';
import '../../models/loan_item.dart';
import '../../models/subscription_item.dart';
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
      where: 'is_deleted = 0',
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
      where: 'timestamp >= ? AND timestamp < ? AND is_deleted = 0',
      whereArgs: [startOfMonth, endOfMonth],
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => TransactionItem.fromMap(map)).toList();
  }

  Future<void> insertTransaction(TransactionItem item) async {
    final db = await _db;
    final itemMap = item.copyWith(syncStatus: 'pending').toMap();
    await db.insert(
      'transactions',
      itemMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTransaction(TransactionItem item) async {
    final db = await _db;
    final itemMap = item.copyWith(syncStatus: 'pending').toMap();
    await db.update(
      'transactions',
      itemMap,
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await _db;
    // Mark as deleted and pending sync
    await db.update(
      'transactions',
      {'is_deleted': 1, 'sync_status': 'pending'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sync operations
  Future<void> markAllTransactionsAsPending() async {
    final db = await _db;
    await db.update(
      'transactions',
      {'sync_status': 'pending'},
      where: 'is_deleted = 0',
    );
  }

  Future<List<TransactionItem>> getPendingSyncTransactions() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: "sync_status = 'pending'",
    );
    return maps.map((map) => TransactionItem.fromMap(map)).toList();
  }

  Future<void> markTransactionsAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _db;
    final batch = db.batch();
    for (final id in ids) {
      batch.update(
        'transactions',
        {'sync_status': 'synced'},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    // Purge any synced items that were marked is_deleted = 1
    batch.delete(
      'transactions',
      where: "is_deleted = 1 AND sync_status = 'synced'",
    );
    await batch.commit(noResult: true);
  }

  Future<void> mergeServerTransactions(List<dynamic> serverChanges) async {
    if (serverChanges.isEmpty) return;
    final db = await _db;
    final batch = db.batch();

    for (final change in serverChanges) {
      final map = change as Map<String, dynamic>;
      final id = map['id'].toString();
      final isDeleted = (map['is_deleted'] == true || map['is_deleted'] == 1);

      if (isDeleted) {
        batch.delete('transactions', where: 'id = ?', whereArgs: [id]);
      } else {
        final timestampVal = map['timestamp'];
        int timestampMs;
        if (timestampVal is int) {
          timestampMs = timestampVal;
        } else {
          timestampMs = DateTime.tryParse(timestampVal?.toString() ?? '')?.millisecondsSinceEpoch ??
              DateTime.now().millisecondsSinceEpoch;
        }

        final rawAmount = map['amount'];
        final double amount = (rawAmount is num)
            ? rawAmount.toDouble()
            : (double.tryParse(rawAmount?.toString() ?? '') ?? 0.0);

        final localMap = {
          'id': id,
          'title': (map['title'] ?? 'Expense').toString(),
          'amount': amount,
          'type': (map['type'] ?? 'expense').toString().toLowerCase(),
          'category': (map['category'] ?? 'Other').toString(),
          'paymentMethod': (map['payment_method'] ?? 'UPI').toString(),
          'timestamp': timestampMs,
          'notes': map['notes']?.toString(),
          'sync_status': 'synced',
          'is_deleted': 0,
        };

        batch.insert(
          'transactions',
          localMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    await batch.commit(noResult: true);
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

  // Subscriptions CRUD & Automation
  Future<List<SubscriptionItem>> getAllSubscriptions() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'subscriptions',
      orderBy: 'nextBillingDate ASC',
    );
    return maps.map((map) => SubscriptionItem.fromMap(map)).toList();
  }

  Future<void> insertSubscription(SubscriptionItem sub) async {
    final db = await _db;
    await db.insert(
      'subscriptions',
      sub.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSubscription(SubscriptionItem sub) async {
    final db = await _db;
    await db.update(
      'subscriptions',
      sub.toMap(),
      where: 'id = ?',
      whereArgs: [sub.id],
    );
  }

  Future<void> deleteSubscription(String id) async {
    final db = await _db;
    await db.delete(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markSubscriptionPaid(SubscriptionItem sub) async {
    final db = await _db;
    final now = DateTime.now();

    // 1. Insert a transaction for this billing cycle
    final txItem = TransactionItem(
      id: 'tx_sub_${sub.id}_${now.millisecondsSinceEpoch}',
      title: sub.name,
      amount: sub.amount,
      type: TransactionType.expense,
      category: sub.category,
      paymentMethod: PaymentMethod.fromString(sub.paymentMethod),
      timestamp: now,
      notes: 'Recurring ${sub.billingCycle} Subscription',
      syncStatus: 'pending',
    );
    await insertTransaction(txItem);

    // 2. Advance nextBillingDate to next cycle
    DateTime nextDate;
    if (sub.billingCycle.toLowerCase() == 'yearly') {
      nextDate = DateTime(
        sub.nextBillingDate.year + 1,
        sub.nextBillingDate.month,
        sub.nextBillingDate.day,
      );
    } else if (sub.billingCycle.toLowerCase() == 'weekly') {
      nextDate = sub.nextBillingDate.add(const Duration(days: 7));
    } else {
      // Monthly
      final nextMonth = sub.nextBillingDate.month == 12 ? 1 : sub.nextBillingDate.month + 1;
      final nextYear = sub.nextBillingDate.month == 12 ? sub.nextBillingDate.year + 1 : sub.nextBillingDate.year;
      nextDate = DateTime(nextYear, nextMonth, sub.nextBillingDate.day);
    }

    final updated = sub.copyWith(nextBillingDate: nextDate);
    await updateSubscription(updated);
  }

  // Loans & EMI Tracking
  Future<List<LoanItem>> getAllLoans() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'loans',
      orderBy: 'isClosed ASC, dueDay ASC',
    );
    return maps.map((map) => LoanItem.fromMap(map)).toList();
  }

  Future<void> insertLoan(LoanItem loan) async {
    final db = await _db;
    await db.insert(
      'loans',
      loan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateLoan(LoanItem loan) async {
    final db = await _db;
    await db.update(
      'loans',
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  Future<void> deleteLoan(String id) async {
    final db = await _db;
    await db.delete(
      'loans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> payLoanEmi(LoanItem loan, {PaymentMethod? method}) async {
    final db = await _db;
    final now = DateTime.now();

    final newPaidEmis = loan.paidEmis + 1;
    final newPaidAmount = loan.paidAmount + loan.monthlyEmi;
    final isNowClosed = newPaidEmis >= loan.tenureMonths;

    // 1. Insert an Expense transaction for this EMI
    final txItem = TransactionItem(
      id: 'tx_emi_${loan.id}_${now.millisecondsSinceEpoch}',
      title: 'EMI: ${loan.name} ($newPaidEmis/${loan.tenureMonths})',
      amount: loan.monthlyEmi,
      type: TransactionType.expense,
      category: 'Loans & EMIs',
      paymentMethod: method ?? PaymentMethod.fromString(loan.paymentMethod),
      timestamp: now,
      notes: 'Monthly EMI payment for ${loan.name} (${loan.lender})',
      syncStatus: 'pending',
    );
    await insertTransaction(txItem);

    // 2. Update the loan progress
    final updatedLoan = loan.copyWith(
      paidEmis: newPaidEmis,
      paidAmount: newPaidAmount,
      isClosed: isNowClosed,
    );
    await updateLoan(updatedLoan);
  }
}
