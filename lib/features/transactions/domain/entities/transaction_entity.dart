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
    @Default(<String>{}) Set<String> categoryIds,
    @Default(<String>{}) Set<String> accountIds,
    DateTime? startDate,
    DateTime? endDate,
  }) = _TransactionFilter;

  Set<String> get effectiveCategoryIds {
    if (categoryIds.isNotEmpty) return categoryIds;
    if (categoryId != null) return {categoryId!};
    return const <String>{};
  }

  Set<String> get effectiveAccountIds {
    if (accountIds.isNotEmpty) return accountIds;
    if (accountId != null) return {accountId!};
    return const <String>{};
  }

  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      type != null ||
      effectiveCategoryIds.isNotEmpty ||
      effectiveAccountIds.isNotEmpty ||
      startDate != null ||
      endDate != null;

  int get activeFiltersCount {
    var count = 0;
    if (searchQuery.trim().isNotEmpty) count++;
    if (type != null) count++;
    if (effectiveCategoryIds.isNotEmpty) count += effectiveCategoryIds.length;
    if (effectiveAccountIds.isNotEmpty) count += effectiveAccountIds.length;
    if (startDate != null || endDate != null) count++;
    return count;
  }
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

