import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../providers/analytics_providers.dart';

class CategoryDonutChart extends ConsumerWidget {
  final AnalyticsDataState dataState;

  const CategoryDonutChart({super.key, required this.dataState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ranked = dataState.rankedCategories;
    final totalExpense = dataState.totalExpense;
    final selectedIndex = ref.watch(selectedPieSectionIndexProvider);

    if (ranked.isEmpty || totalExpense <= 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.pie_chart_outline_rounded,
                    size: 48, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(height: 12),
                const Text('No expense data available for this timeframe',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
    }

    // Identify highlighted item
    final activeItem = (selectedIndex != null && selectedIndex >= 0 && selectedIndex < ranked.length)
        ? ranked[selectedIndex]
        : null;

    final centerTitle = activeItem != null
        ? activeItem.categoryName
        : 'Total Spend';
    final centerAmount = activeItem != null
        ? Formatters.formatCurrency(activeItem.amount)
        : Formatters.formatCurrency(totalExpense);
    final centerSub = activeItem != null
        ? '${(activeItem.percentage * 100).toStringAsFixed(1)}% of total'
        : '${ranked.length} Categories';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (selectedIndex != null)
                  TextButton(
                    onPressed: () {
                      ref.read(selectedPieSectionIndexProvider.notifier).state = null;
                    },
                    child: const Text('Reset Selection', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Donut Chart with Center Hole
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            return;
                          }
                          final touchedIndex =
                              pieTouchResponse.touchedSection!.touchedSectionIndex;
                          if (touchedIndex >= 0 && touchedIndex < ranked.length) {
                            ref.read(selectedPieSectionIndexProvider.notifier).state =
                                touchedIndex;
                          }
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 65,
                      sections: List.generate(ranked.length, (i) {
                        final isTouched = i == selectedIndex;
                        final item = ranked[i];
                        final radius = isTouched ? 36.0 : 28.0;

                        return PieChartSectionData(
                          color: item.color,
                          value: item.amount,
                          title: isTouched
                              ? '${(item.percentage * 100).toStringAsFixed(0)}%'
                              : '',
                          radius: radius,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ),

                  // Center Hole Content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        centerTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        centerAmount,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        centerSub,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: activeItem != null ? activeItem.color : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Interactive Legend Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(ranked.length, (i) {
                final item = ranked[i];
                final isSelected = i == selectedIndex;

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    ref.read(selectedPieSectionIndexProvider.notifier).state =
                        isSelected ? null : i;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? item.color.withOpacity(0.18)
                          : theme.colorScheme.onSurface.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? item.color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.categoryName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(item.percentage * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

