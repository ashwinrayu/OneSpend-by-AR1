import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
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
  final _paidAmountController = TextEditingController();
  final _notesController = TextEditingController();

  int _dueDay = 5;
  String _category = 'Personal';
  String _paymentMethod = 'Bank Transfer';
  String _interestType = 'reducing'; // 'no_cost', 'reducing', 'flat', 'custom'

  bool _isUpdatingFromCode = false;

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
      _rateController.text = l.interestRate > 0 ? l.interestRate.toStringAsFixed(1) : '0';
      _tenureController.text = l.tenureMonths.toString();
      _emiController.text = l.monthlyEmi.toStringAsFixed(0);
      _paidEmisController.text = l.paidEmis.toString();
      _paidAmountController.text = l.paidAmount.toStringAsFixed(0);
      _notesController.text = l.notes ?? '';
      _dueDay = l.dueDay.clamp(1, 28);
      _category = l.category;
      _paymentMethod = l.paymentMethod;
      _interestType = l.interestType;
    } else {
      _tenureController.text = '12';
      _rateController.text = '10.5';
      _paidEmisController.text = '0';
      _paidAmountController.text = '0';
      _interestType = 'reducing';
    }

    _amountController.addListener(_onPrincipalOrTenureOrRateChanged);
    _rateController.addListener(_onPrincipalOrTenureOrRateChanged);
    _tenureController.addListener(_onPrincipalOrTenureOrRateChanged);
    _emiController.addListener(_onEmiDirectlyEdited);
    _paidEmisController.addListener(_onPaidEmisChanged);
    _paidAmountController.addListener(_onPaidAmountChanged);

    // Initial calculation if editing or preset
    if (l == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recalculateEmi();
      });
    }
  }

  void _onPrincipalOrTenureOrRateChanged() {
    if (_isUpdatingFromCode) return;
    if (_interestType != 'custom') {
      _recalculateEmi();
    } else {
      setState(() {}); // refresh preview
    }
  }

  void _onEmiDirectlyEdited() {
    if (_isUpdatingFromCode) return;
    if (_interestType != 'custom') {
      setState(() {
        _interestType = 'custom';
      });
    } else {
      setState(() {}); // refresh preview
    }
  }

  void _onPaidEmisChanged() {
    if (_isUpdatingFromCode) return;
    final emis = int.tryParse(_paidEmisController.text.trim()) ?? 0;
    final emi = double.tryParse(_emiController.text.trim()) ?? 0.0;
    if (emi > 0) {
      _isUpdatingFromCode = true;
      _paidAmountController.text = (emis * emi).toStringAsFixed(0);
      _isUpdatingFromCode = false;
    }
    setState(() {});
  }

  void _onPaidAmountChanged() {
    if (_isUpdatingFromCode) return;
    final amount = double.tryParse(_paidAmountController.text.trim()) ?? 0.0;
    final emi = double.tryParse(_emiController.text.trim()) ?? 0.0;
    if (emi > 0) {
      _isUpdatingFromCode = true;
      _paidEmisController.text = (amount / emi).round().toString();
      _isUpdatingFromCode = false;
    }
    setState(() {});
  }

  void _recalculateEmi() {
    final principal = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final rate = _interestType == 'no_cost' ? 0.0 : (double.tryParse(_rateController.text.trim()) ?? 0.0);
    final tenure = int.tryParse(_tenureController.text.trim()) ?? 1;

    if (principal > 0 && tenure > 0) {
      final calculatedEmi = LoanItem.calculateEmi(
        principal: principal,
        annualInterestRate: rate,
        tenureMonths: tenure,
        interestType: _interestType,
      );

      _isUpdatingFromCode = true;
      _emiController.text = calculatedEmi.toStringAsFixed(0);
      _isUpdatingFromCode = false;

      // Update paid amount based on paid emis
      final paidEmis = int.tryParse(_paidEmisController.text.trim()) ?? 0;
      if (paidEmis > 0) {
        _paidAmountController.text = (paidEmis * calculatedEmi).toStringAsFixed(0);
      }
    }
    setState(() {});
  }

  void _setInterestMode(String mode) {
    setState(() {
      _interestType = mode;
      if (mode == 'no_cost') {
        _rateController.text = '0';
      } else if (mode == 'reducing' || mode == 'flat') {
        if ((double.tryParse(_rateController.text.trim()) ?? 0.0) <= 0) {
          _rateController.text = '10.5';
        }
      }
      _recalculateEmi();
    });
  }

  String _formatOrdinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
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
    _paidAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveLoan() async {
    final name = _nameController.text.trim();
    final lender = _lenderController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    final rate = _interestType == 'no_cost' ? 0.0 : (double.tryParse(_rateController.text.trim()) ?? 0.0);
    final tenure = int.tryParse(_tenureController.text.trim());
    final emi = double.tryParse(_emiController.text.trim());
    final paidEmis = int.tryParse(_paidEmisController.text.trim()) ?? 0;
    final paidAmount = double.tryParse(_paidAmountController.text.trim()) ?? (paidEmis * (emi ?? 0.0));

    if (name.isEmpty) {
      _showError('Please enter a Loan Name (e.g. MacBook EMI, Home Loan).');
      return;
    }
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid Loan Principal Amount.');
      return;
    }
    if (tenure == null || tenure <= 0) {
      _showError('Please enter a valid Tenure (in months).');
      return;
    }
    if (emi == null || emi <= 0) {
      _showError('Please enter or calculate a valid Monthly EMI.');
      return;
    }

    final isClosed = paidEmis >= tenure;

    final loan = LoanItem(
      id: widget.initialLoan?.id ?? const Uuid().v4(),
      name: name,
      lender: lender.isEmpty ? 'Direct Lender' : lender,
      totalAmount: amount,
      interestRate: rate,
      tenureMonths: tenure,
      monthlyEmi: emi,
      paidEmis: paidEmis.clamp(0, tenure),
      paidAmount: paidAmount.clamp(0.0, emi * tenure),
      startDate: widget.initialLoan?.startDate ?? DateTime.now(),
      dueDay: _dueDay,
      category: _category,
      paymentMethod: _paymentMethod,
      isClosed: isClosed,
      notes: _notesController.text.trim(),
      interestType: _interestType,
      lastPaymentDate: widget.initialLoan?.lastPaymentDate,
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.expense),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final isEditing = widget.initialLoan != null;

    // Real-time calculated summary values
    final principal = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final tenure = int.tryParse(_tenureController.text.trim()) ?? 0;
    final emi = double.tryParse(_emiController.text.trim()) ?? 0.0;
    final paidEmis = int.tryParse(_paidEmisController.text.trim()) ?? 0;
    final paidAmount = double.tryParse(_paidAmountController.text.trim()) ?? (paidEmis * emi);

    final totalPayable = emi * tenure;
    final totalInterest = totalPayable > principal ? totalPayable - principal : 0.0;
    final remainingDebt = totalPayable > paidAmount ? totalPayable - paidAmount : 0.0;
    final remainingEmis = tenure > paidEmis ? tenure - paidEmis : 0;
    final progressPct = totalPayable > 0 ? (paidAmount / totalPayable).clamp(0.0, 1.0) : 0.0;

    return Dialog(
      backgroundColor: const Color(0xFF13161C),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                        isEditing ? 'Edit Loan & EMI Plan' : 'Add Loan & EMI Plan',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Track principal debt, monthly EMI & repayment progress',
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
            const SizedBox(height: 16),

            // Loan Name & Lender
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Loan / Plan Name *',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'e.g. MacBook Pro, Home Loan',
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

            // Principal Amount
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Total Loan Principal Amount *',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixText: '$currency ',
                prefixStyle: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold),
                hintText: 'e.g. 60000',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF1A1E26),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),

            // Interest Mode Selection Chips
            const Text(
              'Calculation & Interest Mode:',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildModeChip('0% No-Cost EMI', 'no_cost'),
                _buildModeChip('Reducing Balance (% p.a.)', 'reducing'),
                _buildModeChip('Flat Rate (% p.a.)', 'flat'),
                _buildModeChip('Custom / Fixed EMI', 'custom'),
              ],
            ),
            const SizedBox(height: 12),

            // Interest Rate Input (hidden if No-Cost)
            if (_interestType != 'no_cost') ...[
              TextField(
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: _interestType == 'flat' ? 'Flat Interest Rate (% p.a.)' : 'Annual Interest Rate (% p.a.)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  suffixText: '%',
                  suffixStyle: const TextStyle(color: Colors.white70),
                  hintText: 'e.g. 10.5',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF1A1E26),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Tenure (Months) + Quick Chips
            TextField(
              controller: _tenureController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Loan Tenure (Total Months) *',
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [3, 6, 9, 12, 18, 24, 36, 48, 60, 120, 240].map((m) {
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
                        _tenureController.text = m.toString();
                        _recalculateEmi();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Monthly EMI Box (ALWAYS EDITABLE)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1E26),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.income.withOpacity(0.4)),
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
                      Text(
                        _interestType == 'custom' ? 'Custom Input' : 'Auto-Calculated',
                        style: TextStyle(
                          color: _interestType == 'custom' ? Colors.amberAccent : AppColors.income,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _emiController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      color: AppColors.income,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      prefixText: '$currency ',
                      prefixStyle: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold, fontSize: 20),
                      hintText: '0',
                      hintStyle: const TextStyle(color: Colors.white30),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                  const Text(
                    'You can edit this amount directly anytime.',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Repayment Progress (EMIs Paid & Total Paid Amount)
            const Text(
              'Repayment Progress (If Existing Loan):',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _paidEmisController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'EMIs Paid',
                      labelStyle: const TextStyle(color: Colors.white70),
                      suffixText: 'EMIs',
                      suffixStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF1A1E26),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _paidAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Amount Paid',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixText: '$currency ',
                      prefixStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF1A1E26),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // LIVE SUMMARY PREVIEW BOX
            if (principal > 0 && emi > 0 && tenure > 0) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF161922),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF262C3A)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount Payable:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(
                          Formatters.formatCurrency(totalPayable),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Interest Included:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(
                          Formatters.formatCurrency(totalInterest),
                          style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Already Paid:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(
                          '${Formatters.formatCurrency(paidAmount)} ($paidEmis of $tenure EMIs)',
                          style: const TextStyle(color: AppColors.income, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Remaining Debt:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(
                          '${Formatters.formatCurrency(remainingDebt)} ($remainingEmis left)',
                          style: const TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progressPct,
                        backgroundColor: const Color(0xFF232733),
                        color: AppColors.income,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

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
                        .map((day) => DropdownMenuItem(value: day, child: Text('Every ${_formatOrdinal(day)}')))
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
                    label: Text(isEditing ? 'Save Changes' : 'Add Loan Plan'),
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

  Widget _buildModeChip(String label, String mode) {
    final isSel = _interestType == mode;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSel,
      selectedColor: AppColors.income.withOpacity(0.2),
      checkmarkColor: AppColors.income,
      labelStyle: TextStyle(
        color: isSel ? AppColors.income : Colors.white70,
        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: const Color(0xFF1A1E26),
      side: BorderSide(color: isSel ? AppColors.income : Colors.white12),
      onSelected: (_) => _setInterestMode(mode),
    );
  }
}
