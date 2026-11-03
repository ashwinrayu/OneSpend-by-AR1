import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/expense_repository.dart';
import '../models/budget_item.dart';
import '../models/mock_data.dart';
import 'database_provider.dart';
import 'transaction_provider.dart';

final selectedMonthProvider = StateProvider<int>((ref) => DateTime.now().month);
final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);

final budgetProvider = FutureProvider<BudgetItem>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final month = ref.watch(selectedMonthProvider);
  final year = ref.watch(selectedYearProvider);

  final budget = await repo.getBudget(month, year);
  return budget ?? MockData.defaultBudget.copyWith(month: month, year: year);
});

final monthlySummaryProvider = FutureProvider<MonthlySummary>((ref) async {
  // Recompute summary whenever transactions or month/year changes
  ref.watch(transactionsProvider);
  final repo = ref.watch(expenseRepositoryProvider);
  final month = ref.watch(selectedMonthProvider);
  final year = ref.watch(selectedYearProvider);

  return await repo.getMonthlySummary(month, year);
});

