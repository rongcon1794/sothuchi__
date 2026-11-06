import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:so_thu_chi/core/errors/app_exception.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/accounts/data/repositories/firestore_account_repository.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';
import 'package:so_thu_chi/features/transactions/data/models/transaction_dto.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:uuid/uuid.dart';

/// Pure balance impact calculator shared across Firestore and In-Memory repositories.
///
/// Maps `accountId -> signed minor-unit delta` for applying ([multiplier] = `1`)
/// or reversing ([multiplier] = `-1`) a transaction's wallet impact.
Map<String, int> computeWalletBalanceDeltas(
  TransactionEntity tx, {
  int multiplier = 1,
}) {
  final deltas = <String, int>{};
  void addDelta(String accountId, int delta) {
    if (accountId.isEmpty || delta == 0) return;
    final next = (deltas[accountId] ?? 0) + delta;
    if (next == 0) {
      deltas.remove(accountId);
    } else {
      deltas[accountId] = next;
    }
  }

  switch (tx.type) {
    case TransactionType.income:
      addDelta(tx.accountId, tx.amount * multiplier);
    case TransactionType.expense:
      addDelta(tx.accountId, -tx.amount * multiplier);
    case TransactionType.transfer:
      addDelta(tx.accountId, -tx.amount * multiplier);
      if (tx.toAccountId != null && tx.toAccountId!.isNotEmpty) {
        addDelta(tx.toAccountId!, tx.amount * multiplier);
      }
  }
  return deltas;
}

Map<String, int> mergeBalanceDeltas(Map<String, int> a, Map<String, int> b) {
  final merged = <String, int>{...a};
  for (final entry in b.entries) {
    final next = (merged[entry.key] ?? 0) + entry.value;
    if (next == 0) {
      merged.remove(entry.key);
    } else {
      merged[entry.key] = next;
    }
  }
  return merged;
}

List<String> normalizeTransactionTags(List<String> tags) {
  return tags
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toSet()
      .toList(growable: false);
}

ValidationException? validateTransactionInput({
  required int amount,
  required TransactionType type,
  required String accountId,
  required String? toAccountId,
  required String categoryId,
  required String note,
  required List<String> normalizedTags,
}) {
  if (amount <= 0) {
    return const ValidationException('Transaction amount must be > 0');
  }
  if (accountId.trim().isEmpty) {
    return const ValidationException('Source wallet is required');
  }
  if (type == TransactionType.transfer) {
    if (toAccountId == null || toAccountId.trim().isEmpty) {
      return const ValidationException('Destination wallet is required');
    }
    if (toAccountId == accountId) {
      return const ValidationException(
        'Source and destination wallets must differ',
      );
    }
  } else if (categoryId.trim().isEmpty) {
    return const ValidationException('Category is required');
  }
  if (note.trim().length > 1000) {
    return const ValidationException('Note must not exceed 1000 characters');
  }
  if (normalizedTags.length > 20) {
    return const ValidationException('Maximum 20 tags per transaction');
  }
  if (normalizedTags.any((t) => t.length > 64)) {
    return const ValidationException('Each tag must be at most 64 characters');
  }
  return null;
}

class FirestoreTransactionRepository implements TransactionRepository {
  FirestoreTransactionRepository({
    required this.firestore,
    required this.uid,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final FirebaseFirestore firestore;
  final String uid;
  final Uuid _uuid;
  final Set<String> _inFlightIds = <String>{};

  CollectionReference<Map<String, dynamic>> get _txCol =>
      firestore.collection('users').doc(uid).collection('transactions');

  CollectionReference<Map<String, dynamic>> get _accCol =>
      firestore.collection('users').doc(uid).collection('accounts');

  List<TransactionEntity> _parseActiveSorted(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final items = <TransactionEntity>[];
    for (final doc in snap.docs) {
      final dto = TransactionDto.fromJson({...doc.data(), 'id': doc.id});
      final entity = dto.toDomain();
      if (entity.deletedAt != null) continue;
      items.add(entity);
    }
    items.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.createdAt.compareTo(a.createdAt);
    });
    return items;
  }

  @override
  Stream<List<TransactionEntity>> watchTransactions() {
    return _txCol
        .where('deletedAt', isNull: true)
        .orderBy('date', descending: true)
        .snapshots()
        .map(_parseActiveSorted);
  }

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    final snap = await _txCol
        .where('deletedAt', isNull: true)
        .orderBy('date', descending: true)
        .get();
    return _parseActiveSorted(snap);
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async {
    final doc = await _txCol.doc(id).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    final entity = TransactionDto.fromJson({...data, 'id': doc.id}).toDomain();
    if (entity.deletedAt != null) return null;
    return entity;
  }

  @override
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
  }) async {
    final effectiveCategory = type == TransactionType.transfer
        ? 'system_transfer'
        : categoryId;
    final normalizedTags = normalizeTransactionTags(tags);
    final validationErr = validateTransactionInput(
      amount: amount,
      type: type,
      accountId: accountId,
      toAccountId: toAccountId,
      categoryId: effectiveCategory,
      note: note,
      normalizedTags: normalizedTags,
    );
    if (validationErr != null) {
      return Failure(validationErr);
    }

    try {
      final now = DateTime.now();
      final nowTs = Timestamp.fromDate(now);
      final id = _uuid.v4();
      final entity = TransactionEntity(
        id: id,
        amount: amount,
        currency: currency,
        type: type,
        accountId: accountId,
        toAccountId: type == TransactionType.transfer ? toAccountId : null,
        categoryId: effectiveCategory,
        note: note.trim(),
        date: date,
        tags: normalizedTags,
        ledgerId: (ledgerId ?? '').trim().isEmpty
            ? LedgerBook.defaultPersonalId
            : ledgerId!.trim(),
        createdAt: now,
        updatedAt: now,
      );

      final deltas = computeWalletBalanceDeltas(entity);
      final batch = firestore.batch()
        ..set(_txCol.doc(id), TransactionDto.fromDomain(entity).toJson());

      for (final entry in deltas.entries) {
        batch.update(_accCol.doc(entry.key), {
          'balance': FieldValue.increment(entry.value),
          'updatedAt': nowTs,
        });
      }

      await batch.commit();
      return Success(entity);
    } on FirebaseException catch (e) {
      return Failure(StorageException('${e.code}: ${e.message}'));
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    }
  }

  @override
  Future<Result<TransactionEntity>> updateTransaction(
    TransactionEntity updated,
  ) async {
    final effectiveCategory = updated.type == TransactionType.transfer
        ? 'system_transfer'
        : updated.categoryId;
    final normalizedTags = normalizeTransactionTags(updated.tags);
    final validationErr = validateTransactionInput(
      amount: updated.amount,
      type: updated.type,
      accountId: updated.accountId,
      toAccountId: updated.toAccountId,
      categoryId: effectiveCategory,
      note: updated.note,
      normalizedTags: normalizedTags,
    );
    if (validationErr != null) {
      return Failure(validationErr);
    }
    if (!_inFlightIds.add(updated.id)) {
      return const Failure(
        ValidationException('Another update is already in progress'),
      );
    }

    try {
      final existingDoc = await _txCol.doc(updated.id).get();
      final existingData = existingDoc.data();
      if (!existingDoc.exists || existingData == null) {
        return const Failure(NotFoundException('Transaction not found'));
      }
      final previous = TransactionDto.fromJson({
        ...existingData,
        'id': existingDoc.id,
      }).toDomain();
      if (previous.deletedAt != null) {
        return const Failure(NotFoundException('Transaction was deleted'));
      }

      final now = DateTime.now();
      final nowTs = Timestamp.fromDate(now);
      final normalized = updated.copyWith(
        toAccountId: updated.type == TransactionType.transfer
            ? updated.toAccountId
            : null,
        categoryId: effectiveCategory,
        note: updated.note.trim(),
        tags: normalizedTags,
        createdAt: previous.createdAt,
        updatedAt: now,
      );

      final reverseOld = computeWalletBalanceDeltas(previous, multiplier: -1);
      final applyNew = computeWalletBalanceDeltas(normalized);
      final netDeltas = mergeBalanceDeltas(reverseOld, applyNew);

      final batch = firestore.batch()
        ..set(
          _txCol.doc(normalized.id),
          TransactionDto.fromDomain(normalized).toJson(),
          SetOptions(merge: true),
        );

      for (final entry in netDeltas.entries) {
        batch.update(_accCol.doc(entry.key), {
          'balance': FieldValue.increment(entry.value),
          'updatedAt': nowTs,
        });
      }

      await batch.commit();
      return Success(normalized);
    } on FirebaseException catch (e) {
      return Failure(StorageException('${e.code}: ${e.message}'));
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    } finally {
      _inFlightIds.remove(updated.id);
    }
  }

  @override
  Future<Result<void>> softDeleteTransaction(String transactionId) async {
    if (!_inFlightIds.add(transactionId)) {
      return const Failure(
        ValidationException('Transaction operation already in progress'),
      );
    }
    try {
      final doc = await _txCol.doc(transactionId).get();
      final data = doc.data();
      if (!doc.exists || data == null) {
        return const Success(null);
      }
      final existing = TransactionDto.fromJson({
        ...data,
        'id': doc.id,
      }).toDomain();
      if (existing.deletedAt != null) {
        return const Success(null);
      }

      final nowTs = Timestamp.fromDate(DateTime.now());
      final reverseDeltas = computeWalletBalanceDeltas(
        existing,
        multiplier: -1,
      );

      final batch = firestore.batch()
        ..update(_txCol.doc(transactionId), {
          'deletedAt': nowTs,
          'updatedAt': nowTs,
        });

      for (final entry in reverseDeltas.entries) {
        batch.update(_accCol.doc(entry.key), {
          'balance': FieldValue.increment(entry.value),
          'updatedAt': nowTs,
        });
      }

      await batch.commit();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(StorageException('${e.code}: ${e.message}'));
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    } finally {
      _inFlightIds.remove(transactionId);
    }
  }

  @override
  Future<Result<void>> restoreTransaction(String transactionId) async {
    if (!_inFlightIds.add(transactionId)) {
      return const Failure(
        ValidationException('Transaction operation already in progress'),
      );
    }
    try {
      final doc = await _txCol.doc(transactionId).get();
      final data = doc.data();
      if (!doc.exists || data == null) {
        return const Failure(NotFoundException('Transaction not found'));
      }
      final existing = TransactionDto.fromJson({
        ...data,
        'id': doc.id,
      }).toDomain();
      if (existing.deletedAt == null) {
        return const Success(null);
      }

      final nowTs = Timestamp.fromDate(DateTime.now());
      final reapplyDeltas = computeWalletBalanceDeltas(existing);

      final batch = firestore.batch()
        ..update(_txCol.doc(transactionId), {
          'deletedAt': null,
          'updatedAt': nowTs,
        });

      for (final entry in reapplyDeltas.entries) {
        batch.update(_accCol.doc(entry.key), {
          'balance': FieldValue.increment(entry.value),
          'updatedAt': nowTs,
        });
      }

      await batch.commit();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(StorageException('${e.code}: ${e.message}'));
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    } finally {
      _inFlightIds.remove(transactionId);
    }
  }
}

/// Reactive in-memory repository for Offline Demo Mode and widget testing.
class InMemoryTransactionRepository implements TransactionRepository {
  InMemoryTransactionRepository({
    required this.accountRepo,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid() {
    accountRepo.onTransferRecorded = ({
      required String fromAccountId,
      required String toAccountId,
      required int amountMinorUnits,
      required String currency,
      required String note,
      required DateTime date,
    }) async {
      await addTransaction(
        amount: amountMinorUnits,
        currency: currency,
        type: TransactionType.transfer,
        accountId: fromAccountId,
        toAccountId: toAccountId,
        categoryId: 'system_transfer',
        note: note,
        date: date,
      );
    };
  }

  final InMemoryAccountRepository accountRepo;
  final Uuid _uuid;
  final Map<String, TransactionEntity> _items = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  void _applyAccountDeltas(Map<String, int> deltas, DateTime now) {
    if (deltas.isEmpty) return;
    final store = accountRepo.rawStore;
    var mutated = false;
    for (final entry in deltas.entries) {
      final acc = store[entry.key];
      if (acc != null) {
        store[entry.key] = acc.copyWith(
          balance: acc.balance + entry.value,
          updatedAt: now,
        );
        mutated = true;
      }
    }
    if (mutated) {
      accountRepo.notifyExternalMutation();
    }
  }

  List<TransactionEntity> _snapshot() {
    final list = _items.values.where((t) => t.deletedAt == null).toList()
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        if (byDate != 0) return byDate;
        return b.createdAt.compareTo(a.createdAt);
      });
    return list;
  }

  @override
  Stream<List<TransactionEntity>> watchTransactions() async* {
    yield _snapshot();
    await for (final _ in _changes.stream) {
      yield _snapshot();
    }
  }

  @override
  Future<List<TransactionEntity>> getTransactions() async => _snapshot();

  @override
  Future<TransactionEntity?> getTransactionById(String id) async {
    final tx = _items[id];
    if (tx == null || tx.deletedAt != null) return null;
    return tx;
  }

  @override
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
  }) async {
    final effectiveCategory = type == TransactionType.transfer
        ? 'system_transfer'
        : categoryId;
    final normalizedTags = normalizeTransactionTags(tags);
    final err = validateTransactionInput(
      amount: amount,
      type: type,
      accountId: accountId,
      toAccountId: toAccountId,
      categoryId: effectiveCategory,
      note: note,
      normalizedTags: normalizedTags,
    );
    if (err != null) return Failure(err);

    final store = accountRepo.rawStore;
    if (type == TransactionType.transfer && toAccountId != null) {
      final fromAcc = store[accountId];
      final toAcc = store[toAccountId];
      if (fromAcc != null &&
          toAcc != null &&
          fromAcc.currency != toAcc.currency) {
        return const Failure(
          ValidationException(
            'Cross-currency wallet transfers are not supported',
          ),
        );
      }
    }

    final now = DateTime.now();
    final effectiveCurrency = store[accountId]?.currency ?? currency;
    final entity = TransactionEntity(
      id: _uuid.v4(),
      amount: amount,
      currency: effectiveCurrency,
      type: type,
      accountId: accountId,
      toAccountId: type == TransactionType.transfer ? toAccountId : null,
      categoryId: effectiveCategory,
      note: note.trim(),
      date: date,
      tags: normalizedTags,
      ledgerId: (ledgerId ?? '').trim().isEmpty
          ? LedgerBook.defaultPersonalId
          : ledgerId!.trim(),
      createdAt: now,
      updatedAt: now,
    );
    _items[entity.id] = entity;
    _applyAccountDeltas(computeWalletBalanceDeltas(entity), now);
    _notify();
    return Success(entity);
  }

  @override
  Future<Result<TransactionEntity>> updateTransaction(
    TransactionEntity updated,
  ) async {
    final effectiveCategory = updated.type == TransactionType.transfer
        ? 'system_transfer'
        : updated.categoryId;
    final normalizedTags = normalizeTransactionTags(updated.tags);
    final err = validateTransactionInput(
      amount: updated.amount,
      type: updated.type,
      accountId: updated.accountId,
      toAccountId: updated.toAccountId,
      categoryId: effectiveCategory,
      note: updated.note,
      normalizedTags: normalizedTags,
    );
    if (err != null) return Failure(err);

    final previous = _items[updated.id];
    if (previous == null || previous.deletedAt != null) {
      return const Failure(NotFoundException('Transaction not found'));
    }

    final store = accountRepo.rawStore;
    if (updated.type == TransactionType.transfer &&
        updated.toAccountId != null) {
      final fromAcc = store[updated.accountId];
      final toAcc = store[updated.toAccountId!];
      if (fromAcc != null &&
          toAcc != null &&
          fromAcc.currency != toAcc.currency) {
        return const Failure(
          ValidationException(
            'Cross-currency wallet transfers are not supported',
          ),
        );
      }
    }

    final now = DateTime.now();
    final effectiveCurrency = store[updated.accountId]?.currency ?? updated.currency;
    final normalized = updated.copyWith(
      currency: effectiveCurrency,
      toAccountId: updated.type == TransactionType.transfer
          ? updated.toAccountId
          : null,
      categoryId: effectiveCategory,
      note: updated.note.trim(),
      tags: normalizedTags,
      createdAt: previous.createdAt,
      updatedAt: now,
    );

    final netDeltas = mergeBalanceDeltas(
      computeWalletBalanceDeltas(previous, multiplier: -1),
      computeWalletBalanceDeltas(normalized),
    );
    _items[normalized.id] = normalized;
    _applyAccountDeltas(netDeltas, now);
    _notify();
    return Success(normalized);
  }

  @override
  Future<Result<void>> softDeleteTransaction(String transactionId) async {
    final existing = _items[transactionId];
    if (existing == null || existing.deletedAt != null) {
      return const Success(null);
    }
    final now = DateTime.now();
    _items[transactionId] = existing.copyWith(deletedAt: now, updatedAt: now);
    _applyAccountDeltas(computeWalletBalanceDeltas(existing, multiplier: -1), now);
    _notify();
    return const Success(null);
  }

  @override
  Future<Result<void>> restoreTransaction(String transactionId) async {
    final existing = _items[transactionId];
    if (existing == null) {
      return const Failure(NotFoundException('Transaction not found'));
    }
    if (existing.deletedAt == null) return const Success(null);
    final now = DateTime.now();
    _items[transactionId] = existing.copyWith(deletedAt: null, updatedAt: now);
    _applyAccountDeltas(computeWalletBalanceDeltas(existing), now);
    _notify();
    return const Success(null);
  }

  void clear() {
    _items.clear();
    _notify();
  }
}
