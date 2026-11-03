import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../transactions/providers/transaction_providers.dart';

class CategoryFilterChips extends ConsumerWidget {
  const CategoryFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedFilter = ref.watch(selectedDashboardCategoryFilterProvider);

    return categoriesAsync.when(
      data: (categories) {
        final allFilters = ['All', ...categories.map((c) => c.name)];

        return SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final name = allFilters[index];
              final isSelected = selectedFilter.toLowerCase() == name.toLowerCase();

              return ChoiceChip(
                label: Text(name),
                selected: isSelected,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                showCheckmark: false,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(selectedDashboardCategoryFilterProvider.notifier).state = name;
                  }
                },
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 38,
        child: Center(child: LinearProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

