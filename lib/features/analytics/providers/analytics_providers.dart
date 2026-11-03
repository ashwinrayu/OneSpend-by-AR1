import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/category_item.dart';
import '../../../models/enums.dart';
import '../../../models/transaction_item.dart';
import '../../transactions/providers/transaction_providers.dart';

enum AnalyticsTimeframe {
  thisMonth,
  lastMonth,
  thisYear,
  customRange;

  String get displayName {
    switch (this) {
      case AnalyticsTimeframe.thisMonth:
        return 'This Month';
      case AnalyticsTimeframe.lastMonth:
        return 'Last Month';
      case AnalyticsTimeframe.thisYear:
        return 'This Year';
      case AnalyticsTimeframe.customRange:
        return 'Custom Range';
    }
  }
}

final selectedTimeframeProvider =
    StateProvider<AnalyticsTimeframe>((ref) => AnalyticsTimeframe.thisMonth);

final customDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final selectedPieSectionIndexProvider = StateProvider<int?>((ref) => null);

class CategoryRankItem {
  final String categoryName;
  final double amount;
  final double percentage;
  final Color color;
  final IconData iconData;

  const CategoryRankItem({
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.iconData,
  });
}

class AnalyticsDataState {
  final List<TransactionItem> filteredTransactions;
  final List<TransactionItem> expenses;
  final double totalExpense;
  final double totalIncome;
  final Map<String, double> categoryTotals;
  final List<CategoryRankItem> rankedCategories;
  final Map<int, double> dailyExpenses; // day of month/period -> amount
  final DateTimeRange activeDateRange;

  const AnalyticsDataState({
    required this.filteredTransactions,
    required this.expenses,
    required this.totalExpense,
    required this.totalIncome,
    required this.categoryTotals,
    required this.rankedCategories,
    required this.dailyExpenses,
    required this.activeDateRange,
  });
}

final analyticsDataProvider = Provider<AsyncValue<AnalyticsDataState>>((ref) {
  final txAsync = ref.watch(transactionListProvider);
  final categoriesAsync = ref.watch(categoriesProvider);
  final timeframe = ref.watch(selectedTimeframeProvider);
  final customRange = ref.watch(customDateRangeProvider);

  if (txAsync.isLoading || categoriesAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (txAsync.hasError) {
    return AsyncValue.error(txAsync.error!, txAsync.stackTrace!);
  }

  final allTransactions = txAsync.value ?? [];
  final categories = categoriesAsync.value ?? [];

  final now = DateTime.now();
  late DateTime start;
  late DateTime end;

  switch (timeframe) {
    case AnalyticsTimeframe.thisMonth:
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      break;
    case AnalyticsTimeframe.lastMonth:
      start = DateTime(now.year, now.month - 1, 1);
      end = DateTime(now.year, now.month, 0, 23, 59, 59);
      break;
    case AnalyticsTimeframe.thisYear:
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year, 12, 31, 23, 59, 59);
      break;
    case AnalyticsTimeframe.customRange:
      if (customRange != null) {
        start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
        end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day, 23, 59, 59);
      } else {
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      }
      break;
  }

  final range = DateTimeRange(start: start, end: end);

  final filtered = allTransactions.where((t) {
    return t.timestamp.isAfter(start.subtract(const Duration(seconds: 1))) &&
        t.timestamp.isBefore(end.add(const Duration(seconds: 1)));
  }).toList();

  final expenses = filtered.where((t) => t.isExpense).toList();
  double totalExpense = 0.0;
  double totalIncome = 0.0;

  for (final t in filtered) {
    if (t.isExpense) {
      totalExpense += t.amount;
    } else {
      totalIncome += t.amount;
    }
  }

  // Category totals
  final catTotals = <String, double>{};
  for (final e in expenses) {
    catTotals[e.category] = (catTotals[e.category] ?? 0.0) + e.amount;
  }

  final ranked = <CategoryRankItem>[];
  final sortedEntries = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  for (final entry in sortedEntries) {
    final cat = categories.firstWhere(
      (c) => c.name.toLowerCase() == entry.key.toLowerCase(),
      orElse: () => CategoryItem(
        id: entry.key,
        name: entry.key,
        iconName: 'category',
        hexColor: '#6366F1',
      ),
    );

    final pct = totalExpense > 0 ? (entry.value / totalExpense) : 0.0;
    ranked.add(CategoryRankItem(
      categoryName: entry.key,
      amount: entry.value,
      percentage: pct,
      color: cat.color,
      iconData: cat.iconData,
    ));
  }

  // Daily spend for bar chart
  final dailyExpenses = <int, double>{};
  for (final e in expenses) {
    // Group by day of the month or day of the range
    final key = e.timestamp.day;
    dailyExpenses[key] = (dailyExpenses[key] ?? 0.0) + e.amount;
  }

  return AsyncValue.data(
    AnalyticsDataState(
      filteredTransactions: filtered,
      expenses: expenses,
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      categoryTotals: catTotals,
      rankedCategories: ranked,
      dailyExpenses: dailyExpenses,
      activeDateRange: range,
    ),
  );
});

