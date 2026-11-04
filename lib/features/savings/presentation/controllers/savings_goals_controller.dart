import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/savings/domain/entities/savings_goal.dart';
import 'package:so_thu_chi/features/savings/domain/repositories/savings_goal_repository.dart';

final savingsGoalsStreamProvider = StreamProvider<List<SavingsGoal>>((ref) {
  final repo = ref.watch(savingsGoalRepositoryProvider);
  return repo.watchSavingsGoals();
});

final activeSavingsGoalsProvider = Provider<List<SavingsGoal>>((ref) {
  final all = ref.watch(savingsGoalsStreamProvider).value ?? const [];
  return all.where((g) => !g.isCompleted).toList();
});

final completedSavingsGoalsProvider = Provider<List<SavingsGoal>>((ref) {
  final all = ref.watch(savingsGoalsStreamProvider).value ?? const [];
  return all.where((g) => g.isCompleted).toList();
});

class SavingsSummary {
  const SavingsSummary({
    required this.totalTarget,
    required this.totalSaved,
    required this.currency,
    required this.overallProgress,
    required this.activeCount,
    required this.completedCount,
  });

  final int totalTarget;
  final int totalSaved;
  final String currency;
  final double overallProgress;
  final int activeCount;
  final int completedCount;

  Money get targetMoney => Money(minorUnits: totalTarget, currencyCode: currency);
  Money get savedMoney => Money(minorUnits: totalSaved, currencyCode: currency);
}

final savingsSummaryProvider = Provider<SavingsSummary>((ref) {
  final all = ref.watch(savingsGoalsStreamProvider).value ?? const [];
  int totalTarget = 0;
  int totalSaved = 0;
  String currency = AppCurrencies.defaultCode;
  int active = 0;
  int completed = 0;

  for (final g in all) {
    totalTarget += g.targetAmount;
    totalSaved += g.currentAmount;
    currency = g.currency;
    if (g.isCompleted) {
      completed++;
    } else {
      active++;
    }
  }

  final progress = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

  return SavingsSummary(
    totalTarget: totalTarget,
    totalSaved: totalSaved,
    currency: currency,
    overallProgress: progress,
    activeCount: active,
    completedCount: completed,
  );
});

class SavingsGoalsActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  SavingsGoalRepository get _repository => ref.read(savingsGoalRepositoryProvider);

  Future<Result<SavingsGoal>> createGoal(SavingsGoal goal) async {
    state = const AsyncLoading();
    final res = await _repository.createGoal(goal);
    state = res.isSuccess
        ? const AsyncData(null)
        : AsyncError(res.errorOrNull!, StackTrace.current);
    return res;
  }

  Future<Result<SavingsGoal>> updateGoal(SavingsGoal goal) async {
    state = const AsyncLoading();
    final res = await _repository.updateGoal(goal);
    state = res.isSuccess
        ? const AsyncData(null)
        : AsyncError(res.errorOrNull!, StackTrace.current);
    return res;
  }

  Future<Result<void>> deleteGoal(String id) async {
    state = const AsyncLoading();
    final res = await _repository.deleteGoal(id);
    state = res.isSuccess
        ? const AsyncData(null)
        : AsyncError(res.errorOrNull!, StackTrace.current);
    return res;
  }

  Future<Result<void>> depositToGoal({
    required String goalId,
    required int amount,
    required String fromAccountId,
    String note = '',
  }) async {
    state = const AsyncLoading();
    final res = await _repository.depositToGoal(
      goalId: goalId,
      amount: amount,
      fromAccountId: fromAccountId,
      note: note,
    );
    state = res.isSuccess
        ? const AsyncData(null)
        : AsyncError(res.errorOrNull!, StackTrace.current);
    return res;
  }

  Future<Result<void>> withdrawFromGoal({
    required String goalId,
    required int amount,
    required String toAccountId,
    String note = '',
  }) async {
    state = const AsyncLoading();
    final res = await _repository.withdrawFromGoal(
      goalId: goalId,
      amount: amount,
      toAccountId: toAccountId,
      note: note,
    );
    state = res.isSuccess
        ? const AsyncData(null)
        : AsyncError(res.errorOrNull!, StackTrace.current);
    return res;
  }
}

final savingsGoalsActionControllerProvider =
    NotifierProvider<SavingsGoalsActionController, AsyncValue<void>>(
  SavingsGoalsActionController.new,
);
