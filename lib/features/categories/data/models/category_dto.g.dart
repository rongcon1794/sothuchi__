// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CategoryDto _$CategoryDtoFromJson(Map<String, dynamic> json) => _CategoryDto(
  id: json['id'] as String,
  name: json['name'] as String,
  type: json['type'] as String,
  icon: json['icon'] as String? ?? 'other',
  color: (json['color'] as num?)?.toInt() ?? 0xFF0D7C66,
  parentId: json['parentId'] as String?,
  isDefault: json['isDefault'] as bool? ?? false,
  createdAt: const FirestoreDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const FirestoreDateTimeConverter().fromJson(json['updatedAt']),
  deletedAt: const NullableFirestoreDateTimeConverter().fromJson(
    json['deletedAt'],
  ),
);

Map<String, dynamic> _$CategoryDtoToJson(
  _CategoryDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': instance.type,
  'icon': instance.icon,
  'color': instance.color,
  'parentId': instance.parentId,
  'isDefault': instance.isDefault,
  'createdAt': const FirestoreDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const FirestoreDateTimeConverter().toJson(instance.updatedAt),
  'deletedAt': const NullableFirestoreDateTimeConverter().toJson(
    instance.deletedAt,
  ),
};
