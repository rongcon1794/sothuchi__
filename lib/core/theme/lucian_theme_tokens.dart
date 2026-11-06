import 'package:flutter/material.dart';

/// Lucian Labs UX/UI Design Tokens and Animation Physics.
/// Grounded in https://lucianlabs.dev/uxui-prompt/ and the open-source
/// Lucian UX/UI Prompt library (MIT License (c) 2026 Seokwoooo).
abstract final class LucianTokens {
  // --- Core Theme Colors (Light & Dark) ---
  // Accent & Brand (Purple-Indigo & Vibrant Electric Blue)
  static const Color accentLight = Color(0xFF6A57F2); // --ux-accent
  static const Color accentDark = Color(0xFFB7A4FF);
  static const Color accent2Light = Color(0xFF2F8FE0); // --ux-accent-2
  static const Color accent2Dark = Color(0xFF7DB4FF);
  static const Color accentSoftLight = Color(0x1F6A57F2); // rgba(106,87,242,.12)
  static const Color accentSoftDark = Color(0x26B7A4FF); // rgba(183,164,255,.15)

  // Financial Semantics (Mint Income & Danger Expense)
  static const Color mintLight = Color(0xFF119C72); // --ux-mint
  static const Color mintDark = Color(0xFF7EE8C0);
  static const Color warnLight = Color(0xFFD6731E); // --ux-warn
  static const Color warnDark = Color(0xFFFFB26B);
  static const Color dangerLight = Color(0xFFD93A55); // --ux-danger
  static const Color dangerDark = Color(0xFFFF7D8C);
  static const Color danger = dangerLight;
  static const Color mint = mintLight;
  static const Color warn = warnLight;

  // Surfaces & Glass
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF13141C);
  static const Color surface2Light = Color(0xFFF5F3EF);
  static const Color surface2Dark = Color(0xFF1A1B25);
  static const Color surface3Light = Color(0xFFEAE7E1);
  static const Color surface3Dark = Color(0xFF252632);

  // Text & Inks
  static const Color inkLight = Color(0xFF16151B);
  static const Color inkDark = Color(0xFFF4F0E8);
  static const Color ink2Light = Color(0xFF57535F);
  static const Color ink2Dark = Color(0xADF4F0E8); // rgba(244,240,232,.68)
  static const Color ink3Light = Color(0xFF8E8A97);
  static const Color ink3Dark = Color(0x6BF4F0E8); // rgba(244,240,232,.42)

  // Signatures Gradients
  static const LinearGradient gradLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7B61FF),
      Color(0xFF3D8BFF),
      Color(0xFF1FB89A),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient gradDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFB7A4FF),
      Color(0xFF7DB4FF),
      Color(0xFFA5F2D3),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  // --- Animation Physics Curves ---
  /// Lucian Smooth Deceleration: cubic-bezier(.2, .8, .2, 1)
  static const Curve ease = Cubic(0.2, 0.8, 0.2, 1.0);

  /// Lucian Tactile Spring Overshoot: cubic-bezier(.34, 1.45, .64, 1)
  static const Curve spring = Cubic(0.34, 1.45, 0.64, 1.0);

  /// Lucian Number Digit Roll: cubic-bezier(.3, 1.25, .5, 1)
  static const Curve digitRoll = Cubic(0.3, 1.25, 0.5, 1.0);

  // Helper Methods to resolve colors based on theme brightness
  static Color resolveAccent(bool isDark) => isDark ? accentDark : accentLight;
  static Color resolveMint(bool isDark) => isDark ? mintDark : mintLight;
  static Color resolveDanger(bool isDark) => isDark ? dangerDark : dangerLight;
  static Color resolveWarn(bool isDark) => isDark ? warnDark : warnLight;
  static Color resolveSurface(bool isDark) => isDark ? surfaceDark : surfaceLight;
  static Color resolveSurface2(bool isDark) => isDark ? surface2Dark : surface2Light;
  static Color resolveInk(bool isDark) => isDark ? inkDark : inkLight;
  static Color resolveInk2(bool isDark) => isDark ? ink2Dark : ink2Light;
  static Color resolveInk3(bool isDark) => isDark ? ink3Dark : ink3Light;
  static LinearGradient resolveGrad(bool isDark) => isDark ? gradDark : gradLight;
}

