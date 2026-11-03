import 'enums.dart';

class TransactionItem {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final PaymentMethod paymentMethod;
  final DateTime timestamp;
  final String? notes;
  final String syncStatus; // 'synced' | 'pending'
  final bool isDeleted;

  const TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.paymentMethod,
    required this.timestamp,
    this.notes,
    this.syncStatus = 'pending',
    this.isDeleted = false,
  });

  bool get isExpense => type == TransactionType.expense;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'paymentMethod': paymentMethod.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'notes': notes,
      'sync_status': syncStatus,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.fromString(map['type'] as String),
      category: map['category'] as String,
      paymentMethod: PaymentMethod.fromString(map['paymentMethod'] as String),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      notes: map['notes'] as String?,
      syncStatus: (map['sync_status'] as String?) ?? 'synced',
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  TransactionItem copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    PaymentMethod? paymentMethod,
    DateTime? timestamp,
    String? notes,
    String? syncStatus,
    bool? isDeleted,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
