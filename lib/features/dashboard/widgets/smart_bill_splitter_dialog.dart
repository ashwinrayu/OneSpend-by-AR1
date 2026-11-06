import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/enums.dart';
import '../../../models/transaction_item.dart';
import '../../settings/providers/preferences_provider.dart';
import '../../transactions/providers/transaction_providers.dart';

class SmartBillSplitterDialog extends ConsumerStatefulWidget {
  final double? initialTotal;
  final String? initialTitle;

  const SmartBillSplitterDialog({
    super.key,
    this.initialTotal,
    this.initialTitle,
  });

  @override
  ConsumerState<SmartBillSplitterDialog> createState() => _SmartBillSplitterDialogState();
}

class _SmartBillSplitterDialogState extends ConsumerState<SmartBillSplitterDialog> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _upiController = TextEditingController();
  final _tipController = TextEditingController();

  int _peopleCount = 3;
  bool _includeTip = false;
  String _savedUpiId = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialTotal != null && widget.initialTotal! > 0) {
      _amountController.text = widget.initialTotal!.toStringAsFixed(2);
    }
    _titleController.text = widget.initialTitle ?? 'Dinner / Group Expense';
    _loadSavedUpiId();
  }

  Future<void> _loadSavedUpiId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('onespend_user_upi_id') ?? '';
    setState(() {
      _savedUpiId = saved;
      _upiController.text = saved;
    });
  }

  Future<void> _saveUpiId(String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onespend_user_upi_id', val.trim());
    _savedUpiId = val.trim();
  }

  double get _billAmount => double.tryParse(_amountController.text.trim()) ?? 0.0;
  double get _tipAmount => _includeTip ? (double.tryParse(_tipController.text.trim()) ?? 0.0) : 0.0;
  double get _totalWithTip => _billAmount + _tipAmount;
  double get _perPersonAmount => _peopleCount > 0 ? (_totalWithTip / _peopleCount) : 0.0;

  String get _upiPayload {
    final upi = _upiController.text.trim();
    if (upi.isEmpty || _perPersonAmount <= 0) return '';
    final encodedPn = Uri.encodeComponent('OneSpend');
    return 'upi://pay?pa=$upi&pn=$encodedPn&am=${_perPersonAmount.toStringAsFixed(2)}&cu=INR';
  }

  String _generateShareText(String currency) {
    final title = _titleController.text.trim().isEmpty ? 'Group Bill' : _titleController.text.trim();
    final upi = _upiController.text.trim();

    final buffer = StringBuffer();
    buffer.writeln('🧾 *Bill Split via OneSpend*');
    buffer.writeln('🏷️ *Title:* $title');
    buffer.writeln('💵 *Total:* $currency ${_totalWithTip.toStringAsFixed(2)}');
    buffer.writeln('👥 *Split between:* $_peopleCount people');
    buffer.writeln('👉 *Each person owes:* $currency ${_perPersonAmount.toStringAsFixed(2)}');
    if (upi.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('📲 *Pay via UPI to:* `$upi`');
      buffer.writeln('🔗 *Direct UPI Pay Link:* $_upiPayload');
    }
    return buffer.toString();
  }

  Future<void> _saveMyShareAsExpense() async {
    if (_perPersonAmount <= 0) return;

    final title = _titleController.text.trim().isEmpty ? 'Group Bill (My Share)' : '${_titleController.text.trim()} (My Share)';
    final item = TransactionItem(
      id: const Uuid().v4(),
      title: title,
      amount: _perPersonAmount,
      type: TransactionType.expense,
      category: 'Food & Dining',
      paymentMethod: PaymentMethod.upi,
      timestamp: DateTime.now(),
      notes: 'Split of $title (Total: ${_totalWithTip.toStringAsFixed(2)} among $_peopleCount people)',
    );

    await ref.read(transactionListProvider.notifier).addTransaction(item);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved your share of ${ref.read(currencyProvider)} ${_perPersonAmount.toStringAsFixed(2)} as an expense!'),
          backgroundColor: AppColors.income,
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _upiController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);

    return Dialog(
      backgroundColor: const Color(0xFF13161C),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.income.withOpacity(0.3)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.income.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.call_split_rounded, color: AppColors.income, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Bill Splitter',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Split bills & generate instant UPI QR code',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Bill Title Input
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Bill / Occasion',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'e.g., Weekend Dinner, Goa Trip',
                hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon: const Icon(Icons.label_outline, color: AppColors.income, size: 20),
                filled: true,
                fillColor: const Color(0xFF1A1E26),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // Total Amount Input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Total Bill Amount',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixText: '$currency ',
                prefixStyle: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: const Color(0xFF1A1E26),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),

            // Split Count Selector
            Row(
              children: [
                const Text('Split between:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: _peopleCount > 2 ? () => setState(() => _peopleCount--) : null,
                  icon: const Icon(Icons.remove, size: 16),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E222B)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.income.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_peopleCount people',
                    style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _peopleCount < 20 ? () => setState(() => _peopleCount++) : null,
                  icon: const Icon(Icons.add, size: 16),
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E222B)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // UPI ID input for QR generation
            TextField(
              controller: _upiController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              onChanged: (val) {
                _saveUpiId(val);
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Your UPI ID (VPA for QR code)',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'e.g. yourname@okhdfcbank or upi@paytm',
                hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon: const Icon(Icons.qr_code_2_rounded, color: AppColors.income, size: 20),
                filled: true,
                fillColor: const Color(0xFF1A1E26),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                isDense: true,
              ),
            ),
            const SizedBox(height: 18),

            // Result Display Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1E26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.income.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Each Person Owes:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(
                        '$currency ${_perPersonAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.income,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 12),

                  // UPI QR Code Section
                  if (_upiPayload.isNotEmpty) ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: _upiPayload,
                          version: QrVersions.auto,
                          size: 160.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scan with Google Pay, PhonePe, or Paytm',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    const Text(
                      'Enter your UPI ID above to display a live payment QR code',
                      style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Share and Copy Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _perPersonAmount > 0
                              ? () {
                                  final text = _generateShareText(currency);
                                  Clipboard.setData(ClipboardData(text: text));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Split breakdown copied to clipboard!')),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy Details', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _perPersonAmount > 0 ? _saveMyShareAsExpense : null,
                          icon: const Icon(Icons.save_alt_rounded, size: 16),
                          label: const Text('Log My Share', style: TextStyle(fontSize: 12)),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.income,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
