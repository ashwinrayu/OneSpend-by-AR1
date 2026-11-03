import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/enums.dart';
import '../../../models/transaction_item.dart';
import 'transaction_providers.dart';

enum TransactionSortOption {
  dateNewest('Date: Newest First'),
  dateOldest('Date: Oldest First'),
  amountHighToLow('Amount: High to Low'),
  amountLowToHigh('Amount: Low to High');

  final String label;
  const TransactionSortOption(this.label);
}

// Search
final historySearchQueryProvider = StateProvider<String>((ref) => '');

// Type filter: null for All, or TransactionType.expense, TransactionType.income
final historyTypeFilterProvider = StateProvider<TransactionType?>((ref) => null);

// Category filter: set of selected category names (empty set means All)
final historySelectedCategoriesProvider = StateProvider<Set<String>>((ref) => <String>{});

// Payment method filter: null for All, or PaymentMethod
final historyPaymentMethodFilterProvider = StateProvider<PaymentMethod?>((ref) => null);

// Sort Option
final historySortOptionProvider =
    StateProvider<TransactionSortOption>((ref) => TransactionSortOption.dateNewest);

// Pagination: items per page
const int kTransactionsPageSize = 25;
final historyLoadedCountProvider = StateProvider<int>((ref) => kTransactionsPageSize);

// Full filtered & sorted list
final historyFilteredListProvider = Provider<AsyncValue<List<TransactionItem>>>((ref) {
  final txAsync = ref.watch(transactionListProvider);
  final query = ref.watch(historySearchQueryProvider).trim().toLowerCase();
  final typeFilter = ref.watch(historyTypeFilterProvider);
  final selectedCats = ref.watch(historySelectedCategoriesProvider);
  final paymentFilter = ref.watch(historyPaymentMethodFilterProvider);
  final sortOption = ref.watch(historySortOptionProvider);

  return txAsync.whenData((transactions) {
    var result = transactions.where((t) {
      // 1. Text search
      if (query.isNotEmpty) {
        final matchesTitle = t.title.toLowerCase().contains(query);
        final matchesCat = t.category.toLowerCase().contains(query);
        final matchesNotes = t.notes != null && t.notes!.toLowerCase().contains(query);
        if (!matchesTitle && !matchesCat && !matchesNotes) {
          return false;
        }
      }

      // 2. Type filter
      if (typeFilter != null && t.type != typeFilter) {
        return false;
      }

      // 3. Category filter (multi-select)
      if (selectedCats.isNotEmpty && !selectedCats.contains(t.category)) {
        return false;
      }

      // 4. Payment method filter
      if (paymentFilter != null && t.paymentMethod != paymentFilter) {
        return false;
      }

      return true;
    }).toList();

    // Sorting
    switch (sortOption) {
      case TransactionSortOption.dateNewest:
        result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case TransactionSortOption.dateOldest:
        result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case TransactionSortOption.amountHighToLow:
        result.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case TransactionSortOption.amountLowToHigh:
        result.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return result;
  });
});

