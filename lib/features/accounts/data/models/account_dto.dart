import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/data/firebase/firestore_timestamp_converter.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';

part 'account_dto.freezed.dart';
part 'account_dto.g.dart';

@freezed
abstract class AccountDto with _$AccountDto {
  const AccountDto._();

  const factory AccountDto({
    required String id,
    required String name,
    required String type,
    required int balance,
    @Default(AppCurrencies.defaultCode) String currency,
    @Default('wallet') String icon,
    @Default(0xFF0D7C66) int color,
    @Default(false) bool archived,
    @Default(LedgerBook.defaultPersonalId) String ledgerId,
    @FirestoreDateTimeConverter() required DateTime createdAt,
    @FirestoreDateTimeConverter() required DateTime updatedAt,
    @NullableFirestoreDateTimeConverter() DateTime? deletedAt,
  }) = _AccountDto;

  factory AccountDto.fromJson(Map<String, dynamic> json) =>
      _$AccountDtoFromJson(json);

  factory AccountDto.fromDomain(Account entity) => AccountDto(
    id: entity.id,
    name: entity.name,
    type: entity.type.name,
    balance: entity.balance,
    currency: entity.currency,
    icon: entity.icon,
    color: entity.color,
    archived: entity.archived,
    ledgerId: entity.ledgerId,
    createdAt: entity.createdAt,
    updatedAt: entity.updatedAt,
    deletedAt: entity.deletedAt,
  );

  Account toDomain() {
    final parsedType = AccountType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => AccountType.cash,
    );
    return Account(
      id: id,
      name: name,
      type: parsedType,
      balance: balance,
      currency: currency,
      icon: icon,
      color: color,
      archived: archived,
      ledgerId: ledgerId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

