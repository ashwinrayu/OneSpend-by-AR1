import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/loan_item.dart';
import '../../settings/providers/preferences_provider.dart';
import '../providers/loan_providers.dart';

class AddEditLoanDialog extends ConsumerStatefulWidget {
  final LoanItem? initialLoan;

  const AddEditLoanDialog({super.key, this.initialLoan});

  @override
  ConsumerState<AddEditLoanDialog> createState() => _AddEditLoanDialogState();
}

class _AddEditLoanDialogState extends ConsumerState<AddEditLoanDialog> {
  final _nameController = TextEditingController();
  final _lenderController = TextEditingController();
  final _amountController = TextEditingController();
  final _rateController = TextEditingController();
  final _tenureController = TextEditingController();
  final _emiController = TextEditingController();
  final _paidEmisController = TextEditingController();
  final _notesController = TextEditingController();

  int _dueDay = 5;
  String _category = 'Personal';
  String _paymentMethod = 'Bank Transfer';
  bool _isNoCostEmi = false;
  bool _customEmiOverride = false;

  final List<String> _categories = [
    'Personal',
    'Home Loan',
    'Vehicle / Car',
    'Gadgets / Electronics',
    'Education',
    'Business',
    'Other'
  ];

  final List<String> _paymentMethods = [
    'Bank Transfer',
    'UPI',
    'Auto-Debit',
    'Credit Card',
    'Cash',
  ];

  @override
  void initState() {
    super.initState();
    final l = widget.initialLoan;
    if (l != null) {
      _nameController.text = l.name;
      _lenderController.text = l.lender;
      _amountController.text = l.totalAmount.toStringAsFixed(0);
      _rateController.text = l.interestRate.toStringAsFixed(1);
      _tenureController.text = l.tenureMonths.toString();
      _emiController.text = l.monthlyEmi.toStringAsFixed(0);
      _paidEmisController.text = l.paidEmis.toString();
      _notesController.text = l.notes ?? '';
      _dueDay = l.dueDay;
      _category = l.category;
      _paymentMethod = l.paymentMethod;
      _isNoCostEmi = l.interestRate == 0;
    } else {
      _tenureController.text = '12';
      _rateController.text = '10.5';
      _paidEmisController.text = '0';
    }

    _amountController.addListener(_recalculateEmi);
    _rateController.addListener(_recalculateEmi);
    _tenureController.addListener(_recalculateEmi);
  }

  void _recalculateEmi() {
    if (_customEmiOverride) return;

    final principal = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final rate = _isNoCostEmi ? 0.0 : (double.tryParse(_rateController.text.trim()) ?? 0.0);
    final tenure = int.tryParse(_tenureController.text.trim()) ?? 1;

    if (principal > 0 && tenure > 0) {
      final calculatedEmi = LoanItem.calculateEmi(
        principal: principal,
        annualInterestRate: rate,
        tenureMonths: tenure,
      );
      _emiController.text = calculatedEmi.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lenderController.dispose();
    _amountController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    _emiController.dispose();
    _paidEmisController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveLoan() async {
    final name = _nameController.text.trim();
    final lender = _lenderController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final rate = _isNoCostEmi ? 0.0 : (double.tryParse(_rateController.text.trim()) ?? 0.0);
    final tenure = int.tryParse(_tenureController.text.trim());
    final emi = double.tryParse(_emiController.text.trim());
    final paidEmis = int.tryParse(_paidEmisController.text.trim()) ?? 0;

    if (name.isEmpty || amount == null || amount <= 0 || tenure == null || tenure <= 0 || emi == null || emi <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields correctly.')),
      );
      return;
    }

    final paidAmount = paidEmis * emi;
    final isClosed = paidEmis >= tenure;

    final loan = LoanItem(
      id: widget.initialLoan?.id ?? const Uuid().v4(),
      name: name,
      lender: lender.isEmpty ? 'Direct Lender' : lender,
      totalAmount: amount,
      interestRate: rate,
      tenureMonths: tenure,
      monthlyEmi: emi,
      paidEmis: paidEmis,
      paidAmount: paidAmount,
      startDate: widget.initialLoan?.startDate ?? DateTime.now(),
      dueDay: _dueDay,
      category: _category,
      paymentMethod: _paymentMethod,
      isClosed: isClosed,
      notes: _notesController.text.trim(),
    );

    if (widget.initialLoan != null) {
      await ref.read(loansProvider.notifier).updateLoan(loan);
    } else {
      await ref.read(loansProvider.notifier).addLoan(loan);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.initialLoan != null ? 'Loan updated successfully!' : 'New Loan added successfully!'),
          backgroundColor: AppColors.income,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final isEditing = widget.initialLoan != null;

    return Dialog(
      backgroundColor: const Color(0xFF13161C),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF262C3A), width: 1),
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
                  child: const Icon(Icons.account_balance_rounded, color: AppColors.income, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Loan & EMI' : 'Add New Loan & EMI',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Track total debt, monthly EMI & repayment progress',
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

            // Loan Name & Lender
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Loan Name *',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'e.g. Home Loan, iPhone EMI',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF1A1E26),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _lenderController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Lender / Bank',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'e.g. HDFC, SBI',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF1A1E26),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Total Loan Amount (Principal)
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Total Loan Principal Amount *',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixText: '$currency ',
                prefixStyle: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: const Color(0xFF1A1E26),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // Interest Rate & No-Cost Toggle
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rateController,
                    enabled: !_isNoCostEmi,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      color: _isNoCostEmi ? Colors.white38 : Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Interest Rate (% p.a.)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      suffixText: '%',
                      suffixStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF1A1E26),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilterChip(
                  label: const Text('0% No-Cost EMI', style: TextStyle(fontSize: 11)),
                  selected: _isNoCostEmi,
                  selectedColor: AppColors.income.withOpacity(0.2),
                  checkmarkColor: AppColors.income,
                  labelStyle: TextStyle(
                    color: _isNoCostEmi ? AppColors.income : Colors.white70,
                    fontWeight: _isNoCostEmi ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: const Color(0xFF1A1E26),
                  side: BorderSide(
                    color: _isNoCostEmi ? AppColors.income : Colors.white12,
                  ),
                  onSelected: (val) {
                    setState(() {
                      _isNoCostEmi = val;
                      if (val) {
                        _rateController.text = '0';
                      } else {
                        _rateController.text = '10.5';
                      }
                      _recalculateEmi();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tenure in Months
            TextField(
              controller: _tenureController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Tenure (Total Months) *',
                labelStyle: const TextStyle(color: Colors.white70),
                suffixText: 'months',
                suffixStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1A1E26),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),

            // Quick Tenure Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [6, 12, 24, 36, 60, 120, 240].map((m) {
                  final isSel = _tenureController.text == m.toString();
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text('${m}m', style: const TextStyle(fontSize: 11)),
                      selected: isSel,
                      selectedColor: AppColors.income.withOpacity(0.25),
                      labelStyle: TextStyle(
                        color: isSel ? AppColors.income : Colors.white70,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: const Color(0xFF1A1E26),
                      side: BorderSide(color: isSel ? AppColors.income : Colors.white12),
                      onSelected: (_) {
                        setState(() {
                          _tenureController.text = m.toString();
                          _recalculateEmi();
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Monthly EMI Box (Auto-calculated / Editable)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1E26),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.income.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Monthly EMI Amount *',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _customEmiOverride = !_customEmiOverride;
                            if (!_customEmiOverride) _recalculateEmi();
                          });
                        },
                        child: Text(
                          _customEmiOverride ? 'Auto-calculate' : 'Custom EMI',
                          style: const TextStyle(color: AppColors.income, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _emiController,
                    enabled: _customEmiOverride,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      color: AppColors.income,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixText: '$currency ',
                      prefixStyle: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Already Paid EMIs
            TextField(
              controller: _paidEmisController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'EMIs Already Paid (if existing loan)',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: '0 if brand new loan',
                hintStyle: const TextStyle(color: Colors.white30),
                suffixText: 'EMIs',
                suffixStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1A1E26),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // Category & Due Day
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    dropdownColor: const Color(0xFF1E222B),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF1A1E26),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      isDense: true,
                    ),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _dueDay,
                    dropdownColor: const Color(0xFF1E222B),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Due Day',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF1A1E26),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      isDense: true,
                    ),
                    items: List.generate(28, (i) => i + 1)
                        .map((day) => DropdownMenuItem(value: day, child: Text('Every ${day}th')))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _dueDay = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Payment Method
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              dropdownColor: const Color(0xFF1E222B),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Debit Method',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1A1E26),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                isDense: true,
              ),
              items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _paymentMethod = val);
              },
            ),
            const SizedBox(height: 18),

            // Save Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _saveLoan,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(isEditing ? 'Save Changes' : 'Add Loan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.income,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
