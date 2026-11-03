import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/errors/app_exception.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/debts/data/models/debt_dto.dart';
import 'package:so_thu_chi/features/debts/domain/entities/debt.dart';
import 'package:so_thu_chi/features/debts/domain/repositories/debt_repository.dart';
import 'package:uuid/uuid.dart';

class FirestoreDebtRepository implements DebtRepository {
  FirestoreDebtRepository({
    required this.firestore,
    required this.uid,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final FirebaseFirestore firestore;
  final String uid;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _debtsCol =>
      firestore.collection('users').doc(uid).collection('debts');

  CollectionReference<Map<String, dynamic>> get _accountsCol =>
      firestore.collection('users').doc(uid).collection('accounts');

  List<Debt> _parseActive(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = <Debt>[];
    for (final doc in snap.docs) {
      final dto = DebtDto.fromJson(doc.data(), doc.id);
      final entity = dto.toDomain();
      if (entity.deletedAt != null) continue;
      list.add(entity);
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Stream<List<Debt>> watchDebts() {
    return _debtsCol.snapshots().map(_parseActive);
  }

  @override
  Future<Debt?> getDebtById(String id) async {
    try {
      final doc = await _debtsCol.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      final dto = DebtDto.fromJson(doc.data()!, doc.id);
      final entity = dto.toDomain();
      if (entity.deletedAt != null) return null;
      return entity;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<Debt>> addDebt({
    required String personName,
    String? phoneNumber,
    required DebtType type,
    required int amount,
    String? currency,
    DateTime? dueDate,
    String? accountId,
    String note = '',
  }) async {
    if (amount <= 0) {
      return const Failure(
        ValidationException('Số tiền nợ phải lớn hơn 0'),
      );
    }
    if (personName.trim().isEmpty) {
      return const Failure(
        ValidationException('Tên người nợ / cho vay không được để trống'),
      );
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    final debt = Debt(
      id: id,
      personName: personName.trim(),
      phoneNumber: phoneNumber?.trim(),
      type: type,
      amount: amount,
      remainingAmount: amount,
      currency: currency ?? AppCurrencies.defaultCode,
      dueDate: dueDate,
      accountId: accountId,
      note: note.trim(),
      createdAt: now,
      updatedAt: now,
    );

    try {
      final batch = firestore.batch();
      final debtDocRef = _debtsCol.doc(id);
      batch.set(debtDocRef, DebtDto.fromDomain(debt).toJson());

      // If linked with a wallet, update wallet balance atomically
      if (accountId != null && accountId.isNotEmpty) {
        final accDocRef = _accountsCol.doc(accountId);
        final delta = type == DebtType.lent ? -amount : amount;
        batch.update(accDocRef, {
          'balance': FieldValue.increment(delta),
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      await batch.commit();
      return Success(debt);
    } catch (e) {
      return Failure(
        StorageException('Không thể lưu sổ nợ: $e'),
      );
    }
  }

  @override
  Future<Result<Debt>> updateDebt(Debt debt) async {
    try {
      final updated = debt.copyWith(updatedAt: DateTime.now());
      await _debtsCol.doc(debt.id).set(
            DebtDto.fromDomain(updated).toJson(),
            SetOptions(merge: true),
          );
      return Success(updated);
    } catch (e) {
      return Failure(
        StorageException('Không thể cập nhật sổ nợ: $e'),
      );
    }
  }

  @override
  Future<Result<void>> recordRepayment({
    required String debtId,
    required int amount,
    String? accountId,
    String note = '',
  }) async {
    if (amount <= 0) {
      return const Failure(
        ValidationException('Số tiền trả phải lớn hơn 0'),
      );
    }

    try {
      final debt = await getDebtById(debtId);
      if (debt == null) {
        return const Failure(
          NotFoundException('Khoản nợ không tồn tại hoặc đã bị xóa'),
        );
      }

      final newRemaining = (debt.remainingAmount - amount).clamp(0, debt.amount);
      final now = DateTime.now();

      final batch = firestore.batch();
      final debtDocRef = _debtsCol.doc(debtId);
      batch.update(debtDocRef, {
        'remainingAmount': newRemaining,
        'updatedAt': Timestamp.fromDate(now),
      });

      // Update linked wallet if specified
      if (accountId != null && accountId.isNotEmpty) {
        final accDocRef = _accountsCol.doc(accountId);
        // If we lent money, receiving repayment increases our wallet balance.
        // If we borrowed money, paying debt decreases our wallet balance.
        final delta = debt.type == DebtType.lent ? amount : -amount;
        batch.update(accDocRef, {
          'balance': FieldValue.increment(delta),
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      await batch.commit();
      return const Success(null);
    } catch (e) {
      return Failure(
        StorageException('Không thể ghi nhận trả nợ: $e'),
      );
    }
  }

  @override
  Future<Result<void>> softDeleteDebt(String id) async {
    try {
      await _debtsCol.doc(id).update({
        'deletedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return const Success(null);
    } catch (e) {
      return Failure(
        StorageException('Không thể xóa khoản nợ: $e'),
      );
    }
  }
}

/// In-memory implementation of [DebtRepository] for offline demo mode and unit testing.
class InMemoryDebtRepository implements DebtRepository {
  InMemoryDebtRepository({Uuid? uuid}) : _uuid = uuid ?? const Uuid() {
    _seedDefaultDemoDebts();
  }

  final Uuid _uuid;
  final Map<String, Debt> _store = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  List<Debt> _snapshot() {
    final list = _store.values.where((d) => d.deletedAt == null).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void _notify() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  void _seedDefaultDemoDebts() {
    final now = DateTime.now();
    final demo1 = Debt(
      id: 'demo_debt_1',
      personName: 'Nguyễn Văn Nam',
      phoneNumber: '0901234567',
      type: DebtType.lent,
      amount: 1500000,
      remainingAmount: 500000,
      currency: AppCurrencies.defaultCode,
      dueDate: now.add(const Duration(days: 5)),
      note: 'Vay tiền mua vé máy bay',
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: now.subtract(const Duration(days: 2)),
    );

    final demo2 = Debt(
      id: 'demo_debt_2',
      personName: 'Anh Ba Hàng Xóm',
      phoneNumber: '0987654321',
      type: DebtType.borrowed,
      amount: 2000000,
      remainingAmount: 2000000,
      currency: AppCurrencies.defaultCode,
      dueDate: now.subtract(const Duration(days: 2)), // Overdue demo
      note: 'Mượn tiền sửa xe máy',
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now.subtract(const Duration(days: 15)),
    );

    _store[demo1.id] = demo1;
    _store[demo2.id] = demo2;
    _notify();
  }

  void clear() {
    _store.clear();
    _notify();
  }

  @override
  Stream<List<Debt>> watchDebts() async* {
    yield _snapshot();
    await for (final _ in _changes.stream) {
      yield _snapshot();
    }
  }

  @override
  Future<Debt?> getDebtById(String id) async {
    final debt = _store[id];
    if (debt == null || debt.deletedAt != null) return null;
    return debt;
  }

  @override
  Future<Result<Debt>> addDebt({
    required String personName,
    String? phoneNumber,
    required DebtType type,
    required int amount,
    String? currency,
    DateTime? dueDate,
    String? accountId,
    String note = '',
  }) async {
    if (amount <= 0) {
      return const Failure(
        ValidationException('Số tiền nợ phải lớn hơn 0'),
      );
    }
    if (personName.trim().isEmpty) {
      return const Failure(
        ValidationException('Tên người nợ / cho vay không được để trống'),
      );
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    final debt = Debt(
      id: id,
      personName: personName.trim(),
      phoneNumber: phoneNumber?.trim(),
      type: type,
      amount: amount,
      remainingAmount: amount,
      currency: currency ?? AppCurrencies.defaultCode,
      dueDate: dueDate,
      accountId: accountId,
      note: note.trim(),
      createdAt: now,
      updatedAt: now,
    );

    _store[id] = debt;
    _notify();
    return Success(debt);
  }

  @override
  Future<Result<Debt>> updateDebt(Debt debt) async {
    if (!_store.containsKey(debt.id)) {
      return const Failure(NotFoundException('Khoản nợ không tồn tại'));
    }
    final updated = debt.copyWith(updatedAt: DateTime.now());
    _store[debt.id] = updated;
    _notify();
    return Success(updated);
  }

  @override
  Future<Result<void>> recordRepayment({
    required String debtId,
    required int amount,
    String? accountId,
    String note = '',
  }) async {
    final debt = _store[debtId];
    if (debt == null || debt.deletedAt != null) {
      return const Failure(NotFoundException('Khoản nợ không tồn tại'));
    }

    final newRemaining = (debt.remainingAmount - amount).clamp(0, debt.amount);
    final updated = debt.copyWith(
      remainingAmount: newRemaining,
      updatedAt: DateTime.now(),
    );
    _store[debtId] = updated;
    _notify();
    return const Success(null);
  }

  @override
  Future<Result<void>> softDeleteDebt(String id) async {
    final debt = _store[id];
    if (debt != null) {
      _store[id] = debt.copyWith(deletedAt: DateTime.now());
      _notify();
    }
    return const Success(null);
  }

  void dispose() {
    _changes.close();
  }
}
