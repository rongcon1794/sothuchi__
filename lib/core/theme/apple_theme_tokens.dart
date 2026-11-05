import 'package:flutter/material.dart';

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
  // Light Mode
  static const Color bgLightGrouped = Color(0xFFF8FAFC);
  static const Color bgLightPrimary = bgLightGrouped;
  static const Color bgLightCard = Color(0xFFFFFFFF);
  static const Color bgLightSecondary = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Dark Mode
  static const Color bgDarkGrouped = Color(0xFF000000);
  static const Color bgDarkPrimary = bgDarkGrouped;
  static const Color bgDarkCard = Color(0xFF1C1C1E);
  static const Color bgDarkSecondary = Color(0xFF2C2C2E);
  static const Color bgDarkTertiary = Color(0xFF3A3A3C);

  // --- Hairline Borders & Separators ---
  static const double hairline = 0.5;
  static Color separatorLight = const Color(0xFF3C3C43).withValues(alpha: 0.18);
  static Color separatorDark = const Color(0xFF545458).withValues(alpha: 0.35);

  // --- Corner Radii (Continuous Apple Squircles) ---
  static const double radiusHero = 24.0;
  static const double radiusCard = 18.0;
  static const double radiusSheet = 20.0;
  static const double radiusControl = 12.0;
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
  static const double navRailWidthCompact = 64.0;
  static const double navRailWidthExpanded = 72.0;
  static const double appBarHeightPortrait = 56.0;
  static const double appBarHeightLandscape = 44.0;
  static const double scrollBottomPaddingWithFab = 120.0;
  static const double scrollBottomPaddingNoFab = 40.0;
  static const double scrollBottomPaddingLandscape = 24.0;
}
