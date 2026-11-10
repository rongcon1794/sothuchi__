import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

class SelectedReportMonthController extends Notifier<DateTime> {
  @override
  DateTime build() => AppDateUtils.startOfMonth(DateTime.now());

  void previousMonth() => state = AppDateUtils.addMonths(state, -1);

  void nextMonth() => state = AppDateUtils.addMonths(state, 1);

  void setMonth(DateTime date) => state = AppDateUtils.startOfMonth(date);
}

final selectedReportMonthProvider =
    NotifierProvider<SelectedReportMonthController, DateTime>(
      SelectedReportMonthController.new,
    );

final monthlyReportProvider = Provider<MonthlyReportData>((ref) {
  final selectedMonth = ref.watch(selectedReportMonthProvider);
  final currency = ref.watch(
    settingsControllerProvider.select(
      (s) => s.value?.currencyCode ?? AppCurrencies.defaultCode,
    ),
  );
  final txs =
      ref.watch(transactionsStreamProvider).value ??
      const <TransactionEntity>[];
  final categoriesMap = ref.watch(categoriesMapProvider);
  final repo = ref.watch(reportsRepositoryProvider);

  return repo.buildMonthlyReport(
    selectedMonth: selectedMonth,
    currencyCode: currency,
    transactions: txs,
    categoriesById: categoriesMap,
  );
});

/// Computes the total budget for the selected report month in the active currency.
/// Returns null if no active budget is configured for this month.
final selectedReportMonthBudgetMinorProvider = Provider<int?>((ref) {
  final selectedMonth = ref.watch(selectedReportMonthProvider);
  final currency = ref.watch(
    settingsControllerProvider.select(
      (s) => s.value?.currencyCode ?? AppCurrencies.defaultCode,
    ),
  );
  final budgets = ref.watch(budgetsStreamProvider).value ?? const <Budget>[];

  final monthBudgets = budgets
      .where(
        (b) =>
            AppDateUtils.isSameMonth(b.startDate, selectedMonth) &&
            b.currency == currency &&
            b.deletedAt == null,
      )
      .toList(growable: false);

  if (monthBudgets.isEmpty) return null;

  // 1. Overall monthly budget takes priority if present
  final overall = monthBudgets.where((b) => b.isOverall).firstOrNull;
  if (overall != null && overall.amount > 0) {
    return overall.amount;
  }

  // 2. Otherwise sum all category-specific budgets
  final totalCategoryBudget = monthBudgets
      .where((b) => !b.isOverall)
      .fold<int>(0, (sum, b) => sum + b.amount);

  return totalCategoryBudget > 0 ? totalCategoryBudget : null;
});

