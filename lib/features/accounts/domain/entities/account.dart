import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';

part 'account.freezed.dart';

enum AccountType {
  cash,
  bank,
  ewallet,
  card;

  String get defaultIconKey => switch (this) {
    AccountType.cash => 'cash',
    AccountType.bank => 'bank',
    AccountType.ewallet => 'ewallet',
    AccountType.card => 'card',
  };
}

@freezed
abstract class Account with _$Account {
  const Account._();

  const factory Account({
    required String id,
    required String name,
    required AccountType type,
    required int balance,
    @Default(AppCurrencies.defaultCode) String currency,
    @Default('wallet') String icon,
    @Default(0xFF0D7C66) int color,
    @Default(false) bool archived,
    @Default(LedgerBook.defaultPersonalId) String ledgerId,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _Account;

  Money get balanceMoney => Money(minorUnits: balance, currencyCode: currency);

  bool get isActive => !archived && deletedAt == null;
}

