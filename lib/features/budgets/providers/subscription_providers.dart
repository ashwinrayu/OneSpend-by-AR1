import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../models/subscription_item.dart';
import '../../transactions/providers/transaction_providers.dart';

class SubscriptionsNotifier extends StateNotifier<AsyncValue<List<SubscriptionItem>>> {
  final Ref ref;

  SubscriptionsNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchSubscriptions();
  }

  ExpenseRepository get _repo => ref.read(expenseRepositoryProvider);

  Future<void> fetchSubscriptions() async {
    try {
      state = const AsyncValue.loading();
      final list = await _repo.getAllSubscriptions();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSubscription(SubscriptionItem sub) async {
    try {
      await _repo.insertSubscription(sub);
      await fetchSubscriptions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSubscription(SubscriptionItem sub) async {
    try {
      await _repo.updateSubscription(sub);
      await fetchSubscriptions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteSubscription(String id) async {
    try {
      await _repo.deleteSubscription(id);
      await fetchSubscriptions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleActive(SubscriptionItem sub) async {
    final updated = sub.copyWith(isActive: !sub.isActive);
    await updateSubscription(updated);
  }

  Future<void> markAsPaid(SubscriptionItem sub) async {
    try {
      await _repo.markSubscriptionPaid(sub);
      await fetchSubscriptions();
      // Refresh transactions so the newly paid bill appears immediately in the history!
      await ref.read(transactionListProvider.notifier).fetchTransactions();
      ref.invalidate(monthlySummaryProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final subscriptionsProvider =
    StateNotifierProvider<SubscriptionsNotifier, AsyncValue<List<SubscriptionItem>>>((ref) {
  return SubscriptionsNotifier(ref);
});

// Computes monthly recurring burn
final monthlySubscriptionBurnProvider = Provider<double>((ref) {
  final subsAsync = ref.watch(subscriptionsProvider);
  return subsAsync.when(
    data: (list) {
      double total = 0.0;
      for (final s in list) {
        if (s.isActive) {
          total += s.monthlyNormalizedAmount;
        }
      }
      return total;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

class CategoryBudgetProgress {
  final String category;
  final double spent;
  final double limit;
  final double percentage;

  const CategoryBudgetProgress({
    required this.category,
    required this.spent,
    required this.limit,
    required this.percentage,
  });

  bool get isOverLimit => spent > limit;
}

final categoryBudgetProgressListProvider = Provider<List<CategoryBudgetProgress>>((ref) {
  final txAsync = ref.watch(transactionListProvider);
  final budgetAsync = ref.watch(activeBudgetProvider);

  final totalMonthlyBudget = budgetAsync.when(
    data: (b) => b.monthlyLimit,
    loading: () => 45000.0,
    error: (_, __) => 45000.0,
  );

  return txAsync.when(
    data: (transactions) {
      final now = DateTime.now();
      final currentMonthTx = transactions.where((tx) =>
          tx.timestamp.month == now.month &&
          tx.timestamp.year == now.year &&
          tx.isExpense);

      final Map<String, double> categorySpent = {};
      for (final tx in currentMonthTx) {
        categorySpent[tx.category] = (categorySpent[tx.category] ?? 0.0) + tx.amount;
      }

      // Default category distribution weights of total budget
      final Map<String, double> categoryWeight = {
        'Food': 0.35,
        'Shopping': 0.25,
        'Bills': 0.20,
        'Transport': 0.12,
        'Entertainment': 0.08,
      };

      final List<CategoryBudgetProgress> result = [];
      categoryWeight.forEach((cat, weight) {
        final spent = categorySpent[cat] ?? 0.0;
        final limit = totalMonthlyBudget * weight;
        final percentage = limit > 0 ? (spent / limit).clamp(0.0, 2.0) : 0.0;

        result.add(CategoryBudgetProgress(
          category: cat,
          spent: spent,
          limit: limit,
          percentage: percentage,
        ));
      });

      return result;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
