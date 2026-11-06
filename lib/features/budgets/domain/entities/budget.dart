import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';

part 'budget.freezed.dart';

@freezed
abstract class Budget with _$Budget {
  const Budget._();

  const factory Budget({
    required String id,

    /// `null` means Overall Monthly Budget; non-null targets a specific expense category.
    String? categoryId,
    required int amount,
    @Default(AppCurrencies.defaultCode) String currency,
    @Default('month') String period,
    required DateTime startDate,

    /// Percentage (1..100) at which an alert is triggered (default 80%).
    @Default(80) int alertThreshold,
    @Default(LedgerBook.defaultPersonalId) String ledgerId,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _Budget;

  bool get isOverall => categoryId == null || categoryId!.isEmpty;

  Money get limitMoney => Money(minorUnits: amount, currencyCode: currency);
}

/// Computed progress of a [Budget] against actual monthly expenses (pure integer math).
class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spentMinorUnits,
  });

  final Budget budget;
  final int spentMinorUnits;

  Money get spentMoney =>
      Money(minorUnits: spentMinorUnits, currencyCode: budget.currency);

  int get remainingMinorUnits => budget.amount - spentMinorUnits;

  Money get remainingOrExceededMoney => Money(
    minorUnits: remainingMinorUnits.abs(),
    currencyCode: budget.currency,
  );

  /// Integer percentage (`0..999+`) computed without floating-point money math.
  int get usedPercent =>
      budget.amount > 0 ? (spentMinorUnits * 100) ~/ budget.amount : 0;

  bool get isExceeded => spentMinorUnits > budget.amount;

  bool get isWarningTriggered => usedPercent >= budget.alertThreshold;
}

