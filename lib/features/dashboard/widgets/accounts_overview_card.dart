import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/enums.dart';
import '../../../models/transaction_item.dart';
import '../../loans/providers/loan_providers.dart';
import '../../settings/providers/preferences_provider.dart';
import '../../transactions/providers/transaction_providers.dart';

class AccountsOverviewCard extends ConsumerWidget {
  const AccountsOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final allTransactions = ref.watch(transactionListProvider).valueOrNull ?? [];

    // Calculate balances per method
    double upiNet = 0;
    double cashNet = 0;
    double bankNet = 0;
    double cardNet = 0;

    for (final tx in allTransactions) {
      final amount = tx.type == TransactionType.income ? tx.amount : -tx.amount;
      switch (tx.paymentMethod) {
        case PaymentMethod.upi:
          upiNet += amount;
          break;
        case PaymentMethod.cash:
          cashNet += amount;
          break;
        case PaymentMethod.bank:
          bankNet += amount;
          break;
        case PaymentMethod.creditCard:
          // For credit card, track total spent/outstanding
          if (tx.type == TransactionType.expense) {
            cardNet += tx.amount;
          }
          break;
      }
    }

    final totalLoanDebt = ref.watch(totalOutstandingDebtProvider);

    final accounts = [
      _AccountDisplay(
        name: 'UPI / Wallets',
        balance: upiNet,
        isDebt: false,
        icon: Icons.qr_code_scanner_rounded,
        color: AppColors.income,
      ),
      _AccountDisplay(
        name: 'Bank Account',
        balance: bankNet,
        isDebt: false,
        icon: Icons.account_balance_rounded,
        color: Colors.blueAccent,
      ),
      _AccountDisplay(
        name: 'Cash in Hand',
        balance: cashNet,
        isDebt: false,
        icon: Icons.payments_rounded,
        color: Colors.amberAccent,
      ),
      _AccountDisplay(
        name: 'Credit Card (Spent)',
        balance: cardNet,
        isDebt: true,
        icon: Icons.credit_card_rounded,
        color: Colors.deepPurpleAccent,
      ),
      if (totalLoanDebt > 0)
        _AccountDisplay(
          name: 'Loans & EMI Debt',
          balance: totalLoanDebt,
          isDebt: true,
          icon: Icons.account_balance_wallet_rounded,
          color: const Color(0xFFF43F5E),
        ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACCOUNTS & WALLETS',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, idx) {
                final acc = accounts[idx];
                return Container(
                  width: 150,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13161C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(acc.icon, color: acc.color, size: 20),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: acc.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acc.name,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${acc.isDebt ? 'Due: ' : ''}$currency ${acc.balance.abs().toStringAsFixed(0)}',
                            style: TextStyle(
                              color: acc.isDebt ? Colors.deepPurpleAccent.shade100 : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountDisplay {
  final String name;
  final double balance;
  final bool isDebt;
  final IconData icon;
  final Color color;

  const _AccountDisplay({
    required this.name,
    required this.balance,
    required this.isDebt,
    required this.icon,
    required this.color,
  });
}

