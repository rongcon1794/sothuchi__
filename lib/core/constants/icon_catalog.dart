import 'package:flutter/material.dart';

/// Tree-shake-safe catalog of Material Symbols for wallets and categories.
///
/// Using constant `Icons.*_rounded` references guarantees Android & iOS release
/// builds pass `--tree-shake-icons` without runtime missing-glyph issues.
abstract final class AppIconCatalog {
  static const Map<String, IconData> icons = {
    // Wallets
    'wallet': Icons.account_balance_wallet_rounded,
    'cash': Icons.payments_rounded,
    'bank': Icons.account_balance_rounded,
    'ewallet': Icons.qr_code_2_rounded,
    'card': Icons.credit_card_rounded,
    'savings': Icons.savings_rounded,

    // Expense categories
    'food': Icons.restaurant_rounded,
    'coffee': Icons.local_cafe_rounded,
    'transport': Icons.directions_car_rounded,
    'housing': Icons.home_rounded,
    'bills': Icons.receipt_long_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'entertainment': Icons.movie_rounded,
    'health': Icons.medical_services_rounded,
    'education': Icons.school_rounded,
    'fitness': Icons.fitness_center_rounded,
    'travel': Icons.flight_takeoff_rounded,
    'pets': Icons.pets_rounded,
    'family': Icons.family_restroom_rounded,
    'gift': Icons.redeem_rounded,

    // Income & Transfer
    'salary': Icons.work_rounded,
    'bonus': Icons.workspace_premium_rounded,
    'investment': Icons.trending_up_rounded,
    'transfer': Icons.swap_horiz_rounded,
    'other': Icons.category_rounded,
  };

  static List<String> get keys => icons.keys.toList(growable: false);

  static IconData resolve(String key) => icons[key] ?? Icons.category_rounded;

  /// Ensures >= 3:1 non-text contrast for icons rendered against dark surfaces.
  static Color contrastSafeColor(Color base, Brightness brightness) {
    if (brightness == Brightness.light) return base;
    final hsl = HSLColor.fromColor(base);
    if (hsl.lightness < 0.62) {
      return hsl.withLightness(0.66).toColor();
    }
    return base;
  }

  /// Localized human-readable label for screen readers (TalkBack / VoiceOver).
  static String iconAccessibilityLabel(String key, {required bool isVi}) {
    return switch (key) {
      'wallet' => isVi ? 'Ví tiền' : 'Wallet',
      'cash' => isVi ? 'Tiền mặt' : 'Cash',
      'bank' => isVi ? 'Ngân hàng' : 'Bank',
      'ewallet' => isVi ? 'Ví điện tử' : 'E-wallet',
      'card' => isVi ? 'Thẻ' : 'Card',
      'savings' => isVi ? 'Tiết kiệm' : 'Savings',
      'food' => isVi ? 'Ăn uống' : 'Food',
      'coffee' => isVi ? 'Cà phê' : 'Coffee',
      'transport' => isVi ? 'Di chuyển' : 'Transport',
      'housing' => isVi ? 'Nhà ở' : 'Housing',
      'bills' => isVi ? 'Hóa đơn' : 'Bills',
      'shopping' => isVi ? 'Mua sắm' : 'Shopping',
      'entertainment' => isVi ? 'Giải trí' : 'Entertainment',
      'health' => isVi ? 'Sức khỏe' : 'Health',
      'education' => isVi ? 'Giáo dục' : 'Education',
      'fitness' => isVi ? 'Thể thao' : 'Fitness',
      'travel' => isVi ? 'Du lịch' : 'Travel',
      'pets' => isVi ? 'Thú cưng' : 'Pets',
      'family' => isVi ? 'Gia đình' : 'Family',
      'gift' => isVi ? 'Quà tặng' : 'Gift',
      'salary' => isVi ? 'Lương' : 'Salary',
      'bonus' => isVi ? 'Thưởng' : 'Bonus',
      'investment' => isVi ? 'Đầu tư' : 'Investment',
      'transfer' => isVi ? 'Chuyển khoản' : 'Transfer',
      _ => isVi ? 'Khác' : 'Other',
    };
  }

  static String colorAccessibilityLabel(
    int colorValue, {
    required bool isVi,
  }) {
    return switch (colorValue) {
      0xFF0D7C66 => isVi ? 'Xanh ngọc bích' : 'Jade green',
      0xFF1D5BD6 => isVi ? 'Xanh dương đậm' : 'Cobalt blue',
      0xFFC0352B => isVi ? 'Đỏ son' : 'Vermilion red',
      0xFFD97706 => isVi ? 'Vàng hổ phách' : 'Amber',
      0xFF7C3AED => isVi ? 'Tím diên vĩ' : 'Iris purple',
      0xFFDB2777 => isVi ? 'Hồng đậm' : 'Berry pink',
      0xFF0891B2 => isVi ? 'Xanh lam' : 'Cyan',
      0xFF4F46E5 => isVi ? 'Xanh chàm' : 'Indigo',
      0xFF15803D => isVi ? 'Xanh lá rừng' : 'Forest green',
      0xFFB45309 => isVi ? 'Nâu đất nung' : 'Terracotta',
      0xFF334155 => isVi ? 'Xám đá' : 'Slate',
      0xFF9333EA => isVi ? 'Tím mận' : 'Plum',
      _ => isVi ? 'Màu tùy chỉnh' : 'Custom color',
    };
  }

  /// Curated high-contrast palette for categories and wallets.
  static const List<int> palette = [
    0xFF0D7C66, // Jade
    0xFF1D5BD6, // Cobalt
    0xFFC0352B, // Vermilion
    0xFFD97706, // Amber
    0xFF7C3AED, // Iris
    0xFFDB2777, // Berry
    0xFF0891B2, // Cyan
    0xFF4F46E5, // Indigo
    0xFF15803D, // Forest
    0xFFB45309, // Terracotta
    0xFF334155, // Slate
    0xFF9333EA, // Plum
  ];
}
