import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';

abstract interface class TransactionRepository {
  /// Streams all non-deleted transactions sorted newest first (`date` desc, `createdAt` desc).
  Stream<List<TransactionEntity>> watchTransactions();

  /// Returns all non-deleted transactions sorted newest first.
  Future<List<TransactionEntity>> getTransactions();

  /// Looks up a single non-deleted transaction by [id], or `null` if not found.
  Future<TransactionEntity?> getTransactionById(String id);

  /// Records a new transaction and atomically updates affected wallet balance(s).
  Future<Result<TransactionEntity>> addTransaction({
    required int amount,
    required String currency,
    required TransactionType type,
    required String accountId,
    String? toAccountId,
    required String categoryId,
    String note = '',
    required DateTime date,
    List<String> tags = const <String>[],
    String? ledgerId,
  });

  /// Updates an existing transaction and atomically reconciles wallet balance deltas
  /// (even when amount, type, source wallet, or destination wallet changes).
  Future<Result<TransactionEntity>> updateTransaction(
    TransactionEntity updated,
  );

  /// Soft-deletes a transaction (`deletedAt = now`) and reverses its wallet balance impact.
  Future<Result<void>> softDeleteTransaction(String transactionId);

  /// Restores a previously soft-deleted transaction (`deletedAt = null`) and re-applies
  /// its wallet balance impact (used by the Undo action).
  Future<Result<void>> restoreTransaction(String transactionId);
}

