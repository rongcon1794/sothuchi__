import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/features/debts/domain/entities/debt.dart';

class DebtDto {
  const DebtDto({
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
  final String type;
  final int amount;
  final int remainingAmount;
  final String currency;
  final DateTime? dueDate;
  final String? accountId;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  factory DebtDto.fromJson(Map<String, dynamic> json, [String? id]) {
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

    return DebtDto(
      id: id ?? (json['id'] as String? ?? ''),
      personName: json['personName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      type: json['type'] as String? ?? DebtType.lent.name,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      remainingAmount: (json['remainingAmount'] as num?)?.toInt() ??
          (json['amount'] as num?)?.toInt() ??
          0,
      currency: json['currency'] as String? ?? AppCurrencies.defaultCode,
      dueDate: parseNullableDate(json['dueDate']),
      accountId: json['accountId'] as String?,
      note: json['note'] as String? ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      deletedAt: parseNullableDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'personName': personName,
        'phoneNumber': phoneNumber,
        'type': type,
        'amount': amount,
        'remainingAmount': remainingAmount,
        'currency': currency,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'accountId': accountId,
        'note': note,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      };

  factory DebtDto.fromDomain(Debt entity) => DebtDto(
        id: entity.id,
        personName: entity.personName,
        phoneNumber: entity.phoneNumber,
        type: entity.type.name,
        amount: entity.amount,
        remainingAmount: entity.remainingAmount,
        currency: entity.currency,
        dueDate: entity.dueDate,
        accountId: entity.accountId,
        note: entity.note,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
        deletedAt: entity.deletedAt,
      );

  Debt toDomain() {
    final parsedType = DebtType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => DebtType.lent,
    );
    return Debt(
      id: id,
      personName: personName,
      phoneNumber: phoneNumber,
      type: parsedType,
      amount: amount,
      remainingAmount: remainingAmount,
      currency: currency,
      dueDate: dueDate,
      accountId: accountId,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

