import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/data/providers/repository_providers.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';

/// Streams all active (non-deleted) categories.
final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchCategories();
});

final expenseCategoriesProvider = Provider<List<Category>>((ref) {
  final all = ref.watch(categoriesStreamProvider).value ?? const <Category>[];
  return all
      .where((c) => c.type == CategoryType.expense)
      .toList(growable: false);
});

final incomeCategoriesProvider = Provider<List<Category>>((ref) {
  final all = ref.watch(categoriesStreamProvider).value ?? const <Category>[];
  return all
      .where((c) => c.type == CategoryType.income)
      .toList(growable: false);
});

final categoriesMapProvider = Provider<Map<String, Category>>((ref) {
  final all = ref.watch(categoriesStreamProvider).value ?? const <Category>[];
  return {for (final c in all) c.id: c};
});

class CategoriesActionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<Result<Category>> createCategory({
    required String name,
    required CategoryType type,
    required String icon,
    required int color,
  }) async {
    state = const AsyncLoading();
    final res = await ref
        .read(categoryRepositoryProvider)
        .createCategory(name: name, type: type, icon: icon, color: color);
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }

  Future<Result<Category>> updateCategory(Category category) async {
    state = const AsyncLoading();
    final res = await ref
        .read(categoryRepositoryProvider)
        .updateCategory(category);
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }

  Future<Result<void>> deleteCategory(String categoryId) async {
    state = const AsyncLoading();
    final res = await ref
        .read(categoryRepositoryProvider)
        .softDeleteCategory(categoryId);
    state = res.fold(
      onSuccess: (_) => const AsyncData(null),
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    return res;
  }
}

final categoriesActionControllerProvider =
    NotifierProvider<CategoriesActionController, AsyncValue<void>>(
      CategoriesActionController.new,
    );

