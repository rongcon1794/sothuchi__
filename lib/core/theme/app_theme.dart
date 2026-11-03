import 'package:flutter/material.dart';

/// Semantic financial colors meeting WCAG AA >= 4.5:1 contrast in Light & Dark modes.
@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({
    required this.income,
    required this.incomeContainer,
    required this.onIncomeContainer,
    required this.expense,
    required this.expenseContainer,
    required this.onExpenseContainer,
    required this.transfer,
    required this.transferContainer,
    required this.onTransferContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
  });

  final Color income;
  final Color incomeContainer;
  final Color onIncomeContainer;
  final Color expense;
  final Color expenseContainer;
  final Color onExpenseContainer;
  final Color transfer;
  final Color transferContainer;
  final Color onTransferContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;

  static const FinanceColors light = FinanceColors(
    income: Color(0xFF0B7A5C),
    incomeContainer: Color(0xFFE3F6EF),
    onIncomeContainer: Color(0xFF064B38),
    expense: Color(0xFFC0352B),
    expenseContainer: Color(0xFFFCEAE8),
    onExpenseContainer: Color(0xFF7A1C15),
    transfer: Color(0xFF1D5BD6),
    transferContainer: Color(0xFFE8F0FE),
    onTransferContainer: Color(0xFF103888),
    warning: Color(0xFFA65606),
    warningContainer: Color(0xFFFEF3E2),
    onWarningContainer: Color(0xFF6E3803),
  );

  static const FinanceColors dark = FinanceColors(
    income: Color(0xFF5CE0B8),
    incomeContainer: Color(0xFF0E382C),
    onIncomeContainer: Color(0xFFB8F5E0),
    expense: Color(0xFFFF8A80),
    expenseContainer: Color(0xFF3E1815),
    onExpenseContainer: Color(0xFFFFDAD6),
    transfer: Color(0xFF8AB4F8),
    transferContainer: Color(0xFF162B54),
    onTransferContainer: Color(0xFFD6E4FF),
    warning: Color(0xFFFFB74D),
    warningContainer: Color(0xFF3B2307),
    onWarningContainer: Color(0xFFFFE0B2),
  );

  @override
  FinanceColors copyWith({
    Color? income,
    Color? incomeContainer,
    Color? onIncomeContainer,
    Color? expense,
    Color? expenseContainer,
    Color? onExpenseContainer,
    Color? transfer,
    Color? transferContainer,
    Color? onTransferContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
  }) {
    return FinanceColors(
      income: income ?? this.income,
      incomeContainer: incomeContainer ?? this.incomeContainer,
      onIncomeContainer: onIncomeContainer ?? this.onIncomeContainer,
      expense: expense ?? this.expense,
      expenseContainer: expenseContainer ?? this.expenseContainer,
      onExpenseContainer: onExpenseContainer ?? this.onExpenseContainer,
      transfer: transfer ?? this.transfer,
      transferContainer: transferContainer ?? this.transferContainer,
      onTransferContainer: onTransferContainer ?? this.onTransferContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
    );
  }

  @override
  FinanceColors lerp(ThemeExtension<FinanceColors>? other, double t) {
    if (other is! FinanceColors) return this;
    return FinanceColors(
      income: Color.lerp(income, other.income, t)!,
      incomeContainer: Color.lerp(incomeContainer, other.incomeContainer, t)!,
      onIncomeContainer: Color.lerp(
        onIncomeContainer,
        other.onIncomeContainer,
        t,
      )!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseContainer: Color.lerp(
        expenseContainer,
        other.expenseContainer,
        t,
      )!,
      onExpenseContainer: Color.lerp(
        onExpenseContainer,
        other.onExpenseContainer,
        t,
      )!,
      transfer: Color.lerp(transfer, other.transfer, t)!,
      transferContainer: Color.lerp(
        transferContainer,
        other.transferContainer,
        t,
      )!,
      onTransferContainer: Color.lerp(
        onTransferContainer,
        other.onTransferContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
    );
  }
}

/// Material 3 "Jade Ledger" design system with dynamic seed color & tabular numerals.
abstract final class AppTheme {
  static const Color seedColor = Color(0xFF0D7C66);
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  static ThemeData light([Color seed = seedColor]) =>
      _build(Brightness.light, seed);

  static ThemeData dark([Color seed = seedColor]) =>
      _build(Brightness.dark, seed);

  static ThemeData _build(Brightness brightness, Color seed) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: isDark ? const Color(0xFF0F1513) : const Color(0xFFF8FAF9),
    );
    final baseText = Typography.material2021().black.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: [isDark ? FinanceColors.dark : FinanceColors.light],
      textTheme: baseText.copyWith(
        displaySmall: baseText.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          fontFeatures: tabularFigures,
        ),
        headlineMedium: baseText.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          fontFeatures: tabularFigures,
        ),
        headlineSmall: baseText.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          fontFeatures: tabularFigures,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(height: 1.4),
        bodyMedium: baseText.bodyMedium?.copyWith(height: 1.4),
        labelLarge: baseText.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontFeatures: tabularFigures,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainer
            : colorScheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      segmentedButtonTheme: const SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(48, 48)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: isDark
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerLowest,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
      ),
    );
  }
}

extension FinanceThemeContext on BuildContext {
  FinanceColors get financeColors =>
      Theme.of(this).extension<FinanceColors>() ?? FinanceColors.light;
}

