enum TransactionType {
  expense,
  income;

  String get displayName {
    switch (this) {
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.income:
        return 'Income';
    }
  }

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TransactionType.expense,
    );
  }
}

enum PaymentMethod {
  upi,
  cash,
  creditCard,
  bank;

  String get displayName {
    switch (this) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.bank:
        return 'Bank Transfer';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value.toLowerCase()) {
      case 'upi':
        return PaymentMethod.upi;
      case 'cash':
        return PaymentMethod.cash;
      case 'creditcard':
      case 'credit card':
      case 'credit_card':
        return PaymentMethod.creditCard;
      case 'bank':
      case 'bank transfer':
      case 'bank_transfer':
        return PaymentMethod.bank;
      default:
        return PaymentMethod.upi;
    }
  }
}

