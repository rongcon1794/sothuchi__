// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AccountDto _$AccountDtoFromJson(Map<String, dynamic> json) => _AccountDto(
  id: json['id'] as String,
  name: json['name'] as String,
  type: json['type'] as String,
  balance: (json['balance'] as num).toInt(),
  currency: json['currency'] as String? ?? AppCurrencies.defaultCode,
  icon: json['icon'] as String? ?? 'wallet',
  color: (json['color'] as num?)?.toInt() ?? 0xFF0D7C66,
  archived: json['archived'] as bool? ?? false,
  ledgerId: json['ledgerId'] as String? ?? LedgerBook.defaultPersonalId,
  createdAt: const FirestoreDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const FirestoreDateTimeConverter().fromJson(json['updatedAt']),
  deletedAt: const NullableFirestoreDateTimeConverter().fromJson(
    json['deletedAt'],
  ),
);

Map<String, dynamic> _$AccountDtoToJson(
  _AccountDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': instance.type,
  'balance': instance.balance,
  'currency': instance.currency,
  'icon': instance.icon,
  'color': instance.color,
  'archived': instance.archived,
  'ledgerId': instance.ledgerId,
  'createdAt': const FirestoreDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const FirestoreDateTimeConverter().toJson(instance.updatedAt),
  'deletedAt': const NullableFirestoreDateTimeConverter().toJson(
    instance.deletedAt,
  ),
};
