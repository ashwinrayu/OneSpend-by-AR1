import 'category_item.dart';
import 'transaction_item.dart';
import 'budget_item.dart';
import 'enums.dart';

class MockData {
  static final List<CategoryItem> defaultCategories = [
    const CategoryItem(
      id: 'cat_food',
      name: 'Food',
      iconName: 'fastfood',
      hexColor: '#FF7043',
      isExpense: true,
    ),
    const CategoryItem(
      id: 'cat_bills',
      name: 'Bills',
      iconName: 'receipt',
      hexColor: '#42A5F5',
      isExpense: true,
    ),
    const CategoryItem(
      id: 'cat_shopping',
      name: 'Shopping',
      iconName: 'shopping_bag',
      hexColor: '#AB47BC',
      isExpense: true,
    ),
    const CategoryItem(
      id: 'cat_travel',
      name: 'Travel',
      iconName: 'directions_car',
      hexColor: '#FFA726',
      isExpense: true,
    ),
    const CategoryItem(
      id: 'cat_entertainment',
      name: 'Entertainment',
      iconName: 'movie',
      hexColor: '#EC407A',
      isExpense: true,
    ),
    const CategoryItem(
      id: 'cat_health',
      name: 'Health',
      iconName: 'health',
      hexColor: '#26A69A',
      isExpense: true,
    ),
    const CategoryItem(
      id: 'cat_salary',
      name: 'Salary',
      iconName: 'salary',
      hexColor: '#10B981',
      isExpense: false,
    ),
    const CategoryItem(
      id: 'cat_investment',
      name: 'Investment',
      iconName: 'attach_money',
      hexColor: '#3B82F6',
      isExpense: false,
    ),
    const CategoryItem(
      id: 'cat_other',
      name: 'Other',
      iconName: 'category',
      hexColor: '#78909C',
      isExpense: true,
    ),
  ];

  static BudgetItem defaultBudget = BudgetItem(
    id: 'budget_current',
    monthlyLimit: 45000.0,
    month: DateTime.now().month,
    year: DateTime.now().year,
  );

  static List<TransactionItem> getSampleTransactions() {
    final now = DateTime.now();
    return [
      TransactionItem(
        id: 'tx_today_1',
        title: 'Artisan Coffee & Croissant',
        amount: 280.00,
        type: TransactionType.expense,
        category: 'Food',
        paymentMethod: PaymentMethod.upi,
        timestamp: DateTime(now.year, now.month, now.day, 10, 15),
        notes: 'Morning coffee break',
      ),
      TransactionItem(
        id: 'tx_today_2',
        title: 'Uber to Client Office',
        amount: 340.00,
        type: TransactionType.expense,
        category: 'Travel',
        paymentMethod: PaymentMethod.upi,
        timestamp: DateTime(now.year, now.month, now.day, 8, 45),
        notes: 'Morning meeting travel',
      ),
      TransactionItem(
        id: 'tx_yesterday_1',
        title: 'Organic Groceries & Dairy',
        amount: 2450.00,
        type: TransactionType.expense,
        category: 'Food',
        paymentMethod: PaymentMethod.creditCard,
        timestamp: now.subtract(const Duration(days: 1)),
        notes: 'Weekly pantry restocking',
      ),
      TransactionItem(
        id: 'tx_yesterday_2',
        title: 'Consulting Project Milestone',
        amount: 20000.00,
        type: TransactionType.income,
        category: 'Salary',
        paymentMethod: PaymentMethod.bank,
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        notes: 'Direct client wire transfer',
      ),
      TransactionItem(
        id: 'tx_1',
        title: 'Monthly Salary Deposit',
        amount: 75000.00,
        type: TransactionType.income,
        category: 'Salary',
        paymentMethod: PaymentMethod.bank,
        timestamp: DateTime(now.year, now.month, 1, 10, 0),
        notes: 'Base salary credit',
      ),
      TransactionItem(
        id: 'tx_2',
        title: 'Apartment Rent & Maintenance',
        amount: 18000.00,
        type: TransactionType.expense,
        category: 'Bills',
        paymentMethod: PaymentMethod.bank,
        timestamp: DateTime(now.year, now.month, 2, 11, 30),
        notes: 'Monthly rent transfer to landlord',
      ),
      TransactionItem(
        id: 'tx_3',
        title: 'Broadband Fiber Internet',
        amount: 1199.00,
        type: TransactionType.expense,
        category: 'Bills',
        paymentMethod: PaymentMethod.upi,
        timestamp: DateTime(now.year, now.month, 4, 14, 20),
        notes: 'Airtel Xstream Fiber 300 Mbps',
      ),
      TransactionItem(
        id: 'tx_4',
        title: 'Dinner at Japanese Restaurant',
        amount: 2850.00,
        type: TransactionType.expense,
        category: 'Food',
        paymentMethod: PaymentMethod.creditCard,
        timestamp: DateTime(now.year, now.month, 6, 20, 45),
        notes: 'Dinner with team',
      ),
      TransactionItem(
        id: 'tx_5',
        title: 'Noise Cancelling Headphones',
        amount: 5499.00,
        type: TransactionType.expense,
        category: 'Shopping',
        paymentMethod: PaymentMethod.creditCard,
        timestamp: DateTime(now.year, now.month, 10, 16, 50),
        notes: 'Work audio upgrade',
      ),
      TransactionItem(
        id: 'tx_6',
        title: 'Gym & Fitness Membership',
        amount: 3200.00,
        type: TransactionType.expense,
        category: 'Health',
        paymentMethod: PaymentMethod.upi,
        timestamp: DateTime(now.year, now.month, 12, 12, 10),
        notes: 'Monthly fitness pass',
      ),
    ];
  }
}
