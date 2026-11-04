import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:so_thu_chi/core/errors/app_exception.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/savings/data/models/savings_goal_dto.dart';
import 'package:so_thu_chi/features/savings/domain/entities/savings_goal.dart';
import 'package:so_thu_chi/features/savings/domain/repositories/savings_goal_repository.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/domain/repositories/transaction_repository.dart';

class FirestoreSavingsGoalRepository implements SavingsGoalRepository {
  FirestoreSavingsGoalRepository({
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
    return firestore.collection('users').doc(uid).collection('savings_goals');
  }

  @override
  Stream<List<SavingsGoal>> watchSavingsGoals() {
    try {
      return _collection()
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => SavingsGoalDto.fromJson(doc.data(), doc.id).toDomain())
            .toList();
        list.sort((a, b) {
          if (a.isCompleted != b.isCompleted) {
            return a.isCompleted ? 1 : -1;
          }
          return b.progress.compareTo(a.progress);
        });
        return list;
      });
    } catch (_) {
      return Stream.value(const <SavingsGoal>[]);
    }
  }

  @override
  Future<Result<SavingsGoal>> createGoal(SavingsGoal goal) async {
    try {
      final docRef = _collection().doc();
      final entity = goal.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await docRef.set(SavingsGoalDto.fromDomain(entity).toJson());
      return Success(entity);
    } catch (e) {
      return Failure(StorageException('Failed to create savings goal: $e'));
    }
  }

  @override
  Future<Result<SavingsGoal>> updateGoal(SavingsGoal goal) async {
    try {
      final updated = goal.copyWith(updatedAt: DateTime.now());
      await _collection()
          .doc(goal.id)
          .update(SavingsGoalDto.fromDomain(updated).toJson());
      return Success(updated);
    } catch (e) {
      return Failure(StorageException('Failed to update savings goal: $e'));
    }
  }

  @override
  Future<Result<void>> deleteGoal(String id) async {
    try {
      await _collection().doc(id).delete();
      return const Success(null);
    } catch (e) {
      return Failure(StorageException('Failed to delete savings goal: $e'));
    }
  }

  @override
  Future<Result<void>> depositToGoal({
    required String goalId,
    required int amount,
    required String fromAccountId,
    String note = '',
  }) async {
    try {
      final docSnap = await _collection().doc(goalId).get();
      if (!docSnap.exists || docSnap.data() == null) {
        return const Failure(NotFoundException('Savings goal not found'));
      }
      final goal =
          SavingsGoalDto.fromJson(docSnap.data()!, docSnap.id).toDomain();

      // 1. Record expense / savings deposit transaction
      final txRes = await transactionRepository.addTransaction(
        amount: amount,
        currency: goal.currency,
        type: TransactionType.expense,
        accountId: fromAccountId,
        categoryId: 'default_other',
        note: note.isNotEmpty
            ? '[Tích lũy] ${goal.title}: $note'
            : '[Tích lũy] Nạp vào: ${goal.title}',
        date: DateTime.now(),
        tags: const ['tiết kiệm', 'mục tiêu'],
      );

      if (txRes.isFailure) {
        return Failure(txRes.errorOrNull!);
      }

      // 2. Update goal balance and completion status
      final newCurrent = goal.currentAmount + amount;
      final isNowCompleted = newCurrent >= goal.targetAmount;
      final updated = goal.copyWith(
        currentAmount: newCurrent,
        isCompleted: isNowCompleted,
        updatedAt: DateTime.now(),
      );

      await _collection()
          .doc(goalId)
          .update(SavingsGoalDto.fromDomain(updated).toJson());

      return const Success(null);
    } catch (e) {
      return Failure(StorageException('Failed to deposit to savings goal: $e'));
    }
  }

  @override
  Future<Result<void>> withdrawFromGoal({
    required String goalId,
    required int amount,
    required String toAccountId,
    String note = '',
  }) async {
    try {
      final docSnap = await _collection().doc(goalId).get();
      if (!docSnap.exists || docSnap.data() == null) {
        return const Failure(NotFoundException('Savings goal not found'));
      }
      final goal =
          SavingsGoalDto.fromJson(docSnap.data()!, docSnap.id).toDomain();

      if (goal.currentAmount < amount) {
        return const Failure(
          ValidationException('Số tiền rút vượt quá số dư hiện có trong mục tiêu'),
        );
      }

      // 1. Record income / savings refund transaction
      final txRes = await transactionRepository.addTransaction(
        amount: amount,
        currency: goal.currency,
        type: TransactionType.income,
        accountId: toAccountId,
        categoryId: 'default_salary',
        note: note.isNotEmpty
            ? '[Rút tích lũy] ${goal.title}: $note'
            : '[Rút tích lũy] Từ: ${goal.title}',
        date: DateTime.now(),
        tags: const ['tiết kiệm', 'rút tiền'],
      );

      if (txRes.isFailure) {
        return Failure(txRes.errorOrNull!);
      }

      // 2. Update goal balance and completion status
      final newCurrent = goal.currentAmount - amount;
      final isNowCompleted = newCurrent >= goal.targetAmount;
      final updated = goal.copyWith(
        currentAmount: newCurrent,
        isCompleted: isNowCompleted,
        updatedAt: DateTime.now(),
      );

      await _collection()
          .doc(goalId)
          .update(SavingsGoalDto.fromDomain(updated).toJson());

      return const Success(null);
    } catch (e) {
      return Failure(StorageException('Failed to withdraw from savings goal: $e'));
    }
  }
}

/// In-memory repository for unit and widget tests.
class InMemorySavingsGoalRepository implements SavingsGoalRepository {
  InMemorySavingsGoalRepository({
    this.transactionRepository,
  });

  final TransactionRepository? transactionRepository;
  final Map<String, SavingsGoal> _store = {};
  final StreamController<List<SavingsGoal>> _controller =
      StreamController<List<SavingsGoal>>.broadcast();

  void _emit() {
    final list = _store.values.toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.progress.compareTo(a.progress);
      });
    _controller.add(list);
  }

  @override
  Stream<List<SavingsGoal>> watchSavingsGoals() async* {
    yield _store.values.toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.progress.compareTo(a.progress);
      });
    yield* _controller.stream;
  }

  @override
  Future<Result<SavingsGoal>> createGoal(SavingsGoal goal) async {
    final id = goal.id.isEmpty
        ? 'goal_${DateTime.now().millisecondsSinceEpoch}'
        : goal.id;
    final entity = goal.copyWith(
      id: id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _store[id] = entity;
    _emit();
    return Success(entity);
  }

  @override
  Future<Result<SavingsGoal>> updateGoal(SavingsGoal goal) async {
    if (!_store.containsKey(goal.id)) {
      return const Failure(NotFoundException('Savings goal not found'));
    }
    final updated = goal.copyWith(updatedAt: DateTime.now());
    _store[goal.id] = updated;
    _emit();
    return Success(updated);
  }

  @override
  Future<Result<void>> deleteGoal(String id) async {
    _store.remove(id);
    _emit();
    return const Success(null);
  }

  @override
  Future<Result<void>> depositToGoal({
    required String goalId,
    required int amount,
    required String fromAccountId,
    String note = '',
  }) async {
    final goal = _store[goalId];
    if (goal == null) {
      return const Failure(NotFoundException('Savings goal not found'));
    }

    if (transactionRepository != null) {
      final txRes = await transactionRepository!.addTransaction(
        amount: amount,
        currency: goal.currency,
        type: TransactionType.expense,
        accountId: fromAccountId,
        categoryId: 'default_other',
        note: note.isNotEmpty
            ? '[Tích lũy] ${goal.title}: $note'
            : '[Tích lũy] Nạp vào: ${goal.title}',
        date: DateTime.now(),
        tags: const ['tiết kiệm', 'mục tiêu'],
      );
      if (txRes.isFailure) return Failure(txRes.errorOrNull!);
    }

    final newCurrent = goal.currentAmount + amount;
    _store[goalId] = goal.copyWith(
      currentAmount: newCurrent,
      isCompleted: newCurrent >= goal.targetAmount,
      updatedAt: DateTime.now(),
    );
    _emit();
    return const Success(null);
  }

  @override
  Future<Result<void>> withdrawFromGoal({
    required String goalId,
    required int amount,
    required String toAccountId,
    String note = '',
  }) async {
    final goal = _store[goalId];
    if (goal == null) {
      return const Failure(NotFoundException('Savings goal not found'));
    }
    if (goal.currentAmount < amount) {
      return const Failure(
        ValidationException('Số tiền rút vượt quá số dư hiện có trong mục tiêu'),
      );
    }

    if (transactionRepository != null) {
      final txRes = await transactionRepository!.addTransaction(
        amount: amount,
        currency: goal.currency,
        type: TransactionType.income,
        accountId: toAccountId,
        categoryId: 'default_salary',
        note: note.isNotEmpty
            ? '[Rút tích lũy] ${goal.title}: $note'
            : '[Rút tích lũy] Từ: ${goal.title}',
        date: DateTime.now(),
        tags: const ['tiết kiệm', 'rút tiền'],
      );
      if (txRes.isFailure) return Failure(txRes.errorOrNull!);
    }

    final newCurrent = goal.currentAmount - amount;
    _store[goalId] = goal.copyWith(
      currentAmount: newCurrent,
      isCompleted: newCurrent >= goal.targetAmount,
      updatedAt: DateTime.now(),
    );
    _emit();
    return const Success(null);
  }

  void clear() {
    _store.clear();
    _emit();
  }

  void dispose() {
    _controller.close();
  }
}

