import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../models/enums.dart';
import '../../../models/loan_item.dart';
import '../../transactions/providers/transaction_providers.dart';

class LoansNotifier extends StateNotifier<AsyncValue<List<LoanItem>>> {
  final Ref ref;

  LoansNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchLoans();
  }

  ExpenseRepository get _repo => ref.read(expenseRepositoryProvider);

  Future<void> fetchLoans() async {
    try {
      state = const AsyncValue.loading();
      final list = await _repo.getAllLoans();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addLoan(LoanItem loan) async {
    try {
      await _repo.insertLoan(loan);
      await fetchLoans();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateLoan(LoanItem loan) async {
    try {
      await _repo.updateLoan(loan);
      await fetchLoans();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteLoan(String id) async {
    try {
      await _repo.deleteLoan(id);
      await fetchLoans();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> payEmi(LoanItem loan, {PaymentMethod? method}) async {
    try {
      await _repo.payLoanEmi(loan, method: method);
      await fetchLoans();
      // Refresh transactions so the EMI expense shows up immediately
      await ref.read(transactionListProvider.notifier).fetchTransactions();
      ref.invalidate(monthlySummaryProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleClosed(LoanItem loan) async {
    final updated = loan.copyWith(isClosed: !loan.isClosed);
    await updateLoan(updated);
  }
}

final loansProvider =
    StateNotifierProvider<LoansNotifier, AsyncValue<List<LoanItem>>>((ref) {
  return LoansNotifier(ref);
});

/// Active (open) loans
final activeLoansProvider = Provider<List<LoanItem>>((ref) {
  final loansAsync = ref.watch(loansProvider);
  return loansAsync.when(
    data: (list) => list.where((l) => !l.isClosed).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Total outstanding debt to be paid
final totalOutstandingDebtProvider = Provider<double>((ref) {
  final active = ref.watch(activeLoansProvider);
  double sum = 0.0;
  for (final l in active) {
    sum += l.remainingAmount;
  }
  return sum;
});

/// Total monthly EMI burden across all active loans
final totalMonthlyEmiBurdenProvider = Provider<double>((ref) {
  final active = ref.watch(activeLoansProvider);
  double sum = 0.0;
  for (final l in active) {
    sum += l.monthlyEmi;
  }
  return sum;
});

/// Total amount paid across all loans
final totalLoanPaidAmountProvider = Provider<double>((ref) {
  final loansAsync = ref.watch(loansProvider);
  return loansAsync.when(
    data: (list) {
      double sum = 0.0;
      for (final l in list) {
        sum += l.paidAmount;
      }
      return sum;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});
