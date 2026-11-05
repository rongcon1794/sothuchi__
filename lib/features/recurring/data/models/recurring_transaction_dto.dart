import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';

class RecurringTransactionDto {
  const RecurringTransactionDto({
    required this.id,
    required this.title,
    required this.amount,
    this.currency = AppCurrencies.defaultCode,
    required this.type,
    required this.interval,
    this.intervalCount = 1,
    required this.startDate,
    required this.nextDueDate,
    this.lastExecutedDate,
    required this.accountId,
    this.toAccountId,
    required this.categoryId,
    this.autoExecute = false,
    this.isPaused = false,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final int amount;
  final String currency;
  final String type;
  final String interval;
  final int intervalCount;
  final DateTime startDate;
  final DateTime nextDueDate;
  final DateTime? lastExecutedDate;
  final String accountId;
  final String? toAccountId;
  final String categoryId;
  final bool autoExecute;
  final bool isPaused;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RecurringTransactionDto.fromJson(Map<String, dynamic> json, [String? id]) {
    DateTime parseDate(Object? val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    DateTime? parseNullableDate(Object? val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    return RecurringTransactionDto(
      id: id ?? (json['id'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? AppCurrencies.defaultCode,
      type: json['type'] as String? ?? TransactionType.expense.name,
      interval: json['interval'] as String? ?? json['frequency'] as String? ?? RecurringInterval.monthly.name,
      intervalCount: (json['intervalCount'] as num?)?.toInt() ?? 1,
      startDate: parseDate(json['startDate']),
      nextDueDate: parseDate(json['nextDueDate']),
      lastExecutedDate: parseNullableDate(json['lastExecutedDate']),
      accountId: json['accountId'] as String? ?? '',
      toAccountId: json['toAccountId'] as String?,
      categoryId: json['categoryId'] as String? ?? '',
      autoExecute: json['autoExecute'] as bool? ?? false,
      isPaused: json['isPaused'] as bool? ?? !(json['isActive'] as bool? ?? true),
      note: json['note'] as String? ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'currency': currency,
        'type': type,
        'interval': interval,
        'frequency': interval,
        'intervalCount': intervalCount,
        'startDate': Timestamp.fromDate(startDate),
        'nextDueDate': Timestamp.fromDate(nextDueDate),
        'lastExecutedDate': lastExecutedDate != null
            ? Timestamp.fromDate(lastExecutedDate!)
            : null,
        'accountId': accountId,
        'toAccountId': toAccountId,
        'categoryId': categoryId,
        'autoExecute': autoExecute,
        'isPaused': isPaused,
        'isActive': !isPaused,
        'note': note,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory RecurringTransactionDto.fromDomain(RecurringTransaction entity) {
    final cleanToAccount = entity.toAccountId?.trim();
    return RecurringTransactionDto(
      id: entity.id,
      title: entity.title.trim(),
      amount: entity.amount,
      currency: entity.currency,
      type: entity.type.name,
      interval: entity.interval.name,
      intervalCount: entity.intervalCount,
      startDate: entity.startDate,
      nextDueDate: entity.nextDueDate,
      lastExecutedDate: entity.lastExecutedDate,
      accountId: entity.accountId,
      toAccountId: (cleanToAccount != null && cleanToAccount.isNotEmpty)
          ? cleanToAccount
          : null,
      categoryId: entity.categoryId,
      autoExecute: entity.autoExecute,
      isPaused: entity.isPaused,
      note: entity.note.trim(),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  RecurringTransaction toDomain() {
    final parsedType = TransactionType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => TransactionType.expense,
    );
    final parsedInterval = RecurringInterval.values.firstWhere(
      (e) => e.name == interval,
      orElse: () => RecurringInterval.monthly,
    );
    return RecurringTransaction(
      id: id,
      title: title,
      amount: amount,
      currency: currency,
      type: parsedType,
      interval: parsedInterval,
      intervalCount: intervalCount,
      startDate: startDate,
      nextDueDate: nextDueDate,
      lastExecutedDate: lastExecutedDate,
      accountId: accountId,
      toAccountId: toAccountId,
      categoryId: categoryId,
      autoExecute: autoExecute,
      isPaused: isPaused,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

