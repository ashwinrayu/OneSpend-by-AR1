class CategoryBudgetItem {
  final String category;
  final double limit;

  const CategoryBudgetItem({
    required this.category,
    required this.limit,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'limit': limit,
    };
  }

  factory CategoryBudgetItem.fromMap(Map<String, dynamic> map) {
    return CategoryBudgetItem(
      category: map['category'] as String,
      limit: (map['limit'] as num).toDouble(),
    );
  }
}
