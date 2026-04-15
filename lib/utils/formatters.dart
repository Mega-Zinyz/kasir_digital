import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  static String formatCompact(double amount) {
    if (amount >= 1000000) {
      final v = amount / 1000000;
      return 'Rp ${v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1)} Juta';
    } else if (amount >= 1000) {
      final v = amount / 1000;
      return 'Rp ${v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1)} Ribu';
    }
    return 'Rp ${amount.toStringAsFixed(0)}';
  }
}

class DateTimeFormatter {
  static String formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm', 'id_ID').format(dateTime);
  }

  static String formatMonthYear(DateTime dateTime) {
    return DateFormat('MMMM yyyy', 'id_ID').format(dateTime);
  }

  static String formatDayName(DateTime dateTime) {
    return DateFormat('EEEE', 'id_ID').format(dateTime);
  }
}
