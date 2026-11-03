import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_item.dart';
import '../models/mock_data.dart';
import 'database_provider.dart';

final categoriesProvider = FutureProvider<List<CategoryItem>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final categories = await repo.getAllCategories();
  if (categories.isEmpty) {
    return MockData.defaultCategories;
  }
  return categories;
});

