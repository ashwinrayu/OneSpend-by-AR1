import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../providers/analytics_providers.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/highest_expense_categories_list.dart';
import '../widgets/spending_trend_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final current = ref.read(customDateRangeProvider) ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: current,
    );

    if (picked != null) {
      ref.read(customDateRangeProvider.notifier).state = picked;
      ref.read(selectedTimeframeProvider.notifier).state = AnalyticsTimeframe.customRange;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(analyticsDataProvider);
    final selectedTimeframe = ref.watch(selectedTimeframeProvider);
    final customRange = ref.watch(customDateRangeProvider);
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Visualizations'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Timeframe Selector Segmented Control
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<AnalyticsTimeframe>(
                  segments: AnalyticsTimeframe.values.map((tf) {
                    return ButtonSegment(
                      value: tf,
                      label: Text(tf.displayName),
                    );
                  }).toList(),
                  selected: {selectedTimeframe},
                  onSelectionChanged: (set) {
                    final choice = set.first;
                    if (choice == AnalyticsTimeframe.customRange) {
                      _pickCustomRange(context, ref);
                    } else {
                      ref.read(selectedTimeframeProvider.notifier).state = choice;
                    }
                  },
                ),
                if (selectedTimeframe == AnalyticsTimeframe.customRange && customRange != null)
                  ActionChip(
                    avatar: const Icon(Icons.date_range_rounded, size: 16),
                    label: Text(
                      '${Formatters.formatDate(customRange.start)} - ${Formatters.formatDate(customRange.end)}',
                    ),
                    onPressed: () => _pickCustomRange(context, ref),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Content Area
            dataAsync.when(
              data: (data) {
                // Summary Metric Cards
                final net = data.totalIncome - data.totalExpense;

                final summaryRow = Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        'Total Spend',
                        Formatters.formatCurrency(data.totalExpense),
                        Icons.trending_down_rounded,
                        AppColors.expense,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        'Total Income',
                        Formatters.formatCurrency(data.totalIncome),
                        Icons.trending_up_rounded,
                        AppColors.income,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        'Net Balance',
                        Formatters.formatCurrency(net),
                        net >= 0 ? Icons.check_circle_rounded : Icons.warning_rounded,
                        net >= 0 ? AppColors.income : AppColors.expense,
                      ),
                    ),
                  ],
                );

                if (isDesktop) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      summaryRow,
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: CategoryDonutChart(dataState: data),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 6,
                            child: SpendingTrendChart(dataState: data),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      HighestExpenseCategoriesList(dataState: data),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      summaryRow,
                      const SizedBox(height: 20),
                      CategoryDonutChart(dataState: data),
                      const SizedBox(height: 20),
                      SpendingTrendChart(dataState: data),
                      const SizedBox(height: 20),
                      HighestExpenseCategoriesList(dataState: data),
                    ],
                  );
                }
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Text('Error loading analytics: $err'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context,
    String label,
    String amount,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
