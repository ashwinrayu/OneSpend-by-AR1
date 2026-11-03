import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/budgets/screens/budgets_screen.dart';
import '../../features/dashboard/desktop_dashboard.dart';
import '../../features/dashboard/mobile_dashboard.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/transactions/screens/transactions_screen.dart';
import '../../features/transactions/widgets/add_transaction_sheet_or_dialog.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/navigation/desktop_sidebar.dart';

class ResponsiveShell extends ConsumerWidget {
  const ResponsiveShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        // Desktop layout
        if (isDesktop) {
          if (currentIndex == 0) {
            return const DesktopDashboard();
          }

          final desktopScreens = const [
            DesktopDashboard(),
            TransactionsScreen(),
            AnalyticsScreen(),
            BudgetsScreen(),
            SettingsScreen(),
          ];

          final currentScreen = desktopScreens[currentIndex.clamp(0, desktopScreens.length - 1)];

          return Shortcuts(
            shortcuts: <LogicalKeySet, Intent>{
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
                  const _NewTxIntent(),
              LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
                  const _HistorySearchIntent(),
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
                _HistorySearchIntent: CallbackAction<_HistorySearchIntent>(
                  onInvoke: (_) {
                    ref.read(navigationIndexProvider.notifier).state = 1; // History
                    return null;
                  },
                ),
                _BackupIntent: CallbackAction<_BackupIntent>(
                  onInvoke: (_) {
                    ref.read(navigationIndexProvider.notifier).state = 4; // Settings
                    return null;
                  },
                ),
              },
              child: Scaffold(
                backgroundColor: const Color(0xFF0D0F14),
                body: Row(
                  children: [
                    const DesktopSidebar(),
                    Expanded(child: currentScreen),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Mobile layout: persistent bottom navigation bar + back interceptor
          final mobileScreens = const [
            MobileDashboard(),
            TransactionsScreen(),
            AnalyticsScreen(),
            BudgetsScreen(),
            SettingsScreen(),
          ];

          final currentScreen = mobileScreens[currentIndex.clamp(0, mobileScreens.length - 1)];

          return PopScope(
            canPop: currentIndex == 0,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) {
                // If on any sub-screen, return cleanly to Dashboard (index 0)
                ref.read(navigationIndexProvider.notifier).state = 0;
              }
            },
            child: Scaffold(
              backgroundColor: AppColors.mobileBg,
              body: currentScreen,
              bottomNavigationBar: _OneSpendMobileBottomNav(
                currentIndex: currentIndex,
                onSelected: (index) {
                  ref.read(navigationIndexProvider.notifier).state = index;
                },
              ),
              floatingActionButton: FloatingActionButton(
                backgroundColor: AppColors.primary,
                elevation: 6,
                shape: const CircleBorder(),
                tooltip: 'Add Transaction',
                onPressed: () => AddTransactionSheetOrDialog.show(context),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            ),
          );
        }
      },
    );
  }
}

class _OneSpendMobileBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const _OneSpendMobileBottomNav({
    required this.currentIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      (Icons.dashboard_rounded, Icons.dashboard_outlined, 'Home'),
      (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'History'),
      (Icons.insights_rounded, Icons.insights_outlined, 'Analytics'),
      (Icons.pie_chart_rounded, Icons.pie_chart_outline_rounded, 'Budgets'),
      (Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
    ];

    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: AppColors.mobileNavBg,
        border: Border(
          top: BorderSide(
            color: AppColors.mobileCardBorder.withOpacity(0.6),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (index) {
            final isSelected = currentIndex == index;
            final item = navItems[index];

            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? item.$1 : item.$2,
                        color: isSelected ? AppColors.primary : const Color(0xFF8E95A5),
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.$3,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : const Color(0xFF8E95A5),
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NewTxIntent extends Intent {
  const _NewTxIntent();
}

class _HistorySearchIntent extends Intent {
  const _HistorySearchIntent();
}

class _BackupIntent extends Intent {
  const _BackupIntent();
}
