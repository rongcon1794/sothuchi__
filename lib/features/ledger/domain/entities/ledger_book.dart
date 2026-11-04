import 'package:so_thu_chi/core/constants/currency_constants.dart';

enum LedgerType { personal, family, business, custom }

class LedgerBook {
  const LedgerBook({
    required this.id,
    required this.name,
    this.type = LedgerType.personal,
    this.icon = 'person',
    this.color = 0xFF00A86B,
    this.currency = AppCurrencies.defaultCode,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final LedgerType type;
  final String icon;
  final int color;
  final String currency;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const String defaultPersonalId = 'default_personal';

  static LedgerBook defaultPersonal() {
    final now = DateTime(2026, 1, 1);
    return LedgerBook(
      id: defaultPersonalId,
      name: 'Sổ Cá Nhân',
      type: LedgerType.personal,
      icon: 'person',
      color: 0xFF00A86B,
      currency: AppCurrencies.defaultCode,
      isDefault: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  LedgerBook copyWith({
    String? id,
    String? name,
    LedgerType? type,
    String? icon,
    int? color,
    String? currency,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LedgerBook(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      currency: currency ?? this.currency,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerBook &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          color == other.color &&
          isDefault == other.isDefault;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      type.hashCode ^
      color.hashCode ^
      isDefault.hashCode;
}

