import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/savings/domain/entities/savings_goal.dart';

abstract interface class SavingsGoalRepository {
  Stream<List<SavingsGoal>> watchSavingsGoals();

  Future<Result<SavingsGoal>> createGoal(SavingsGoal goal);

  Future<Result<SavingsGoal>> updateGoal(SavingsGoal goal);

  Future<Result<void>> deleteGoal(String id);

  Future<Result<void>> depositToGoal({
    required String goalId,
    required int amount,
    required String fromAccountId,
    String note = '',
  });

  Future<Result<void>> withdrawFromGoal({
    required String goalId,
    required int amount,
    required String toAccountId,
    String note = '',
  });
}
