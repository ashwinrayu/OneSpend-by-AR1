import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/category_item.dart';
import '../../../models/enums.dart';
import '../../../models/transaction_item.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../../transactions/widgets/add_transaction_sheet_or_dialog.dart';

class TransactionTile extends ConsumerWidget {
  final TransactionItem transaction;
  final List<CategoryItem> categories;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.categories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isExpense = transaction.isExpense;

    // Find category metadata
    final category = categories.firstWhere(
      (c) => c.name.toLowerCase() == transaction.category.toLowerCase(),
      orElse: () => CategoryItem(
        id: 'default',
        name: transaction.category,
        iconName: 'category',
        hexColor: isExpense ? '#EF4444' : '#10B981',
      ),
    );

    // Payment method badge styling
    Color paymentBadgeColor;
    switch (transaction.paymentMethod) {
      case PaymentMethod.upi:
        paymentBadgeColor = const Color(0xFF0284C7); // Sky blue
        break;
      case PaymentMethod.creditCard:
        paymentBadgeColor = const Color(0xFF8B5CF6); // Purple
        break;
      case PaymentMethod.bank:
        paymentBadgeColor = const Color(0xFF0D9488); // Teal
        break;
      case PaymentMethod.cash:
        paymentBadgeColor = const Color(0xFFD97706); // Amber
        break;
    }

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.expense,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Transaction?'),
            content: Text('Are you sure you want to remove "${transaction.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(transactionListProvider.notifier).deleteTransaction(transaction.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${transaction.title}"'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                ref.read(transactionListProvider.notifier).addTransaction(transaction);
              },
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          AddTransactionSheetOrDialog.show(context, initialItem: transaction);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Category Icon with colored background
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  category.iconData,
                  color: category.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Title, Category, Payment Tag & Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Payment Method Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: paymentBadgeColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            transaction.paymentMethod.displayName,
                            style: TextStyle(
                              color: paymentBadgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Relative Date
                        Text(
                          Formatters.formatRelativeDateTime(transaction.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount & Indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isExpense ? '-' : '+'} ${Formatters.formatCurrency(transaction.amount)}',
                    style: TextStyle(
                      color: isExpense ? AppColors.expense : AppColors.income,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sticky_note_2_outlined,
                          size: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(width: 3),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 90),
                          child: Text(
                            transaction.notes!,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

