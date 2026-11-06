// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BudgetDto _$BudgetDtoFromJson(Map<String, dynamic> json) => _BudgetDto(
  id: json['id'] as String,
  categoryId: json['categoryId'] as String?,
  amount: (json['amount'] as num).toInt(),
  currency: json['currency'] as String? ?? AppCurrencies.defaultCode,
  period: json['period'] as String? ?? 'month',
  startDate: const FirestoreDateTimeConverter().fromJson(json['startDate']),
  alertThreshold: (json['alertThreshold'] as num?)?.toInt() ?? 80,
  ledgerId: json['ledgerId'] as String? ?? LedgerBook.defaultPersonalId,
  createdAt: const FirestoreDateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const FirestoreDateTimeConverter().fromJson(json['updatedAt']),
  deletedAt: const NullableFirestoreDateTimeConverter().fromJson(
    json['deletedAt'],
  ),
);

Map<String, dynamic> _$BudgetDtoToJson(
  _BudgetDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'categoryId': instance.categoryId,
  'amount': instance.amount,
  'currency': instance.currency,
  'period': instance.period,
  'startDate': const FirestoreDateTimeConverter().toJson(instance.startDate),
  'alertThreshold': instance.alertThreshold,
  'ledgerId': instance.ledgerId,
  'createdAt': const FirestoreDateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const FirestoreDateTimeConverter().toJson(instance.updatedAt),
  'deletedAt': const NullableFirestoreDateTimeConverter().toJson(
    instance.deletedAt,
  ),
};
