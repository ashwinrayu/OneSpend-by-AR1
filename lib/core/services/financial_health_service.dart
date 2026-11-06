import 'dart:math';
import '../../models/budget_item.dart';
import '../../models/transaction_item.dart';

class FinancialHealthMetrics {
  final double monthlyLimit;
  final double spentThisMonth;
  final double incomeThisMonth;
  final double remainingBudget;
  final double safeDailySpend;
  final double dailyAverageSpent;
  final double projectedExpense;
  final double savingsRate; // Percentage e.g. 35.5
  final int healthScore; // 0 - 100
  final int daysRemaining;
  final int totalDaysInMonth;
  final String statusHeadline;
  final String statusAdvice;
  final bool isOverBudget;

  const FinancialHealthMetrics({
    required this.monthlyLimit,
    required this.spentThisMonth,
    required this.incomeThisMonth,
    required this.remainingBudget,
    required this.safeDailySpend,
    required this.dailyAverageSpent,
    required this.projectedExpense,
    required this.savingsRate,
    required this.healthScore,
    required this.daysRemaining,
    required this.totalDaysInMonth,
    required this.statusHeadline,
    required this.statusAdvice,
    required this.isOverBudget,
  });
}

class FinancialHealthService {
  static FinancialHealthMetrics calculate({
    required BudgetItem? activeBudget,
    required List<TransactionItem> allTransactions,
  }) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final nextMonthFirstDay = (now.month < 12)
        ? DateTime(now.year, now.month + 1, 1)
        : DateTime(now.year + 1, 1, 1);
    final totalDaysInMonth = nextMonthFirstDay.difference(firstDayOfMonth).inDays;
    final dayOfMonth = now.day;
    final daysRemaining = max(1, totalDaysInMonth - dayOfMonth + 1);

    double spentThisMonth = 0;
    double incomeThisMonth = 0;

    for (final tx in allTransactions) {
      if (tx.timestamp.isAfter(firstDayOfMonth) ||
          tx.timestamp.isAtSameMomentAs(firstDayOfMonth)) {
        if (tx.type == TransactionType.expense) {
          spentThisMonth += tx.amount;
        } else if (tx.type == TransactionType.income) {
          incomeThisMonth += tx.amount;
        }
      }
    }

    final monthlyLimit = activeBudget?.monthlyLimit ?? 30000.0;
    final remainingBudget = max(0.0, monthlyLimit - spentThisMonth);
    final isOverBudget = spentThisMonth > monthlyLimit;

    final safeDailySpend = isOverBudget
        ? 0.0
        : (remainingBudget / daysRemaining);

    final dailyAverageSpent = spentThisMonth / max(1, dayOfMonth);
    final projectedExpense = dailyAverageSpent * totalDaysInMonth;

    // Calculate Savings Rate (%)
    final netSavings = incomeThisMonth - spentThisMonth;
    final savingsRate = incomeThisMonth > 0
        ? max(0.0, (netSavings / incomeThisMonth) * 100)
        : 0.0;

    // Calculate Financial Health Score (0 - 100)
    int score = 70; // baseline

    // Factor 1: Budget utilization vs calendar elapsed
    final calendarElapsedRatio = dayOfMonth / totalDaysInMonth;
    final budgetUsedRatio = monthlyLimit > 0 ? (spentThisMonth / monthlyLimit) : 1.0;

    if (budgetUsedRatio < calendarElapsedRatio * 0.8) {
      score += 20; // Burning slower than calendar
    } else if (budgetUsedRatio <= calendarElapsedRatio) {
      score += 10; // Perfectly on track
    } else if (budgetUsedRatio <= calendarElapsedRatio * 1.25) {
      score -= 15; // Slightly accelerated burn
    } else {
      score -= 35; // Severe budget drain
    }

    // Factor 2: Savings discipline
    if (savingsRate >= 30) {
      score += 10;
    } else if (savingsRate >= 15) {
      score += 5;
    } else if (incomeThisMonth > 0 && netSavings < 0) {
      score -= 20;
    }

    score = score.clamp(15, 99);

    // Formulate personalized actionable headline & advice
    String headline;
    String advice;

    if (isOverBudget) {
      headline = 'Budget Exceeded';
      advice =
          'You have crossed your limit by ${(spentThisMonth - monthlyLimit).toStringAsFixed(0)}. Freeze non-essential expenses for the next $daysRemaining days.';
    } else if (score >= 85) {
      headline = 'Elite Discipline 🌟';
      advice =
          'You are spending below your budget velocity. Keep your daily spending around ${safeDailySpend.toStringAsFixed(0)} to finish the month with high surplus.';
    } else if (score >= 70) {
      headline = 'On Track 👍';
      advice =
          'Your pace is sustainable. You have ${remainingBudget.toStringAsFixed(0)} left for $daysRemaining days (${safeDailySpend.toStringAsFixed(0)}/day limit).';
    } else if (score >= 50) {
      headline = 'Moderate Caution ⚠️';
      advice =
          'Your average daily burn of ${dailyAverageSpent.toStringAsFixed(0)} is slightly ahead of target. Trim dining or shopping to stay under.';
    } else {
      headline = 'High Burn Rate 🔥';
      advice =
          'At current pace, projected monthly spend will hit ${projectedExpense.toStringAsFixed(0)}. Reduce daily spending to below ${safeDailySpend.toStringAsFixed(0)}.';
    }

    return FinancialHealthMetrics(
      monthlyLimit: monthlyLimit,
      spentThisMonth: spentThisMonth,
      incomeThisMonth: incomeThisMonth,
      remainingBudget: remainingBudget,
      safeDailySpend: safeDailySpend,
      dailyAverageSpent: dailyAverageSpent,
      projectedExpense: projectedExpense,
      savingsRate: savingsRate,
      healthScore: score,
      daysRemaining: daysRemaining,
      totalDaysInMonth: totalDaysInMonth,
      statusHeadline: headline,
      statusAdvice: advice,
      isOverBudget: isOverBudget,
    );
  }
}
