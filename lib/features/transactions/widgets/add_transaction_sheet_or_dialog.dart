import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/enums.dart';
import '../../../models/transaction_item.dart';
import '../providers/transaction_providers.dart';
import '../../settings/providers/preferences_provider.dart';
import 'category_chip_grid.dart';
import 'payment_mode_selector.dart';

class AddTransactionSheetOrDialog extends ConsumerStatefulWidget {
  final TransactionItem? initialItem;

  const AddTransactionSheetOrDialog({super.key, this.initialItem});

  /// Static helper to show as Dialog on Desktop, BottomSheet on Mobile
  static Future<void> show(BuildContext context, {TransactionItem? initialItem}) {
    if (Responsive.isDesktop(context)) {
      return showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: AddTransactionSheetOrDialog(initialItem: initialItem),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: AddTransactionSheetOrDialog(initialItem: initialItem),
          ),
        ),
      );
    }
  }

  @override
  ConsumerState<AddTransactionSheetOrDialog> createState() =>
      _AddTransactionSheetOrDialogState();
}

class _AddTransactionSheetOrDialogState
    extends ConsumerState<AddTransactionSheetOrDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  final FocusNode _amountFocusNode = FocusNode();

  late TransactionType _type;
  late String _selectedCategory;
  late PaymentMethod _paymentMethod;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _amountController = TextEditingController(
      text: item != null ? item.amount.toStringAsFixed(2) : '',
    );
    _titleController = TextEditingController(text: item?.title ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');

    _type = item?.type ?? TransactionType.expense;
    _selectedCategory = item?.category ?? (_type == TransactionType.expense ? 'Food' : 'Salary');
    _paymentMethod = item?.paymentMethod ?? ref.read(defaultPaymentMethodProvider);
    _selectedDate = item?.timestamp ?? DateTime.now();

    // Auto-focus amount field on desktop dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    final item = TransactionItem(
      id: widget.initialItem?.id ?? const Uuid().v4(),
      title: title,
      amount: amount,
      type: _type,
      category: _selectedCategory,
      paymentMethod: _paymentMethod,
      timestamp: _selectedDate,
      notes: notes,
    );

    if (widget.initialItem != null) {
      ref.read(transactionListProvider.notifier).updateTransaction(item);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated "${item.title}" successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ref.read(transactionListProvider.notifier).addTransaction(item);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "${item.title}" for ₹${item.amount.toStringAsFixed(2)}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _type == TransactionType.income ? AppColors.income : AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = Responsive.isDesktop(context);

    // Desktop Esc key closes dialog
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.escape): const _CloseModalIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _CloseModalIntent: CallbackAction<_CloseModalIntent>(
            onInvoke: (_) {
              Navigator.of(context).pop();
              return null;
            },
          ),
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Bar (Drag handle on mobile, or title + close on desktop)
                if (!isDesktop) ...[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.initialItem != null ? 'Edit Transaction' : 'New Transaction',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: isDesktop ? 'Close (Esc)' : 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. Segmented Switch for [Expense | Income]
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Expense'),
                      icon: Icon(Icons.arrow_downward_rounded, color: AppColors.expense),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Income'),
                      icon: Icon(Icons.arrow_upward_rounded, color: AppColors.income),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (set) {
                    setState(() {
                      _type = set.first;
                      if (_type == TransactionType.income && _selectedCategory != 'Salary') {
                        _selectedCategory = 'Salary';
                      } else if (_type == TransactionType.expense && _selectedCategory == 'Salary') {
                        _selectedCategory = 'Food';
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),

                // 2. Large Numeric Amount Field with ₹ symbol
                TextFormField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _type == TransactionType.expense ? AppColors.expense : AppColors.income,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    prefixText: '${ref.watch(currencyProvider)} ',
                    prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: _type == TransactionType.expense ? AppColors.expense : AppColors.income,
                    ),
                    labelText: 'Amount',
                    hintText: '0.00',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter transaction amount';
                    }
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Amount must be greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Title / Description
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _submit(),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title / Description',
                    hintText: 'e.g., Grocery Store, Coffee, Freelance Client',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 3. Category Selector Grid
                Text(
                  'Category',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                CategoryChipGrid(
                  transactionType: _type,
                  selectedCategory: _selectedCategory,
                  onSelected: (cat) {
                    setState(() => _selectedCategory = cat);
                  },
                ),
                const SizedBox(height: 18),

                // 4. Payment Mode Selector
                Text(
                  'Payment Mode',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                PaymentModeSelector(
                  selectedMode: _paymentMethod,
                  onSelected: (mode) {
                    setState(() => _paymentMethod = mode);
                  },
                ),
                const SizedBox(height: 18),

                // 5. Date & Time Picker
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                _selectedDate.hour,
                                _selectedDate.minute,
                              );
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time_rounded, size: 18),
                        label: Text(DateFormat('hh:mm a').format(_selectedDate)),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_selectedDate),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedDate = DateTime(
                                _selectedDate.year,
                                _selectedDate.month,
                                _selectedDate.day,
                                picked.hour,
                                picked.minute,
                              );
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 6. Optional Note/Remarks
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Note / Remarks (Optional)',
                    hintText: 'Add receipt note, tag or memo...',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    widget.initialItem != null ? 'Update Transaction' : 'Save Transaction',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseModalIntent extends Intent {
  const _CloseModalIntent();
}

