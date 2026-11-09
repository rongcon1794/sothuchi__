import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

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
    income: Color(0xFF059669),
    incomeContainer: Color(0xFFECFDF5),
    onIncomeContainer: Color(0xFF065F46),
    expense: Color(0xFFE11D48),
    expenseContainer: Color(0xFFFFF1F2),
    onExpenseContainer: Color(0xFF9F1239),
    transfer: Color(0xFF0284C7),
    transferContainer: Color(0xFFF0F9FF),
    onTransferContainer: Color(0xFF075985),
    warning: Color(0xFFD97706),
    warningContainer: Color(0xFFFFFBEB),
    onWarningContainer: Color(0xFF92400E),
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
  static const Color seedColor = Color(0xFF00A86B);
  static const List<Color> palettes = [
    Color(0xFF00A86B), // Ngọc Bích (Fresh Jade)
    Color(0xFF007AFF), // Đại Dương (Ocean Blue)
    Color(0xFFFF9500), // Hoàng Hôn (Sunset Amber)
    Color(0xFFAF52DE), // Thạch Anh (Amethyst Violet)
  ];
  static const List<String> paletteNames = [
    'Ngọc Bích',
    'Đại Dương',
    'Hoàng Hôn',
    'Thạch Anh',
  ];
  static const List<String> paletteNamesEn = [
    'Emerald Jade',
    'Ocean Blue',
    'Sunset Amber',
    'Amethyst Violet',
  ];

  /// Returns the localized palette name based on [locale].
  static String localizedPaletteName(int index, {String locale = 'vi'}) {
    final clamped = index.clamp(0, palettes.length - 1);
    if (locale.toLowerCase().startsWith('en')) {
      return paletteNamesEn[clamped];
    }
    return paletteNames[clamped];
  }
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  static ThemeData light([Color seed = seedColor]) =>
      _build(Brightness.light, seed);

  static ThemeData dark([Color seed = seedColor, bool oledMode = false]) =>
      _build(Brightness.dark, seed, oledMode: oledMode);

  static ThemeData _build(Brightness brightness, Color seed, {bool oledMode = false}) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      primary: seed,
      brightness: brightness,
      surface: isDark
          ? (oledMode ? AppleTokens.bgOledCard : AppleTokens.bgDarkCard)
          : AppleTokens.bgLightCard,
    );
    final baseText = Typography.material2021().black.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark
          ? (oledMode ? AppleTokens.bgOledPrimary : AppleTokens.bgDarkGrouped)
          : AppleTokens.bgLightGrouped,
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
          letterSpacing: -0.1,
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
        scrolledUnderElevation: 0,
        backgroundColor: isDark
            ? (oledMode ? AppleTokens.bgOledPrimary : AppleTokens.bgDarkGrouped)
            : AppleTokens.bgLightGrouped,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark
            ? (oledMode ? AppleTokens.bgOledCard : AppleTokens.bgDarkCard)
            : AppleTokens.bgLightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
          side: BorderSide(
            color: isDark
                ? (oledMode
                    ? AppleTokens.bgOledBorder
                    : Colors.white.withValues(alpha: 0.08))
                : Colors.black.withValues(alpha: 0.05),
            width: AppleTokens.hairline,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? (oledMode
                ? AppleTokens.bgOledSecondary
                : const Color(0xFF2C2C2E))
            : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6),
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
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
            ? (oledMode
                ? AppleTokens.bgOledPrimary
                : colorScheme.surfaceContainerLow)
            : colorScheme.surfaceContainerLowest,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark
            ? (oledMode ? AppleTokens.bgOledCard : AppleTokens.bgDarkCard)
            : AppleTokens.bgLightCard,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.18),
        surfaceTintColor: Colors.transparent,
        color: isDark
            ? (oledMode ? AppleTokens.bgOledCard : AppleTokens.bgDarkCard)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
          side: BorderSide(
            color: isDark
                ? (oledMode
                    ? AppleTokens.bgOledBorder
                    : AppleTokens.separatorDark)
                : AppleTokens.separatorLight,
            width: AppleTokens.hairline,
          ),
        ),
        textStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black87,
        ),
        position: PopupMenuPosition.under,
      ),
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
      ),
      chipTheme: const ChipThemeData(
        showCheckmark: false,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}

extension FinanceThemeContext on BuildContext {
  FinanceColors get financeColors =>
      Theme.of(this).extension<FinanceColors>() ?? FinanceColors.light;
}

