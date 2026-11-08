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
  String _interestType = 'no_cost'; // 'no_cost', 'reducing', 'flat'

  bool _hasInterest = false;
  bool _showMoreDetails = false;
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
      _hasInterest = l.interestRate > 0 && l.interestType != 'no_cost';
      _rateController.text = l.interestRate > 0 ? l.interestRate.toStringAsFixed(1) : '10.5';
      _tenureController.text = l.tenureMonths.toString();
      _emiController.text = l.monthlyEmi.toStringAsFixed(0);
      _paidEmisController.text = l.paidEmis.toString();
      _paidAmountController.text = l.paidAmount.toStringAsFixed(0);
      _notesController.text = l.notes ?? '';
      _dueDay = l.dueDay.clamp(1, 28);
      _category = l.category;
      _paymentMethod = l.paymentMethod;
      _interestType = _hasInterest ? (l.interestType == 'flat' ? 'flat' : 'reducing') : 'no_cost';
      _showMoreDetails = l.lender.isNotEmpty || (l.notes?.isNotEmpty ?? false);
    } else {
      _hasInterest = false;
      _interestType = 'no_cost';
      _rateController.text = '10.5';
      _tenureController.text = '';
      _emiController.text = '';
      _paidEmisController.text = '0';
      _paidAmountController.text = '0';
      _showMoreDetails = false;
    }

    _amountController.addListener(_onPrincipalChanged);
    _rateController.addListener(_onRateChanged);
    _tenureController.addListener(_onTenureChanged);
    _emiController.addListener(_onEmiDirectlyEdited);
    _paidEmisController.addListener(_onPaidEmisChanged);
    _paidAmountController.addListener(_onPaidAmountChanged);
  }

  void _onPrincipalChanged() {
    if (_isUpdatingFromCode) return;
    final principal = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final emi = double.tryParse(_emiController.text.trim()) ?? 0.0;
    final tenure = int.tryParse(_tenureController.text.trim()) ?? 0;

    if (principal > 0) {
      if (emi > 0 && !_hasInterest) {
        // Link 2-way: update tenure based on principal & emi
        _isUpdatingFromCode = true;
        _tenureController.text = (principal / emi).round().clamp(1, 360).toString();
        _isUpdatingFromCode = false;
      } else if (tenure > 0) {
        _recalculateEmi();
      }
    }
    setState(() {});
  }

  void _onEmiDirectlyEdited() {
    if (_isUpdatingFromCode) return;
    final principal = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final emi = double.tryParse(_emiController.text.trim()) ?? 0.0;

    if (principal > 0 && emi > 0 && !_hasInterest) {
      // 0% interest: typing EMI sets tenure accurately!
      _isUpdatingFromCode = true;
      _tenureController.text = (principal / emi).round().clamp(1, 360).toString();
      _isUpdatingFromCode = false;
    }
    setState(() {});
  }

  void _onTenureChanged() {
    if (_isUpdatingFromCode) return;
    _recalculateEmi();
  }

  void _onRateChanged() {
    if (_isUpdatingFromCode) return;
    if (_hasInterest) {
      _recalculateEmi();
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
    final rate = _hasInterest ? (double.tryParse(_rateController.text.trim()) ?? 0.0) : 0.0;
    final tenure = int.tryParse(_tenureController.text.trim()) ?? 0;

    if (principal > 0 && tenure > 0) {
      final calculatedEmi = LoanItem.calculateEmi(
        principal: principal,
        annualInterestRate: rate,
        tenureMonths: tenure,
        interestType: _hasInterest ? _interestType : 'no_cost',
      );

      _isUpdatingFromCode = true;
      _emiController.text = calculatedEmi.toStringAsFixed(0);
      _isUpdatingFromCode = false;

      final paidEmis = int.tryParse(_paidEmisController.text.trim()) ?? 0;
      if (paidEmis > 0) {
        _paidAmountController.text = (paidEmis * calculatedEmi).toStringAsFixed(0);
      }
    }
    setState(() {});
  }

  void _toggleInterest(bool value) {
    setState(() {
      _hasInterest = value;
      if (!value) {
        _interestType = 'no_cost';
        _rateController.text = '0';
      } else {
        _interestType = 'reducing';
        if ((double.tryParse(_rateController.text.trim()) ?? 0) <= 0) {
          _rateController.text = '10.5';
        }
      }
      _recalculateEmi();
    });
  }

  void _setInterestMode(String mode) {
    setState(() {
      _interestType = mode;
      _recalculateEmi();
    });
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
    final hasInterest = _hasInterest && (double.tryParse(_rateController.text.trim()) ?? 0.0) > 0;
    final rate = hasInterest ? (double.tryParse(_rateController.text.trim()) ?? 0.0) : 0.0;
    int? tenure = int.tryParse(_tenureController.text.trim());
    double? emi = double.tryParse(_emiController.text.trim());
    final paidEmis = int.tryParse(_paidEmisController.text.trim()) ?? 0;
    final paidAmount = double.tryParse(_paidAmountController.text.trim()) ?? (paidEmis * (emi ?? 0.0));

    if (name.isEmpty) {
      _showError('Please enter a Loan Name (e.g. MacBook EMI, Home Loan).');
      return;
    }
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid Loan Amount.');
      return;
    }
    if (emi == null || emi <= 0) {
      if (tenure != null && tenure > 0) {
        emi = amount / tenure;
      } else {
        _showError('Please enter a valid Monthly EMI.');
        return;
      }
    }
    if (tenure == null || tenure <= 0) {
      tenure = (amount / emi).round().clamp(1, 360);
    }

    final totalPayable = hasInterest ? (emi * tenure) : amount;
    final isClosed = paidAmount >= totalPayable || paidEmis >= tenure;

    final loan = LoanItem(
      id: widget.initialLoan?.id ?? const Uuid().v4(),
      name: name,
      lender: lender.isEmpty ? 'Direct Lender' : lender,
      totalAmount: amount,
      interestRate: rate,
      tenureMonths: tenure,
      monthlyEmi: emi,
      paidEmis: paidEmis.clamp(0, tenure),
      paidAmount: paidAmount.clamp(0.0, totalPayable),
      startDate: widget.initialLoan?.startDate ?? DateTime.now(),
      dueDay: _dueDay,
      category: _category,
      paymentMethod: _paymentMethod,
      isClosed: isClosed,
      notes: _notesController.text.trim(),
      interestType: hasInterest ? _interestType : 'no_cost',
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

    final principal = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final tenure = int.tryParse(_tenureController.text.trim()) ?? 0;
    final emi = double.tryParse(_emiController.text.trim()) ?? 0.0;
    final paidEmis = int.tryParse(_paidEmisController.text.trim()) ?? 0;
    final paidAmount = double.tryParse(_paidAmountController.text.trim()) ?? (paidEmis * emi);

    final hasInterest = _hasInterest && (double.tryParse(_rateController.text.trim()) ?? 0.0) > 0;
    final totalPayable = hasInterest ? (emi * tenure) : principal;
    final totalInterest = hasInterest ? (totalPayable > principal ? totalPayable - principal : 0.0) : 0.0;
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
                        isEditing ? 'Edit Loan Plan' : 'Add Loan Plan',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Track loan balance, monthly EMI & repayment',
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

            // Loan Name
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Loan / Plan Name *',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'e.g. Personal Loan, Friend Loan, Phone EMI',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF1A1E26),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // Principal Amount
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Total Loan Amount *',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixText: '$currency ',
                prefixStyle: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold),
                hintText: 'e.g. 50000',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF1A1E26),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // Monthly EMI & Tenure Side-by-Side (Linked 2-way)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emiController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppColors.income, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Monthly EMI *',
                      labelStyle: const TextStyle(color: AppColors.income, fontWeight: FontWeight.bold),
                      prefixText: '$currency ',
                      prefixStyle: const TextStyle(color: AppColors.income),
                      hintText: 'e.g. 5000',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF1A1E26),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.income)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _tenureController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Tenure *',
                      labelStyle: const TextStyle(color: Colors.white70),
                      suffixText: 'months',
                      suffixStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                      hintText: 'e.g. 10',
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

            // Repayment So Far (Paid Amount & Paid EMIs)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _paidAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Already Paid Amount',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixText: '$currency ',
                      prefixStyle: const TextStyle(color: Colors.white70),
                      hintText: '0',
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
                  child: TextField(
                    controller: _paidEmisController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'EMIs Paid',
                      labelStyle: const TextStyle(color: Colors.white70),
                      suffixText: 'EMIs',
                      suffixStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                      hintText: '0',
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
            const SizedBox(height: 14),

            // LIVE SUMMARY PREVIEW BOX
            if (principal > 0 && emi > 0 && tenure > 0) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF161922),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.income.withOpacity(0.3)),
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
                    if (hasInterest && totalInterest > 0) ...[
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
                    ],
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
                        const Text('Remaining Debt:', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(
                          '${Formatters.formatCurrency(remainingDebt)} ($remainingEmis left)',
                          style: const TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.bold, fontSize: 14),
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

            // Switch 1: Include Interest Rate (Optional, OFF by default)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1E26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF262C3A)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Add Interest / APR Rate',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _hasInterest ? 'Interest enabled (Annual %)' : '0% No-Cost EMI (Default)',
                      style: TextStyle(color: _hasInterest ? AppColors.income : Colors.white38, fontSize: 11),
                    ),
                    value: _hasInterest,
                    activeColor: AppColors.income,
                    onChanged: _toggleInterest,
                  ),
                  if (_hasInterest) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 4),
                          const Text(
                            'Calculation Mode:',
                            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Reducing Balance', style: TextStyle(fontSize: 11)),
                                selected: _interestType == 'reducing',
                                selectedColor: AppColors.income.withOpacity(0.2),
                                checkmarkColor: AppColors.income,
                                labelStyle: TextStyle(
                                  color: _interestType == 'reducing' ? AppColors.income : Colors.white70,
                                  fontWeight: _interestType == 'reducing' ? FontWeight.bold : FontWeight.normal,
                                ),
                                backgroundColor: const Color(0xFF14171F),
                                onSelected: (_) => _setInterestMode('reducing'),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Flat Rate', style: TextStyle(fontSize: 11)),
                                selected: _interestType == 'flat',
                                selectedColor: AppColors.income.withOpacity(0.2),
                                checkmarkColor: AppColors.income,
                                labelStyle: TextStyle(
                                  color: _interestType == 'flat' ? AppColors.income : Colors.white70,
                                  fontWeight: _interestType == 'flat' ? FontWeight.bold : FontWeight.normal,
                                ),
                                backgroundColor: const Color(0xFF14171F),
                                onSelected: (_) => _setInterestMode('flat'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
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
                              fillColor: const Color(0xFF14171F),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Switch 2: More Options (Lender, Category, Due Day, Payment Method) (Optional, Collapsed by default)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1E26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF262C3A)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'More Details (Lender, Due Day, Category)',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Optional financial institution & payment details',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    value: _showMoreDetails,
                    activeColor: AppColors.income,
                    onChanged: (val) => setState(() => _showMoreDetails = val),
                  ),
                  if (_showMoreDetails) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: Colors.white12),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _lenderController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Lender / Bank / Person',
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintText: 'e.g. HDFC Bank, SBI, Friend',
                              hintStyle: const TextStyle(color: Colors.white30),
                              filled: true,
                              fillColor: const Color(0xFF14171F),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 10),
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
                                    fillColor: const Color(0xFF14171F),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
                                    fillColor: const Color(0xFF14171F),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _paymentMethod,
                            dropdownColor: const Color(0xFF1E222B),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Payment Method',
                              labelStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: const Color(0xFF14171F),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              isDense: true,
                            ),
                            items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _paymentMethod = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Save & Cancel Buttons
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
}
