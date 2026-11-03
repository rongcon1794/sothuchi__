import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/utils/money.dart';

enum DebtType {
  /// Money lent to others (Người khác nợ mình / Cho vay).
  lent,

  /// Money borrowed from others (Mình nợ người khác / Đi vay).
  borrowed;

  bool get isLent => this == DebtType.lent;
  bool get isBorrowed => this == DebtType.borrowed;
}

class Debt {
  const Debt({
    required this.id,
    required this.personName,
    this.phoneNumber,
    required this.type,
    required this.amount,
    required this.remainingAmount,
    this.currency = AppCurrencies.defaultCode,
    this.dueDate,
    this.accountId,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String personName;
  final String? phoneNumber;
  final DebtType type;
  final int amount;
  final int remainingAmount;
  final String currency;
  final DateTime? dueDate;
  final String? accountId;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isSettled => remainingAmount <= 0;
  bool get isOverdue => dueDate != null && !isSettled && dueDate!.isBefore(DateTime.now());
  int get paidAmount => (amount - remainingAmount).clamp(0, amount);
  double get progress => amount > 0 ? ((amount - remainingAmount) / amount).clamp(0.0, 1.0) : 1.0;

  Money get remainingMoney => Money(minorUnits: remainingAmount, currencyCode: currency);
  Money get totalMoney => Money(minorUnits: amount, currencyCode: currency);
  Money get paidMoney => Money(minorUnits: paidAmount, currencyCode: currency);

  Debt copyWith({
    String? id,
    String? personName,
    String? phoneNumber,
    DebtType? type,
    int? amount,
    int? remainingAmount,
    String? currency,
    DateTime? dueDate,
    String? accountId,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Debt(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      currency: currency ?? this.currency,
      dueDate: dueDate ?? this.dueDate,
      accountId: accountId ?? this.accountId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Debt &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          personName == other.personName &&
          phoneNumber == other.phoneNumber &&
          type == other.type &&
          amount == other.amount &&
          remainingAmount == other.remainingAmount &&
          currency == other.currency &&
          dueDate == other.dueDate &&
          accountId == other.accountId &&
          note == other.note &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          deletedAt == other.deletedAt;

  @override
  int get hashCode => Object.hash(
        id,
        personName,
        phoneNumber,
        type,
        amount,
        remainingAmount,
        currency,
        dueDate,
        accountId,
        note,
        createdAt,
        updatedAt,
        deletedAt,
      );
}

class DebtSummary {
  const DebtSummary({
    required this.totalLent,
    required this.totalBorrowed,
    required this.netBalance,
    required this.overdueCount,
  });

  final Money totalLent;
  final Money totalBorrowed;
  final Money netBalance;
  final int overdueCount;
}
