import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../transactions/providers/transaction_providers.dart';

class DesktopMetricCards extends StatelessWidget {
  final DashboardMonthlySummary summary;

  const DesktopMetricCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Card 1: Total Balance with sparkline & +12.4% badge
        Expanded(
          child: _buildBalanceCard(context),
        ),
        const SizedBox(width: 16),

        // Card 2: Monthly Income
        Expanded(
          child: _buildIncomeCard(context),
        ),
        const SizedBox(width: 16),

        // Card 3: Monthly Expenses
        Expanded(
          child: _buildExpenseCard(context),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Container(
      height: 125,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.desktopCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.desktopBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Title, Balance, Delta Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Total Balance',
                style: TextStyle(
                  color: AppColors.desktopTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                Formatters.formatCurrency(summary.balance),
                style: const TextStyle(
                  color: AppColors.desktopTextPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.income.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '+12.4%',
                      style: TextStyle(
                        color: AppColors.income,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'this month',
                    style: TextStyle(
                      color: AppColors.desktopTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: Mini Decorative Sparkline
          SizedBox(
            width: 75,
            height: 40,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1.2),
                      FlSpot(1, 1.8),
                      FlSpot(2, 1.5),
                      FlSpot(3, 2.4),
                      FlSpot(4, 2.1),
                      FlSpot(5, 3.2),
                      FlSpot(6, 2.9),
                      FlSpot(7, 3.8),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.brandTeal,
                    barWidth: 2.2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.brandTeal.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeCard(BuildContext context) {
    return Container(
      height: 125,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.desktopCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.desktopBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Monthly Income',
                style: TextStyle(
                  color: AppColors.desktopTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                Formatters.formatCurrency(summary.totalIncome),
                style: const TextStyle(
                  color: AppColors.income,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Inflow deposits active',
                style: TextStyle(
                  color: AppColors.desktopTextSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          // Deposit Icon Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.income.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_downward_rounded, color: AppColors.income, size: 20),
                SizedBox(height: 2),
                Text(
                  'deposit',
                  style: TextStyle(
                    color: AppColors.income,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context) {
    return Container(
      height: 125,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.desktopCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.desktopBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Monthly Expenses',
                style: TextStyle(
                  color: AppColors.desktopTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                Formatters.formatCurrency(summary.totalExpense),
                style: const TextStyle(
                  color: AppColors.expense,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(summary.spendToBudgetPercentage * 100).toStringAsFixed(0)}% of monthly budget',
                style: const TextStyle(
                  color: AppColors.desktopTextSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          // Withdraw Icon Badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.expense.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_upward_rounded, color: AppColors.expense, size: 20),
                SizedBox(height: 2),
                Text(
                  'withdraw',
                  style: TextStyle(
                    color: AppColors.expense,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

