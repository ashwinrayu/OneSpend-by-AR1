import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/budgets/screens/budgets_screen.dart';
import '../../features/dashboard/desktop_dashboard.dart';
import '../../features/dashboard/mobile_dashboard.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/shell/responsive_layout.dart';
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

        // If on Dashboard tab (index 0), use the dedicated ResponsiveLayout
        if (currentIndex == 0) {
          return const ResponsiveLayout(
            mobile: MobileDashboard(),
            desktop: DesktopDashboard(),
          );
        }

        final screens = const [
          ResponsiveLayout(
            mobile: MobileDashboard(),
            desktop: DesktopDashboard(),
          ),
          TransactionsScreen(),
          AnalyticsScreen(),
          BudgetsScreen(),
          SettingsScreen(),
        ];

        final currentScreen = screens[currentIndex.clamp(0, screens.length - 1)];

        if (isDesktop) {
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
                    ref.read(navigationIndexProvider.notifier).state = 3; // Settings
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
          // On mobile screens, provide the screen with safe padding
          return currentScreen;
        }
      },
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
