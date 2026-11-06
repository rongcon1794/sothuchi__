import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/ledger/presentation/controllers/ledgers_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

/// Streams all active (non-deleted) budgets across all ledgers from the repository.
final rawBudgetsStreamProvider = StreamProvider<List<Budget>>((ref) {
  return ref.watch(budgetRepositoryProvider).watchBudgets();
});

/// Streams all active (non-deleted) budgets for the currently active ledger.
final budgetsStreamProvider = Provider<AsyncValue<List<Budget>>>((ref) {
  final activeLedgerId = ref.watch(activeLedgerIdProvider);
  final rawAsync = ref.watch(rawBudgetsStreamProvider);
  return rawAsync.whenData(
    (all) => all
        .where((b) => b.ledgerId == activeLedgerId)
        .toList(growable: false),
  );
});

/// Selected month anchor for viewing and configuring monthly budgets.
class SelectedBudgetMonthController extends Notifier<DateTime> {
  @override
  DateTime build() => AppDateUtils.startOfMonth(DateTime.now());

  void previousMonth() => state = AppDateUtils.addMonths(state, -1);

  void nextMonth() => state = AppDateUtils.addMonths(state, 1);

  void setMonth(DateTime date) => state = AppDateUtils.startOfMonth(date);
}

final selectedBudgetMonthProvider =
    NotifierProvider<SelectedBudgetMonthController, DateTime>(
      SelectedBudgetMonthController.new,
    );

/// Computes [BudgetProgress] items for any given [monthAnchor].
List<BudgetProgress> computeMonthlyBudgetProgress({
  required List<Budget> budgets,
  required List<TransactionEntity> transactions,
  required DateTime monthAnchor,
}) {
  final monthBudgets = budgets
      .where((b) => AppDateUtils.isSameMonth(b.startDate, monthAnchor))
      .toList(growable: false);
  if (monthBudgets.isEmpty) return const <BudgetProgress>[];

  final monthExpenses = transactions.where(
    (tx) =>
        tx.type == TransactionType.expense &&
        AppDateUtils.isSameMonth(tx.date, monthAnchor),
  );

  final totalExpenseByCurrency = <String, int>{};
  final spentByCurrencyAndCategory = <String, Map<String, int>>{};
  for (final tx in monthExpenses) {
    totalExpenseByCurrency[tx.currency] =
        (totalExpenseByCurrency[tx.currency] ?? 0) + tx.amount;
    final byCat = spentByCurrencyAndCategory.putIfAbsent(
      tx.currency,
      () => <String, int>{},
    );
    byCat[tx.categoryId] = (byCat[tx.categoryId] ?? 0) + tx.amount;
  }

  return [
    for (final budget in monthBudgets)
      BudgetProgress(
        budget: budget,
        spentMinorUnits: budget.isOverall
            ? (totalExpenseByCurrency[budget.currency] ?? 0)
            : (spentByCurrencyAndCategory[budget.currency]?[budget.categoryId!] ??
                  0),
      ),
  ];
}

/// Progress list for the currently selected month in [BudgetsScreen].
final selectedMonthBudgetProgressProvider = Provider<List<BudgetProgress>>((
  ref,
) {
  final month = ref.watch(selectedBudgetMonthProvider);
  final budgets = ref.watch(budgetsStreamProvider).value ?? const <Budget>[];
  final txs =
      ref.watch(transactionsStreamProvider).value ??
      const <TransactionEntity>[];
  return computeMonthlyBudgetProgress(
    budgets: budgets,
    transactions: txs,
    monthAnchor: month,
  );
});

/// Triggered budget warnings (`usedPercent >= alertThreshold`) for the current calendar month.
final currentMonthTriggeredBudgetsProvider = Provider<List<BudgetProgress>>((
  ref,
) {
  final budgets = ref.watch(budgetsStreamProvider).value ?? const <Budget>[];
  final txs =
      ref.watch(transactionsStreamProvider).value ??
      const <TransactionEntity>[];
  final all = computeMonthlyBudgetProgress(
    budgets: budgets,
    transactions: txs,
    monthAnchor: DateTime.now(),
  );
  return all.where((p) => p.isWarningTriggered).toList(growable: false);
});

/// Evaluates whether a newly saved/updated expense crosses any budget threshold
/// for that expense's month, returning a localized warning message if triggered.
String? evaluateExpenseBudgetAlert({
  required BuildContext context,
  required WidgetRef ref,
  required TransactionEntity savedExpense,
}) {
  if (savedExpense.type != TransactionType.expense) return null;
  final budgets = ref.read(budgetsStreamProvider).value ?? const <Budget>[];
  if (budgets.isEmpty) return null;

  final existingTxs =
      ref.read(transactionsStreamProvider).value ?? const <TransactionEntity>[];
  final hasSavedAlready = existingTxs.any((t) => t.id == savedExpense.id);
  final combined = hasSavedAlready
      ? [
          for (final t in existingTxs)
            if (t.id == savedExpense.id) savedExpense else t,
        ]
      : [savedExpense, ...existingTxs];

  final progressList = computeMonthlyBudgetProgress(
    budgets: budgets,
    transactions: combined,
    monthAnchor: savedExpense.date,
  );

  // Check category-specific budget first, then overall monthly budget.
  BudgetProgress? triggered;
  for (final p in progressList) {
    if (!p.isOverall_ &&
        p.budget.categoryId == savedExpense.categoryId &&
        p.isWarningTriggered) {
      triggered = p;
      break;
    }
  }
  triggered ??= progressList
      .cast<BudgetProgress?>()
      .firstWhere(
        (p) => p != null && p.budget.isOverall && p.isWarningTriggered,
        orElse: () => null,
      );

  if (triggered == null) return null;

  final l10n = context.l10n;
  final categoriesMap = ref.read(categoriesMapProvider);
  final scopeName = triggered.budget.isOverall
      ? l10n.overallMonthlyBudget
      : DefaultCategoryLocalization.resolveName(
          l10n,
          categoryId: triggered.budget.categoryId!,
          fallbackName:
              categoriesMap[triggered.budget.categoryId!]?.name ??
              l10n.categoryBudget,
        );
  return l10n.budgetWarningBanner(scopeName, triggered.usedPercent);
}

extension on BudgetProgress {
  bool get isOverall_ => budget.isOverall;
}

class BudgetsActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Result<Budget>> upsertBudget({
    String? existingId,
    String? categoryId,
    required int amount,
    required String currency,
    required DateTime monthStart,
    required int alertThreshold,
    String? ledgerId,
  }) async {
    state = const AsyncLoading();
    final effectiveLedgerId = ledgerId ?? ref.read(activeLedgerIdProvider);
    final res = await ref
        .read(budgetRepositoryProvider)
        .upsertMonthlyBudget(
          existingId: existingId,
          categoryId: categoryId,
          amount: amount,
          currency: currency,
          monthStart: monthStart,
          alertThreshold: alertThreshold,
          ledgerId: effectiveLedgerId,
        );
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }

  Future<Result<void>> deleteBudget(String budgetId) async {
    state = const AsyncLoading();
    final res = await ref
        .read(budgetRepositoryProvider)
        .softDeleteBudget(budgetId);
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }
}

final budgetsActionControllerProvider =
    NotifierProvider<BudgetsActionController, AsyncValue<void>>(
      BudgetsActionController.new,
    );

