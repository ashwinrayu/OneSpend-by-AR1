import 'package:intl/intl.dart';

class Formatters {
  static String activeCurrencySymbol = '₹';

  static String formatCurrency(double amount, [String? symbol]) {
    final sym = symbol ?? activeCurrencySymbol;
    final formatter = NumberFormat.currency(
      symbol: sym,
      decimalDigits: 2,
      locale: sym == '₹' ? 'en_IN' : 'en_US',
    );
    return formatter.format(amount);
  }

  static String formatCompactCurrency(double amount, [String? symbol]) {
    final sym = symbol ?? activeCurrencySymbol;
    final formatter = NumberFormat.compactCurrency(
      symbol: sym,
      locale: sym == '₹' ? 'en_IN' : 'en_US',
    );
    return formatter.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Relative date formatting: "Today", "Yesterday", or "dd MMM"
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(itemDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference > 1 && difference < 7) {
      return DateFormat('EEEE').format(date); // e.g. "Monday"
    } else if (date.year == now.year) {
      return DateFormat('dd MMM').format(date); // e.g. "15 Oct"
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  static String formatRelativeDateTime(DateTime date) {
    final relDate = formatRelativeDate(date);
    final timeStr = formatTime(date);
    return '$relDate, $timeStr';
  }
}
