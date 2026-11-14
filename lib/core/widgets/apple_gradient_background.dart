import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_dynamic_ambient_background.dart';

export 'package:so_thu_chi/core/widgets/apple_dynamic_ambient_background.dart'
    show AppleAmbientTheme;

/// Synchronous, opaque Apple HIG gradient canvas component.
///
/// Solves the screen bleed-through problem during route transitions by painting
/// a 100% opaque foundation canvas combined with a synchronized luminous Apple
/// gradient wash and ambient orbs.
///
/// Used both for main tab screens and automatically injected into all
/// pushed child routes via [adaptivePage], ensuring 100% visual harmony across
/// the entire application without graphical glitches or previous-screen leaks.
class AppleGradientBackground extends StatelessWidget {
  const AppleGradientBackground({
    super.key,
    required this.child,
    this.paletteIndex,
    this.isOled,
  });

  /// The child widget (typically a Scaffold with transparent background).
  final Widget child;

  /// Optional palette index override (0: Overview, 1: Transactions, 2: Budgets, 3: Reports, 4: Settings).
  /// If null, automatically synchronizes with [AppleAmbientTheme] (or defaults to 0).
  final int? paletteIndex;

  /// Optional OLED True Black override. If null, automatically queries [context.isOled].
  final bool? isOled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final oled = isOled ?? context.isOled;

    final int activeIndex = paletteIndex ?? AppleAmbientTheme.of(context);
    final int clampedIndex = activeIndex.clamp(
      0,
      AppleDynamicAmbientBackground.tabPalettes.length - 1,
    ).toInt();
    final blobs = AppleDynamicAmbientBackground.tabPalettes[clampedIndex];

    final baseColor = isDark
        ? (oled ? AppleTokens.bgOledPrimary : AppleTokens.bgDarkGrouped)
        : AppleTokens.bgLightGrouped;

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _SynchronousGradientPainter(
              blobs: blobs,
              baseColor: baseColor,
              isDark: isDark,
              isOled: oled,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _SynchronousGradientPainter extends CustomPainter {
  const _SynchronousGradientPainter({
    required this.blobs,
    required this.baseColor,
    required this.isDark,
    required this.isOled,
  });

  final List<AmbientBlobSpec> blobs;
  final Color baseColor;
  final bool isDark;
  final bool isOled;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw solid foundation canvas (100% OPAQUE -> prevents route bleed-through)
    final basePaint = Paint()..color = baseColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // In OLED True Black mode, keep absolute pitch black for pixel shutoff and battery savings
    if (isOled) return;

    // 2. Subtle directional gradient wash for vertical depth
    final topTint = isDark
        ? const Color(0xFF141726).withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.65);
    final bottomTint = isDark
        ? const Color(0xFF030407).withValues(alpha: 0.60)
        : const Color(0xFFE5E1D8).withValues(alpha: 0.45);

    final washGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topTint, Colors.transparent, bottomTint],
      stops: const [0.0, 0.45, 1.0],
    );

    final washPaint = Paint()
      ..shader = washGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), washPaint);

    // 3. Draw ambient gradient orbs with luminous, vibrant Apple styling
    final maxDim = math.max(size.width, size.height);
    final centerAlpha = isDark ? 0.160 : 0.105;
    final midAlpha = isDark ? 0.075 : 0.048;

    for (final blob in blobs) {
      final color = blob.resolveColor(isDark);
      final center = Offset(
        (blob.alignment.x + 1.0) / 2.0 * size.width,
        (blob.alignment.y + 1.0) / 2.0 * size.height,
      );
      final radius = maxDim * blob.radiusFactor;

      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          color.withValues(alpha: centerAlpha),
          color.withValues(alpha: midAlpha),
          Colors.transparent,
        ],
        stops: const [0.0, 0.52, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..blendMode = BlendMode.srcOver;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SynchronousGradientPainter oldDelegate) {
    return oldDelegate.baseColor != baseColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isOled != isOled ||
        oldDelegate.blobs != blobs;
  }
}
