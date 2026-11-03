import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../transactions/providers/transaction_providers.dart';

class BudgetProgressBar extends StatelessWidget {
  final DashboardMonthlySummary summary;

  const BudgetProgressBar({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = summary.spendToBudgetPercentage;
    final clampedProgress = pct.clamp(0.0, 1.0);

    // Color shifts based on rules:
    // Green (< 70%)
    // Orange (70% - 90%)
    // Red (> 90%)
    Color barColor;
    String statusLabel;
    IconData statusIcon;

    if (pct > 0.90) {
      barColor = AppColors.expense;
      statusLabel = summary.isOverBudget ? 'Over Budget' : 'Critical (>90%)';
      statusIcon = Icons.warning_amber_rounded;
    } else if (pct >= 0.70) {
      barColor = AppColors.warning;
      statusLabel = 'Warning (70-90%)';
      statusIcon = Icons.info_outline_rounded;
    } else {
      barColor = AppColors.income;
      statusLabel = 'On Track (<70%)';
      statusIcon = Icons.check_circle_outline_rounded;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: barColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.pie_chart_outline_rounded, color: barColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Budget Progress',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${Formatters.formatCurrency(summary.totalExpense)} spent of ${Formatters.formatCurrency(summary.monthlyBudget)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: barColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: barColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: barColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Container(
                    height: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.08),
                  ),
                  FractionallySizedBox(
                    widthFactor: clampedProgress,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(pct * 100).toStringAsFixed(1)}% consumed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                ),
                Text(
                  summary.isOverBudget
                      ? 'Exceeded by ${Formatters.formatCurrency(summary.totalExpense - summary.monthlyBudget)}'
                      : 'Remaining: ${Formatters.formatCurrency(summary.budgetRemaining)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: summary.isOverBudget
                        ? AppColors.expense
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

