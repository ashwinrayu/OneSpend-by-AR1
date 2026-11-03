import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/repositories/expense_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final dbHelper = ref.watch(appDatabaseProvider);
  return ExpenseRepository(dbHelper);
});

