import 'package:so_thu_chi/core/utils/money.dart';

/// Single category slice in the monthly expense breakdown (pure integer math).
class CategorySpendSlice {
  const CategorySpendSlice({
    required this.categoryId,
    required this.fallbackName,
    required this.icon,
    required this.color,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.percentage,
    required this.transactionCount,
  });

  final String categoryId;
  final String fallbackName;
  final String icon;
  final int color;
  final int amountMinorUnits;
  final String currencyCode;

  /// Integer percentage (`0..100`) of total monthly expenses.
  final int percentage;
  final int transactionCount;

  Money get amountMoney =>
      Money(minorUnits: amountMinorUnits, currencyCode: currencyCode);
}

/// One month's Income vs Expense point in the 6-month trend chart.
class MonthlyTrendBar {
  const MonthlyTrendBar({
    required this.monthAnchor,
    required this.incomeMinorUnits,
    required this.expenseMinorUnits,
    required this.currencyCode,
  });

  final DateTime monthAnchor;
  final int incomeMinorUnits;
  final int expenseMinorUnits;
  final String currencyCode;

  Money get incomeMoney =>
      Money(minorUnits: incomeMinorUnits, currencyCode: currencyCode);

  Money get expenseMoney =>
      Money(minorUnits: expenseMinorUnits, currencyCode: currencyCode);
}

/// Complete aggregated report for a selected calendar month.
class MonthlyReportData {
  const MonthlyReportData({
    required this.selectedMonth,
    required this.currencyCode,
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
    required this.categorySlices,
    required this.sixMonthTrend,
    this.dailyExpenseMinor = const {},
    this.nowOverride,
  });

  final DateTime selectedMonth;
  final String currencyCode;
  final int totalIncomeMinor;
  final int totalExpenseMinor;
  final List<CategorySpendSlice> categorySlices;
  final List<MonthlyTrendBar> sixMonthTrend;
  final Map<int, int> dailyExpenseMinor;
  final DateTime? nowOverride;

  int get netMinor => totalIncomeMinor - totalExpenseMinor;

  Money get incomeMoney =>
      Money(minorUnits: totalIncomeMinor, currencyCode: currencyCode);

  Money get expenseMoney =>
      Money(minorUnits: totalExpenseMinor, currencyCode: currencyCode);

  Money get netMoney => Money(minorUnits: netMinor, currencyCode: currencyCode);

  /// Integer savings rate `(income - expense) * 100 ~/ income`, or `0` if no income.
  int get savingsRatePercent {
    if (totalIncomeMinor <= 0) return 0;
    final rate = ((totalIncomeMinor - totalExpenseMinor) * 100) ~/ totalIncomeMinor;
    return rate.clamp(-999, 100);
  }

  /// Total days in the selected calendar month.
  int get daysInMonth {
    final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }

  /// Total days elapsed in the selected calendar month so far.
  /// - Past month: all days in that month have passed ([daysInMonth]).
  /// - Current month: days passed up to today (`now.day.clamp(1, daysInMonth)`),
  ///   ensuring that average spending reflects only the days that have passed so far.
  /// - Future month: [daysInMonth].
  int get elapsedDaysInMonth {
    final now = nowOverride ?? DateTime.now();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;
    final isPastMonth = selectedMonth.year < now.year ||
        (selectedMonth.year == now.year && selectedMonth.month < now.month);

    if (isPastMonth) {
      return daysInMonth;
    } else if (isCurrentMonth) {
      return now.day.clamp(1, daysInMonth);
    } else {
      return daysInMonth;
    }
  }

  /// Average daily expense minor units.
  /// Calculated based on elapsed days so far in the month, rather than
  /// diluting the average across the entire month when the month is ongoing.
  int get averageDailyExpenseMinor {
    final days = elapsedDaysInMonth;
    return days > 0 ? totalExpenseMinor ~/ days : 0;
  }

  /// Average expense on days where spending actually occurred.
  /// Used for benchmark tiering (Low, Medium, High) so that spending levels
  /// reflect genuine spending intensity on active days rather than being
  /// diluted by zero-spending days.
  int get activeDailyExpenseMinor {
    final count = activeSpendingDaysCount;
    if (count <= 0) return averageDailyExpenseMinor;
    return totalExpenseMinor ~/ count;
  }

  /// Day with the highest expense (`1..31`), or `0` if no spending.
  int get peakSpendingDay {
    if (dailyExpenseMinor.isEmpty) return 0;
    var maxDay = 0;
    var maxVal = 0;
    for (final entry in dailyExpenseMinor.entries) {
      if (entry.value > maxVal) {
        maxVal = entry.value;
        maxDay = entry.key;
      }
    }
    return maxDay;
  }

  /// Amount spent on the peak day.
  int get peakSpendingAmountMinor => dailyExpenseMinor[peakSpendingDay] ?? 0;

  /// Count of days where at least 1 expense was recorded.
  int get activeSpendingDaysCount =>
      dailyExpenseMinor.values.where((amount) => amount > 0).length;

  bool get hasAnyActivityInSelectedMonth =>
      totalIncomeMinor > 0 || totalExpenseMinor > 0;

  bool get hasSixMonthActivity => sixMonthTrend.any(
    (b) => b.incomeMinorUnits > 0 || b.expenseMinorUnits > 0,
  );

  /// Previous month in trend window, or null if trend has < 2 months.
  MonthlyTrendBar? get previousMonthTrend =>
      sixMonthTrend.length >= 2 ? sixMonthTrend[sixMonthTrend.length - 2] : null;

  /// Percentage change in expenses vs previous month (+/- int), or null if no previous data.
  int? get expenseChangeVsPreviousMonthPercent {
    final prev = previousMonthTrend;
    if (prev == null || prev.expenseMinorUnits <= 0) return null;
    final diff = totalExpenseMinor - prev.expenseMinorUnits;
    return ((diff * 100) ~/ prev.expenseMinorUnits);
  }

  /// Absolute minor-units change in expenses vs previous month, or null if no previous data.
  int? get expenseChangeVsPreviousMonthMinor {
    final prev = previousMonthTrend;
    if (prev == null || prev.expenseMinorUnits <= 0) return null;
    return totalExpenseMinor - prev.expenseMinorUnits;
  }
}

