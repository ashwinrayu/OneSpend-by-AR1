import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/settings/providers/preferences_provider.dart';
import 'screens/shell/responsive_shell.dart';

class ExpenseTrackerApp extends ConsumerWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themePreferenceProvider);
    // Watching currencyProvider ensures all currency formatters re-trigger on change
    ref.watch(currencyProvider);

    final authState = ref.watch(authControllerProvider);

    Widget homeWidget;
    if (authState.isLoading) {
      homeWidget = const Scaffold(
        backgroundColor: Color(0xFF0F1115),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF10B981),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'OneSpend by AR1',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (authState.canAccessApp) {
      homeWidget = const ResponsiveShell();
    } else {
      homeWidget = const LoginScreen();
    }

    return MaterialApp(
      title: 'OneSpend by AR1',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: homeWidget,
    );
  }
}
