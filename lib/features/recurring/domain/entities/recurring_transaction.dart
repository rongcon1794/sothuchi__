import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';

enum RecurringInterval { daily, weekly, biweekly, monthly, yearly }

/// Represents an automated or recurring payment/subscription contract.
class RecurringTransaction {
  const RecurringTransaction({
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
  final TransactionType type;
  final RecurringInterval interval;
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

  Money get money => Money(minorUnits: amount, currencyCode: currency);

  bool get isDue {
    if (isPaused) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return !dueDay.isAfter(today);
  }

  int get daysUntilDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return dueDay.difference(today).inDays;
  }

  DateTime computeNextDate([DateTime? fromDate]) {
    final base = fromDate ?? nextDueDate;
    switch (interval) {
      case RecurringInterval.daily:
        return base.add(Duration(days: intervalCount));
      case RecurringInterval.weekly:
        return base.add(Duration(days: 7 * intervalCount));
      case RecurringInterval.biweekly:
        return base.add(Duration(days: 14 * intervalCount));
      case RecurringInterval.monthly:
        final newYear = base.year + ((base.month + intervalCount - 1) ~/ 12);
        final newMonth = ((base.month + intervalCount - 1) % 12) + 1;
        final daysInMonth = DateTime(newYear, newMonth + 1, 0).day;
        final newDay = base.day > daysInMonth ? daysInMonth : base.day;
        return DateTime(newYear, newMonth, newDay, base.hour, base.minute);
      case RecurringInterval.yearly:
        final newYear = base.year + intervalCount;
        final daysInMonth = DateTime(newYear, base.month + 1, 0).day;
        final newDay = base.day > daysInMonth ? daysInMonth : base.day;
        return DateTime(newYear, base.month, newDay, base.hour, base.minute);
    }
  }

  RecurringTransaction copyWith({
    String? id,
    String? title,
    int? amount,
    String? currency,
    TransactionType? type,
    RecurringInterval? interval,
    int? intervalCount,
    DateTime? startDate,
    DateTime? nextDueDate,
    DateTime? lastExecutedDate,
    String? accountId,
    String? toAccountId,
    String? categoryId,
    bool? autoExecute,
    bool? isPaused,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      interval: interval ?? this.interval,
      intervalCount: intervalCount ?? this.intervalCount,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      lastExecutedDate: lastExecutedDate ?? this.lastExecutedDate,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      autoExecute: autoExecute ?? this.autoExecute,
      isPaused: isPaused ?? this.isPaused,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

