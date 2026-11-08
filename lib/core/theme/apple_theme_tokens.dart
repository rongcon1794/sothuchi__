import 'package:flutter/material.dart';
export 'package:so_thu_chi/core/theme/lucian_theme_tokens.dart';

/// Pure Apple Human Interface Guidelines (HIG) Design Tokens & System Colors.
/// Aligned with iOS 17 / iOS 18 design language.
abstract final class AppleTokens {
  // --- iOS System Colors (Light & Dark) ---
  static const Color systemBlue = Color(0xFF007AFF);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemIndigo = Color(0xFF5856D6);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemPink = Color(0xFFFF2D55);
  static const Color systemPurple = Color(0xFFAF52DE);
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemTeal = Color(0xFF30B0C7);
  static const Color systemYellow = Color(0xFFFFCC00);
  static const Color systemMint = Color(0xFF00C7BE);
  static const Color systemCyan = Color(0xFF32ADE6);
  static const Color systemGray = Color(0xFF8E8E93);

  // Financial Semantics (Vibrant Fresh Jade & Ruby Apple-styled)
  static const Color jadePrimary = Color(0xFF00A86B);
  static const Color jadeDark = Color(0xFF034A3C);
  static const Color rubyExpense = Color(0xFFF43F5E);
  static const Color emeraldIncome = Color(0xFF10B981);
  static const Color cobaltTransfer = Color(0xFF0284C7);

  // --- Backgrounds & Grouped Surfaces (iOS 18 Fresh Luminous Canvas) ---
  // Light Mode (Lucian Warm Linen Canvas)
  static const Color bgLightGrouped = Color(0xFFF4F2EE);
  static const Color bgLightPrimary = bgLightGrouped;
  static const Color bgLightCard = Color(0xFFFFFFFF);
  static const Color bgLightSecondary = Color(0xFFF5F3EF);
  static const Color borderLight = Color(0xFFE5E2DC);

  // Dark Mode (Lucian Velvety Obsidian Canvas)
  static const Color bgDarkGrouped = Color(0xFF07080D);
  static const Color bgDarkPrimary = bgDarkGrouped;
  static const Color bgDarkCard = Color(0xFF13141C);
  static const Color bgDarkSecondary = Color(0xFF1A1B25);
  static const Color bgDarkTertiary = Color(0xFF252632);

  // --- Hairline Borders & Separators ---
  static const double hairline = 0.5;
  static Color separatorLight = const Color(0xFF3C3C43).withValues(alpha: 0.18);
  static Color separatorDark = const Color(0xFF545458).withValues(alpha: 0.35);

  // --- Corner Radii (Continuous Apple Squircles) ---
  static const double radiusHero = 24.0;
  static const double radiusCard = 18.0;
  static const double radiusSheet = 20.0;
  static const double radiusControl = 12.0;
  static const double radiusSm = 10.0;
  static const double radiusPill = 999.0;

  // --- Shadows ---
  static List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> cardShadowDark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> floatingBarShadowLight = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> floatingBarShadowDark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];

  // --- Navigation Bar, Left Rail & Responsive Layout Clearance Tokens ---
  static const double navBarHeight = 52.0;
  static const double navBarHeightPortrait = 52.0;
  static const double navBarHeightLandscape = 38.0;
  static const double navRailWidthCompact = 64.0;
  static const double navRailWidthExpanded = 72.0;
  static const double appBarHeightPortrait = 56.0;
  static const double appBarHeightLandscape = 38.0;
  static const double scrollBottomPaddingWithFab = 120.0;
  static const double scrollBottomPaddingNoFab = 40.0;
  static const double scrollBottomPaddingLandscape = 24.0;

  // --- Unified Layout Max Width Constraints ---
  /// Main screens (Overview, Transactions, Accounts, Budgets, Reports, Settings, etc.)
  static const double maxContentWidth = 1024.0;
  /// Detail views and forms on tablets/desktops
  static const double maxDetailWidth = 860.0;
  /// Compact auth / modal / alert screens
  static const double maxCardDialogWidth = 480.0;

  // --- OLED True Black Palette Tokens ---
  static const Color bgOledPrimary = Color(0xFF000000);
  static const Color bgOledCard = Color(0xFF070709);
  static const Color bgOledSecondary = Color(0xFF101014);
  static const Color bgOledBorder = Color(0xFF24242A);

  /// Returns true if the app is currently in Dark Mode with OLED True Black enabled.
  static bool isOled(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark &&
        theme.scaffoldBackgroundColor == bgOledPrimary;
  }

  /// Resolves the card/surface background adapting seamlessly across Light, Dark, and OLED True Black.
  static Color resolveSurface(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (!isDark) return bgLightCard;
    return isOled(context) ? bgOledCard : bgDarkCard;
  }

  /// Resolves the secondary/control background adapting seamlessly across Light, Dark, and OLED True Black.
  static Color resolveSecondary(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (!isDark) return bgLightSecondary;
    return isOled(context) ? bgOledSecondary : bgDarkSecondary;
  }

  /// Resolves surface borders with sharp high-contrast hairline in OLED mode.
  static Color resolveBorder(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    if (!isDark) return borderLight;
    return isOled(context) ? bgOledBorder : Colors.white.withValues(alpha: 0.12);
  }
}

/// Extension on [BuildContext] for ergonomic OLED and theme awareness.
extension AppleThemeContextX on BuildContext {
  bool get isOled => AppleTokens.isOled(this);
}
