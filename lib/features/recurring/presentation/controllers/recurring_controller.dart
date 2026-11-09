import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:so_thu_chi/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';

final recurringStreamProvider = StreamProvider<List<RecurringTransaction>>((ref) {
  final repo = ref.watch(recurringRepositoryProvider);
  return repo.watchRecurringTransactions();
});

/// Returns all bills & recurring transactions that are due today or overdue.
final dueRecurringListProvider = Provider<List<RecurringTransaction>>((ref) {
  final all = ref.watch(recurringStreamProvider).value ?? const [];
  return all.where((r) => r.isDue && !r.isPaused).toList();
});

/// Returns bills / expenses that are due today or overdue.
final dueRecurringExpensesProvider = Provider<List<RecurringTransaction>>((ref) {
  final all = ref.watch(recurringStreamProvider).value ?? const [];
  return all.where((r) => r.isDue && !r.isPaused && r.type == TransactionType.expense).toList();
});

/// Returns recurring incomes (e.g. salary) that are due today or overdue.
final dueRecurringIncomesProvider = Provider<List<RecurringTransaction>>((ref) {
  final all = ref.watch(recurringStreamProvider).value ?? const [];
  return all.where((r) => r.isDue && !r.isPaused && r.type == TransactionType.income).toList();
});

/// Returns active upcoming recurring transactions within the next 30 days.
final upcomingRecurringListProvider = Provider<List<RecurringTransaction>>((ref) {
  final all = ref.watch(recurringStreamProvider).value ?? const [];
  return all.where((r) => !r.isPaused && r.daysUntilDue >= 0 && r.daysUntilDue <= 30).toList();
});

int _calculateMonthlyEquivalent(RecurringTransaction r) {
  switch (r.interval) {
    case RecurringInterval.daily:
      return r.amount * 30;
    case RecurringInterval.weekly:
      return r.amount * 4;
    case RecurringInterval.biweekly:
      return r.amount * 2;
    case RecurringInterval.monthly:
      return r.amount;
    case RecurringInterval.yearly:
      return (r.amount / 12).round();
  }
}

/// Monthly estimated total of active recurring EXPENSES (bills & subscriptions).
final monthlyRecurringExpenseEstimateProvider = Provider<int>((ref) {
  final all = ref.watch(recurringStreamProvider).value ?? const [];
  int total = 0;
  for (final r in all) {
    if (r.isPaused || r.type != TransactionType.expense) continue;
    total += _calculateMonthlyEquivalent(r);
  }
  return total;
});

/// Monthly estimated total of active recurring INCOMES (salary, rent income, investments).
final monthlyRecurringIncomeEstimateProvider = Provider<int>((ref) {
  final all = ref.watch(recurringStreamProvider).value ?? const [];
  int total = 0;
  for (final r in all) {
    if (r.isPaused || r.type != TransactionType.income) continue;
    total += _calculateMonthlyEquivalent(r);
  }
  return total;
});

/// Net monthly recurring cash flow (Income - Expenses).
final monthlyRecurringNetCashflowProvider = Provider<int>((ref) {
  final income = ref.watch(monthlyRecurringIncomeEstimateProvider);
  final expense = ref.watch(monthlyRecurringExpenseEstimateProvider);
  return income - expense;
});

/// Legacy alias for total monthly expenses.
final monthlyRecurringEstimateProvider = Provider<int>((ref) {
  return ref.watch(monthlyRecurringExpenseEstimateProvider);
});

class RecurringActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  RecurringRepository get _repository => ref.read(recurringRepositoryProvider);

  Future<Result<RecurringTransaction>> createRecurring(RecurringTransaction item) async {
    state = const AsyncLoading();
    final res = await _repository.createRecurring(item);
    state = res.isSuccess
        ? const AsyncData(null)
        : AsyncError(res.errorOrNull!, StackTrace.current);
    return res;
  }

  Future<Result<RecurringTransaction>> updateRecurring(RecurringTransaction item) async {
    state = const AsyncLoading();
    final res = await _repository.updateRecurring(item);
    state = res.isSuccess
        ? const AsyncData(null)
        : AsyncError(res.errorOrNull!, StackTrace.current);
    return res;
  }

  Future<Result<void>> deleteRecurring(String id) async {
    state = const AsyncLoading();
    final res = await _repository.deleteRecurring(id);
    state = res.isSuccess
        ? const AsyncData(null)
        : AsyncError(res.errorOrNull!, StackTrace.current);
    return res;
  }

  Future<Result<void>> togglePause(String id, bool isPaused) async {
    state = const AsyncLoading();
    final res = await _repository.togglePause(id, isPaused);
    state = res.isSuccess
        ? const AsyncData(null)
        : AsyncError(res.errorOrNull!, StackTrace.current);
    return res;
  }

  Future<Result<void>> executeRecurring(String id) async {
    state = const AsyncLoading();
    final res = await _repository.executeRecurring(id);
    state = res.isSuccess
        ? const AsyncData(null)
        : AsyncError(res.errorOrNull!, StackTrace.current);
    return res;
  }
}

final recurringActionControllerProvider =
    NotifierProvider<RecurringActionController, AsyncValue<void>>(
  RecurringActionController.new,
);
