import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/category_budget_item.dart';

class CategoryBudgetsNotifier extends StateNotifier<Map<String, double>> {
  CategoryBudgetsNotifier() : super({}) {
    loadCategoryBudgets();
  }

  static const _key = 'onespend_category_budgets';

  Future<void> loadCategoryBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        final map = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
        state = map;
        return;
      } catch (_) {}
    }

    // Defaults if none set
    state = {
      'Food & Dining': 8000.0,
      'Groceries': 6000.0,
      'Transport': 3000.0,
      'Shopping': 4000.0,
      'Bills & Utilities': 3500.0,
      'Entertainment': 2000.0,
    };
  }

  Future<void> setCategoryBudget(String category, double limit) async {
    final updated = Map<String, double>.from(state);
    if (limit <= 0) {
      updated.remove(category);
    } else {
      updated[category] = limit;
    }
    state = updated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(updated));
  }
}

final categoryBudgetsProvider =
    StateNotifierProvider<CategoryBudgetsNotifier, Map<String, double>>((ref) {
  return CategoryBudgetsNotifier();
});
