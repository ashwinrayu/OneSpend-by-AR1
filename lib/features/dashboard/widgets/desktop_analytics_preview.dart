import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/enums.dart';
import '../../../providers/navigation_provider.dart';
import '../../transactions/providers/transaction_providers.dart';

class DesktopAnalyticsPreview extends ConsumerWidget {
  const DesktopAnalyticsPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionListProvider);
    final theme = Theme.of(context);

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
                        color: AppColors.secondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.donut_large_rounded, color: AppColors.secondary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Spend Breakdown',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to Analytics screen (Index 2)
                    ref.read(navigationIndexProvider.notifier).state = 2;
                  },
                  child: const Text('Full Report', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            txAsync.when(
              data: (transactions) {
                final expenses = transactions.where((t) => t.isExpense).toList();
                final total = expenses.fold<double>(0.0, (sum, t) => sum + t.amount);

                if (expenses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No expenses recorded for breakdown.', style: TextStyle(fontSize: 12)),
                    ),
                  );
                }

                final map = <String, double>{};
                for (final e in expenses) {
                  map[e.category] = (map[e.category] ?? 0.0) + e.amount;
                }

                final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                final topCategories = sorted.take(4).toList();

                return Column(
                  children: topCategories.map((entry) {
                    final fraction = total > 0 ? entry.value / total : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${Formatters.formatCurrency(entry.value)} (${(fraction * 100).toStringAsFixed(0)}%)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.65),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: fraction,
                              minHeight: 6,
                              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.08),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: LinearProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

