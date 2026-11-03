import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_item.dart';
import 'database_provider.dart';

class TransactionNotifier extends StateNotifier<AsyncValue<List<TransactionItem>>> {
  final Ref ref;

  TransactionNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      state = const AsyncValue.loading();
      final repo = ref.read(expenseRepositoryProvider);
      final list = await repo.getAllTransactions();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTransaction(TransactionItem item) async {
    try {
      final repo = ref.read(expenseRepositoryProvider);
      await repo.insertTransaction(item);
      await loadTransactions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTransaction(TransactionItem item) async {
    try {
      final repo = ref.read(expenseRepositoryProvider);
      await repo.updateTransaction(item);
      await loadTransactions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final repo = ref.read(expenseRepositoryProvider);
      await repo.deleteTransaction(id);
      await loadTransactions();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<List<TransactionItem>>>((ref) {
  return TransactionNotifier(ref);
});

// Search and Filter State
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);

final filteredTransactionsProvider = Provider<AsyncValue<List<TransactionItem>>>((ref) {
  final txAsync = ref.watch(transactionsProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final categoryFilter = ref.watch(selectedCategoryFilterProvider);

  return txAsync.whenData((transactions) {
    return transactions.where((tx) {
      final matchesQuery = query.isEmpty ||
          tx.title.toLowerCase().contains(query) ||
          tx.category.toLowerCase().contains(query) ||
          (tx.notes != null && tx.notes!.toLowerCase().contains(query));

      final matchesCategory = categoryFilter == null ||
          categoryFilter == 'All' ||
          tx.category == categoryFilter;

      return matchesQuery && matchesCategory;
    }).toList();
  });
});

