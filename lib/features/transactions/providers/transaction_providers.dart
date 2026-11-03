import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/sync_service.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../models/budget_item.dart';
import '../../../models/category_item.dart';
import '../../../models/enums.dart';
import '../../../models/mock_data.dart';
import '../../../models/transaction_item.dart';

// Database & Repository Providers
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExpenseRepository(db);
});

// Categories Provider
final categoriesProvider = FutureProvider<List<CategoryItem>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final categories = await repo.getAllCategories();
  if (categories.isEmpty) {
    return MockData.defaultCategories;
  }
  return categories;
});

// Active Month & Year
final activeMonthProvider = StateProvider<int>((ref) => DateTime.now().month);
final activeYearProvider = StateProvider<int>((ref) => DateTime.now().year);

// Monthly Budget Provider
final activeBudgetProvider = FutureProvider<BudgetItem>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final month = ref.watch(activeMonthProvider);
  final year = ref.watch(activeYearProvider);

  final budget = await repo.getBudget(month, year);
  return budget ?? MockData.defaultBudget.copyWith(month: month, year: year);
});

// 1. Transaction List StateNotifier Provider
class TransactionListNotifier extends StateNotifier<AsyncValue<List<TransactionItem>>> {
  final Ref ref;

  TransactionListNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      state = const AsyncValue.loading();
      final repo = ref.read(expenseRepositoryProvider);
      final list = await repo.getAllTransactions();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _triggerBackgroundSync() {
    try {
      ref.read(syncServiceProvider.notifier).syncNow();
    } catch (_) {}
  }

  Future<void> addTransaction(TransactionItem item) async {
    try {
      final repo = ref.read(expenseRepositoryProvider);
      await repo.insertTransaction(item);
      await fetchTransactions();
      _triggerBackgroundSync();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTransaction(TransactionItem item) async {
    try {
      final repo = ref.read(expenseRepositoryProvider);
      await repo.updateTransaction(item);
      await fetchTransactions();
      _triggerBackgroundSync();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final repo = ref.read(expenseRepositoryProvider);
      await repo.deleteTransaction(id);
      await fetchTransactions();
      _triggerBackgroundSync();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final transactionListProvider =
    StateNotifierProvider<TransactionListNotifier, AsyncValue<List<TransactionItem>>>((ref) {
  return TransactionListNotifier(ref);
});

// Summary Model
class DashboardMonthlySummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final double monthlyBudget;
  final double budgetRemaining;
  final double spendToBudgetPercentage;

  const DashboardMonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.monthlyBudget,
    required this.budgetRemaining,
    required this.spendToBudgetPercentage,
  });

  bool get isOverBudget => totalExpense > monthlyBudget;
}

// 2. Monthly Summary Provider
final monthlySummaryProvider = Provider<AsyncValue<DashboardMonthlySummary>>((ref) {
  final txAsync = ref.watch(transactionListProvider);
  final budgetAsync = ref.watch(activeBudgetProvider);
  final month = ref.watch(activeMonthProvider);
  final year = ref.watch(activeYearProvider);

  if (txAsync.isLoading || budgetAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (txAsync.hasError) {
    return AsyncValue.error(txAsync.error!, txAsync.stackTrace!);
  }
  if (budgetAsync.hasError) {
    return AsyncValue.error(budgetAsync.error!, budgetAsync.stackTrace!);
  }

  final allTransactions = txAsync.value ?? [];
  final budget = budgetAsync.value?.monthlyLimit ?? 45000.0;

  // Filter transactions for active month & year
  final monthTransactions = allTransactions.where((t) {
    return t.timestamp.month == month && t.timestamp.year == year;
  });

  double income = 0.0;
  double expense = 0.0;

  for (final t in monthTransactions) {
    if (t.type == TransactionType.income) {
      income += t.amount;
    } else {
      expense += t.amount;
    }
  }

  final balance = income - expense;
  final remaining = budget - expense;
  final pct = budget > 0 ? (expense / budget) : 0.0;

  return AsyncValue.data(
    DashboardMonthlySummary(
      totalIncome: income,
      totalExpense: expense,
      balance: balance,
      monthlyBudget: budget,
      budgetRemaining: remaining,
      spendToBudgetPercentage: pct,
    ),
  );
});

// Category Quick Filter for Dashboard
final selectedDashboardCategoryFilterProvider = StateProvider<String>((ref) => 'All');

// 3. Recent Transactions Provider (Latest 5 to 10 transactions, optionally filtered by category)
final recentTransactionsProvider = Provider<AsyncValue<List<TransactionItem>>>((ref) {
  final txAsync = ref.watch(transactionListProvider);
  final categoryFilter = ref.watch(selectedDashboardCategoryFilterProvider);

  return txAsync.whenData((transactions) {
    final filtered = transactions.where((t) {
      if (categoryFilter == 'All') return true;
      return t.category.toLowerCase() == categoryFilter.toLowerCase();
    }).toList();

    // Sort descending by timestamp
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered.take(10).toList();
  });
});

