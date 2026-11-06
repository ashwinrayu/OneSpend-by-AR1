import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/smart_expense_parser.dart';
import '../../../models/transaction_item.dart';
import '../../settings/providers/preferences_provider.dart';
import '../../transactions/providers/transaction_providers.dart';

class SmartMagicAddBar extends ConsumerStatefulWidget {
  const SmartMagicAddBar({super.key});

  @override
  ConsumerState<SmartMagicAddBar> createState() => _SmartMagicAddBarState();
}

class _SmartMagicAddBarState extends ConsumerState<SmartMagicAddBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  ParsedExpense _parsed = ParsedExpense.empty();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      setState(() {
        _isExpanded = _focusNode.hasFocus || _controller.text.isNotEmpty;
      });
    });
  }

  void _onTextChanged() {
    final parsed = SmartExpenseParser.parse(_controller.text);
    setState(() {
      _parsed = parsed;
    });
  }

  Future<void> _submitExpense() async {
    if (!_parsed.isValid) return;

    final item = TransactionItem(
      id: const Uuid().v4(),
      title: _parsed.title,
      amount: _parsed.amount,
      type: _parsed.type,
      category: _parsed.category,
      paymentMethod: _parsed.paymentMethod,
      timestamp: DateTime.now(),
      notes: 'Quick-logged via Smart Magic Add',
    );

    await ref.read(transactionListProvider.notifier).addTransaction(item);

    final currency = ref.read(currencyProvider);
    final amtStr = '$currency ${_parsed.amount.toStringAsFixed(0)}';

    _controller.clear();
    _focusNode.unfocus();
    setState(() {
      _parsed = ParsedExpense.empty();
      _isExpanded = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚡ Added "$amtStr for ${_parsed.title}"'),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF13161C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpanded ? AppColors.income.withOpacity(0.5) : Colors.white12,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.flash_on_rounded, color: AppColors.income, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Quick Add: "350 lunch upi" or "fuel 500 card"',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _submitExpense(),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _controller.clear();
                      setState(() {
                        _parsed = ParsedExpense.empty();
                      });
                    },
                    icon: const Icon(Icons.clear, color: Colors.white38, size: 16),
                  ),
                if (_parsed.isValid)
                  IconButton.filled(
                    onPressed: _submitExpense,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.income,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(32, 32),
                    ),
                  ),
              ],
            ),
          ),
          if (_parsed.isValid) ...[
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _chip(
                    '$currency ${_parsed.amount.toStringAsFixed(0)}',
                    AppColors.income,
                  ),
                  const SizedBox(width: 6),
                  _chip(_parsed.title, Colors.white70),
                  const SizedBox(width: 6),
                  _chip(_parsed.category, Colors.white54),
                  const SizedBox(width: 6),
                  _chip(_parsed.paymentMethod.displayName, Colors.white38),
                  const Spacer(),
                  const Text('Tap ➔ or Enter', style: TextStyle(color: AppColors.income, fontSize: 10)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
