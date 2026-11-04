import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/recurring/domain/entities/recurring_transaction.dart';

abstract class RecurringRepository {
  Stream<List<RecurringTransaction>> watchRecurringTransactions();
  Future<Result<RecurringTransaction>> createRecurring(RecurringTransaction recurring);
  Future<Result<RecurringTransaction>> updateRecurring(RecurringTransaction recurring);
  Future<Result<void>> deleteRecurring(String id);
  Future<Result<void>> togglePause(String id, bool isPaused);
  Future<Result<void>> executeRecurring(String id);
}

