import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../core/services/update_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/budget_item.dart';
import '../../../models/enums.dart';
import '../../../providers/navigation_provider.dart';
import '../../analytics/providers/analytics_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../shell/widgets/sync_status_badge.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../providers/preferences_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _editBudget(BuildContext context, WidgetRef ref, BudgetItem current) {
    final controller = TextEditingController(text: current.monthlyLimit.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Monthly Budget Target'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set your spending target limit for this month:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                prefixText: '${ref.watch(currencyProvider)} ',
                labelText: 'Monthly Limit',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                final repo = ref.read(expenseRepositoryProvider);
                await repo.setBudget(current.copyWith(monthlyLimit: val));
                ref.invalidate(activeBudgetProvider);
                ref.invalidate(monthlySummaryProvider);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budget target updated successfully!')),
                );
              }
            },
            child: const Text('Save Target'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    final result = await BackupService.exportBackup();
    if (!context.mounted) return;

    if (result.success) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 40),
          title: const Text('Backup Completed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${result.message}:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  result.filePath ?? 'Saved',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: AppColors.expense),
      );
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final result = await BackupService.importBackup();
    if (!context.mounted) return;

    if (result.success) {
      // Invalidate all state to refresh the entire UI
      ref.invalidate(transactionListProvider);
      ref.invalidate(monthlySummaryProvider);
      ref.invalidate(activeBudgetProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(analyticsDataProvider);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.cloud_done_rounded, color: AppColors.income, size: 40),
          title: const Text('Restore Successful'),
          content: Text(result.message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Great'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: AppColors.expense),
      );
    }
  }

  void _confirmFactoryReset(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final isConfirmed = textController.text.trim() == 'DELETE';

          return AlertDialog(
            icon: const Icon(Icons.warning_amber_rounded, color: AppColors.expense, size: 40),
            title: const Text('Factory Reset & Wipe Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This action will permanently erase all transactions, custom categories, and budgets in your local vault. This cannot be undone.',
                  style: TextStyle(height: 1.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Type "DELETE" below to confirm:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: textController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'DELETE',
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
                onPressed: isConfirmed
                    ? () async {
                        Navigator.of(ctx).pop();
                        await BackupService.factoryReset();
                        ref.invalidate(transactionListProvider);
                        ref.invalidate(monthlySummaryProvider);
                        ref.invalidate(activeBudgetProvider);
                        ref.invalidate(categoriesProvider);
                        ref.invalidate(analyticsDataProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vault reset to factory defaults.'),
                              backgroundColor: AppColors.expense,
                            ),
                          );
                        }
                      }
                    : null,
                child: const Text('Erase All Data'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.income.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.income, width: 2),
              ),
              child: const Text(
                '1S',
                style: TextStyle(
                  color: AppColors.income,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'OneSpend by AR1',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'v1.0.0 Pro',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Engineered by AR1studios',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.income.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.income.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.income, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '100% Offline • Local SQLite Storage • Zero Cloud Tracking',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.income,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);

    final currency = ref.watch(currencyProvider);
    final themeMode = ref.watch(themePreferenceProvider);
    final defaultPayment = ref.watch(defaultPaymentMethodProvider);
    final budgetAsync = ref.watch(activeBudgetProvider);

    return Scaffold(
      appBar: AppBar(
        leading: !isDesktop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back to Dashboard',
                onPressed: () {
                  ref.read(navigationIndexProvider.notifier).state = 0;
                },
              )
            : null,
        title: const Text('Settings & Preferences'),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 20,
        ),
        children: [
          // 0. Account & Cloud Sync Section
          Text(
            'Account & Cloud Sync',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final auth = ref.watch(authControllerProvider);
              final userName = auth.user?['full_name'] as String? ?? (auth.isGuest ? 'Guest User' : 'Ashwin');
              final email = auth.user?['email'] as String? ?? (auth.isGuest ? 'Offline Local Storage' : '');

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary.withOpacity(0.15),
                            child: Icon(
                              auth.isGuest ? Icons.person_outline_rounded : Icons.person_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SyncStatusBadge(),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!auth.isGuest)
                            OutlinedButton.icon(
                              onPressed: () {
                                ref.read(syncServiceProvider.notifier).syncNow();
                              },
                              icon: const Icon(Icons.sync_rounded, size: 16),
                              label: const Text('Sync Now', style: TextStyle(fontSize: 12)),
                            ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              ref.read(authControllerProvider.notifier).logout();
                            },
                            icon: Icon(
                              auth.isGuest ? Icons.login_rounded : Icons.logout_rounded,
                              size: 16,
                            ),
                            label: Text(
                              auth.isGuest ? 'Sign In / Register' : 'Sign Out',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // 1. Currency Preference
          Text(
            'Currency & Region',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.currency_exchange_rounded, color: AppColors.primary),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Active Currency', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('Used across cards, tables & charts',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  DropdownButton<String>(
                    value: currency,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: '₹', child: Text('₹  (INR - Rupee)')),
                      DropdownMenuItem(value: '\$', child: Text('\$  (USD - Dollar)')),
                      DropdownMenuItem(value: '€', child: Text('€  (EUR - Euro)')),
                      DropdownMenuItem(value: '£', child: Text('£  (GBP - Pound)')),
                      DropdownMenuItem(value: '¥', child: Text('¥  (JPY - Yen)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(currencyProvider.notifier).setCurrency(val);
                        ref.invalidate(monthlySummaryProvider);
                        ref.invalidate(transactionListProvider);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Monthly Budget Target
          Text(
            'Budget & Goals',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: budgetAsync.when(
              data: (budget) => ListTile(
                leading: const Icon(Icons.savings_outlined, color: AppColors.primary),
                title: const Text('Monthly Budget Target'),
                subtitle: Text('Currently set to ${Formatters.formatCurrency(budget.monthlyLimit)}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _editBudget(context, ref, budget),
              ),
              loading: () => const ListTile(title: Text('Loading budget...')),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Default Payment Method
          Text(
            'Quick Entry Defaults',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.payment_rounded, color: AppColors.primary),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Default Payment Method',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('Pre-selected in Add Transaction modal',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  DropdownButton<PaymentMethod>(
                    value: defaultPayment,
                    underline: const SizedBox.shrink(),
                    items: PaymentMethod.values.map((pm) {
                      return DropdownMenuItem(
                        value: pm,
                        child: Text(pm.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(defaultPaymentMethodProvider.notifier).setDefaultPayment(val);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 4. Appearance & Theme Preference
          Text(
            'Appearance & Display',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  title: const Text('Obsidian Dark (Default)'),
                  secondary: const Icon(Icons.dark_mode_rounded),
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(themePreferenceProvider.notifier).setThemeMode(val);
                    }
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  title: const Text('Crisp Light'),
                  secondary: const Icon(Icons.light_mode_rounded),
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(themePreferenceProvider.notifier).setThemeMode(val);
                    }
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  title: const Text('System Default'),
                  secondary: const Icon(Icons.brightness_auto_rounded),
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(themePreferenceProvider.notifier).setThemeMode(val);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. Data Backup, Restore & Reset Engine
          Text(
            'Data Backup & Recovery',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file_rounded, color: AppColors.primary),
                  title: const Text('Export Vault Backup (.json)'),
                  subtitle: const Text('Save all data safely into a JSON backup file'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => _exportBackup(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_for_offline_rounded, color: AppColors.info),
                  title: const Text('Import / Restore Vault'),
                  subtitle: const Text('Restore records from a previously exported JSON backup'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => _importBackup(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: AppColors.expense),
                  title: const Text('Factory Reset / Wipe Data',
                      style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Permanently erase all entries from local storage'),
                  trailing: const Icon(Icons.warning_amber_rounded, color: AppColors.expense),
                  onTap: () => _confirmFactoryReset(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 6. About OneSpend & Updates
          Text(
            'Updates & About',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.income.withOpacity(0.3)),
            ),
            color: AppColors.income.withOpacity(0.08),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.income.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_sync_rounded, color: AppColors.income, size: 20),
              ),
              title: const Text('Check for Cloud Updates', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: const Text('In-App Over-The-Air updater', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.income),
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Checking Render Cloud for updates...'),
                    duration: Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Color(0xFF1E222B),
                  ),
                );
                final updateService = ref.read(updateServiceProvider);
                final updateInfo = await updateService.checkForUpdate();
                if (updateInfo != null && updateInfo.hasUpdate && context.mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: !updateInfo.isMandatory,
                    builder: (ctx) => AppUpdateDialog(updateInfo: updateInfo),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('OneSpend is up to date! (v${updateInfo?.currentVersion ?? "1.0.2"})'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.income.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.income),
                ),
                child: const Text(
                  '1S',
                  style: TextStyle(
                    color: AppColors.income,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              title: const Text(
                'OneSpend by AR1',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('v1.0.0 Pro • Engineered by AR1studios'),
              trailing: const Icon(Icons.info_outline_rounded),
              onTap: () => _showAboutDialog(context),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
