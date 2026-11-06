import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/subscription_item.dart';
import '../../../providers/navigation_provider.dart';
import '../../settings/providers/preferences_provider.dart';
import '../../transactions/providers/transaction_providers.dart';
import '../providers/category_budget_provider.dart';
import '../providers/subscription_providers.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditCategoryBudgetDialog(BuildContext context, String category, double currentLimit) {
    final controller = TextEditingController(text: currentLimit.toStringAsFixed(0));
    final currency = ref.read(currencyProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppColors.income),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Set Budget: $category',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixText: '$currency ',
            prefixStyle: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold),
            labelText: 'Monthly Limit',
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: const Color(0xFF12141A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.income),
            onPressed: () async {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val >= 0) {
                await ref.read(categoryBudgetsProvider.notifier).setCategoryBudget(category, val);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Updated $category budget to $currency ${val.toStringAsFixed(0)}'),
                      backgroundColor: AppColors.income,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Limit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddSubscriptionDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String billingCycle = 'Monthly';
    String category = 'Bills';
    String paymentMethod = 'UPI';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF181B22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.autorenew_rounded, color: AppColors.income),
              SizedBox(width: 8),
              Text('New Subscription / Bill', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Service / Bill Name',
                    hintText: 'e.g., Netflix, Gym, Internet',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    prefixText: '${ref.watch(currencyProvider)} ',
                    labelText: 'Amount',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: billingCycle,
                        dropdownColor: const Color(0xFF1E222B),
                        decoration: const InputDecoration(labelText: 'Cycle', isDense: true),
                        items: const [
                          DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                          DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
                          DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => billingCycle = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: category,
                        dropdownColor: const Color(0xFF1E222B),
                        decoration: const InputDecoration(labelText: 'Category', isDense: true),
                        items: const [
                          DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                          DropdownMenuItem(value: 'Entertainment', child: Text('Entertainment')),
                          DropdownMenuItem(value: 'Food', child: Text('Food')),
                          DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => category = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Next Due Date', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy').format(selectedDate),
                    style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today_rounded, size: 20, color: Colors.white70),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.income),
              onPressed: () async {
                final name = nameController.text.trim();
                final amt = double.tryParse(amountController.text.trim());
                if (name.isNotEmpty && amt != null && amt > 0) {
                  final newSub = SubscriptionItem(
                    id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    amount: amt,
                    billingCycle: billingCycle,
                    category: category,
                    nextBillingDate: selectedDate,
                    paymentMethod: paymentMethod,
                  );
                  await ref.read(subscriptionsProvider.notifier).addSubscription(newSub);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                }
              },
              child: const Text('Add Subscription', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final subsAsync = ref.watch(subscriptionsProvider);
    final monthlyBurn = ref.watch(monthlySubscriptionBurnProvider);
    final categoryBudgets = ref.watch(categoryBudgetProgressListProvider);
    final budgetAsync = ref.watch(activeBudgetProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        leading: !isDesktop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back to Dashboard',
                onPressed: () {
                  ref.read(navigationIndexProvider.notifier).state = 0;
                },
              )
            : null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Budgets & Subscriptions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.income,
          labelColor: AppColors.income,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Recurring Subscriptions', icon: Icon(Icons.autorenew_rounded, size: 18)),
            Tab(text: 'Category Limits', icon: Icon(Icons.pie_chart_outline_rounded, size: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.income),
            tooltip: 'Add Subscription',
            onPressed: () => _showAddSubscriptionDialog(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Subscriptions List
          RefreshIndicator(
            color: AppColors.income,
            backgroundColor: const Color(0xFF181B22),
            onRefresh: () async {
              await ref.read(subscriptionsProvider.notifier).fetchSubscriptions();
            },
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: 20,
              ),
              children: [
                // Top Metrics Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181B22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF262B35)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Monthly Burn', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.formatCurrency(monthlyBurn),
                            style: const TextStyle(
                              color: AppColors.income,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(height: 36, width: 1, color: const Color(0xFF262B35)),
                      Column(
                        children: [
                          const Text('Yearly Projection', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.formatCurrency(monthlyBurn * 12),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(height: 36, width: 1, color: const Color(0xFF262B35)),
                      subsAsync.when(
                        data: (list) => Column(
                          children: [
                            const Text('Active Subscriptions', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              '${list.where((s) => s.isActive).length} services',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Active Subscriptions & Bills',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddSubscriptionDialog(context),
                      icon: const Icon(Icons.add, size: 16, color: AppColors.income),
                      label: const Text('Add Service', style: TextStyle(color: AppColors.income, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                subsAsync.when(
                  data: (subscriptions) {
                    if (subscriptions.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: const Text('No subscriptions added yet.', style: TextStyle(color: Colors.grey)),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: subscriptions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final sub = subscriptions[index];
                        final days = sub.daysRemaining;

                        Color statusColor;
                        if (days <= 0) {
                          statusColor = const Color(0xFFEF4444); // red
                        } else if (days <= 3) {
                          statusColor = const Color(0xFFF59E0B); // amber
                        } else {
                          statusColor = const Color(0xFF10B981); // green
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181B22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF262B35)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.income.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.credit_card_rounded, color: AppColors.income, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          sub.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF262B35),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            sub.billingCycle,
                                            style: const TextStyle(color: Colors.grey, fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          sub.dueStatusString,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Text(' • ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                        Text(
                                          DateFormat('MMM dd').format(sub.nextBillingDate),
                                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    Formatters.formatCurrency(sub.amount),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.income,
                                      side: const BorderSide(color: AppColors.income, width: 1),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () async {
                                      await ref.read(subscriptionsProvider.notifier).markAsPaid(sub);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Paid ${sub.name}! Recorded in transaction history.'),
                                            backgroundColor: const Color(0xFF10B981),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text('Mark Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.income)),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ],
            ),
          ),

          // Tab 2: Category Limits & Health
          ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: 20,
            ),
            children: [
              // Overall Target Card
              budgetAsync.when(
                data: (budget) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181B22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF262B35)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Monthly Budget Target', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.formatCurrency(budget.monthlyLimit),
                            style: const TextStyle(
                              color: AppColors.income,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.savings_outlined, color: AppColors.income, size: 32),
                    ],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              const Text(
                'Category Budget Breakdown & Thresholds',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),

              ...categoryBudgets.map((item) {
                Color progressColor;
                if (item.percentage >= 0.9) {
                  progressColor = const Color(0xFFEF4444); // Red > 90%
                } else if (item.percentage >= 0.7) {
                  progressColor = const Color(0xFFF59E0B); // Amber 70-90%
                } else {
                  progressColor = const Color(0xFF10B981); // Green < 70%
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181B22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF262B35)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showEditCategoryBudgetDialog(context, item.category, item.limit),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.category,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.edit_outlined, color: Colors.white30, size: 14),
                                  ],
                                ),
                                Text(
                                  '${Formatters.formatCurrency(item.spent)} / ${Formatters.formatCurrency(item.limit)}',
                                  style: TextStyle(color: progressColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: item.percentage.clamp(0.0, 1.0),
                                backgroundColor: const Color(0xFF262B35),
                                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                minHeight: 7,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(item.percentage * 100).toStringAsFixed(1)}% spent',
                                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                                ),
                                const Text(
                                  'Tap to customize limit',
                                  style: TextStyle(color: AppColors.income, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

