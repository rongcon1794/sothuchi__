import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/features/savings/domain/entities/savings_goal.dart';

class SavingsGoalDto {
  const SavingsGoalDto({
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

  factory SavingsGoalDto.fromJson(Map<String, dynamic> json, [String? id]) {
    DateTime parseDate(Object? val, [DateTime? fallback]) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return fallback ?? DateTime.now();
    }

    DateTime? parseNullableDate(Object? val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    return SavingsGoalDto(
      id: id ?? (json['id'] as String? ?? ''),
      title: json['title'] as String? ?? '',
      targetAmount: (json['targetAmount'] as num?)?.toInt() ?? 0,
      currentAmount: (json['currentAmount'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? AppCurrencies.defaultCode,
      deadline: parseNullableDate(json['deadline']),
      icon: json['icon'] as String? ?? 'piggy_bank',
      color: (json['color'] as num?)?.toInt() ?? 0xFF00A86B,
      isCompleted: json['isCompleted'] as bool? ?? false,
      linkedAccountId: json['linkedAccountId'] as String?,
      note: json['note'] as String? ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  factory SavingsGoalDto.fromDomain(SavingsGoal domain) {
    return SavingsGoalDto(
      id: domain.id,
      title: domain.title,
      targetAmount: domain.targetAmount,
      currentAmount: domain.currentAmount,
      currency: domain.currency,
      deadline: domain.deadline,
      icon: domain.icon,
      color: domain.color,
      isCompleted: domain.isCompleted,
      linkedAccountId: domain.linkedAccountId,
      note: domain.note,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
    );
  }

  SavingsGoal toDomain() {
    return SavingsGoal(
      id: id,
      title: title,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      currency: currency,
      deadline: deadline,
      icon: icon,
      color: color,
      isCompleted: isCompleted,
      linkedAccountId: linkedAccountId,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'currency': currency,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'icon': icon,
      'color': color,
      'isCompleted': isCompleted,
      'linkedAccountId': linkedAccountId,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
