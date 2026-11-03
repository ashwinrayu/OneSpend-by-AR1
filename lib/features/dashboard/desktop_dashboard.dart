import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/navigation_provider.dart';
import '../auth/providers/auth_provider.dart';
import '../shell/widgets/sync_status_badge.dart';
import '../transactions/providers/transaction_providers.dart';
import '../transactions/widgets/add_transaction_sheet_or_dialog.dart';
import 'widgets/desktop_metric_cards.dart';
import 'widgets/expense_breakdown_donut.dart';
import 'widgets/monthly_analytics_chart.dart';
import 'widgets/recent_transactions_table.dart';

class DesktopDashboard extends ConsumerStatefulWidget {
  const DesktopDashboard({super.key});

  @override
  ConsumerState<DesktopDashboard> createState() => _DesktopDashboardState();
}

class _DesktopDashboardState extends ConsumerState<DesktopDashboard> {
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final navIndex = ref.watch(navigationIndexProvider);

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
            const _NewTxIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
            const _FocusSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const _FocusHistorySearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB):
            const _BackupIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NewTxIntent: CallbackAction<_NewTxIntent>(
            onInvoke: (_) {
              AddTransactionSheetOrDialog.show(context);
              return null;
            },
          ),
          _FocusSearchIntent: CallbackAction<_FocusSearchIntent>(
            onInvoke: (_) {
              _searchFocusNode.requestFocus();
              return null;
            },
          ),
          _FocusHistorySearchIntent: CallbackAction<_FocusHistorySearchIntent>(
            onInvoke: (_) {
              ref.read(navigationIndexProvider.notifier).state = 1; // History tab
              return null;
            },
          ),
          _BackupIntent: CallbackAction<_BackupIntent>(
            onInvoke: (_) {
              ref.read(navigationIndexProvider.notifier).state = 3; // Settings tab (Backup)
              return null;
            },
          ),
        },
        child: Scaffold(
          backgroundColor: AppColors.desktopBg,
          body: Row(
            children: [
              // 1. Fixed Left Sidebar (250px, #161920)
              _buildLeftSidebar(context, ref, navIndex),

              // 2. Main Content Area (Top Bar + 2-Column Dashboard Grid)
              Expanded(
                child: Column(
                  children: [
                    // Top Action Bar
                    _buildTopActionBar(context),
                    const Divider(color: AppColors.desktopBorder, height: 1),

                    // Scrollable Dashboard Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row 1: Metric Cards
                            summaryAsync.when(
                              data: (summary) =>
                                  DesktopMetricCards(summary: summary),
                              loading: () => const SizedBox(
                                height: 125,
                                child: Center(
                                    child: CircularProgressIndicator()),
                              ),
                              error: (e, _) => Center(
                                child: Text('Failed to load metrics: $e',
                                    style: const TextStyle(
                                        color: AppColors.expense)),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Row 2: Visual Analytics Grid (60% Left, 40% Right)
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left (60%): Monthly Analytics Curve
                                Expanded(
                                  flex: 6,
                                  child: MonthlyAnalyticsChart(),
                                ),
                                SizedBox(width: 20),

                                // Right (40%): Expense Breakdown Donut
                                Expanded(
                                  flex: 4,
                                  child: ExpenseBreakdownDonut(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Row 3: Recent Transactions Data Table
                            const RecentTransactionsTable(),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Left Fixed Sidebar (250px)
  Widget _buildLeftSidebar(
      BuildContext context, WidgetRef ref, int activeIndex) {
    final navItems = [
      (Icons.grid_view_rounded, 'Dashboard', 0),
      (Icons.sync_alt_rounded, 'Transactions', 1),
      (Icons.show_chart_rounded, 'Analytics', 2),
      (Icons.pie_chart_outline_rounded, 'Budgets', 3),
      (Icons.folder_outlined, 'Categories', 4),
      (Icons.insert_drive_file_outlined, 'Reports', 5),
      (Icons.settings_outlined, 'Settings', 6),
    ];

    return Container(
      width: 250,
      color: AppColors.desktopSidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branding Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Row(
              children: [
                // Stylized Monogram Tag: [ 1S ]
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.income.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.income, width: 1.5),
                  ),
                  child: const Text(
                    '1S',
                    style: TextStyle(
                      color: AppColors.income,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OneSpend',
                      style: TextStyle(
                        color: AppColors.desktopTextPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'by AR1studios',
                      style: TextStyle(
                        color: AppColors.desktopTextSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Vertical Navigation Items
          Expanded(
            child: ListView.builder(
              itemCount: navItems.length,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = activeIndex == item.$3;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      ref.read(navigationIndexProvider.notifier).state =
                          item.$3.clamp(0, 4);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF20242D)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? const Border(
                                left: BorderSide(
                                    color: AppColors.income, width: 3),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.$1,
                            size: 19,
                            color: isSelected
                                ? AppColors.income
                                : AppColors.desktopTextSecondary,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            item.$2,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.desktopTextPrimary
                                  : AppColors.desktopTextSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom User Profile & Theme Action Tile
          Builder(builder: (context) {
            final auth = ref.watch(authControllerProvider);
            final userName = auth.user?['full_name'] as String? ??
                (auth.isGuest ? 'Guest User' : 'Ashwin');
            final userInitial =
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1E26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.desktopBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.brandTeal.withOpacity(0.2),
                    child: Text(
                      userInitial,
                      style: const TextStyle(
                        color: AppColors.brandTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.desktopTextPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          auth.isGuest ? 'Offline Mode' : 'Cloud Synced',
                          style: const TextStyle(
                            color: AppColors.desktopTextSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded,
                        size: 17, color: AppColors.desktopTextSecondary),
                    tooltip: auth.isGuest ? 'Exit Guest Mode' : 'Sign Out',
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Top Action Bar
  Widget _buildTopActionBar(BuildContext context) {
    return Container(
      color: AppColors.desktopBg,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting & Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back, Ashwin',
                style: TextStyle(
                  color: AppColors.desktopTextPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Current date • ${Formatters.formatDate(DateTime.now())}',
                style: const TextStyle(
                  color: AppColors.desktopTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Actions Row: Sync Badge, Search, Date Selector, "+ Add Transaction"
          Row(
            children: [
              // Cloud Sync Status Indicator
              const SyncStatusBadge(),
              const SizedBox(width: 14),

              // Search Input with Ctrl+K badge
              Container(
                width: 240,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.desktopCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.desktopBorder),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded,
                        color: AppColors.desktopTextSecondary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: const TextStyle(
                          color: AppColors.desktopTextPrimary,
                          fontSize: 13,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search records...',
                          hintStyle: TextStyle(
                            color: AppColors.desktopTextSecondary,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.desktopBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Ctrl+K',
                        style: TextStyle(
                          color: AppColors.desktopTextSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Month/Year Selector
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.desktopCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.desktopBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    dropdownColor: AppColors.desktopCard,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.desktopTextSecondary, size: 18),
                    items: List.generate(12, (index) {
                      const monthNames = [
                        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                      ];
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(
                          '${monthNames[index]} $_selectedYear',
                          style: const TextStyle(
                            color: AppColors.desktopTextPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedMonth = val);
                        ref.read(activeMonthProvider.notifier).state = val;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Primary Action: "+ Add Transaction" (Emerald Green #10B981)
              ElevatedButton.icon(
                onPressed: () => AddTransactionSheetOrDialog.show(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Row(
                  children: [
                    Text(
                      '+ Add Transaction',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Ctrl+N',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // #10B981
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewTxIntent extends Intent {
  const _NewTxIntent();
}

class _FocusSearchIntent extends Intent {
  const _FocusSearchIntent();
}

class _FocusHistorySearchIntent extends Intent {
  const _FocusHistorySearchIntent();
}

class _BackupIntent extends Intent {
  const _BackupIntent();
}

