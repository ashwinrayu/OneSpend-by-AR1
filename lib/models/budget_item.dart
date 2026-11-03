class BudgetItem {
  final String id;
  final double monthlyLimit;
  final int month;
  final int year;

  const BudgetItem({
    required this.id,
    required this.monthlyLimit,
    required this.month,
    required this.year,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'monthlyLimit': monthlyLimit,
      'month': month,
      'year': year,
    };
  }

  factory BudgetItem.fromMap(Map<String, dynamic> map) {
    return BudgetItem(
      id: map['id'] as String,
      monthlyLimit: (map['monthlyLimit'] as num).toDouble(),
      month: map['month'] as int,
      year: map['year'] as int,
    );
  }

  BudgetItem copyWith({
    String? id,
    double? monthlyLimit,
    int? month,
    int? year,
  }) {
    return BudgetItem(
      id: id ?? this.id,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
}

