import '../../models/enums.dart';

class ParsedExpense {
  final double amount;
  final TransactionType type;
  final String category;
  final PaymentMethod paymentMethod;
  final String title;
  final String rawInput;
  final bool isValid;

  const ParsedExpense({
    required this.amount,
    required this.type,
    required this.category,
    required this.paymentMethod,
    required this.title,
    required this.rawInput,
    required this.isValid,
  });

  static ParsedExpense empty() {
    return const ParsedExpense(
      amount: 0,
      type: TransactionType.expense,
      category: 'Other',
      paymentMethod: PaymentMethod.upi,
      title: '',
      rawInput: '',
      isValid: false,
    );
  }
}

class SmartExpenseParser {
  static const Map<String, List<String>> _categoryKeywords = {
    'Food & Dining': [
      'food', 'lunch', 'dinner', 'breakfast', 'cafe', 'coffee', 'starbucks',
      'swiggy', 'zomato', 'restaurant', 'burger', 'pizza', 'snacks', 'tea', 'biryani', 'meal'
    ],
    'Groceries': [
      'groceries', 'grocery', 'supermarket', 'blinkit', 'zepto', 'instamart',
      'milk', 'vegetables', 'fruits', 'market', 'provisions'
    ],
    'Transport': [
      'uber', 'ola', 'rapido', 'taxi', 'cab', 'metro', 'bus', 'train', 'flight',
      'petrol', 'fuel', 'diesel', 'toll', 'parking', 'auto'
    ],
    'Shopping': [
      'shopping', 'amazon', 'flipkart', 'myntra', 'clothes', 'shoes', 'electronics',
      'mall', 'zara', 'h&m'
    ],
    'Bills & Utilities': [
      'bill', 'electricity', 'water', 'wifi', 'internet', 'recharge', 'mobile',
      'gas', 'cylinder', 'broadband', 'maintenance'
    ],
    'Entertainment': [
      'netflix', 'prime', 'hotstar', 'spotify', 'movie', 'cinema', 'bookmyshow',
      'game', 'concert', 'outing'
    ],
    'Health & Medical': [
      'doctor', 'hospital', 'medicine', 'pharmacy', 'clinic', 'dentist',
      'apollo', '1mg', 'gym', 'fitness', 'supplement'
    ],
    'Housing / Rent': [
      'rent', 'house', 'maid', 'cook', 'brokerage', 'deposit'
    ],
    'Salary': [
      'salary', 'bonus', 'stipend', 'payroll', 'commission'
    ],
    'Investment': [
      'stocks', 'crypto', 'mutual fund', 'sip', 'gold', 'dividend', 'shares'
    ],
  };

  static const List<String> _incomeKeywords = [
    'salary', 'income', 'received', 'dividend', 'bonus', 'cashback',
    'refund', 'freelance', 'client', 'credit', 'interest'
  ];

  static ParsedExpense parse(String input) {
    final text = input.trim();
    if (text.isEmpty) return ParsedExpense.empty();

    // 1. Extract Amount (e.g., 450, 1200.50, 50k, ₹500, rs 400)
    double? detectedAmount;
    final amountRegex = RegExp(r'(?:(?:₹|rs\.?|inr)\s*)?(\d+(?:\.\d{1,2})?|\d+[kK])', caseSensitive: false);
    final match = amountRegex.firstMatch(text);

    String textWithoutAmount = text;
    if (match != null) {
      final matchStr = match.group(1)!;
      if (matchStr.toLowerCase().endsWith('k')) {
        final numPart = double.tryParse(matchStr.substring(0, matchStr.length - 1)) ?? 0;
        detectedAmount = numPart * 1000;
      } else {
        detectedAmount = double.tryParse(matchStr);
      }
      textWithoutAmount = text.replaceFirst(match.group(0)!, ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    if (detectedAmount == null || detectedAmount <= 0) {
      return ParsedExpense.empty();
    }

    final lower = text.toLowerCase();

    // 2. Detect Transaction Type (Income vs Expense)
    TransactionType detectedType = TransactionType.expense;
    for (final kw in _incomeKeywords) {
      if (lower.contains(kw)) {
        detectedType = TransactionType.income;
        break;
      }
    }

    // 3. Detect Payment Method
    PaymentMethod detectedMethod = PaymentMethod.upi;
    if (lower.contains('cash')) {
      detectedMethod = PaymentMethod.cash;
    } else if (lower.contains('credit') || lower.contains('card') || lower.contains('cc')) {
      detectedMethod = PaymentMethod.creditCard;
    } else if (lower.contains('bank') || lower.contains('neft') || lower.contains('rtgs') || lower.contains('netbanking')) {
      detectedMethod = PaymentMethod.bankTransfer;
    } else if (lower.contains('debit')) {
      detectedMethod = PaymentMethod.debitCard;
    }

    // 4. Detect Category
    String detectedCategory = detectedType == TransactionType.income ? 'Salary' : 'General';
    bool categoryFound = false;

    for (final entry in _categoryKeywords.entries) {
      for (final kw in entry.value) {
        if (RegExp(r'\b' + RegExp.escape(kw) + r'\b', caseSensitive: false).hasMatch(lower)) {
          detectedCategory = entry.key;
          categoryFound = true;
          break;
        }
      }
      if (categoryFound) break;
    }

    // 5. Clean Title / Merchant
    String cleanedTitle = textWithoutAmount
        .replaceAll(RegExp(r'\b(via|using|by|with|paid|spent|in|at|on|for|from|rs|inr|cash|upi|card|bank)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleanedTitle.isEmpty) {
      cleanedTitle = detectedCategory;
    } else {
      // Capitalize first letter of each word
      cleanedTitle = cleanedTitle.split(' ').map((w) {
        if (w.isEmpty) return '';
        return w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : '');
      }).join(' ');
    }

    return ParsedExpense(
      amount: detectedAmount,
      type: detectedType,
      category: detectedCategory,
      paymentMethod: detectedMethod,
      title: cleanedTitle,
      rawInput: text,
      isValid: true,
    );
  }
}
