class SubscriptionItem {
  final String id;
  final String name;
  final double amount;
  final String billingCycle; // 'Monthly', 'Yearly', 'Weekly'
  final String category;
  final DateTime nextBillingDate;
  final String paymentMethod;
  final bool isActive;

  const SubscriptionItem({
    required this.id,
    required this.name,
    required this.amount,
    this.billingCycle = 'Monthly',
    required this.category,
    required this.nextBillingDate,
    this.paymentMethod = 'UPI',
    this.isActive = true,
  });

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      nextBillingDate.year,
      nextBillingDate.month,
      nextBillingDate.day,
    );
    return target.difference(today).inDays;
  }

  String get dueStatusString {
    final days = daysRemaining;
    if (days < 0) return 'Overdue by ${-days}d';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in $days days';
  }

  double get monthlyNormalizedAmount {
    switch (billingCycle.toLowerCase()) {
      case 'yearly':
        return amount / 12.0;
      case 'weekly':
        return amount * 4.33;
      default:
        return amount;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'billingCycle': billingCycle,
      'category': category,
      'nextBillingDate': nextBillingDate.millisecondsSinceEpoch,
      'paymentMethod': paymentMethod,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory SubscriptionItem.fromMap(Map<String, dynamic> map) {
    return SubscriptionItem(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      billingCycle: (map['billingCycle'] as String?) ?? 'Monthly',
      category: (map['category'] as String?) ?? 'Bills',
      nextBillingDate: DateTime.fromMillisecondsSinceEpoch(
        map['nextBillingDate'] as int,
      ),
      paymentMethod: (map['paymentMethod'] as String?) ?? 'UPI',
      isActive: (map['isActive'] as int?) == 1,
    );
  }

  SubscriptionItem copyWith({
    String? id,
    String? name,
    double? amount,
    String? billingCycle,
    String? category,
    DateTime? nextBillingDate,
    String? paymentMethod,
    bool? isActive,
  }) {
    return SubscriptionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      billingCycle: billingCycle ?? this.billingCycle,
      category: category ?? this.category,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isActive: isActive ?? this.isActive,
    );
  }
}
