import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/utils/money.dart';

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.currency = AppCurrencies.defaultCode,
    this.deadline,
    this.icon = 'piggy_bank',
    this.color = 0xFF00A86B,
    this.isCompleted = false,
    this.linkedAccountId,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final int targetAmount;
  final int currentAmount;
  final String currency;
  final DateTime? deadline;
  final String icon;
  final int color;
  final bool isCompleted;
  final String? linkedAccountId;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get progress {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  int get progressPercent => (progress * 100).round();

  bool get isReached => targetAmount > 0 && currentAmount >= targetAmount;

  int get remainingAmount =>
      targetAmount > currentAmount ? targetAmount - currentAmount : 0;

  Money get targetMoney =>
      Money(minorUnits: targetAmount, currencyCode: currency);

  Money get currentMoney =>
      Money(minorUnits: currentAmount, currencyCode: currency);

  Money get remainingMoney =>
      Money(minorUnits: remainingAmount, currencyCode: currency);

  int? get daysRemaining {
    if (deadline == null) return null;
    final now = DateTime.now();
    final dDate = DateTime(deadline!.year, deadline!.month, deadline!.day);
    final nDate = DateTime(now.year, now.month, now.day);
    final diff = dDate.difference(nDate).inDays;
    return diff < 0 ? 0 : diff;
  }

  int? get recommendedDailySavings {
    final days = daysRemaining;
    if (days == null || days <= 0 || remainingAmount <= 0) return null;
    return (remainingAmount / days).ceil();
  }

  int? get recommendedMonthlySavings {
    final days = daysRemaining;
    if (days == null || days <= 0 || remainingAmount <= 0) return null;
    final months = days / 30.0;
    if (months <= 1.0) return remainingAmount;
    return (remainingAmount / months).ceil();
  }

  SavingsGoal copyWith({
    String? id,
    String? title,
    int? targetAmount,
    int? currentAmount,
    String? currency,
    DateTime? deadline,
    bool clearDeadline = false,
    String? icon,
    int? color,
    bool? isCompleted,
    String? linkedAccountId,
    bool clearLinkedAccount = false,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      currency: currency ?? this.currency,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      linkedAccountId: clearLinkedAccount
          ? null
          : (linkedAccountId ?? this.linkedAccountId),
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsGoal &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          targetAmount == other.targetAmount &&
          currentAmount == other.currentAmount &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      targetAmount.hashCode ^
      currentAmount.hashCode ^
      isCompleted.hashCode;
}
