import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/ai/presentation/widgets/ai_quick_entry_card.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';

/// Streams all active (non-deleted) transactions ordered newest first.
final transactionsStreamProvider = StreamProvider<List<TransactionEntity>>((
  ref,
) {
  return ref.watch(transactionRepositoryProvider).watchTransactions();
});

/// Map of `accountId -> Account` (including archived wallets for historical display).
final accountsMapProvider = Provider<Map<String, Account>>((ref) {
  final all = ref.watch(accountsStreamProvider).value ?? const <Account>[];
  return {for (final a in all) a.id: a};
});

/// Summary metrics for a calendar month.
class MonthlyCashflowSummary {
  const MonthlyCashflowSummary({
    required this.income,
    required this.expense,
    required this.net,
  });

  final Money income;
  final Money expense;
  final Money net;
}

/// Computes this month's Income vs Expense (excluding internal transfers)
/// strictly for transactions matching the active display currency.
final currentMonthSummaryProvider = Provider<MonthlyCashflowSummary>((ref) {
  final currency =
      ref.watch(settingsControllerProvider).value?.currencyCode ??
      AppCurrencies.defaultCode;
  final txs =
      ref.watch(transactionsStreamProvider).value ??
      const <TransactionEntity>[];
  final now = DateTime.now();

  var incomeMinor = 0;
  var expenseMinor = 0;
  for (final tx in txs) {
    if (tx.currency != currency) continue;
    if (!AppDateUtils.isSameMonth(tx.date, now)) continue;
    switch (tx.type) {
      case TransactionType.income:
        incomeMinor += tx.amount;
      case TransactionType.expense:
        expenseMinor += tx.amount;
      case TransactionType.transfer:
        break;
    }
  }

  return MonthlyCashflowSummary(
    income: Money(minorUnits: incomeMinor, currencyCode: currency),
    expense: Money(minorUnits: expenseMinor, currencyCode: currency),
    net: Money(minorUnits: incomeMinor - expenseMinor, currencyCode: currency),
  );
});

/// Top 6 newest transactions for the Home Dashboard.
final recentTransactionsProvider = Provider<List<TransactionEntity>>((ref) {
  final all =
      ref.watch(transactionsStreamProvider).value ??
      const <TransactionEntity>[];
  if (all.length <= 6) return all;
  return all.sublist(0, 6);
});

/// Filter state controller for [TransactionsScreen].
class TransactionFilterController extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => const TransactionFilter();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setType(TransactionType? type) {
    state = state.copyWith(type: type);
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(categoryId: categoryId);
  }

  void setAccount(String? accountId) {
    state = state.copyWith(accountId: accountId);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void clearAll() {
    state = const TransactionFilter();
  }
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterController, TransactionFilter>(
      TransactionFilterController.new,
    );

/// Filtered transactions matching search query, type, category, wallet, and date range.
final filteredTransactionsProvider = Provider<List<TransactionEntity>>((ref) {
  final all =
      ref.watch(transactionsStreamProvider).value ??
      const <TransactionEntity>[];
  final filter = ref.watch(transactionFilterProvider);
  final categoriesMap = ref.watch(categoriesMapProvider);
  final accountsMap = ref.watch(accountsMapProvider);

  final query = filter.searchQuery.trim().toLowerCase();
  final rangeStart = filter.startDate != null
      ? AppDateUtils.startOfDay(filter.startDate!)
      : null;
  final rangeEnd = filter.endDate != null
      ? AppDateUtils.endOfDay(filter.endDate!)
      : null;

  return all.where((tx) {
    if (filter.type != null && tx.type != filter.type) {
      return false;
    }
    if (filter.categoryId != null && tx.categoryId != filter.categoryId) {
      return false;
    }
    if (filter.accountId != null &&
        tx.accountId != filter.accountId &&
        tx.toAccountId != filter.accountId) {
      return false;
    }
    if (rangeStart != null && tx.date.isBefore(rangeStart)) {
      return false;
    }
    if (rangeEnd != null && tx.date.isAfter(rangeEnd)) {
      return false;
    }
    if (query.isNotEmpty) {
      final noteMatch = tx.note.toLowerCase().contains(query);
      final tagMatch = tx.tags.any((t) => t.toLowerCase().contains(query));
      final cat = categoriesMap[tx.categoryId];
      final catVi = cat?.name.toLowerCase() ?? '';
      final catEn = cat?.localizedName('en').toLowerCase() ?? '';
      final accName = accountsMap[tx.accountId]?.name.toLowerCase() ?? '';
      final toAccName = tx.toAccountId != null
          ? (accountsMap[tx.toAccountId!]?.name.toLowerCase() ?? '')
          : '';
      if (!noteMatch &&
          !tagMatch &&
          !catVi.contains(query) &&
          !catEn.contains(query) &&
          !accName.contains(query) &&
          !toAccName.contains(query)) {
        return false;
      }
    }
    return true;
  }).toList(growable: false);
});

/// Filtered transactions grouped by calendar day (newest day first).
final groupedFilteredTransactionsProvider =
    Provider<List<DailyTransactionGroup>>((ref) {
      final list = ref.watch(filteredTransactionsProvider);
      if (list.isEmpty) return const <DailyTransactionGroup>[];
      final currency =
          ref.watch(settingsControllerProvider).value?.currencyCode ??
          AppCurrencies.defaultCode;

      final groups = <DateTime, List<TransactionEntity>>{};
      for (final tx in list) {
        final day = AppDateUtils.startOfDay(tx.date);
        (groups[day] ??= <TransactionEntity>[]).add(tx);
      }

      final sortedDays = groups.keys.toList()..sort((a, b) => b.compareTo(a));
      return [
        for (final day in sortedDays)
          DailyTransactionGroup(
            dayStart: day,
            transactions: groups[day]!,
            totalIncomeMinor: groups[day]!
                .where(
                  (t) =>
                      t.type == TransactionType.income &&
                      t.currency == currency,
                )
                .fold<int>(0, (sum, t) => sum + t.amount),
            totalExpenseMinor: groups[day]!
                .where(
                  (t) =>
                      t.type == TransactionType.expense &&
                      t.currency == currency,
                )
                .fold<int>(0, (sum, t) => sum + t.amount),
          ),
      ];
    });

/// Slot injected onto Home Dashboard by the Budgets feature in Milestone (e).
final dashboardBudgetAlertSlotProvider = Provider<Widget?>((ref) => null);

/// Optional callback invoked after recording an expense to check budget thresholds.
typedef ExpenseBudgetCheckHook =
    String? Function(BuildContext context, TransactionEntity savedExpense);

final expenseBudgetWarningHookProvider = Provider<ExpenseBudgetCheckHook?>(
  (ref) => null,
);

/// Default slot for `lib/features/ai/` quick natural-language entry card.
final aiQuickEntrySlotProvider = Provider<Widget?>((ref) => const AiQuickEntryCard());

class TransactionsActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<TransactionEntity?> getById(String id) {
    return ref.read(transactionRepositoryProvider).getTransactionById(id);
  }

  Future<Result<TransactionEntity>> add({
    required int amount,
    required String currency,
    required TransactionType type,
    required String accountId,
    String? toAccountId,
    required String categoryId,
    String note = '',
    required DateTime date,
    List<String> tags = const <String>[],
  }) async {
    state = const AsyncLoading();
    final res = await ref
        .read(transactionRepositoryProvider)
        .addTransaction(
          amount: amount,
          currency: currency,
          type: type,
          accountId: accountId,
          toAccountId: toAccountId,
          categoryId: categoryId,
          note: note,
          date: date,
          tags: tags,
        );
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }

  Future<Result<TransactionEntity>> update(TransactionEntity updated) async {
    state = const AsyncLoading();
    final res = await ref
        .read(transactionRepositoryProvider)
        .updateTransaction(updated);
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }

  Future<Result<void>> softDelete(String transactionId) async {
    state = const AsyncLoading();
    final res = await ref
        .read(transactionRepositoryProvider)
        .softDeleteTransaction(transactionId);
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }

  Future<Result<void>> restore(String transactionId) async {
    state = const AsyncLoading();
    final res = await ref
        .read(transactionRepositoryProvider)
        .restoreTransaction(transactionId);
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }
}

final transactionsActionControllerProvider =
    NotifierProvider<TransactionsActionController, AsyncValue<void>>(
      TransactionsActionController.new,
    );
