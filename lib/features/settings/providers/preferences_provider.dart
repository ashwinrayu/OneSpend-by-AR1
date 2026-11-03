import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/formatters.dart';
import '../../../models/enums.dart';

// Keys for SharedPreferences
const String kPrefCurrencyKey = 'onespend_pref_currency';
const String kPrefThemeModeKey = 'onespend_pref_theme';
const String kPrefDefaultPaymentKey = 'onespend_pref_default_payment';
const String kPrefMonthlyBudgetKey = 'onespend_pref_monthly_budget';

// Shared Preferences Instance Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized before runApp');
});

// 1. Currency Provider (₹, $, €, £, ¥)
class CurrencyNotifier extends StateNotifier<String> {
  final SharedPreferences prefs;

  CurrencyNotifier(this.prefs) : super(prefs.getString(kPrefCurrencyKey) ?? '₹') {
    Formatters.activeCurrencySymbol = state;
  }

  Future<void> setCurrency(String symbol) async {
    state = symbol;
    Formatters.activeCurrencySymbol = symbol;
    await prefs.setString(kPrefCurrencyKey, symbol);
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CurrencyNotifier(prefs);
});

// 2. Theme Mode Provider (System Default, Obsidian Dark (Default), Crisp Light)
class AppThemeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences prefs;

  AppThemeNotifier(this.prefs) : super(_loadThemeMode(prefs));

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final val = prefs.getString(kPrefThemeModeKey);
    if (val == 'light') return ThemeMode.light;
    if (val == 'system') return ThemeMode.system;
    return ThemeMode.dark; // Default to Obsidian Dark
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    String val = 'dark';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.system) val = 'system';
    await prefs.setString(kPrefThemeModeKey, val);
  }
}

final themePreferenceProvider = StateNotifierProvider<AppThemeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppThemeNotifier(prefs);
});

// 3. Default Payment Method Provider (UPI, Cash, Card, Bank)
class DefaultPaymentNotifier extends StateNotifier<PaymentMethod> {
  final SharedPreferences prefs;

  DefaultPaymentNotifier(this.prefs) : super(_loadPaymentMethod(prefs));

  static PaymentMethod _loadPaymentMethod(SharedPreferences prefs) {
    final val = prefs.getString(kPrefDefaultPaymentKey);
    if (val != null) {
      return PaymentMethod.fromString(val);
    }
    return PaymentMethod.upi;
  }

  Future<void> setDefaultPayment(PaymentMethod method) async {
    state = method;
    await prefs.setString(kPrefDefaultPaymentKey, method.name);
  }
}

final defaultPaymentMethodProvider =
    StateNotifierProvider<DefaultPaymentNotifier, PaymentMethod>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DefaultPaymentNotifier(prefs);
});

