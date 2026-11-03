import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../features/transactions/widgets/add_transaction_sheet_or_dialog.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/theme_provider.dart';

class DesktopSidebar extends ConsumerWidget {
  const DesktopSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final isExpanded = ref.watch(sidebarExpandedProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final navItems = [
      (Icons.dashboard_rounded, 'Dashboard'),
      (Icons.receipt_long_rounded, 'Transactions'),
      (Icons.insights_rounded, 'Analytics'),
      (Icons.settings_rounded, 'Settings'),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExpanded ? 240 : 76,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App Title / Brand Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OneSpend',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'by AR1studios',
                          style: TextStyle(
                            color: AppColors.desktopTextSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Quick Add Transaction Button (Ctrl+N hint)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: isExpanded
                ? FilledButton.icon(
                    onPressed: () => AddTransactionSheetOrDialog.show(context),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Add New', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          'Ctrl+N',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                : IconButton.filled(
                    tooltip: 'Add Transaction (Ctrl+N)',
                    onPressed: () => AddTransactionSheetOrDialog.show(context),
                    icon: const Icon(Icons.add_rounded),
                  ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, indent: 12, endIndent: 12),
          const SizedBox(height: 12),

          // Navigation Links
          Expanded(
            child: ListView.builder(
              itemCount: navItems.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = currentIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    selected: isSelected,
                    selectedTileColor: AppColors.primary.withOpacity(0.12),
                    selectedColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    leading: Icon(
                      item.$1,
                      color: isSelected
                          ? AppColors.primary
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    title: isExpanded
                        ? Text(
                            item.$2,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          )
                        : null,
                    onTap: () {
                      ref.read(navigationIndexProvider.notifier).state = index;
                    },
                  ),
                );
              },
            ),
          ),

          // Bottom Controls: Collapse toggle & Theme toggle
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment:
                  isExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 20,
                  ),
                  onPressed: () {
                    final current = ref.read(themeModeProvider);
                    ref.read(themeModeProvider.notifier).state =
                        current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                  },
                ),
                IconButton(
                  tooltip: isExpanded ? 'Collapse Sidebar' : 'Expand Sidebar',
                  icon: Icon(
                    isExpanded ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    size: 20,
                  ),
                  onPressed: () {
                    ref.read(sidebarExpandedProvider.notifier).state = !isExpanded;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
