import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

enum CategoryType { income, expense }

@freezed
abstract class Category with _$Category {
  const Category._();

  const factory Category({
    required String id,
    required String name,
    required CategoryType type,
    @Default('other') String icon,
    @Default(0xFF0D7C66) int color,
    String? parentId,
    @Default(false) bool isDefault,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _Category;

  bool get isActive => deletedAt == null;

  /// Returns an English label for untouched built-in categories when [localeCode]
  /// is `'en'`, while preserving user-customized names and Vietnamese defaults.
  String localizedName(String localeCode) {
    if (!isDefault || !localeCode.toLowerCase().startsWith('en')) {
      return name;
    }
    const defaultViNames = <String, String>{
      'default_food': 'Ăn uống',
      'default_transport': 'Di chuyển',
      'default_housing': 'Nhà ở',
      'default_bills': 'Hóa đơn & Tiện ích',
      'default_shopping': 'Mua sắm',
      'default_entertainment': 'Giải trí',
      'default_health': 'Sức khỏe',
      'default_education': 'Giáo dục',
      'default_other_expense': 'Chi tiêu khác',
      'default_salary': 'Lương',
      'default_bonus': 'Thưởng',
      'default_investment': 'Đầu tư & Lãi',
      'default_other_income': 'Thu nhập khác',
    };
    const defaultEnNames = <String, String>{
      'default_food': 'Food & Dining',
      'default_transport': 'Transport',
      'default_housing': 'Housing',
      'default_bills': 'Bills & Utilities',
      'default_shopping': 'Shopping',
      'default_entertainment': 'Entertainment',
      'default_health': 'Health',
      'default_education': 'Education',
      'default_other_expense': 'Other Expense',
      'default_salary': 'Salary',
      'default_bonus': 'Bonus',
      'default_investment': 'Investments & Interest',
      'default_other_income': 'Other Income',
    };
    if (defaultViNames[id] == name && defaultEnNames.containsKey(id)) {
      return defaultEnNames[id]!;
    }
    return name;
  }
}

