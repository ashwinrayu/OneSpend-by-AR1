import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/financial_health_service.dart';
import '../../settings/providers/preferences_provider.dart';
import '../../transactions/providers/transaction_providers.dart';
import 'smart_bill_splitter_dialog.dart';

class FinancialHealthCard extends ConsumerWidget {
  const FinancialHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final activeBudget = ref.watch(activeBudgetProvider).valueOrNull;
    final allTransactions = ref.watch(transactionListProvider).valueOrNull ?? [];

    final metrics = FinancialHealthService.calculate(
      activeBudget: activeBudget,
      allTransactions: allTransactions,
    );

    Color scoreColor;
    if (metrics.healthScore >= 80) {
      scoreColor = AppColors.income;
    } else if (metrics.healthScore >= 60) {
      scoreColor = Colors.amberAccent;
    } else {
      scoreColor = AppColors.expense;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF13161C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showDetailedHealthSheet(context, metrics, currency),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Safe Daily Spend & Health Score badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: scoreColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.speed_rounded, color: scoreColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SAFE DAILY SPEND',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              '$currency ${metrics.safeDailySpend.toStringAsFixed(0)} / day',
                              style: TextStyle(
                                color: metrics.isOverBudget ? AppColors.expense : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: scoreColor.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, color: scoreColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Health: ${metrics.healthScore}/100',
                            style: TextStyle(
                              color: scoreColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Advice Headline & Message
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metrics.statusHeadline,
                            style: TextStyle(
                              color: scoreColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            metrics.statusAdvice,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailedHealthSheet(
    BuildContext context,
    FinancialHealthMetrics metrics,
    String currency,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF13161C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Financial Health Diagnostic',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.income.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Score: ${metrics.healthScore}/100',
                      style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                metrics.statusAdvice,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),

              // Diagnostics Grid
              Row(
                children: [
                  _statItem('Remaining Budget', '$currency ${metrics.remainingBudget.toStringAsFixed(0)}'),
                  const SizedBox(width: 12),
                  _statItem('Days Left', '${metrics.daysRemaining} days'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _statItem('Daily Burn Average', '$currency ${metrics.dailyAverageSpent.toStringAsFixed(0)}/day'),
                  const SizedBox(width: 12),
                  _statItem('Savings Rate', '${metrics.savingsRate.toStringAsFixed(1)}%'),
                ],
              ),
              const SizedBox(height: 20),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        showDialog(
                          context: context,
                          builder: (_) => const SmartBillSplitterDialog(),
                        );
                      },
                      icon: const Icon(Icons.call_split_rounded, size: 16),
                      label: const Text('Split a Bill'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.income,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _statItem(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1E26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
