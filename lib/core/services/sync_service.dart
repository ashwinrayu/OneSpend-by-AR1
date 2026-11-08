import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/expense_repository.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/loans/providers/loan_providers.dart';
import '../../features/transactions/providers/transaction_providers.dart';
import 'api_client.dart';

enum SyncState {
  synced,
  syncing,
  offline,
  error,
}

class SyncStatus {
  final SyncState state;
  final DateTime? lastSyncedAt;
  final int pendingCount;
  final String? errorMessage;

  const SyncStatus({
    required this.state,
    this.lastSyncedAt,
    this.pendingCount = 0,
    this.errorMessage,
  });

  SyncStatus copyWith({
    SyncState? state,
    DateTime? lastSyncedAt,
    int? pendingCount,
    String? errorMessage,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingCount: pendingCount ?? this.pendingCount,
      errorMessage: errorMessage,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncStatus> {
  final Ref ref;
  Timer? _periodicTimer;

  SyncNotifier(this.ref)
      : super(const SyncStatus(state: SyncState.offline)) {
    _init();
  }

  static const String _lastSyncedKey = 'onespend_last_synced_at';
  static const String _lastLoanSyncedKey = 'onespend_last_loan_synced_at';

  Future<void> _init() async {
    // Load last sync timestamp from preferences
    final prefs = await SharedPreferences.getInstance();
    final savedTime = prefs.getString(_lastSyncedKey);
    DateTime? parsedDate;
    if (savedTime != null) {
      parsedDate = DateTime.tryParse(savedTime);
    }

    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated || auth.isGuest) {
      state = SyncStatus(
        state: SyncState.offline,
        lastSyncedAt: parsedDate,
      );
    } else {
      state = SyncStatus(
        state: SyncState.synced,
        lastSyncedAt: parsedDate,
      );
      // Automatically attempt initial sync in background
      syncNow();
    }

    // Periodically sync every 2 minutes if user is authenticated
    _periodicTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      final currentAuth = ref.read(authControllerProvider);
      if (currentAuth.isAuthenticated && !currentAuth.isGuest) {
        syncNow();
      }
    });

    // Listen for authentication transitions (e.g. Guest -> Signed In)
    ref.listen<AuthState>(authControllerProvider, (previous, next) async {
      if (next.isAuthenticated && !next.isGuest && (previous == null || !previous.isAuthenticated || previous.isGuest)) {
        try {
          final repo = ref.read(expenseRepositoryProvider);
          await repo.markAllTransactionsAsPending();
        } catch (_) {}
        syncNow();
      }
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  Future<void> syncNow() async {
    // Prevent duplicate sync calls
    if (state.state == SyncState.syncing) return;

    final auth = ref.read(authControllerProvider);

    // If offline guest or not logged in, remain in offline state
    if (!auth.isAuthenticated || auth.isGuest || auth.token == null) {
      state = state.copyWith(
        state: SyncState.offline,
        errorMessage: auth.isGuest ? 'Offline Guest Mode' : 'Not signed in',
      );
      return;
    }

    state = state.copyWith(state: SyncState.syncing, errorMessage: null);

    try {
      final repo = ref.read(expenseRepositoryProvider);
      final api = ref.read(apiClientProvider);

      // 1. Fetch pending changes from SQLite
      final pendingItems = await repo.getPendingSyncTransactions();
      final pendingCount = pendingItems.length;

      state = state.copyWith(pendingCount: pendingCount);

      // 2. Format client changes for backend API
      final clientChanges = pendingItems.map((item) {
        return {
          'id': item.id,
          'title': item.title,
          'amount': item.amount,
          'type': item.type.name,
          'category': item.category,
          'paymentMethod': item.paymentMethod.displayName,
          'timestamp': item.timestamp.toIso8601String(),
          'notes': item.notes,
          'isDeleted': item.isDeleted,
        };
      }).toList();

      // 3. Read lastSyncedAt from preferences
      final prefs = await SharedPreferences.getInstance();
      final lastSyncedAt = prefs.getString(_lastSyncedKey);

      // 4. Send delta-sync request to Render backend
      final response = await api.syncTransactions(
        token: auth.token!,
        clientChanges: clientChanges,
        lastSyncedAt: lastSyncedAt,
      );

      // 5. Merge server changes into local SQLite
      final serverChanges = (response['serverChanges'] as List<dynamic>?) ?? [];
      if (serverChanges.isNotEmpty) {
        await repo.mergeServerTransactions(serverChanges);
      }

      // 6. Mark pending items as synced in SQLite
      if (pendingItems.isNotEmpty) {
        final pendingIds = pendingItems.map((e) => e.id).toList();
        await repo.markTransactionsAsSynced(pendingIds);
      }

      // 7. Update last synced timestamp
      final syncedAtStr = response['syncedAt'] as String?;
      DateTime? newSyncedAt;
      if (syncedAtStr != null) {
        await prefs.setString(_lastSyncedKey, syncedAtStr);
        newSyncedAt = DateTime.tryParse(syncedAtStr);
      }

      // 8. Refresh transaction provider to reflect any merged server data
      await ref.read(transactionListProvider.notifier).fetchTransactions();

      // 9. Sync Loans with Render Cloud
      try {
        final pendingLoans = await repo.getPendingSyncLoans();
        final clientLoanChanges = pendingLoans.map((l) {
          return {
            'id': l.id,
            'name': l.name,
            'lender': l.lender,
            'totalAmount': l.totalAmount,
            'interestRate': l.interestRate,
            'tenureMonths': l.tenureMonths,
            'monthlyEmi': l.monthlyEmi,
            'paidEmis': l.paidEmis,
            'paidAmount': l.paidAmount,
            'startDate': l.startDate.toIso8601String(),
            'dueDay': l.dueDay,
            'category': l.category,
            'paymentMethod': l.paymentMethod,
            'isClosed': l.isClosed,
            'notes': l.notes,
            'interestType': l.interestType,
            'lastPaymentDate': l.lastPaymentDate?.toIso8601String(),
            'isDeleted': l.isDeleted,
          };
        }).toList();

        final lastLoanSyncedAt = prefs.getString(_lastLoanSyncedKey);
        final loanResponse = await api.syncLoans(
          token: auth.token!,
          clientChanges: clientLoanChanges,
          lastSyncedAt: lastLoanSyncedAt,
        );

        final serverLoanChanges = (loanResponse['serverChanges'] as List<dynamic>?) ?? [];
        if (serverLoanChanges.isNotEmpty) {
          await repo.mergeServerLoans(serverLoanChanges);
          ref.read(loansProvider.notifier).fetchLoans();
        }

        if (pendingLoans.isNotEmpty) {
          final pendingLoanIds = pendingLoans.map((l) => l.id).toList();
          await repo.markLoansAsSynced(pendingLoanIds);
        }

        final loanSyncedAtStr = loanResponse['syncedAt'] as String?;
        if (loanSyncedAtStr != null) {
          await prefs.setString(_lastLoanSyncedKey, loanSyncedAtStr);
        }
      } catch (loanErr) {
        // Non-blocking for transactions sync
        debugPrint('Loan cloud sync notice: $loanErr');
      }

      state = SyncStatus(
        state: SyncState.synced,
        lastSyncedAt: newSyncedAt ?? DateTime.now(),
        pendingCount: 0,
      );
    } on SocketException {
      state = state.copyWith(
        state: SyncState.offline,
        errorMessage: 'Network offline. Changes saved locally.',
      );
    } on TimeoutException {
      state = state.copyWith(
        state: SyncState.offline,
        errorMessage: 'Connection timed out. Changes saved locally.',
      );
    } catch (e) {
      state = state.copyWith(
        state: SyncState.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final syncServiceProvider =
    StateNotifierProvider<SyncNotifier, SyncStatus>((ref) {
  return SyncNotifier(ref);
});

