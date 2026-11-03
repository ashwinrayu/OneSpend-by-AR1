import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/settings/providers/preferences_provider.dart';
import 'screens/shell/responsive_shell.dart';

class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themePreferenceProvider);
    // Watching currencyProvider ensures all currency formatters re-trigger on change
    ref.watch(currencyProvider);

    return MaterialApp(
      title: 'OneSpend by AR1',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const ResponsiveShell(),
    );
  }
}
