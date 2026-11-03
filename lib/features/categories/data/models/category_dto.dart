import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:so_thu_chi/data/firebase/firestore_timestamp_converter.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';

part 'category_dto.freezed.dart';
part 'category_dto.g.dart';

@freezed
abstract class CategoryDto with _$CategoryDto {
  const CategoryDto._();

  const factory CategoryDto({
    required String id,
    required String name,
    required String type,
    @Default('other') String icon,
    @Default(0xFF0D7C66) int color,
    String? parentId,
    @Default(false) bool isDefault,
    @FirestoreDateTimeConverter() required DateTime createdAt,
    @FirestoreDateTimeConverter() required DateTime updatedAt,
    @NullableFirestoreDateTimeConverter() DateTime? deletedAt,
  }) = _CategoryDto;

  factory CategoryDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryDtoFromJson(json);

  factory CategoryDto.fromDomain(Category entity) => CategoryDto(
    id: entity.id,
    name: entity.name,
    type: entity.type.name,
    icon: entity.icon,
    color: entity.color,
    parentId: entity.parentId,
    isDefault: entity.isDefault,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
    deletedAt: entity.deletedAt,
  );

  Category toDomain() {
    final parsedType = CategoryType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => CategoryType.expense,
    );
    return Category(
      id: id,
      name: name,
      type: parsedType,
      icon: icon,
      color: color,
      parentId: parentId,
      isDefault: isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

