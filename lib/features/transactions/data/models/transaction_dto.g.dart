// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TransactionDto _$TransactionDtoFromJson(Map<String, dynamic> json) =>
    _TransactionDto(
      id: json['id'] as String,
      amount: (json['amount'] as num).toInt(),
      currency: json['currency'] as String? ?? AppCurrencies.defaultCode,
      type: json['type'] as String,
      accountId: json['accountId'] as String,
      toAccountId: json['toAccountId'] as String?,
      categoryId: json['categoryId'] as String,
      note: json['note'] as String? ?? '',
      date: const FirestoreDateTimeConverter().fromJson(json['date']),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const <String>[],
      ledgerId: json['ledgerId'] as String? ?? LedgerBook.defaultPersonalId,
      createdAt: const FirestoreDateTimeConverter().fromJson(json['createdAt']),
      updatedAt: const FirestoreDateTimeConverter().fromJson(json['updatedAt']),
      deletedAt: const NullableFirestoreDateTimeConverter().fromJson(
        json['deletedAt'],
      ),
    );

Map<String, dynamic> _$TransactionDtoToJson(
  _TransactionDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'amount': instance.amount,
  'currency': instance.currency,
  'type': instance.type,
  'accountId': instance.accountId,
  'toAccountId': instance.toAccountId,
  'categoryId': instance.categoryId,
  'note': instance.note,
  'date': const FirestoreDateTimeConverter().toJson(instance.date),
  'tags': instance.tags,
  'ledgerId': instance.ledgerId,
  'createdAt': const FirestoreDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const FirestoreDateTimeConverter().toJson(instance.updatedAt),
  'deletedAt': const NullableFirestoreDateTimeConverter().toJson(
    instance.deletedAt,
  ),
};
