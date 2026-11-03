import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';

abstract interface class CategoryRepository {
  Stream<List<Category>> watchCategories({CategoryType? type});
  Future<List<Category>> getCategories({CategoryType? type});
  Future<Result<Category>> createCategory({
    required String name,
    required CategoryType type,
    required String icon,
    required int color,
    String? parentId,
  });
  Future<Result<Category>> updateCategory(Category category);
  Future<Result<void>> softDeleteCategory(String categoryId);
  Future<Result<void>> seedDefaultCategoriesIfNeeded();
}

