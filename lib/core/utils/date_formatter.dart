import 'package:intl/intl.dart';

/// Pure date helpers for grouping, filtering, and localized display.
abstract final class AppDateUtils {
  /// Strips time components to midnight local time.
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// End of day (`23:59:59.999`).
  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  /// First instant of the given month.
  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month);

  /// Last instant of the given month.
  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);

  /// Adds [deltaMonths] to a month anchor cleanly.
  static DateTime addMonths(DateTime monthAnchor, int deltaMonths) =>
      DateTime(monthAnchor.year, monthAnchor.month + deltaMonths);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  /// Formats a day header (Today / Yesterday / Weekday + Date).
  static String formatDayHeader(
    DateTime date, {
    required String locale,
    required String todayLabel,
    required String yesterdayLabel,
    DateTime? nowOverride,
  }) {
    final now = nowOverride ?? DateTime.now();
    final dateOnly = startOfDay(date);
    final today = startOfDay(now);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateText = DateFormat('dd/MM/yyyy', locale).format(dateOnly);

    if (dateOnly == today) {
      return '$todayLabel • $dateText';
    }
    if (dateOnly == yesterday) {
      return '$yesterdayLabel • $dateText';
    }
    final weekday = DateFormat('EEEE', locale).format(dateOnly);
    final capitalized = weekday.isEmpty
        ? ''
        : '${weekday[0].toUpperCase()}${weekday.substring(1)}';
    return '$capitalized • $dateText';
  }

  /// Formats month + year header (e.g., `Tháng 11, 2026` or `November 2026`).
  static String formatMonthYear(DateTime date, {required String locale}) {
    if (locale.toLowerCase().startsWith('vi')) {
      return 'Tháng ${date.month}, ${date.year}';
    }
    return DateFormat('MMMM yyyy', locale).format(date);
  }

  /// Short month label for chart X-axis (e.g., `T11` in `vi`, `Nov` in `en`).
  static String formatShortMonth(DateTime date, {required String locale}) {
    if (locale.toLowerCase().startsWith('vi')) {
      return 'T${date.month}';
    }
    return DateFormat('MMM', locale).format(date);
  }

  static String formatShortDate(DateTime date, {String locale = 'vi'}) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  static String formatVnDate(DateTime date) =>
      formatShortDate(date, locale: 'vi');
}

