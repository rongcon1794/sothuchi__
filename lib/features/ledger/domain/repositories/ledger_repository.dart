import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';

abstract interface class LedgerRepository {
  Stream<List<LedgerBook>> watchLedgers();

  Future<Result<LedgerBook>> createLedger(LedgerBook ledger);

  Future<Result<LedgerBook>> updateLedger(LedgerBook ledger);

  Future<Result<void>> deleteLedger(String id);

  Future<void> ensureDefaultLedgers();
}

