import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/debts/domain/entities/debt.dart';

abstract interface class DebtRepository {
  /// Streams all active (non-deleted) debts.
  Stream<List<Debt>> watchDebts();

  /// Fetches a specific debt by its ID.
  Future<Debt?> getDebtById(String id);

  /// Adds a new debt record (either lent or borrowed).
  Future<Result<Debt>> addDebt({
    required String personName,
    String? phoneNumber,
    required DebtType type,
    required int amount,
    String? currency,
    DateTime? dueDate,
    String? accountId,
    String note = '',
  });

  /// Updates an existing debt record.
  Future<Result<Debt>> updateDebt(Debt debt);

  /// Records a partial or full repayment for the given [debtId].
  ///
  /// If [accountId] is provided:
  /// - For [DebtType.lent] (cho vay): receiving repayment increases the wallet balance.
  /// - For [DebtType.borrowed] (đi vay): paying back decreases the wallet balance.
  Future<Result<void>> recordRepayment({
    required String debtId,
    required int amount,
    String? accountId,
    String note = '',
  });

  /// Soft deletes a debt record.
  Future<Result<void>> softDeleteDebt(String id);
}

