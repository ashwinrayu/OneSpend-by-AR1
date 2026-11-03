import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/category_item.dart';
import '../../../models/enums.dart';
import '../providers/transaction_providers.dart';

class CategoryChipGrid extends ConsumerWidget {
  final TransactionType transactionType;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const CategoryChipGrid({
    super.key,
    required this.transactionType,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        final isExpense = transactionType == TransactionType.expense;
        final filteredCategories = categories.where((c) {
          return isExpense ? c.isExpense : !c.isExpense;
        }).toList();

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filteredCategories.map((cat) {
            final isSelected =
                selectedCategory.toLowerCase() == cat.name.toLowerCase();

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelected(cat.name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? cat.color : cat.color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? cat.color : cat.color.withOpacity(0.25),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.iconData,
                      size: 16,
                      color: isSelected ? Colors.white : cat.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

