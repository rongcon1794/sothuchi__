import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:so_thu_chi/core/errors/app_exception.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/accounts/data/models/account_dto.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/domain/repositories/account_repository.dart';
import 'package:uuid/uuid.dart';

class FirestoreAccountRepository implements AccountRepository {
  FirestoreAccountRepository({
    required this.firestore,
    required this.uid,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  static const int maxNameLength = 100;
  static const int maxNoteLength = 1000;

  final FirebaseFirestore firestore;
  final String uid;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('users').doc(uid).collection('accounts');

  List<Account> _parseAndFilter(
    QuerySnapshot<Map<String, dynamic>> snap, {
    required bool includeArchived,
  }) {
    final accounts = <Account>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final dto = AccountDto.fromJson({...data, 'id': doc.id});
      final entity = dto.toDomain();
      if (entity.deletedAt != null) continue;
      if (!includeArchived && entity.archived) continue;
      accounts.add(entity);
    }
    accounts.sort((a, b) {
      if (a.archived != b.archived) {
        return a.archived ? 1 : -1;
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return accounts;
  }

  @override
  Stream<List<Account>> watchAccounts({bool includeArchived = true}) {
    return _col.snapshots().map(
      (snap) => _parseAndFilter(snap, includeArchived: includeArchived),
    );
  }

  @override
  Future<List<Account>> getAccounts({bool includeArchived = true}) async {
    final snap = await _col.get();
    return _parseAndFilter(snap, includeArchived: includeArchived);
  }

  @override
  Future<Result<Account>> createAccount({
    required String name,
    required AccountType type,
    required int initialBalance,
    required String currency,
    required String icon,
    required int color,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > maxNameLength) {
      return const Failure(
        ValidationException('Account name must be 1..100 characters'),
      );
    }

    try {
      final now = DateTime.now();
      final id = _uuid.v4();
      final entity = Account(
        id: id,
        name: trimmed,
        type: type,
        balance: initialBalance,
        currency: currency,
        icon: icon,
        color: color,
        createdAt: now,
        updatedAt: now,
      );
      await _col.doc(id).set(AccountDto.fromDomain(entity).toJson());
      return Success(entity);
    } on FirebaseException catch (e) {
      return Failure(StorageException('${e.code}: ${e.message}'));
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    }
  }

  @override
  Future<Result<Account>> updateAccount(Account account) async {
    final trimmed = account.name.trim();
    if (trimmed.isEmpty || trimmed.length > maxNameLength) {
      return const Failure(
        ValidationException('Account name must be 1..100 characters'),
      );
    }

    try {
      final updated = account.copyWith(
        name: trimmed,
        updatedAt: DateTime.now(),
      );
      await _col
          .doc(updated.id)
          .set(AccountDto.fromDomain(updated).toJson(), SetOptions(merge: true));
      return Success(updated);
    } on FirebaseException catch (e) {
      return Failure(StorageException('${e.code}: ${e.message}'));
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    }
  }

  @override
  Future<Result<void>> setArchived({
    required String accountId,
    required bool archived,
  }) async {
    try {
      await _col.doc(accountId).update({
        'archived': archived,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(StorageException('${e.code}: ${e.message}'));
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    }
  }

  @override
  Future<Result<void>> softDeleteAccount(String accountId) async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      await _col.doc(accountId).update({
        'deletedAt': now,
        'updatedAt': now,
      });
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(StorageException('${e.code}: ${e.message}'));
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    }
  }

  @override
  Future<Result<void>> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required int amountMinorUnits,
    required String currency,
    String note = '',
    DateTime? date,
  }) async {
    if (fromAccountId == toAccountId) {
      return const Failure(
        ValidationException('Source and destination accounts must differ'),
      );
    }
    if (amountMinorUnits <= 0) {
      return const Failure(ValidationException('Transfer amount must be > 0'));
    }
    final trimmedNote = note.trim();
    if (trimmedNote.length > maxNoteLength) {
      return const Failure(
        ValidationException('Transfer note must not exceed 1000 characters'),
      );
    }

    try {
      final fromSnap = await _col.doc(fromAccountId).get();
      final toSnap = await _col.doc(toAccountId).get();
      if (!fromSnap.exists ||
          fromSnap.data() == null ||
          !toSnap.exists ||
          toSnap.data() == null) {
        return const Failure(NotFoundException('Account not found'));
      }
      final fromAcc = AccountDto.fromJson({
        ...fromSnap.data()!,
        'id': fromSnap.id,
      }).toDomain();
      final toAcc = AccountDto.fromJson({
        ...toSnap.data()!,
        'id': toSnap.id,
      }).toDomain();
      if (fromAcc.deletedAt != null || toAcc.deletedAt != null) {
        return const Failure(NotFoundException('Account not found'));
      }
      if (fromAcc.currency != toAcc.currency) {
        return const Failure(
          ValidationException(
            'Cross-currency wallet transfers are not supported',
          ),
        );
      }

      final effectiveCurrency = fromAcc.currency;
      final now = DateTime.now();
      final nowTs = Timestamp.fromDate(now);
      final txDateTs = Timestamp.fromDate(date ?? now);
      final txId = _uuid.v4();
      final txCol = firestore
          .collection('users')
          .doc(uid)
          .collection('transactions');

      final batch = firestore.batch()
        ..update(_col.doc(fromAccountId), {
          'balance': FieldValue.increment(-amountMinorUnits),
          'updatedAt': nowTs,
        })
        ..update(_col.doc(toAccountId), {
          'balance': FieldValue.increment(amountMinorUnits),
          'updatedAt': nowTs,
        })
        ..set(txCol.doc(txId), {
          'id': txId,
          'amount': amountMinorUnits,
          'currency': effectiveCurrency,
          'type': 'transfer',
          'accountId': fromAccountId,
          'toAccountId': toAccountId,
          'categoryId': 'system_transfer',
          'note': trimmedNote,
          'date': txDateTs,
          'tags': <String>[],
          'createdAt': nowTs,
          'updatedAt': nowTs,
          'deletedAt': null,
        });

      await batch.commit();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(StorageException('${e.code}: ${e.message}'));
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    }
  }

  @override
  Future<Result<void>> ensureDefaultWallet({required String currency}) async {
    try {
      const id = 'default_cash_wallet';
      final defaultDoc = await _col.doc(id).get();
      if (defaultDoc.exists) {
        return const Success(null);
      }
      final existing = await getAccounts();
      if (existing.isNotEmpty) {
        return const Success(null);
      }
      final now = DateTime.now();
      final entity = Account(
        id: id,
        name: 'Tiền mặt',
        type: AccountType.cash,
        balance: 0,
        currency: currency,
        icon: 'cash',
        color: 0xFF0D7C66,
        createdAt: now,
        updatedAt: now,
      );
      await _col.doc(id).set(AccountDto.fromDomain(entity).toJson());
      return const Success(null);
    } catch (e) {
      return Failure(StorageException(e.toString()));
    }
  }
}

/// Reactive in-memory implementation used when running in Offline Demo Mode
/// or unauthenticated initial state.
class InMemoryAccountRepository implements AccountRepository {
  InMemoryAccountRepository({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  final Map<String, Account> _items = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  Map<String, Account> get rawStore => _items;
  void notifyExternalMutation() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  List<Account> _snapshot({required bool includeArchived}) {
    final list = _items.values.where((a) {
      if (a.deletedAt != null) return false;
      if (!includeArchived && a.archived) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        if (a.archived != b.archived) return a.archived ? 1 : -1;
        return a.createdAt.compareTo(b.createdAt);
      });
    return list;
  }

  @override
  Stream<List<Account>> watchAccounts({bool includeArchived = true}) async* {
    yield _snapshot(includeArchived: includeArchived);
    await for (final _ in _changes.stream) {
      yield _snapshot(includeArchived: includeArchived);
    }
  }

  @override
  Future<List<Account>> getAccounts({bool includeArchived = true}) async =>
      _snapshot(includeArchived: includeArchived);

  @override
  Future<Result<Account>> createAccount({
    required String name,
    required AccountType type,
    required int initialBalance,
    required String currency,
    required String icon,
    required int color,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty ||
        trimmed.length > FirestoreAccountRepository.maxNameLength) {
      return const Failure(
        ValidationException('Account name must be 1..100 characters'),
      );
    }
    final now = DateTime.now();
    final entity = Account(
      id: _uuid.v4(),
      name: trimmed,
      type: type,
      balance: initialBalance,
      currency: currency,
      icon: icon,
      color: color,
      createdAt: now,
      updatedAt: now,
    );
    _items[entity.id] = entity;
    notifyExternalMutation();
    return Success(entity);
  }

  @override
  Future<Result<Account>> updateAccount(Account account) async {
    final trimmed = account.name.trim();
    if (trimmed.isEmpty ||
        trimmed.length > FirestoreAccountRepository.maxNameLength) {
      return const Failure(
        ValidationException('Account name must be 1..100 characters'),
      );
    }
    final updated = account.copyWith(name: trimmed, updatedAt: DateTime.now());
    _items[updated.id] = updated;
    notifyExternalMutation();
    return Success(updated);
  }

  @override
  Future<Result<void>> setArchived({
    required String accountId,
    required bool archived,
  }) async {
    final existing = _items[accountId];
    if (existing == null) {
      return const Failure(NotFoundException('Account not found'));
    }
    _items[accountId] = existing.copyWith(
      archived: archived,
      updatedAt: DateTime.now(),
    );
    notifyExternalMutation();
    return const Success(null);
  }

  @override
  Future<Result<void>> softDeleteAccount(String accountId) async {
    final existing = _items[accountId];
    if (existing == null) return const Success(null);
    final now = DateTime.now();
    _items[accountId] = existing.copyWith(deletedAt: now, updatedAt: now);
    notifyExternalMutation();
    return const Success(null);
  }

  Future<void> Function({
    required String fromAccountId,
    required String toAccountId,
    required int amountMinorUnits,
    required String currency,
    required String note,
    required DateTime date,
  })? onTransferRecorded;

  @override
  Future<Result<void>> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required int amountMinorUnits,
    required String currency,
    String note = '',
    DateTime? date,
  }) async {
    if (fromAccountId == toAccountId) {
      return const Failure(
        ValidationException('Source and destination accounts must differ'),
      );
    }
    if (amountMinorUnits <= 0) {
      return const Failure(ValidationException('Transfer amount must be > 0'));
    }
    final trimmedNote = note.trim();
    if (trimmedNote.length > FirestoreAccountRepository.maxNoteLength) {
      return const Failure(
        ValidationException('Transfer note must not exceed 1000 characters'),
      );
    }
    final from = _items[fromAccountId];
    final to = _items[toAccountId];
    if (from == null ||
        to == null ||
        from.deletedAt != null ||
        to.deletedAt != null) {
      return const Failure(NotFoundException('Account not found'));
    }
    if (from.currency != to.currency) {
      return const Failure(
        ValidationException(
          'Cross-currency wallet transfers are not supported',
        ),
      );
    }
    final now = DateTime.now();
    if (onTransferRecorded != null) {
      await onTransferRecorded!(
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        amountMinorUnits: amountMinorUnits,
        currency: from.currency,
        note: trimmedNote,
        date: date ?? now,
      );
    } else {
      _items[fromAccountId] = from.copyWith(
        balance: from.balance - amountMinorUnits,
        updatedAt: now,
      );
      _items[toAccountId] = to.copyWith(
        balance: to.balance + amountMinorUnits,
        updatedAt: now,
      );
      notifyExternalMutation();
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> ensureDefaultWallet({required String currency}) async {
    if (_items.containsKey('default_cash_wallet') ||
        _snapshot(includeArchived: true).isNotEmpty) {
      return const Success(null);
    }
    final now = DateTime.now();
    _items['default_cash_wallet'] = Account(
      id: 'default_cash_wallet',
      name: 'Tiền mặt',
      type: AccountType.cash,
      balance: 0,
      currency: currency,
      icon: 'cash',
      color: 0xFF0D7C66,
      createdAt: now,
      updatedAt: now,
    );
    notifyExternalMutation();
    return const Success(null);
  }

  void clear() {
    _items.clear();
    notifyExternalMutation();
  }
}
