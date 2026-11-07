import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:so_thu_chi/core/errors/app_exception.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/features/budgets/data/models/budget_dto.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';
import 'package:so_thu_chi/features/budgets/domain/repositories/budget_repository.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';
import 'package:uuid/uuid.dart';

class FirestoreBudgetRepository implements BudgetRepository {
  FirestoreBudgetRepository({
    required this.firestore,
    required this.uid,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final FirebaseFirestore firestore;
  final String uid;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('users').doc(uid).collection('budgets');

  List<Budget> _parseActive(QuerySnapshot<Map<String, dynamic>> snap) {
    final result = <Budget>[];
    for (final doc in snap.docs) {
      final entity = BudgetDto.fromJson({
        ...doc.data(),
        'id': doc.id,
      }).toDomain();
      if (entity.deletedAt != null) continue;
      result.add(entity);
    }
    result.sort((a, b) {
      if (a.isOverall != b.isOverall) return a.isOverall ? -1 : 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    return result;
  }

  @override
  Stream<List<Budget>> watchBudgets() {
    return _col.snapshots().map(_parseActive);
  }

  @override
  Future<List<Budget>> getBudgets() async {
    final snap = await _col.get();
    return _parseActive(snap);
  }

  @override
  Future<Result<Budget>> upsertMonthlyBudget({
    String? existingId,
    String? categoryId,
    required int amount,
    required String currency,
    required DateTime monthStart,
    required int alertThreshold,
    String? ledgerId,
  }) async {
    if (amount <= 0) {
      return const Failure(ValidationException('Budget limit must be > 0'));
    }
    final clampedThreshold = alertThreshold.clamp(1, 100);
    final normalizedMonth = AppDateUtils.startOfMonth(monthStart);
    final normalizedCategory =
        categoryId != null && categoryId.trim().isNotEmpty ? categoryId : null;
    final resolvedLedgerId = (ledgerId ?? '').trim().isEmpty
        ? LedgerBook.defaultPersonalId
        : ledgerId!.trim();

    try {
      final now = DateTime.now();
      final active = await getBudgets();
      final duplicate = active.cast<Budget?>().firstWhere(
        (b) =>
            b != null &&
            b.ledgerId == resolvedLedgerId &&
            AppDateUtils.isSameMonth(b.startDate, normalizedMonth) &&
            b.categoryId == normalizedCategory,
        orElse: () => null,
      );

      if (existingId != null &&
          duplicate != null &&
          duplicate.id != existingId) {
        return const Failure(
          ValidationException(
            'A budget for this category and month already exists',
          ),
        );
      }

      DateTime createdAt = duplicate?.createdAt ?? now;
      if (existingId != null) {
        final existingSnap = await _col.doc(existingId).get();
        if (existingSnap.exists && existingSnap.data() != null) {
          final existingDto = BudgetDto.fromJson({
            ...existingSnap.data()!,
            'id': existingSnap.id,
          });
          createdAt = existingDto.createdAt;
        }
      }

      final targetId = existingId ?? duplicate?.id ?? _uuid.v4();
      final entity = Budget(
        id: targetId,
        ledgerId: resolvedLedgerId,
        categoryId: normalizedCategory,
        amount: amount,
        currency: currency,
        startDate: normalizedMonth,
        alertThreshold: clampedThreshold,
        createdAt: createdAt,
        updatedAt: now,
      );

      final isExisting = existingId != null || duplicate != null;
      if (isExisting) {
        final updatePayload = <String, dynamic>{
          'amount': amount,
          'currency': currency,
          'alertThreshold': clampedThreshold,
          'updatedAt': Timestamp.fromDate(now),
        };
        if (normalizedCategory != null) {
          updatePayload['categoryId'] = normalizedCategory;
        }
        await _col.doc(targetId).update(updatePayload);
      } else {
        await _col.doc(targetId).set(BudgetDto.fromDomain(entity).toJson());
      }
      return Success(entity);
    } on FirebaseException catch (e) {
      return Failure(StorageException('${e.code}: ${e.message}'));
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    }
  }

  @override
  Future<Result<void>> softDeleteBudget(String budgetId) async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      await _col.doc(budgetId).update({'deletedAt': now, 'updatedAt': now});
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(StorageException('${e.code}: ${e.message}'));
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    }
  }
}

class InMemoryBudgetRepository implements BudgetRepository {
  InMemoryBudgetRepository({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  final Map<String, Budget> _items = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  List<Budget> _snapshot() {
    final list = _items.values.where((b) => b.deletedAt == null).toList()
      ..sort((a, b) {
        if (a.isOverall != b.isOverall) return a.isOverall ? -1 : 1;
        return a.createdAt.compareTo(b.createdAt);
      });
    return list;
  }

  @override
  Stream<List<Budget>> watchBudgets() async* {
    yield _snapshot();
    await for (final _ in _changes.stream) {
      yield _snapshot();
    }
  }

  @override
  Future<List<Budget>> getBudgets() async => _snapshot();

  @override
  Future<Result<Budget>> upsertMonthlyBudget({
    String? existingId,
    String? categoryId,
    required int amount,
    required String currency,
    required DateTime monthStart,
    required int alertThreshold,
    String? ledgerId,
  }) async {
    if (amount <= 0) {
      return const Failure(ValidationException('Budget limit must be > 0'));
    }
    final clampedThreshold = alertThreshold.clamp(1, 100);
    final normalizedMonth = AppDateUtils.startOfMonth(monthStart);
    final normalizedCategory =
        categoryId != null && categoryId.trim().isNotEmpty ? categoryId : null;
    final resolvedLedgerId = (ledgerId ?? '').trim().isEmpty
        ? LedgerBook.defaultPersonalId
        : ledgerId!.trim();

    final now = DateTime.now();
    final duplicate = _snapshot().cast<Budget?>().firstWhere(
      (b) =>
          b != null &&
          b.ledgerId == resolvedLedgerId &&
          AppDateUtils.isSameMonth(b.startDate, normalizedMonth) &&
          b.categoryId == normalizedCategory,
      orElse: () => null,
    );

    if (existingId != null && duplicate != null && duplicate.id != existingId) {
      return const Failure(
        ValidationException(
          'A budget for this category and month already exists',
        ),
      );
    }

    final targetId = existingId ?? duplicate?.id ?? _uuid.v4();
    final preservedCreatedAt = existingId != null
        ? (_items[existingId]?.createdAt ?? now)
        : (duplicate?.createdAt ?? now);
    final entity = Budget(
      id: targetId,
      ledgerId: resolvedLedgerId,
      categoryId: normalizedCategory,
      amount: amount,
      currency: currency,
      startDate: normalizedMonth,
      alertThreshold: clampedThreshold,
      createdAt: preservedCreatedAt,
      updatedAt: now,
    );
    _items[targetId] = entity;
    _notify();
    return Success(entity);
  }

  @override
  Future<Result<void>> softDeleteBudget(String budgetId) async {
    final existing = _items[budgetId];
    if (existing == null) return const Success(null);
    final now = DateTime.now();
    _items[budgetId] = existing.copyWith(deletedAt: now, updatedAt: now);
    _notify();
    return const Success(null);
  }

  void clear() {
    _items.clear();
    _notify();
  }
}
