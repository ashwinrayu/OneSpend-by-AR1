import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/sync_service.dart';
import '../../core/utils/formatters.dart';
import '../../models/enums.dart';
import '../../models/transaction_item.dart';
import '../../providers/navigation_provider.dart';
import '../auth/providers/auth_provider.dart';
import '../shell/widgets/sync_status_badge.dart';
import '../transactions/providers/transaction_providers.dart';
import '../transactions/widgets/add_transaction_sheet_or_dialog.dart';

class MobileDashboard extends ConsumerStatefulWidget {
  const MobileDashboard({super.key});

  @override
  ConsumerState<MobileDashboard> createState() => _MobileDashboardState();
}

class _MobileDashboardState extends ConsumerState<MobileDashboard> {
  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.mobileBg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.mobileCard,
          onRefresh: () async {
            await ref.read(transactionListProvider.notifier).fetchTransactions();
            ref.invalidate(activeBudgetProvider);
            ref.read(syncServiceProvider.notifier).syncNow();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Status Bar Header (Avatar, Greeting, Notification)
                _buildTopHeader(context),
                const SizedBox(height: 20),

                // 2. Hero Balance Card
                summaryAsync.when(
                  data: (summary) => _buildHeroBalanceCard(context, summary),
                  loading: () => Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.mobileCard,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text('Error: $e', style: const TextStyle(color: AppColors.expense)),
                  ),
                ),
                const SizedBox(height: 22),

                // 3. Quick Action Row: [Scan], [Add], [Transfer], [Insights]
                _buildQuickActionsRow(context),
                const SizedBox(height: 24),

                // 4. Spending Breakdown Card
                _buildSpendingBreakdownCard(context),
                const SizedBox(height: 24),

                // 5. Recent Transactions Header & List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Switch tab to Transactions (index 1)
                        ref.read(navigationIndexProvider.notifier).state = 1;
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Recent Transactions List with Swipe-to-delete
                recentAsync.when(
                  data: (transactions) => _buildRecentTransactionsList(context, ref, transactions),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),

                // Padding at bottom to not be hidden by Bottom Bar & FAB
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Top Status Bar Header
  Widget _buildTopHeader(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final userName = auth.user?['full_name'] as String? ?? (auth.isGuest ? 'Guest' : 'Ashwin');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Profile Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.mobileCardBorder, width: 2),
                color: const Color(0xFF232733),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white70, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'OneSpend by AR1',
                  style: TextStyle(
                    color: AppColors.income,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Actions: Cloud Sync Badge & Notifications
        Row(
          children: [
            const SyncStatusBadge(compact: true),
            const SizedBox(width: 8),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.mobileCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.mobileCardBorder),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                  Positioned(
                    top: 10,
                    right: 11,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444), // red notification dot
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Hero Balance Card (#1A1D24)
  Widget _buildHeroBalanceCard(BuildContext context, DashboardMonthlySummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.mobileCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.mobileCardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(
              color: Color(0xFF8E95A5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatCurrency(summary.balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),

          // Percentage Delta Badge (+12.4% this month)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.income.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+12.4%',
                  style: TextStyle(
                    color: AppColors.income,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'this month',
                style: TextStyle(
                  color: Color(0xFF8E95A5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.mobileCardBorder, height: 1),
          const SizedBox(height: 14),

          // Inflow & Outflow Row
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.income.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_downward_rounded,
                          color: AppColors.income, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Income',
                          style: TextStyle(color: Color(0xFF8E95A5), fontSize: 11),
                        ),
                        Text(
                          Formatters.formatCompactCurrency(summary.totalIncome),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 26, color: AppColors.mobileCardBorder),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_upward_rounded,
                            color: AppColors.expense, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Expenses',
                            style: TextStyle(color: Color(0xFF8E95A5), fontSize: 11),
                          ),
                          Text(
                            Formatters.formatCompactCurrency(summary.totalExpense),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Quick Action Row
  Widget _buildQuickActionsRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionItem(
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan',
              borderColor: const Color(0xFF10B981),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bill scanner ready...')),
                );
              },
            ),
            _buildActionItem(
              icon: Icons.add_rounded,
              label: 'Add',
              borderColor: const Color(0xFF262B35),
              onTap: () => AddTransactionSheetOrDialog.show(context),
            ),
            _buildActionItem(
              icon: Icons.savings_rounded,
              label: 'Budgets',
              borderColor: const Color(0xFF10B981),
              onTap: () {
                ref.read(navigationIndexProvider.notifier).state = 3; // Budgets screen
              },
            ),
            _buildActionItem(
              icon: Icons.insights_rounded,
              label: 'Insights',
              borderColor: const Color(0xFF8B5CF6),
              onTap: () {
                ref.read(navigationIndexProvider.notifier).state = 2; // Analytics
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.mobileActionBg,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: borderColor.withOpacity(0.12),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8E95A5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Spending Breakdown Card
  Widget _buildSpendingBreakdownCard(BuildContext context) {
    final breakdown = const [
      (label: 'Shopping', value: 40.0, color: Color(0xFF10B981)),
      (label: 'Food', value: 30.0, color: Color(0xFFF43F5E)),
      (label: 'Bills', value: 18.0, color: Color(0xFF475569)),
      (label: 'Others', value: 12.0, color: Color(0xFF64748B)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.mobileCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.mobileCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 120,
                height: 120,
                child: PieChart(
                  PieChartData(
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 3,
                    centerSpaceRadius: 38,
                    sections: breakdown.map((item) {
                      return PieChartSectionData(
                        color: item.color,
                        value: item.value,
                        title: '',
                        radius: 18,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 28),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: breakdown.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.label,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Recent Transactions List
  Widget _buildRecentTransactionsList(
      BuildContext context, WidgetRef ref, List<TransactionItem> transactions) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.mobileCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            'No transactions logged yet',
            style: TextStyle(color: Color(0xFF8E95A5)),
          ),
        ),
      );
    }

    final displayed = transactions.take(4).toList();

    return Column(
      children: displayed.map((tx) {
        final isExpense = tx.isExpense;

        // Custom icon & color mapping matching reference image
        IconData itemIcon;
        Color iconBg;
        Color iconColor;

        if (tx.category.toLowerCase().contains('shop')) {
          itemIcon = Icons.shopping_bag_outlined;
          iconBg = const Color(0xFFF43F5E).withOpacity(0.18);
          iconColor = const Color(0xFFF43F5E);
        } else if (tx.type == TransactionType.income ||
            tx.category.toLowerCase().contains('salary')) {
          itemIcon = Icons.account_balance_wallet_outlined;
          iconBg = const Color(0xFF10B981).withOpacity(0.18);
          iconColor = const Color(0xFF10B981);
        } else if (tx.category.toLowerCase().contains('bill') ||
            tx.category.toLowerCase().contains('util')) {
          itemIcon = Icons.bolt_rounded;
          iconBg = const Color(0xFF475569).withOpacity(0.28);
          iconColor = const Color(0xFF94A3B8);
        } else {
          itemIcon = Icons.restaurant_outlined;
          iconBg = const Color(0xFFF59E0B).withOpacity(0.18);
          iconColor = const Color(0xFFF59E0B);
        }

        return Dismissible(
          key: Key(tx.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.expense,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          onDismissed: (_) {
            ref.read(transactionListProvider.notifier).deleteTransaction(tx.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Removed "${tx.title}"'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    ref.read(transactionListProvider.notifier).addTransaction(tx);
                  },
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.mobileCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.mobileCardBorder.withOpacity(0.7)),
            ),
            child: Row(
              children: [
                // Category Rounded Container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(itemIcon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),

                // Title & Subtitle (Time + Payment Mode)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${Formatters.formatRelativeDate(tx.timestamp)}, ${Formatters.formatTime(tx.timestamp)}',
                        style: const TextStyle(
                          color: Color(0xFF8E95A5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  '${isExpense ? '-' : '+'}${Formatters.formatCurrency(tx.amount)}',
                  style: TextStyle(
                    color: isExpense ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

