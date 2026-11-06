import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';

part 'transaction_entity.freezed.dart';

enum TransactionType { income, expense, transfer }

@freezed
abstract class TransactionEntity with _$TransactionEntity {
  const TransactionEntity._();

  const factory TransactionEntity({
    required String id,
    required int amount,
    @Default(AppCurrencies.defaultCode) String currency,
    required TransactionType type,
    required String accountId,
    String? toAccountId,
    required String categoryId,
    @Default('') String note,
    required DateTime date,
    @Default(<String>[]) List<String> tags,
    @Default(LedgerBook.defaultPersonalId) String ledgerId,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _TransactionEntity;

  Money get money => Money(minorUnits: amount, currencyCode: currency);
}

/// Immutable filter criteria for searching and filtering transactions.
@freezed
abstract class TransactionFilter with _$TransactionFilter {
  const TransactionFilter._();

  const factory TransactionFilter({
    @Default('') String searchQuery,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) = _TransactionFilter;

  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      type != null ||
      categoryId != null ||
      accountId != null ||
      startDate != null ||
      endDate != null;
}

/// Group of transactions occurring on a single calendar day.
class DailyTransactionGroup {
  const DailyTransactionGroup({
    required this.dayStart,
    required this.transactions,
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
  });

  final DateTime dayStart;
  final List<TransactionEntity> transactions;
  final int totalIncomeMinor;
  final int totalExpenseMinor;

  int get netMinor => totalIncomeMinor - totalExpenseMinor;
}

