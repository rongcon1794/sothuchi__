import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';
import 'package:so_thu_chi/features/reports/domain/repositories/reports_repository.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  const ReportsRepositoryImpl();

  @override
  MonthlyReportData buildMonthlyReport({
    required DateTime selectedMonth,
    required String currencyCode,
    required List<TransactionEntity> transactions,
    required Map<String, Category> categoriesById,
  }) {
    final anchor = AppDateUtils.startOfMonth(selectedMonth);
    final windowMonths = <DateTime>[
      for (var offset = -5; offset <= 0; offset++)
        AppDateUtils.addMonths(anchor, offset),
    ];

    final incomeByMonthIndex = List<int>.filled(6, 0);
    final expenseByMonthIndex = List<int>.filled(6, 0);
    final spendByCat = <String, int>{};
    final countByCat = <String, int>{};

    // Single O(N) pass filtering strictly by `currencyCode`.
    for (final tx in transactions) {
      if (tx.currency != currencyCode) continue;
      if (tx.type == TransactionType.transfer) continue;

      final monthDiff =
          (tx.date.year - anchor.year) * 12 + (tx.date.month - anchor.month);
      if (monthDiff < -5 || monthDiff > 0) continue;

      final trendIdx = monthDiff + 5;
      if (tx.type == TransactionType.income) {
        incomeByMonthIndex[trendIdx] += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        expenseByMonthIndex[trendIdx] += tx.amount;
        if (monthDiff == 0) {
          spendByCat[tx.categoryId] =
              (spendByCat[tx.categoryId] ?? 0) + tx.amount;
          countByCat[tx.categoryId] = (countByCat[tx.categoryId] ?? 0) + 1;
        }
      }
    }

    final monthIncome = incomeByMonthIndex[5];
    final monthExpense = expenseByMonthIndex[5];

    final sortedCatEntries = spendByCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final slices = <CategorySpendSlice>[
      for (final entry in sortedCatEntries)
        BuilderHelper.buildSlice(
          categoryId: entry.key,
          amountMinor: entry.value,
          totalExpenseMinor: monthExpense,
          count: countByCat[entry.key] ?? 1,
          currencyCode: currencyCode,
          category: categoriesById[entry.key],
        ),
    ];

    final trend = <MonthlyTrendBar>[
      for (var i = 0; i < 6; i++)
        MonthlyTrendBar(
          monthAnchor: windowMonths[i],
          incomeMinorUnits: incomeByMonthIndex[i],
          expenseMinorUnits: expenseByMonthIndex[i],
          currencyCode: currencyCode,
        ),
    ];

    return MonthlyReportData(
      selectedMonth: anchor,
      currencyCode: currencyCode,
      totalIncomeMinor: monthIncome,
      totalExpenseMinor: monthExpense,
      categorySlices: slices,
      sixMonthTrend: trend,
    );
  }
}

abstract final class BuilderHelper {
  static CategorySpendSlice buildSlice({
    required String categoryId,
    required int amountMinor,
    required int totalExpenseMinor,
    required int count,
    required String currencyCode,
    required Category? category,
  }) {
    final pct = totalExpenseMinor > 0
        ? ((amountMinor * 100) + (totalExpenseMinor ~/ 2)) ~/ totalExpenseMinor
        : 0;
    return CategorySpendSlice(
      categoryId: categoryId,
      fallbackName: category?.name ?? 'Khác',
      icon: category?.icon ?? 'other',
      color: category?.color ?? 0xFF64748B,
      amountMinorUnits: amountMinor,
      currencyCode: currencyCode,
      percentage: pct,
      transactionCount: count,
    );
  }
}
