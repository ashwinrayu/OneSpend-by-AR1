import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/loan_item.dart';
import '../../settings/providers/preferences_provider.dart';
import '../providers/loan_providers.dart';
import 'add_edit_loan_dialog.dart';

class LoanCard extends ConsumerWidget {
  final LoanItem loan;

  const LoanCard({super.key, required this.loan});

  void _confirmPayEmi(BuildContext context, WidgetRef ref) {
    final currency = ref.read(currencyProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161922),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.payment_rounded, color: AppColors.income),
            const SizedBox(width: 8),
            const Text('Pay Monthly EMI', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Record EMI payment for "${loan.name}"?',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E222B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('EMI Amount:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(
                        '$currency ${loan.monthlyEmi.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Installment:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      Text(
                        '#${loan.paidEmis + 1} of ${loan.tenureMonths}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This will automatically log an expense of this amount in your transaction history and update the remaining balance.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.income,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(loansProvider.notifier).payEmi(loan);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Paid EMI of $currency ${loan.monthlyEmi.toStringAsFixed(0)} for ${loan.name}!',
                    ),
                    backgroundColor: AppColors.income,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
            label: const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161922),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Loan?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove "${loan.name}"? Historical EMI transactions logged in your history will remain untouched.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(loansProvider.notifier).deleteLoan(loan.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final isClosed = loan.isClosed || loan.remainingEmis == 0;
    final progress = loan.progressPercentage;

    Color statusColor;
    if (isClosed) {
      statusColor = AppColors.income;
    } else if (loan.daysUntilNextDue <= 2) {
      statusColor = AppColors.expense;
    } else if (loan.daysUntilNextDue <= 7) {
      statusColor = Colors.amberAccent;
    } else {
      statusColor = Colors.blueAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13161C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isClosed ? Colors.white12 : statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Name, Lender & Popup Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            loan.name,
                            style: TextStyle(
                              color: isClosed ? Colors.white54 : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              decoration: isClosed ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E222B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            loan.category,
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loan.lender.isNotEmpty ? loan.lender : 'Direct Loan',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  loan.dueStatusString,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white38, size: 20),
                color: const Color(0xFF1E222B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'edit') {
                    showDialog(
                      context: context,
                      builder: (_) => AddEditLoanDialog(initialLoan: loan),
                    );
                  } else if (val == 'toggle_close') {
                    ref.read(loansProvider.notifier).toggleClosed(loan);
                  } else if (val == 'delete') {
                    _confirmDelete(context, ref);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit Loan', style: TextStyle(color: Colors.white, fontSize: 13))),
                  PopupMenuItem(
                    value: 'toggle_close',
                    child: Text(isClosed ? 'Reopen Loan' : 'Mark as Closed', style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.expense, fontSize: 13))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Row 2: EMI Amount & Next Due
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MONTHLY EMI', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    '$currency ${loan.monthlyEmi.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.income,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (!isClosed)
                FilledButton.icon(
                  onPressed: () => _confirmPayEmi(context, ref),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                  label: const Text('Pay EMI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.income,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF1E222B),
              valueColor: AlwaysStoppedAnimation<Color>(isClosed ? AppColors.income : const Color(0xFF10B981)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),

          // Progress Breakdown Numbers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid: $currency ${loan.paidAmount.toStringAsFixed(0)} (${loan.paidEmis} EMIs)',
                style: const TextStyle(color: AppColors.income, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              Text(
                'Remaining: $currency ${loan.remainingAmount.toStringAsFixed(0)} (${loan.remainingEmis} left)',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),

          // Loan Specs Footer (Principal, Interest Rate, Total Payable)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Principal: $currency ${loan.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
              Text(
                'Rate: ${loan.interestRate > 0 ? '${loan.interestRate.toStringAsFixed(1)}%' : '0% No-Cost'}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
              Text(
                'Total: $currency ${loan.totalPayable.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
