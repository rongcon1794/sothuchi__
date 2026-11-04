import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:so_thu_chi/core/errors/app_exception.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/recurring/data/models/recurring_transaction_dto.dart';
import 'package:so_thu_chi/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:so_thu_chi/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:so_thu_chi/features/transactions/domain/repositories/transaction_repository.dart';

class FirestoreRecurringRepository implements RecurringRepository {
  FirestoreRecurringRepository({
    required this.firestore,
    required this.currentUserIdGetter,
    required this.transactionRepository,
  });

  final FirebaseFirestore firestore;
  final String Function() currentUserIdGetter;
  final TransactionRepository transactionRepository;

  CollectionReference<Map<String, dynamic>> _collection() {
    final uid = currentUserIdGetter();
    if (uid.isEmpty) {
      throw const AuthFailedException('User not authenticated');
    }
    return firestore.collection('users').doc(uid).collection('recurring');
  }

  @override
  Stream<List<RecurringTransaction>> watchRecurringTransactions() {
    try {
      return _collection()
          .orderBy('nextDueDate', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => RecurringTransactionDto.fromJson(doc.data(), doc.id).toDomain())
            .toList();
      });
    } catch (_) {
      return Stream.value(const <RecurringTransaction>[]);
    }
  }

  @override
  Future<Result<RecurringTransaction>> createRecurring(RecurringTransaction recurring) async {
    try {
      final docRef = _collection().doc();
      final entity = recurring.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(RecurringTransactionDto.fromDomain(entity).toJson());
      return Success(entity);
    } catch (e) {
      return Failure(StorageException('Failed to create recurring transaction: $e'));
    }
  }

  @override
  Future<Result<RecurringTransaction>> updateRecurring(RecurringTransaction recurring) async {
    try {
      final entity = recurring.copyWith(updatedAt: DateTime.now());
      await _collection().doc(entity.id).update(
            RecurringTransactionDto.fromDomain(entity).toJson(),
          );
      return Success(entity);
    } catch (e) {
      return Failure(StorageException('Failed to update recurring transaction: $e'));
    }
  }

  @override
  Future<Result<void>> deleteRecurring(String id) async {
    try {
      await _collection().doc(id).delete();
      return const Success(null);
    } catch (e) {
      return Failure(StorageException('Failed to delete recurring transaction: $e'));
    }
  }

  @override
  Future<Result<void>> togglePause(String id, bool isPaused) async {
    try {
      await _collection().doc(id).update({
        'isPaused': isPaused,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return const Success(null);
    } catch (e) {
      return Failure(StorageException('Failed to toggle pause: $e'));
    }
  }

  @override
  Future<Result<void>> executeRecurring(String id) async {
    try {
      final docSnap = await _collection().doc(id).get();
      if (!docSnap.exists || docSnap.data() == null) {
        return const Failure(NotFoundException('Recurring transaction not found'));
      }
      final recurring = RecurringTransactionDto.fromJson(docSnap.data()!, docSnap.id).toDomain();

      // 1. Create real transaction
      final txRes = await transactionRepository.addTransaction(
        amount: recurring.amount,
        currency: recurring.currency,
        type: recurring.type,
        accountId: recurring.accountId,
        toAccountId: recurring.toAccountId,
        categoryId: recurring.categoryId,
        note: recurring.title.isNotEmpty ? '[Định kỳ] ${recurring.title}' : recurring.note,
        date: DateTime.now(),
        tags: const ['định kỳ', 'tự động'],
      );

      if (txRes.isFailure) {
        return Failure(txRes.errorOrNull!);
      }

      // 2. Compute next due date & update recurring record
      final next = recurring.computeNextDate(recurring.nextDueDate);
      final updated = recurring.copyWith(
        nextDueDate: next,
        lastExecutedDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _collection().doc(id).update(
            RecurringTransactionDto.fromDomain(updated).toJson(),
          );

      return const Success(null);
    } catch (e) {
      return Failure(StorageException('Failed to execute recurring: $e'));
    }
  }
}

/// In-memory repository for unit and widget tests.
class InMemoryRecurringRepository implements RecurringRepository {
  InMemoryRecurringRepository({
    this.transactionRepository,
  });

  final TransactionRepository? transactionRepository;
  final Map<String, RecurringTransaction> _store = {};
  final StreamController<List<RecurringTransaction>> _controller =
      StreamController<List<RecurringTransaction>>.broadcast();

  void _emit() {
    final list = _store.values.toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    _controller.add(list);
  }

  @override
  Stream<List<RecurringTransaction>> watchRecurringTransactions() async* {
    final list = _store.values.toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    yield list;
    yield* _controller.stream;
  }

  @override
  Future<Result<RecurringTransaction>> createRecurring(RecurringTransaction recurring) async {
    final id = recurring.id.isEmpty
        ? 'rec_${DateTime.now().millisecondsSinceEpoch}_${_store.length}'
        : recurring.id;
    final entity = recurring.copyWith(id: id);
    _store[id] = entity;
    _emit();
    return Success(entity);
  }

  @override
  Future<Result<RecurringTransaction>> updateRecurring(RecurringTransaction recurring) async {
    if (!_store.containsKey(recurring.id)) {
      return const Failure(NotFoundException('Not found'));
    }
    _store[recurring.id] = recurring;
    _emit();
    return Success(recurring);
  }

  @override
  Future<Result<void>> deleteRecurring(String id) async {
    _store.remove(id);
    _emit();
    return const Success(null);
  }

  @override
  Future<Result<void>> togglePause(String id, bool isPaused) async {
    final item = _store[id];
    if (item == null) return const Failure(NotFoundException('Not found'));
    _store[id] = item.copyWith(isPaused: isPaused);
    _emit();
    return const Success(null);
  }

  @override
  Future<Result<void>> executeRecurring(String id) async {
    final item = _store[id];
    if (item == null) return const Failure(NotFoundException('Not found'));

    if (transactionRepository != null) {
      await transactionRepository!.addTransaction(
        amount: item.amount,
        currency: item.currency,
        type: item.type,
        accountId: item.accountId,
        toAccountId: item.toAccountId,
        categoryId: item.categoryId,
        note: item.title.isNotEmpty ? '[Định kỳ] ${item.title}' : item.note,
        date: DateTime.now(),
        tags: const ['định kỳ'],
      );
    }

    final next = item.computeNextDate(item.nextDueDate);
    _store[id] = item.copyWith(
      nextDueDate: next,
      lastExecutedDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _emit();
    return const Success(null);
  }

  void dispose() {
    _controller.close();
  }
}
