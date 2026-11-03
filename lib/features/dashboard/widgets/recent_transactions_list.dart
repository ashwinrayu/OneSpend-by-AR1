import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/transaction_item.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../transactions/widgets/add_transaction_sheet_or_dialog.dart';
import 'transaction_tile.dart';

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final currentFilter = ref.watch(selectedDashboardCategoryFilterProvider);

    return recentAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return _buildEmptyState(context, ref, currentFilter);
        }

        final categories = categoriesAsync.value ?? [];

        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              return TransactionTile(
                transaction: transactions[index],
                categories: categories,
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text('Error loading transactions: $e'),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, String currentFilter) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                currentFilter == 'All'
                    ? 'No transactions yet'
                    : 'No "$currentFilter" transactions found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                currentFilter == 'All'
                    ? 'Tap "+ Add Transaction" or press Ctrl+N to log your first spend.'
                    : 'Try selecting "All" or add a new transaction under $currentFilter.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 20),
              if (currentFilter != 'All')
                OutlinedButton(
                  onPressed: () {
                    ref.read(selectedDashboardCategoryFilterProvider.notifier).state = 'All';
                  },
                  child: const Text('Show All Categories'),
                )
              else
                FilledButton.icon(
                  onPressed: () => AddTransactionSheetOrDialog.show(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add First Transaction'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

