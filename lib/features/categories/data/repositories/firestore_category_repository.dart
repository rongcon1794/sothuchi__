import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:so_thu_chi/core/errors/app_exception.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/categories/data/datasources/default_categories_catalog.dart';
import 'package:so_thu_chi/features/categories/data/models/category_dto.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/domain/repositories/category_repository.dart';
import 'package:uuid/uuid.dart';

class FirestoreCategoryRepository implements CategoryRepository {
  FirestoreCategoryRepository({
    required this.firestore,
    required this.uid,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final FirebaseFirestore firestore;
  final String uid;
  final Uuid _uuid;

  CollectionReference<Map<String, dynamic>> get _col =>
      firestore.collection('users').doc(uid).collection('categories');

  List<Category> _parseAndFilter(
    QuerySnapshot<Map<String, dynamic>> snap, {
    CategoryType? type,
  }) {
    final result = <Category>[];
    for (final doc in snap.docs) {
      final dto = CategoryDto.fromJson({...doc.data(), 'id': doc.id});
      final entity = dto.toDomain();
      if (entity.deletedAt != null) continue;
      if (type != null && entity.type != type) continue;
      result.add(entity);
    }
    result.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    return result;
  }

  @override
  Stream<List<Category>> watchCategories({CategoryType? type}) {
    return _col.snapshots().map((snap) => _parseAndFilter(snap, type: type));
  }

  @override
  Future<List<Category>> getCategories({CategoryType? type}) async {
    final snap = await _col.get();
    return _parseAndFilter(snap, type: type);
  }

  @override
  Future<Result<Category>> createCategory({
    required String name,
    required CategoryType type,
    required String icon,
    required int color,
    String? parentId,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 100) {
      return const Failure(
        ValidationException('Category name must be 1..100 characters'),
      );
    }

    try {
      final now = DateTime.now();
      final id = _uuid.v4();
      final entity = Category(
        id: id,
        name: trimmed,
        type: type,
        icon: icon,
        color: color,
        parentId: parentId,
        createdAt: now,
        updatedAt: now,
      );
      await _col.doc(id).set(CategoryDto.fromDomain(entity).toJson());
      return Success(entity);
    } on FirebaseException catch (e) {
      return Failure(StorageException('${e.code}: ${e.message}'));
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    }
  }

  @override
  Future<Result<Category>> updateCategory(Category category) async {
    final trimmed = category.name.trim();
    if (trimmed.isEmpty || trimmed.length > 100) {
      return const Failure(
        ValidationException('Category name must be 1..100 characters'),
      );
    }

    try {
      final updated = category.copyWith(
        name: trimmed,
        updatedAt: DateTime.now(),
      );
      await _col
          .doc(updated.id)
          .set(
            CategoryDto.fromDomain(updated).toJson(),
            SetOptions(merge: true),
          );
      return Success(updated);
    } on FirebaseException catch (e) {
      return Failure(StorageException('${e.code}: ${e.message}'));
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    }
  }

  @override
  Future<Result<void>> softDeleteCategory(String categoryId) async {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      await _col.doc(categoryId).update({
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
  Future<Result<void>> seedDefaultCategoriesIfNeeded() async {
    try {
      final existingSnap = await _col.limit(1).get();
      if (existingSnap.docs.isNotEmpty) {
        return const Success(null);
      }
      final defaults = DefaultCategoriesCatalog.buildDefaults(DateTime.now());
      final batch = firestore.batch();
      for (final category in defaults) {
        batch.set(
          _col.doc(category.id),
          CategoryDto.fromDomain(category).toJson(),
        );
      }
      await batch.commit();
      return const Success(null);
    } on FirebaseException catch (e) {
      return Failure(StorageException('${e.code}: ${e.message}'));
    } catch (e) {
      return Failure(UnexpectedException(e.toString()));
    }
  }
}

class InMemoryCategoryRepository implements CategoryRepository {
  InMemoryCategoryRepository({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  final Map<String, Category> _items = {};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  List<Category> _snapshot({CategoryType? type}) {
    final list = _items.values.where((c) {
      if (c.deletedAt != null) return false;
      if (type != null && c.type != type) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return a.createdAt.compareTo(b.createdAt);
      });
    return list;
  }

  @override
  Stream<List<Category>> watchCategories({CategoryType? type}) async* {
    yield _snapshot(type: type);
    await for (final _ in _changes.stream) {
      yield _snapshot(type: type);
    }
  }

  @override
  Future<List<Category>> getCategories({CategoryType? type}) async =>
      _snapshot(type: type);

  @override
  Future<Result<Category>> createCategory({
    required String name,
    required CategoryType type,
    required String icon,
    required int color,
    String? parentId,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 100) {
      return const Failure(
        ValidationException('Category name must be 1..100 characters'),
      );
    }
    final now = DateTime.now();
    final entity = Category(
      id: _uuid.v4(),
      name: trimmed,
      type: type,
      icon: icon,
      color: color,
      parentId: parentId,
      createdAt: now,
      updatedAt: now,
    );
    _items[entity.id] = entity;
    _notify();
    return Success(entity);
  }

  @override
  Future<Result<Category>> updateCategory(Category category) async {
    final trimmed = category.name.trim();
    if (trimmed.isEmpty || trimmed.length > 100) {
      return const Failure(
        ValidationException('Category name must be 1..100 characters'),
      );
    }
    final updated = category.copyWith(name: trimmed, updatedAt: DateTime.now());
    _items[updated.id] = updated;
    _notify();
    return Success(updated);
  }

  @override
  Future<Result<void>> softDeleteCategory(String categoryId) async {
    final existing = _items[categoryId];
    if (existing == null) return const Success(null);
    final now = DateTime.now();
    _items[categoryId] = existing.copyWith(deletedAt: now, updatedAt: now);
    _notify();
    return const Success(null);
  }

  @override
  Future<Result<void>> seedDefaultCategoriesIfNeeded() async {
    if (_items.isNotEmpty) return const Success(null);
    for (final cat in DefaultCategoriesCatalog.buildDefaults(DateTime.now())) {
      _items[cat.id] = cat;
    }
    _notify();
    return const Success(null);
  }

  void clear() {
    _items.clear();
    _notify();
  }
}

