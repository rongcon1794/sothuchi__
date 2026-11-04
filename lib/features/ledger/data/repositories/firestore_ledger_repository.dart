import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/errors/app_exception.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/ledger/data/models/ledger_book_dto.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';
import 'package:so_thu_chi/features/ledger/domain/repositories/ledger_repository.dart';

class FirestoreLedgerRepository implements LedgerRepository {
  FirestoreLedgerRepository({
    required this.firestore,
    required this.currentUserIdGetter,
  });

  final FirebaseFirestore firestore;
  final String Function() currentUserIdGetter;

  CollectionReference<Map<String, dynamic>> _collection() {
    final uid = currentUserIdGetter();
    if (uid.isEmpty) {
      throw const AuthFailedException('User not authenticated');
    }
    return firestore.collection('users').doc(uid).collection('ledgers');
  }

  @override
  Stream<List<LedgerBook>> watchLedgers() {
    try {
      return _collection()
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return [LedgerBook.defaultPersonal()];
        }
        return snapshot.docs
            .map((doc) => LedgerBookDto.fromJson(doc.data(), doc.id).toDomain())
            .toList();
      });
    } catch (_) {
      return Stream.value([LedgerBook.defaultPersonal()]);
    }
  }

  @override
  Future<Result<LedgerBook>> createLedger(LedgerBook ledger) async {
    try {
      final docRef = _collection().doc();
      final entity = ledger.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(LedgerBookDto.fromDomain(entity).toJson());
      return Success(entity);
    } catch (e) {
      return Failure(StorageException('Failed to create ledger: $e'));
    }
  }

  @override
  Future<Result<LedgerBook>> updateLedger(LedgerBook ledger) async {
    try {
      final updated = ledger.copyWith(updatedAt: DateTime.now());
      await _collection()
          .doc(ledger.id)
          .update(LedgerBookDto.fromDomain(updated).toJson());
      return Success(updated);
    } catch (e) {
      return Failure(StorageException('Failed to update ledger: $e'));
    }
  }

  @override
  Future<Result<void>> deleteLedger(String id) async {
    try {
      if (id == LedgerBook.defaultPersonalId) {
        return const Failure(ValidationException('Không thể xóa sổ mặc định'));
      }
      await _collection().doc(id).delete();
      return const Success(null);
    } catch (e) {
      return Failure(StorageException('Failed to delete ledger: $e'));
    }
  }

  @override
  Future<void> ensureDefaultLedgers() async {
    try {
      final snapshot = await _collection().limit(1).get();
      if (snapshot.docs.isEmpty) {
        final personal = LedgerBook.defaultPersonal();
        final family = LedgerBook(
          id: 'default_family',
          name: 'Sổ Gia Đình',
          type: LedgerType.family,
          icon: 'family',
          color: 0xFF007AFF,
          currency: AppCurrencies.defaultCode,
          isDefault: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _collection().doc(personal.id).set(LedgerBookDto.fromDomain(personal).toJson());
        await _collection().doc(family.id).set(LedgerBookDto.fromDomain(family).toJson());
      }
    } catch (_) {}
  }
}

/// In-memory repository for unit and widget tests.
class InMemoryLedgerRepository implements LedgerRepository {
  InMemoryLedgerRepository() {
    _seedDefault();
  }

  final Map<String, LedgerBook> _store = {};
  final StreamController<List<LedgerBook>> _controller =
      StreamController<List<LedgerBook>>.broadcast();

  void _seedDefault() {
    final personal = LedgerBook.defaultPersonal();
    final family = LedgerBook(
      id: 'default_family',
      name: 'Sổ Gia Đình',
      type: LedgerType.family,
      icon: 'family',
      color: 0xFF007AFF,
      currency: AppCurrencies.defaultCode,
      isDefault: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _store[personal.id] = personal;
    _store[family.id] = family;
  }

  void _emit() {
    final list = _store.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _controller.add(list);
  }

  @override
  Stream<List<LedgerBook>> watchLedgers() async* {
    yield _store.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    yield* _controller.stream;
  }

  @override
  Future<Result<LedgerBook>> createLedger(LedgerBook ledger) async {
    final id = ledger.id.isEmpty
        ? 'ledger_${DateTime.now().millisecondsSinceEpoch}'
        : ledger.id;
    final entity = ledger.copyWith(
      id: id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _store[id] = entity;
    _emit();
    return Success(entity);
  }

  @override
  Future<Result<LedgerBook>> updateLedger(LedgerBook ledger) async {
    if (!_store.containsKey(ledger.id)) {
      return const Failure(NotFoundException('Ledger not found'));
    }
    final updated = ledger.copyWith(updatedAt: DateTime.now());
    _store[ledger.id] = updated;
    _emit();
    return Success(updated);
  }

  @override
  Future<Result<void>> deleteLedger(String id) async {
    if (id == LedgerBook.defaultPersonalId) {
      return const Failure(ValidationException('Không thể xóa sổ mặc định'));
    }
    _store.remove(id);
    _emit();
    return const Success(null);
  }

  @override
  Future<void> ensureDefaultLedgers() async {
    if (_store.isEmpty) {
      _seedDefault();
      _emit();
    }
  }

  void dispose() {
    _controller.close();
  }
}

