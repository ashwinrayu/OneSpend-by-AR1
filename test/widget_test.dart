import 'package:flutter_test/flutter_test.dart';
import 'package:onespend/core/services/export_service.dart';
import 'package:onespend/core/services/financial_health_service.dart';
import 'package:onespend/core/services/smart_expense_parser.dart';
import 'package:onespend/core/utils/formatters.dart';
import 'package:onespend/features/transactions/providers/transaction_providers.dart';
import 'package:onespend/models/budget_item.dart';
import 'package:onespend/models/enums.dart';
import 'package:onespend/models/subscription_item.dart';
import 'package:onespend/models/transaction_item.dart';

void main() {
  test('DashboardMonthlySummary calculations test', () {
    const summary = DashboardMonthlySummary(
      totalIncome: 50000.0,
      totalExpense: 20000.0,
      balance: 30000.0,
      monthlyBudget: 25000.0,
      budgetRemaining: 5000.0,
      spendToBudgetPercentage: 0.8,
    );

    expect(summary.totalIncome, 50000.0);
    expect(summary.totalExpense, 20000.0);
    expect(summary.balance, 30000.0);
    expect(summary.isOverBudget, false);
    expect(summary.spendToBudgetPercentage, 0.8);
  });

  test('TransactionItem model toMap and fromMap serialization', () {
    final now = DateTime.now();
    final item = TransactionItem(
      id: 'tx_test_1',
      title: 'Coffee',
      amount: 250.0,
      type: TransactionType.expense,
      category: 'Food',
      paymentMethod: PaymentMethod.upi,
      timestamp: now,
      notes: 'Latte',
    );

    final map = item.toMap();
    final restored = TransactionItem.fromMap(map);

    expect(restored.id, item.id);
    expect(restored.title, item.title);
    expect(restored.amount, item.amount);
    expect(restored.type, item.type);
    expect(restored.category, item.category);
    expect(restored.paymentMethod, item.paymentMethod);
    expect(restored.notes, item.notes);
    expect(restored.syncStatus, 'pending');
    expect(restored.isDeleted, false);
  });

  test('TransactionItem syncStatus and isDeleted serialization', () {
    final item = TransactionItem(
      id: 'tx_sync_1',
      title: 'Salary',
      amount: 75000.0,
      type: TransactionType.income,
      category: 'Income',
      paymentMethod: PaymentMethod.bank,
      timestamp: DateTime(2026, 11, 1),
      syncStatus: 'synced',
      isDeleted: true,
    );

    final map = item.toMap();
    expect(map['sync_status'], 'synced');
    expect(map['is_deleted'], 1);

    final restored = TransactionItem.fromMap(map);
    expect(restored.syncStatus, 'synced');
    expect(restored.isDeleted, true);
  });

  test('ExportService CSV generation formatting test', () {
    final item = TransactionItem(
      id: 'tx_csv_1',
      title: 'Monthly Wifi',
      amount: 1199.00,
      type: TransactionType.expense,
      category: 'Bills',
      paymentMethod: PaymentMethod.upi,
      timestamp: DateTime(2026, 11, 1, 14, 30, 0),
      notes: 'High speed fiber',
    );

    final csv = ExportService.generateCsvString([item]);

    // Check headers
    expect(csv.contains('ID,Date,Time,Type,Category,Amount,Payment Method,Note'), true);
    // Check record
    expect(csv.contains('tx_csv_1,2026-11-01,14:30:00,EXPENSE,Bills,1199.00,UPI,High speed fiber'), true);
  });

  test('Formatters dynamic currency test', () {
    Formatters.activeCurrencySymbol = '\$';
    expect(Formatters.formatCurrency(1250.0).contains('\$'), true);

    Formatters.activeCurrencySymbol = '€';
    expect(Formatters.formatCurrency(1250.0).contains('€'), true);

    Formatters.activeCurrencySymbol = '₹';
    expect(Formatters.formatCurrency(1250.0).contains('₹'), true);
  });

  test('SubscriptionItem normalized amount and serialization test', () {
    final subMonthly = SubscriptionItem(
      id: 'sub_test_1',
      name: 'Netflix 4K',
      amount: 649.0,
      billingCycle: 'Monthly',
      category: 'Entertainment',
      nextBillingDate: DateTime.now().add(const Duration(days: 5)),
      paymentMethod: 'UPI',
    );
    expect(subMonthly.monthlyNormalizedAmount, 649.0);
    expect(subMonthly.dueStatusString.contains('Due in'), true);

    final subYearly = SubscriptionItem(
      id: 'sub_test_2',
      name: 'Amazon Prime',
      amount: 1499.0,
      billingCycle: 'Yearly',
      category: 'Shopping',
      nextBillingDate: DateTime.now().add(const Duration(days: 30)),
    );
    expect((subYearly.monthlyNormalizedAmount - (1499.0 / 12)).abs() < 0.01, true);

    final map = subMonthly.toMap();
    final restored = SubscriptionItem.fromMap(map);
    expect(restored.id, subMonthly.id);
    expect(restored.name, subMonthly.name);
    expect(restored.amount, subMonthly.amount);
    expect(restored.billingCycle, 'Monthly');
    expect(restored.isActive, true);
  });

  test('SmartExpenseParser parsing tests', () {
    final res1 = SmartExpenseParser.parse('350 lunch at subway upi');
    expect(res1.isValid, true);
    expect(res1.amount, 350.0);
    expect(res1.type, TransactionType.expense);
    expect(res1.category, 'Food & Dining');
    expect(res1.paymentMethod, PaymentMethod.upi);

    final res2 = SmartExpenseParser.parse('Salary 75000 bank');
    expect(res2.isValid, true);
    expect(res2.amount, 75000.0);
    expect(res2.type, TransactionType.income);
    expect(res2.paymentMethod, PaymentMethod.bank);

    final res3 = SmartExpenseParser.parse('uber 450 card');
    expect(res3.isValid, true);
    expect(res3.amount, 450.0);
    expect(res3.category, 'Transport');
    expect(res3.paymentMethod, PaymentMethod.creditCard);
  });

  test('FinancialHealthService calculation test', () {
    const budget = BudgetItem(
      id: 'b1',
      monthlyLimit: 30000.0,
      month: 11,
      year: 2026,
    );
    final txs = [
      TransactionItem(
        id: 't1',
        title: 'Salary',
        amount: 60000.0,
        type: TransactionType.income,
        category: 'Income',
        paymentMethod: PaymentMethod.bank,
        timestamp: DateTime.now(),
      ),
      TransactionItem(
        id: 't2',
        title: 'Rent',
        amount: 10000.0,
        type: TransactionType.expense,
        category: 'Housing',
        paymentMethod: PaymentMethod.bank,
        timestamp: DateTime.now(),
      ),
    ];

    final metrics = FinancialHealthService.calculate(
      activeBudget: budget,
      allTransactions: txs,
    );

    expect(metrics.monthlyLimit, 30000.0);
    expect(metrics.spentThisMonth, 10000.0);
    expect(metrics.incomeThisMonth, 60000.0);
    expect(metrics.remainingBudget, 20000.0);
    expect(metrics.safeDailySpend > 0, true);
    expect(metrics.healthScore >= 15 && metrics.healthScore <= 100, true);
    expect(metrics.isOverBudget, false);
  });
}
