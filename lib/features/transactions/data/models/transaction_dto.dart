import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/data/firebase/firestore_timestamp_converter.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';

part 'transaction_dto.freezed.dart';
part 'transaction_dto.g.dart';

@freezed
abstract class TransactionDto with _$TransactionDto {
  const TransactionDto._();

  const factory TransactionDto({
    required String id,
    required int amount,
    @Default(AppCurrencies.defaultCode) String currency,
    required String type,
    required String accountId,
    String? toAccountId,
    required String categoryId,
    @Default('') String note,
    @FirestoreDateTimeConverter() required DateTime date,
    @Default(<String>[]) List<String> tags,
    @Default(LedgerBook.defaultPersonalId) String ledgerId,
    @FirestoreDateTimeConverter() required DateTime createdAt,
    @FirestoreDateTimeConverter() required DateTime updatedAt,
    @NullableFirestoreDateTimeConverter() DateTime? deletedAt,
  }) = _TransactionDto;

  factory TransactionDto.fromJson(Map<String, dynamic> json) =>
      _$TransactionDtoFromJson(json);

  factory TransactionDto.fromDomain(TransactionEntity entity) => TransactionDto(
    id: entity.id,
    amount: entity.amount,
    currency: entity.currency,
    type: entity.type.name,
    accountId: entity.accountId,
    toAccountId: entity.toAccountId,
    categoryId: entity.categoryId,
    note: entity.note,
    date: entity.date,
    tags: entity.tags,
    ledgerId: entity.ledgerId,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
    deletedAt: entity.deletedAt,
  );

  TransactionEntity toDomain() {
    final parsedType = TransactionType.values.firstWhere(
      (t) => t.name == type,
      orElse: () => TransactionType.expense,
    );
    return TransactionEntity(
      id: id,
      amount: amount,
      currency: currency,
      type: parsedType,
      accountId: accountId,
      toAccountId: toAccountId,
      categoryId: categoryId,
      note: note,
      date: date,
      tags: tags,
      ledgerId: ledgerId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

