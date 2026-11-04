import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/features/ledger/domain/entities/ledger_book.dart';

class LedgerBookDto {
  const LedgerBookDto({
    required this.id,
    required this.name,
    required this.type,
    this.icon = 'person',
    this.color = 0xFF00A86B,
    this.currency = AppCurrencies.defaultCode,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String type;
  final String icon;
  final int color;
  final String currency;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory LedgerBookDto.fromJson(Map<String, dynamic> json, [String? id]) {
    DateTime parseDate(Object? val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return LedgerBookDto(
      id: id ?? (json['id'] as String? ?? ''),
      name: json['name'] as String? ?? 'Sổ Cá Nhân',
      type: json['type'] as String? ?? 'personal',
      icon: json['icon'] as String? ?? 'person',
      color: (json['color'] as num?)?.toInt() ?? 0xFF00A86B,
      currency: json['currency'] as String? ?? AppCurrencies.defaultCode,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  factory LedgerBookDto.fromDomain(LedgerBook domain) {
    return LedgerBookDto(
      id: domain.id,
      name: domain.name,
      type: domain.type.name,
      icon: domain.icon,
      color: domain.color,
      currency: domain.currency,
      isDefault: domain.isDefault,
      createdAt: domain.createdAt,
      updatedAt: domain.updatedAt,
    );
  }

  LedgerBook toDomain() {
    LedgerType resolveType(String t) {
      switch (t) {
        case 'family':
          return LedgerType.family;
        case 'business':
          return LedgerType.business;
        case 'custom':
          return LedgerType.custom;
        case 'personal':
        default:
          return LedgerType.personal;
      }
    }

    return LedgerBook(
      id: id,
      name: name,
      type: resolveType(type),
      icon: icon,
      color: color,
      currency: currency,
      isDefault: isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'currency': currency,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

