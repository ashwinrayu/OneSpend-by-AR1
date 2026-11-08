import 'dart:math';

class LoanItem {
  final String id;
  final String name;
  final String lender;
  final double totalAmount; // Principal amount
  final double interestRate; // Annual interest rate percentage (e.g. 10.5)
  final int tenureMonths; // Total tenure in months
  final double monthlyEmi; // Monthly EMI amount
  final int paidEmis; // Number of EMIs paid so far
  final double paidAmount; // Total amount paid so far
  final DateTime startDate;
  final int dueDay; // Day of the month EMI is due (1-28)
  final String category; // Home, Vehicle, Personal, Education, Gadgets, Other
  final String paymentMethod; // Bank, UPI, Auto-Debit, Cash
  final bool isClosed; // Whether loan has been fully paid or closed
  final String? notes;
  final String interestType; // 'reducing', 'flat', 'no_cost', 'custom'
  final DateTime? lastPaymentDate;
  final String syncStatus; // 'synced' | 'pending'
  final bool isDeleted;

  const LoanItem({
    required this.id,
    required this.name,
    required this.lender,
    required this.totalAmount,
    this.interestRate = 0.0,
    required this.tenureMonths,
    required this.monthlyEmi,
    this.paidEmis = 0,
    this.paidAmount = 0.0,
    required this.startDate,
    this.dueDay = 5,
    this.category = 'Personal',
    this.paymentMethod = 'Bank Transfer',
    this.isClosed = false,
    this.notes,
    this.interestType = 'reducing',
    this.lastPaymentDate,
    this.syncStatus = 'pending',
    this.isDeleted = false,
  });

  /// Flexible EMI calculation formula (Reducing, Flat, No-Cost)
  static double calculateEmi({
    required double principal,
    required double annualInterestRate,
    required int tenureMonths,
    String interestType = 'reducing',
  }) {
    if (tenureMonths <= 0 || principal <= 0) return 0.0;
    if (annualInterestRate <= 0.0 || interestType == 'no_cost') {
      return principal / tenureMonths;
    }

    if (interestType == 'flat') {
      final totalInterest = principal * (annualInterestRate / 100.0) * (tenureMonths / 12.0);
      return (principal + totalInterest) / tenureMonths;
    }

    // Standard reducing balance formula: E = P * r * (1+r)^n / ((1+r)^n - 1)
    final r = (annualInterestRate / 12.0) / 100.0;
    final factor = pow(1.0 + r, tenureMonths);
    final denominator = factor - 1.0;
    if (denominator == 0) return principal / tenureMonths;
    return (principal * r * factor) / denominator;
  }

  /// Total amount payable over the tenure (Principal + Interest)
  double get totalPayable => monthlyEmi * tenureMonths;

  /// Total interest payable over the tenure
  double get totalInterest => max(0.0, totalPayable - totalAmount);

  /// Remaining amount to be paid
  double get remainingAmount => max(0.0, totalPayable - paidAmount);

  /// Remaining EMIs count
  int get remainingEmis => max(0, tenureMonths - paidEmis);

  /// Progress ratio from 0.0 to 1.0
  double get progressPercentage {
    if (isClosed || remainingEmis == 0) return 1.0;
    if (totalPayable <= 0) return 0.0;
    return (paidAmount / totalPayable).clamp(0.0, 1.0);
  }

  /// Calculates the upcoming EMI due date
  DateTime get nextDueDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int targetDay = dueDay.clamp(1, 28);
    DateTime candidate = DateTime(now.year, now.month, targetDay);

    // If candidate has passed today, OR if the user already paid in the candidate month
    final paidInCandidateMonth = lastPaymentDate != null &&
        lastPaymentDate!.year == candidate.year &&
        lastPaymentDate!.month == candidate.month;

    if (candidate.isBefore(today) || paidInCandidateMonth) {
      final nextMonth = now.month < 12 ? now.month + 1 : 1;
      final nextYear = now.month < 12 ? now.year : now.year + 1;
      candidate = DateTime(nextYear, nextMonth, targetDay);
    }
    return candidate;
  }

  /// Days until the next EMI is due
  int get daysUntilNextDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return nextDueDate.difference(today).inDays;
  }

  /// User-friendly due status
  String get dueStatusString {
    if (isClosed || remainingEmis == 0) return 'Fully Paid 🎉';
    final now = DateTime.now();
    if (lastPaymentDate != null &&
        lastPaymentDate!.year == now.year &&
        lastPaymentDate!.month == now.month) {
      return 'Paid this month ✓';
    }
    final days = daysUntilNextDue;
    if (days == 0) return 'Due Today!';
    if (days == 1) return 'Due Tomorrow';
    return 'Due in $days days';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lender': lender,
      'totalAmount': totalAmount,
      'interestRate': interestRate,
      'tenureMonths': tenureMonths,
      'monthlyEmi': monthlyEmi,
      'paidEmis': paidEmis,
      'paidAmount': paidAmount,
      'startDate': startDate.millisecondsSinceEpoch,
      'dueDay': dueDay,
      'category': category,
      'paymentMethod': paymentMethod,
      'isClosed': isClosed ? 1 : 0,
      'notes': notes ?? '',
      'interestType': interestType,
      'lastPaymentDate': lastPaymentDate?.millisecondsSinceEpoch,
      'sync_status': syncStatus,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory LoanItem.fromMap(Map<String, dynamic> map) {
    return LoanItem(
      id: map['id'] as String,
      name: map['name'] as String,
      lender: (map['lender'] as String?) ?? '',
      totalAmount: (map['totalAmount'] as num).toDouble(),
      interestRate: ((map['interestRate'] as num?) ?? 0.0).toDouble(),
      tenureMonths: map['tenureMonths'] as int,
      monthlyEmi: (map['monthlyEmi'] as num).toDouble(),
      paidEmis: (map['paidEmis'] as int?) ?? 0,
      paidAmount: ((map['paidAmount'] as num?) ?? 0.0).toDouble(),
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int),
      dueDay: (map['dueDay'] as int?) ?? 5,
      category: (map['category'] as String?) ?? 'Personal',
      paymentMethod: (map['paymentMethod'] as String?) ?? 'Bank Transfer',
      isClosed: (map['isClosed'] as int?) == 1,
      notes: map['notes'] as String?,
      interestType: (map['interestType'] as String?) ?? 'reducing',
      lastPaymentDate: map['lastPaymentDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastPaymentDate'] as int)
          : null,
      syncStatus: (map['sync_status'] as String?) ?? 'synced',
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  LoanItem copyWith({
    String? id,
    String? name,
    String? lender,
    double? totalAmount,
    double? interestRate,
    int? tenureMonths,
    double? monthlyEmi,
    int? paidEmis,
    double? paidAmount,
    DateTime? startDate,
    int? dueDay,
    String? category,
    String? paymentMethod,
    bool? isClosed,
    String? notes,
    String? interestType,
    DateTime? lastPaymentDate,
    String? syncStatus,
    bool? isDeleted,
  }) {
    return LoanItem(
      id: id ?? this.id,
      name: name ?? this.name,
      lender: lender ?? this.lender,
      totalAmount: totalAmount ?? this.totalAmount,
      interestRate: interestRate ?? this.interestRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      monthlyEmi: monthlyEmi ?? this.monthlyEmi,
      paidEmis: paidEmis ?? this.paidEmis,
      paidAmount: paidAmount ?? this.paidAmount,
      startDate: startDate ?? this.startDate,
      dueDay: dueDay ?? this.dueDay,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isClosed: isClosed ?? this.isClosed,
      notes: notes ?? this.notes,
      interestType: interestType ?? this.interestType,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      syncStatus: syncStatus ?? this.syncStatus,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
