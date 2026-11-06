import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/pdf_statement_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/category_item.dart';
import '../../../models/enums.dart';
import '../../../models/transaction_item.dart';
import '../../../providers/navigation_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/preferences_provider.dart';
import '../providers/history_providers.dart';
import '../providers/transaction_providers.dart';
import '../widgets/add_transaction_sheet_or_dialog.dart';

class TransactionsHistoryScreen extends ConsumerStatefulWidget {
  const TransactionsHistoryScreen({super.key});

  @override
  ConsumerState<TransactionsHistoryScreen> createState() =>
      _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState
    extends ConsumerState<TransactionsHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Lazy load next chunk
      ref.read(historyLoadedCountProvider.notifier).update((val) => val + 25);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportData(List<TransactionItem> list) async {
    final result = await ExportService.exportTransactionsToCsv(list);
    if (!mounted) return;

    if (result.success) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 40),
          title: const Text('Export Successful'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Exported ${result.recordCount} transactions to:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  result.filePath ?? 'Saved',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Export cancelled or failed'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  Future<void> _exportPdfStatement(List<TransactionItem> list) async {
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export in statement.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF Statement...')),
    );
    final now = DateTime.now();
    final res = await PdfStatementService.generateMonthlyStatement(
      monthName: DateFormat('MMMM').format(now),
      year: now.year,
      currencySymbol: ref.read(currencyProvider),
      transactions: list,
      userEmail: ref.read(authControllerProvider).user?['email'] as String?,
    );
    if (res.success && res.filePath != null) {
      await OpenFilex.open(res.filePath!);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message)),
        );
      }
    }
  }

  void _showContextMenu(
    BuildContext context,
    Offset tapPosition,
    TransactionItem item,
  ) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        tapPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18),
              SizedBox(width: 8),
              Text('Edit Transaction'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expense),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: AppColors.expense)),
            ],
          ),
        ),
      ],
    ).then((choice) {
      if (choice == 'edit') {
        AddTransactionSheetOrDialog.show(context, initialItem: item);
      } else if (choice == 'delete') {
        _confirmDelete(context, item);
      }
    });
  }

  void _confirmDelete(BuildContext context, TransactionItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Text('Are you sure you want to remove "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(transactionListProvider.notifier).deleteTransaction(item.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed "${item.title}"'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      ref.read(transactionListProvider.notifier).addTransaction(item);
                    },
                  ),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyFilteredListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final typeFilter = ref.watch(historyTypeFilterProvider);
    final selectedCategories = ref.watch(historySelectedCategoriesProvider);
    final paymentFilter = ref.watch(historyPaymentMethodFilterProvider);
    final sortOption = ref.watch(historySortOptionProvider);
    final loadedCount = ref.watch(historyLoadedCountProvider);

    final isDesktop = Responsive.isDesktop(context);
    final theme = Theme.of(context);

    return Scaffold(
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
        title: const Text('Transaction History'),
        actions: [
          // Export Menu Button (CSV + PDF Statement)
          historyAsync.when(
            data: (list) => PopupMenuButton<String>(
              tooltip: 'Export Transactions',
              color: const Color(0xFF181B22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'csv') {
                  _exportData(list);
                } else if (val == 'pdf') {
                  _exportPdfStatement(list);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf_rounded, color: AppColors.income, size: 18),
                      SizedBox(width: 8),
                      Text('PDF Statement', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'csv',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart_rounded, color: Colors.blueAccent, size: 18),
                      SizedBox(width: 8),
                      Text('CSV Spreadsheet', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.income.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.income.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_rounded, color: AppColors.income, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Export',
                      style: TextStyle(color: AppColors.income, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Icon(Icons.arrow_drop_down, color: AppColors.income, size: 18),
                  ],
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          if (isDesktop) ...[
            FilledButton.icon(
              onPressed: () => AddTransactionSheetOrDialog.show(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('+ New Entry'),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
      body: Column(
        children: [
          // Filter & Search Controls Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: 12,
            ),
            child: Column(
              children: [
                // Real-time Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by title, category, or notes...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: ref.watch(historySearchQueryProvider).isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(historySearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    ref.read(historySearchQueryProvider.notifier).state = val;
                  },
                ),
                const SizedBox(height: 12),

                // Filter & Sort Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Type Segmented Filter (All / Expense / Income)
                      SegmentedButton<TransactionType?>(
                        segments: const [
                          ButtonSegment(value: null, label: Text('All')),
                          ButtonSegment(
                            value: TransactionType.expense,
                            label: Text('Expenses'),
                            icon: Icon(Icons.arrow_downward_rounded, size: 14),
                          ),
                          ButtonSegment(
                            value: TransactionType.income,
                            label: Text('Income'),
                            icon: Icon(Icons.arrow_upward_rounded, size: 14),
                          ),
                        ],
                        selected: {typeFilter},
                        onSelectionChanged: (set) {
                          ref.read(historyTypeFilterProvider.notifier).state = set.first;
                        },
                      ),
                      const SizedBox(width: 12),

                      // Payment Method Filter
                      DropdownButton<PaymentMethod?>(
                        value: paymentFilter,
                        hint: const Text('Payment Mode'),
                        underline: const SizedBox.shrink(),
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Modes'),
                          ),
                          ...PaymentMethod.values.map((pm) {
                            return DropdownMenuItem(
                              value: pm,
                              child: Text(pm.displayName),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          ref.read(historyPaymentMethodFilterProvider.notifier).state = val;
                        },
                      ),
                      const SizedBox(width: 12),

                      // Sort Order
                      PopupMenuButton<TransactionSortOption>(
                        tooltip: 'Sort By',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sort_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text(sortOption.label, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        onSelected: (opt) {
                          ref.read(historySortOptionProvider.notifier).state = opt;
                        },
                        itemBuilder: (ctx) => TransactionSortOption.values.map((opt) {
                          return PopupMenuItem(
                            value: opt,
                            child: Text(opt.label),
                          );
                        }).toList(),
                      ),
                      const SizedBox(width: 12),

                      // Reset Filters Button
                      if (typeFilter != null ||
                          selectedCategories.isNotEmpty ||
                          paymentFilter != null ||
                          ref.watch(historySearchQueryProvider).isNotEmpty)
                        TextButton.icon(
                          icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                          label: const Text('Clear Filters', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(historySearchQueryProvider.notifier).state = '';
                            ref.read(historyTypeFilterProvider.notifier).state = null;
                            ref.read(historySelectedCategoriesProvider.notifier).state = {};
                            ref.read(historyPaymentMethodFilterProvider.notifier).state = null;
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Multi-select Category Carousel
                categoriesAsync.when(
                  data: (cats) {
                    return SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: cats.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, idx) {
                          final c = cats[idx];
                          final isSelected = selectedCategories.contains(c.name);

                          return FilterChip(
                            label: Text(c.name),
                            selected: isSelected,
                            avatar: Icon(c.iconData,
                                size: 14, color: isSelected ? Colors.white : c.color),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : null,
                            ),
                            selectedColor: c.color,
                            onSelected: (val) {
                              final updated = Set<String>.from(selectedCategories);
                              if (val) {
                                updated.add(c.name);
                              } else {
                                updated.remove(c.name);
                              }
                              ref.read(historySelectedCategoriesProvider.notifier).state =
                                  updated;
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Transactions List with Pagination & Context Actions
          Expanded(
            child: historyAsync.when(
              data: (fullList) {
                if (fullList.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 52, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No transactions match your filters',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  );
                }

                final categories = categoriesAsync.value ?? [];
                final displayedList = fullList.take(loadedCount).toList();
                final hasMore = fullList.length > displayedList.length;

                return ListView.separated(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 16,
                    vertical: 12,
                  ),
                  itemCount: displayedList.length + (hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == displayedList.length) {
                      // Load more footer
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: TextButton.icon(
                            icon: const Icon(Icons.arrow_downward_rounded),
                            label: Text(
                              'Load More (${fullList.length - displayedList.length} remaining)',
                            ),
                            onPressed: () {
                              ref
                                  .read(historyLoadedCountProvider.notifier)
                                  .update((val) => val + 25);
                            },
                          ),
                        ),
                      );
                    }

                    final tx = displayedList[index];
                    final isExpense = tx.isExpense;

                    final cat = categories.firstWhere(
                      (c) => c.name.toLowerCase() == tx.category.toLowerCase(),
                      orElse: () => CategoryItem(
                        id: 'default',
                        name: tx.category,
                        iconName: 'category',
                        hexColor: isExpense ? '#EF4444' : '#10B981',
                      ),
                    );

                    // Row Widget with Right-click listener for Desktop
                    final rowWidget = GestureDetector(
                      onSecondaryTapDown: (details) {
                        _showContextMenu(context, details.globalPosition, tx);
                      },
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cat.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(cat.iconData, color: cat.color, size: 20),
                        ),
                        title: Text(
                          tx.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tx.paymentMethod.displayName,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              Formatters.formatRelativeDateTime(tx.timestamp),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '• ${tx.notes}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${isExpense ? '-' : '+'} ${Formatters.formatCurrency(tx.amount)}',
                              style: TextStyle(
                                color: isExpense ? AppColors.expense : AppColors.income,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (isDesktop) ...[
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit',
                                onPressed: () {
                                  AddTransactionSheetOrDialog.show(context, initialItem: tx);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 18, color: AppColors.expense),
                                tooltip: 'Delete',
                                onPressed: () => _confirmDelete(context, tx),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          AddTransactionSheetOrDialog.show(context, initialItem: tx);
                        },
                      ),
                    );

                    // On Mobile: Swipe to delete with Dismissible
                    if (!isDesktop) {
                      return Dismissible(
                        key: Key(tx.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppColors.expense,
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref.read(transactionListProvider.notifier).deleteTransaction(tx.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed "${tx.title}"'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  ref
                                      .read(transactionListProvider.notifier)
                                      .addTransaction(tx);
                                },
                              ),
                            ),
                          );
                        },
                        child: rowWidget,
                      );
                    }

                    return rowWidget;
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

