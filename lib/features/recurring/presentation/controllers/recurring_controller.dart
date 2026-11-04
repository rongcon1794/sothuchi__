import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:so_thu_chi/features/recurring/domain/repositories/recurring_repository.dart';

final recurringStreamProvider = StreamProvider<List<RecurringTransaction>>((ref) {
  final repo = ref.watch(recurringRepositoryProvider);
  return repo.watchRecurringTransactions();
});

/// Returns bills/subscriptions that are due today or overdue.
final dueRecurringListProvider = Provider<List<RecurringTransaction>>((ref) {
  final all = ref.watch(recurringStreamProvider).value ?? const [];
  return all.where((r) => r.isDue && !r.isPaused).toList();
});

/// Returns active upcoming recurring transactions within the next 30 days.
final upcomingRecurringListProvider = Provider<List<RecurringTransaction>>((ref) {
  final all = ref.watch(recurringStreamProvider).value ?? const [];
  return all.where((r) => !r.isPaused && r.daysUntilDue >= 0 && r.daysUntilDue <= 30).toList();
});

/// Total monthly estimated cost of all active recurring expenses.
final monthlyRecurringEstimateProvider = Provider<int>((ref) {
  final all = ref.watch(recurringStreamProvider).value ?? const [];
  int total = 0;
  for (final r in all) {
    if (r.isPaused) continue;
    switch (r.interval) {
      case RecurringInterval.daily:
        total += r.amount * 30;
        break;
      case RecurringInterval.weekly:
        total += r.amount * 4;
        break;
      case RecurringInterval.biweekly:
        total += r.amount * 2;
        break;
      case RecurringInterval.monthly:
        total += r.amount;
        break;
      case RecurringInterval.yearly:
        total += (r.amount / 12).round();
        break;
    }
  }
  return total;
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
