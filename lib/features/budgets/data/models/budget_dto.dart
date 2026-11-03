import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/data/firebase/firestore_timestamp_converter.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';

part 'budget_dto.freezed.dart';
part 'budget_dto.g.dart';

@freezed
abstract class BudgetDto with _$BudgetDto {
  const BudgetDto._();

  const factory BudgetDto({
    required String id,
    String? categoryId,
    required int amount,
    @Default(AppCurrencies.defaultCode) String currency,
    @Default('month') String period,
    @FirestoreDateTimeConverter() required DateTime startDate,
    @Default(80) int alertThreshold,
    @FirestoreDateTimeConverter() required DateTime createdAt,
    @FirestoreDateTimeConverter() required DateTime updatedAt,
    @NullableFirestoreDateTimeConverter() DateTime? deletedAt,
  }) = _BudgetDto;

  factory BudgetDto.fromJson(Map<String, dynamic> json) =>
      _$BudgetDtoFromJson(json);

  factory BudgetDto.fromDomain(Budget entity) => BudgetDto(
    id: entity.id,
    categoryId: entity.categoryId,
    amount: entity.amount,
    currency: entity.currency,
    period: entity.period,
    startDate: entity.startDate,
    alertThreshold: entity.alertThreshold,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
    deletedAt: entity.deletedAt,
  );

  Budget toDomain() => Budget(
    id: id,
    categoryId: categoryId,
    amount: amount,
    currency: currency,
    period: period,
    startDate: startDate,
    alertThreshold: alertThreshold,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: deletedAt,
  );
}

