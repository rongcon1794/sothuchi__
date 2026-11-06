import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';

abstract interface class BudgetRepository {
  /// Streams all active (non-deleted) budgets.
  Stream<List<Budget>> watchBudgets();

  /// Returns all active (non-deleted) budgets.
  Future<List<Budget>> getBudgets();

  /// Creates or updates a monthly budget for `(monthStart, categoryId)`.
  Future<Result<Budget>> upsertMonthlyBudget({
    String? existingId,
    String? categoryId,
    required int amount,
    required String currency,
    required DateTime monthStart,
    required int alertThreshold,
    String? ledgerId,
  });

  /// Soft-deletes a budget (`deletedAt = now`).
  Future<Result<void>> softDeleteBudget(String budgetId);
}

