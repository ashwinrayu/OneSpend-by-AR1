import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/enums.dart';
import '../../../models/transaction_item.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../transactions/widgets/add_transaction_sheet_or_dialog.dart';

class RecentTransactionsTable extends ConsumerStatefulWidget {
  const RecentTransactionsTable({super.key});

  @override
  ConsumerState<RecentTransactionsTable> createState() =>
      _RecentTransactionsTableState();
}

class _RecentTransactionsTableState extends ConsumerState<RecentTransactionsTable> {
  String? hoveredRowId;

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & dining':
        return const Color(0xFF10B981); // Emerald
      case 'income':
      case 'salary':
        return const Color(0xFF14B8A6); // Teal
      case 'bills':
      case 'utilities':
        return const Color(0xFFF59E0B); // Amber
      case 'shopping':
        return const Color(0xFF8B5CF6); // Purple
      case 'travel':
      case 'transport':
        return const Color(0xFF06B6D4); // Cyan
      case 'entertainment':
        return const Color(0xFFEC4899); // Pink
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentAsync = ref.watch(recentTransactionsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.desktopCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.desktopBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          const Text(
            'Recent Transactions',
            style: TextStyle(
              color: AppColors.desktopTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Date',
                    style: TextStyle(
                      color: AppColors.desktopTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Description',
                    style: TextStyle(
                      color: AppColors.desktopTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Category',
                    style: TextStyle(
                      color: AppColors.desktopTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      color: AppColors.desktopTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Amount',
                      style: TextStyle(
                        color: AppColors.desktopTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.desktopBorder, height: 1),

          // Rows
          recentAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No transactions logged yet',
                      style: TextStyle(color: AppColors.desktopTextSecondary),
                    ),
                  ),
                );
              }

              final displayed = transactions.take(6).toList();

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayed.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: AppColors.desktopBorder, height: 1),
                itemBuilder: (context, index) {
                  final tx = displayed[index];
                  final isHovered = hoveredRowId == tx.id;
                  final isExpense = tx.isExpense;
                  final catColor = _categoryColor(tx.category);

                  return MouseRegion(
                    onEnter: (_) => setState(() => hoveredRowId = tx.id),
                    onExit: (_) => setState(() => hoveredRowId = null),
                    child: InkWell(
                      onTap: () {
                        AddTransactionSheetOrDialog.show(context, initialItem: tx);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isHovered
                              ? AppColors.desktopCardHover
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            // 1. Date (e.g. Nov 02)
                            Expanded(
                              flex: 2,
                              child: Text(
                                Formatters.formatRelativeDate(tx.timestamp),
                                style: const TextStyle(
                                  color: AppColors.desktopTextPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            // 2. Description
                            Expanded(
                              flex: 4,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      tx.title,
                                      style: const TextStyle(
                                        color: AppColors.desktopTextPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 3. Category Chip (Pill outline)
                            Expanded(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: catColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: catColor.withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    tx.category,
                                    style: TextStyle(
                                      color: catColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 4. Status / Payment Mode
                            Expanded(
                              flex: 3,
                              child: Text(
                                tx.paymentMethod.displayName,
                                style: const TextStyle(
                                  color: AppColors.desktopTextSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                            // 5. Amount & Quick Action icons on hover
                            Expanded(
                              flex: 3,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isHovered) ...[
                                    InkWell(
                                      onTap: () => AddTransactionSheetOrDialog.show(
                                          context,
                                          initialItem: tx),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.edit_outlined,
                                            size: 16,
                                            color: AppColors.desktopTextSecondary),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () {
                                        ref
                                            .read(transactionListProvider.notifier)
                                            .deleteTransaction(tx.id);
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.delete_outline_rounded,
                                            size: 16, color: AppColors.expense),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    '${isExpense ? '-' : '+'} ${Formatters.formatCurrency(tx.amount)}',
                                    style: TextStyle(
                                      color: isExpense
                                          ? AppColors.expense
                                          : AppColors.income,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }
}

