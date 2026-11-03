// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfileDto _$UserProfileDtoFromJson(Map<String, dynamic> json) =>
    _UserProfileDto(
      uid: json['uid'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      defaultCurrency:
          json['defaultCurrency'] as String? ?? AppCurrencies.defaultCode,
      locale: json['locale'] as String? ?? 'vi',
      createdAt: const FirestoreDateTimeConverter().fromJson(json['createdAt']),
      updatedAt: const FirestoreDateTimeConverter().fromJson(json['updatedAt']),
      deletedAt: const NullableFirestoreDateTimeConverter().fromJson(
        json['deletedAt'],
      ),
    );

Map<String, dynamic> _$UserProfileDtoToJson(
  _UserProfileDto instance,
) => <String, dynamic>{
  'uid': instance.uid,
  'email': instance.email,
  'displayName': instance.displayName,
  'photoUrl': instance.photoUrl,
  'defaultCurrency': instance.defaultCurrency,
  'locale': instance.locale,
  'createdAt': const FirestoreDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const FirestoreDateTimeConverter().toJson(instance.updatedAt),
  'deletedAt': const NullableFirestoreDateTimeConverter().toJson(
    instance.deletedAt,
  ),
};
