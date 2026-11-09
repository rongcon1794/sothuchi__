import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Semantic Design Token Extension for Apple HIG / Lucian Design System.
/// Provides centralized, theme-aware colors for inputs, surfaces, cards,
/// text hierarchy, and financial semantics.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.inputBackground,
    required this.inputBorder,
    required this.inputFocusedBorder,
    required this.cardBackground,
    required this.cardBorder,
    required this.surfaceGrouped,
    required this.surfaceSecondary,
    required this.surfaceTertiary,
    required this.income,
    required this.incomeContainer,
    required this.expense,
    required this.expenseContainer,
    required this.transfer,
    required this.transferContainer,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.pillBackground,
    required this.pillBorder,
    required this.divider,
  });

  final Color inputBackground;
  final Color inputBorder;
  final Color inputFocusedBorder;
  final Color cardBackground;
  final Color cardBorder;
  final Color surfaceGrouped;
  final Color surfaceSecondary;
  final Color surfaceTertiary;
  final Color income;
  final Color incomeContainer;
  final Color expense;
  final Color expenseContainer;
  final Color transfer;
  final Color transferContainer;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color pillBackground;
  final Color pillBorder;
  final Color divider;

  /// Default Light Mode Tokens
  static const light = AppSemanticColors(
    inputBackground: Colors.white,
    inputBorder: Color(0xFFD1D1D6),
    inputFocusedBorder: AppleTokens.jadePrimary,
    cardBackground: Colors.white,
    cardBorder: Color(0xFFE5E2DC),
    surfaceGrouped: Color(0xFFF4F2EE),
    surfaceSecondary: Color(0xFFF5F3EF),
    surfaceTertiary: Color(0xFFEAE7E1),
    income: AppleTokens.emeraldIncome,
    incomeContainer: Color(0x1F10B981),
    expense: AppleTokens.rubyExpense,
    expenseContainer: Color(0x1FF43F5E),
    transfer: AppleTokens.cobaltTransfer,
    transferContainer: Color(0x1F0284C7),
    textPrimary: Color(0xFF16151B),
    textSecondary: Color(0xFF6C6C70),
    textTertiary: Color(0xFF8E8E93),
    pillBackground: Colors.white,
    pillBorder: Color(0xFFD1D1D6),
    divider: Color(0x2E3C3C43),
  );

  /// Default Dark Mode Tokens
  static const dark = AppSemanticColors(
    inputBackground: Color(0xFF2C2C2E),
    inputBorder: Color(0xFF38383A),
    inputFocusedBorder: AppleTokens.jadePrimary,
    cardBackground: Color(0xFF13141C),
    cardBorder: Color(0xFF2C2C2E),
    surfaceGrouped: Color(0xFF07080D),
    surfaceSecondary: Color(0xFF1A1B25),
    surfaceTertiary: Color(0xFF252632),
    income: Color(0xFF34C759),
    incomeContainer: Color(0x2634C759),
    expense: Color(0xFFFF453A),
    expenseContainer: Color(0x26FF453A),
    transfer: Color(0xFF0A84FF),
    transferContainer: Color(0x260A84FF),
    textPrimary: Color(0xFFF4F0E8),
    textSecondary: Color(0xFF98989D),
    textTertiary: Color(0xFF636366),
    pillBackground: Color(0xFF2C2C2E),
    pillBorder: Color(0xFF38383A),
    divider: Color(0x59545458),
  );

  /// Pure OLED Pitch-Black Mode Tokens
  static const oled = AppSemanticColors(
    inputBackground: Color(0xFF1C1C1E),
    inputBorder: Color(0xFF2C2C2E),
    inputFocusedBorder: AppleTokens.jadePrimary,
    cardBackground: Color(0xFF0C0C0E),
    cardBorder: Color(0xFF1F1F24),
    surfaceGrouped: Colors.black,
    surfaceSecondary: Color(0xFF141416),
    surfaceTertiary: Color(0xFF1C1C1E),
    income: Color(0xFF30D158),
    incomeContainer: Color(0x2630D158),
    expense: Color(0xFFFF453A),
    expenseContainer: Color(0x26FF453A),
    transfer: Color(0xFF0A84FF),
    transferContainer: Color(0x260A84FF),
    textPrimary: Colors.white,
    textSecondary: Color(0xFFA1A1A6),
    textTertiary: Color(0xFF6E6E73),
    pillBackground: Color(0xFF1C1C1E),
    pillBorder: Color(0xFF2C2C2E),
    divider: Color(0x4038383A),
  );

  @override
  ThemeExtension<AppSemanticColors> copyWith({
    Color? inputBackground,
    Color? inputBorder,
    Color? inputFocusedBorder,
    Color? cardBackground,
    Color? cardBorder,
    Color? surfaceGrouped,
    Color? surfaceSecondary,
    Color? surfaceTertiary,
    Color? income,
    Color? incomeContainer,
    Color? expense,
    Color? expenseContainer,
    Color? transfer,
    Color? transferContainer,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? pillBackground,
    Color? pillBorder,
    Color? divider,
  }) {
    return AppSemanticColors(
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorder: inputBorder ?? this.inputBorder,
      inputFocusedBorder: inputFocusedBorder ?? this.inputFocusedBorder,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      surfaceGrouped: surfaceGrouped ?? this.surfaceGrouped,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      surfaceTertiary: surfaceTertiary ?? this.surfaceTertiary,
      income: income ?? this.income,
      incomeContainer: incomeContainer ?? this.incomeContainer,
      expense: expense ?? this.expense,
      expenseContainer: expenseContainer ?? this.expenseContainer,
      transfer: transfer ?? this.transfer,
      transferContainer: transferContainer ?? this.transferContainer,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      pillBackground: pillBackground ?? this.pillBackground,
      pillBorder: pillBorder ?? this.pillBorder,
      divider: divider ?? this.divider,
    );
  }

  @override
  ThemeExtension<AppSemanticColors> lerp(
    covariant ThemeExtension<AppSemanticColors>? other,
    double t,
  ) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      inputFocusedBorder: Color.lerp(inputFocusedBorder, other.inputFocusedBorder, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      surfaceGrouped: Color.lerp(surfaceGrouped, other.surfaceGrouped, t)!,
      surfaceSecondary: Color.lerp(surfaceSecondary, other.surfaceSecondary, t)!,
      surfaceTertiary: Color.lerp(surfaceTertiary, other.surfaceTertiary, t)!,
      income: Color.lerp(income, other.income, t)!,
      incomeContainer: Color.lerp(incomeContainer, other.incomeContainer, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseContainer: Color.lerp(expenseContainer, other.expenseContainer, t)!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      transferContainer: Color.lerp(transferContainer, other.transferContainer, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      pillBackground: Color.lerp(pillBackground, other.pillBackground, t)!,
      pillBorder: Color.lerp(pillBorder, other.pillBorder, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

/// Convenience Extension on BuildContext for 1-line semantic color access
extension SemanticColorsBuildContextX on BuildContext {
  AppSemanticColors get semanticColors {
    final theme = Theme.of(this);
    return theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light);
  }
}

