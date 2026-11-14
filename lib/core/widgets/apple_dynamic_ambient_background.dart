import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Represents a single ambient light blob with position, spread, and adaptive theme colors.
class AmbientBlobSpec {
  const AmbientBlobSpec({
    required this.alignment,
    required this.radiusFactor,
    required this.lightColor,
    required this.darkColor,
  });

  final Alignment alignment;
  final double radiusFactor;
  final Color lightColor;
  final Color darkColor;

  Color resolveColor(bool isDark) => isDark ? darkColor : lightColor;
}

/// Dynamic, luminous ambient gradient background conforming to Apple HIG & Lucian design tokens.
///
/// Features:
/// - Smooth animated transitions (650ms `easeInOutCubic`) of gradient orbs when switching between screens/tabs.
/// - Tab-specific color harmonies:
///   - 0 (Overview): Apple Jade, Mint & Golden Amber
///   - 1 (Transactions): Sapphire Blue, Royal Indigo & Soft Cyan
///   - 2 (Budgets): Emerald Teal, Warm Tangerine & Leaf Green
///   - 3 (Reports): Amethyst Purple, Coral Rose & Indigo
///   - 4 (Settings): Cool Slate, Silver Zinc & Muted Sage
/// - Ultra-subtle, non-distracting opacity (4-7% in Light mode, 8-12% in Dark mode) that preserves full text readability.
/// - 100% OLED True Black mode preservation (zero background power consumption).
/// - High-performance isolated rendering with [RepaintBoundary].
class AppleDynamicAmbientBackground extends StatefulWidget {
  const AppleDynamicAmbientBackground({
    super.key,
    required this.currentIndex,
    required this.child,
    this.duration = const Duration(milliseconds: 650),
    this.curve = Curves.easeInOutCubic,
  });

  /// The active navigation tab index (0 to 4).
  final int currentIndex;

  /// The foreground child (e.g. Navigation shell, Scaffold, etc.).
  final Widget child;

  /// Duration of the smooth transition between screen palettes.
  final Duration duration;

  /// Animation curve for the ambient light glide.
  final Curve curve;

  /// Predefined tab palettes conforming to Apple HIG.
  static const List<List<AmbientBlobSpec>> tabPalettes = [
    // 0: Overview (Jade / Mint / Amber)
    [
      AmbientBlobSpec(
        alignment: Alignment(0.80, -0.65),
        radiusFactor: 0.75,
        lightColor: Color(0xFF00A86B), // Jade Primary
        darkColor: Color(0xFF00C7BE),  // Mint Glow
      ),
      AmbientBlobSpec(
        alignment: Alignment(-0.70, 0.40),
        radiusFactor: 0.70,
        lightColor: Color(0xFF0EA5E9), // Sky Blue
        darkColor: Color(0xFF0284C7),  // Cobalt
      ),
      AmbientBlobSpec(
        alignment: Alignment(0.40, 0.85),
        radiusFactor: 0.60,
        lightColor: Color(0xFFF59E0B), // Warm Amber
        darkColor: Color(0xFFD97706),
      ),
    ],
    // 1: Transactions (Sapphire Blue / Indigo / Cyan)
    [
      AmbientBlobSpec(
        alignment: Alignment(-0.75, -0.60),
        radiusFactor: 0.75,
        lightColor: Color(0xFF007AFF), // System Blue
        darkColor: Color(0xFF2563EB),
      ),
      AmbientBlobSpec(
        alignment: Alignment(0.80, 0.35),
        radiusFactor: 0.70,
        lightColor: Color(0xFF5856D6), // System Indigo
        darkColor: Color(0xFF6366F1),
      ),
      AmbientBlobSpec(
        alignment: Alignment(-0.25, 0.85),
        radiusFactor: 0.55,
        lightColor: Color(0xFF38BDF8), // Cyan
        darkColor: Color(0xFF00C7BE),
      ),
    ],
    // 2: Budgets (Emerald Teal / Amber / Green)
    [
      AmbientBlobSpec(
        alignment: Alignment(0.10, -0.70),
        radiusFactor: 0.80,
        lightColor: Color(0xFF30B0C7), // System Teal
        darkColor: Color(0xFF0D9488),
      ),
      AmbientBlobSpec(
        alignment: Alignment(0.75, 0.55),
        radiusFactor: 0.65,
        lightColor: Color(0xFFFF9500), // System Orange
        darkColor: Color(0xFFD97706),
      ),
      AmbientBlobSpec(
        alignment: Alignment(-0.70, 0.25),
        radiusFactor: 0.60,
        lightColor: Color(0xFF34C759), // System Green
        darkColor: Color(0xFF10B981),
      ),
    ],
    // 3: Reports (Amethyst Purple / Rose / Indigo)
    [
      AmbientBlobSpec(
        alignment: Alignment(0.75, -0.65),
        radiusFactor: 0.75,
        lightColor: Color(0xFFAF52DE), // System Purple
        darkColor: Color(0xFF8B5CF6),
      ),
      AmbientBlobSpec(
        alignment: Alignment(-0.75, 0.45),
        radiusFactor: 0.65,
        lightColor: Color(0xFFFF2D55), // System Pink/Rose
        darkColor: Color(0xFFEC4899),
      ),
      AmbientBlobSpec(
        alignment: Alignment(0.15, 0.85),
        radiusFactor: 0.60,
        lightColor: Color(0xFF6366F1), // Indigo
        darkColor: Color(0xFF4F46E5),
      ),
    ],
    // 4: Settings (Cool Slate / Silver Zinc / Muted Sage)
    [
      AmbientBlobSpec(
        alignment: Alignment(-0.50, -0.70),
        radiusFactor: 0.70,
        lightColor: Color(0xFF64748B), // Slate
        darkColor: Color(0xFF475569),
      ),
      AmbientBlobSpec(
        alignment: Alignment(0.65, 0.45),
        radiusFactor: 0.65,
        lightColor: Color(0xFF94A3B8), // Cool Gray
        darkColor: Color(0xFF64748B),
      ),
      AmbientBlobSpec(
        alignment: Alignment(-0.20, 0.85),
        radiusFactor: 0.55,
        lightColor: Color(0xFF00A86B), // Muted Jade hint
        darkColor: Color(0xFF0284C7),
      ),
    ],
  ];

  @override
  State<AppleDynamicAmbientBackground> createState() =>
      _AppleDynamicAmbientBackgroundState();
}

class _AppleDynamicAmbientBackgroundState
    extends State<AppleDynamicAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  late List<AmbientBlobSpec> _currentPalette;
  late List<AmbientBlobSpec> _targetPalette;
  List<AmbientBlobSpec> _startPalette = const [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    final initialIndex = widget.currentIndex.clamp(0, AppleDynamicAmbientBackground.tabPalettes.length - 1);
    _currentPalette = AppleDynamicAmbientBackground.tabPalettes[initialIndex];
    _targetPalette = _currentPalette;
    _startPalette = _currentPalette;
  }

  @override
  void didUpdateWidget(covariant AppleDynamicAmbientBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      final newIndex = widget.currentIndex.clamp(0, AppleDynamicAmbientBackground.tabPalettes.length - 1);
      final newPalette = AppleDynamicAmbientBackground.tabPalettes[newIndex];

      // Interpolate current state as start state for smooth interruption
      final t = _animation.value;
      _startPalette = [
        for (int i = 0; i < _targetPalette.length; i++)
          AmbientBlobSpec(
            alignment: Alignment.lerp(
              _startPalette.length > i ? _startPalette[i].alignment : _targetPalette[i].alignment,
              _targetPalette[i].alignment,
              t,
            ) ?? _targetPalette[i].alignment,
            radiusFactor: ui.lerpDouble(
              _startPalette.length > i ? _startPalette[i].radiusFactor : _targetPalette[i].radiusFactor,
              _targetPalette[i].radiusFactor,
              t,
            ) ?? _targetPalette[i].radiusFactor,
            lightColor: Color.lerp(
              _startPalette.length > i ? _startPalette[i].lightColor : _targetPalette[i].lightColor,
              _targetPalette[i].lightColor,
              t,
            ) ?? _targetPalette[i].lightColor,
            darkColor: Color.lerp(
              _startPalette.length > i ? _startPalette[i].darkColor : _targetPalette[i].darkColor,
              _targetPalette[i].darkColor,
              t,
            ) ?? _targetPalette[i].darkColor,
          ),
      ];

      _targetPalette = newPalette;
      _controller.duration = widget.duration;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOled = context.isOled;

    final baseColor = isDark
        ? (isOled ? AppleTokens.bgOledPrimary : AppleTokens.bgDarkGrouped)
        : AppleTokens.bgLightGrouped;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _AmbientBackgroundPainter(
              startBlobs: _startPalette,
              targetBlobs: _targetPalette,
              progress: _animation.value,
              baseColor: baseColor,
              isDark: isDark,
              isOled: isOled,
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _AmbientBackgroundPainter extends CustomPainter {
  const _AmbientBackgroundPainter({
    required this.startBlobs,
    required this.targetBlobs,
    required this.progress,
    required this.baseColor,
    required this.isDark,
    required this.isOled,
  });

  final List<AmbientBlobSpec> startBlobs;
  final List<AmbientBlobSpec> targetBlobs;
  final double progress;
  final Color baseColor;
  final bool isDark;
  final bool isOled;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw solid foundation canvas
    final basePaint = Paint()..color = baseColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // In OLED True Black mode, keep absolute pitch black for pixel shutoff and battery savings
    if (isOled) return;

    // 2. Draw animated ambient orbs
    final maxDim = math.max(size.width, size.height);
    final count = math.min(startBlobs.length, targetBlobs.length);

    // Opacity calibrations: gentle, refined, anti-distraction
    final centerAlpha = isDark ? 0.095 : 0.058;
    final midAlpha = isDark ? 0.040 : 0.024;

    for (int i = 0; i < count; i++) {
      final s = startBlobs[i];
      final t = targetBlobs[i];

      final alignment = Alignment.lerp(s.alignment, t.alignment, progress)!;
      final radiusFactor = ui.lerpDouble(s.radiusFactor, t.radiusFactor, progress)!;
      final color = Color.lerp(s.resolveColor(isDark), t.resolveColor(isDark), progress)!;

      final center = Offset(
        (alignment.x + 1.0) / 2.0 * size.width,
        (alignment.y + 1.0) / 2.0 * size.height,
      );
      final radius = maxDim * radiusFactor;

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
  bool shouldRepaint(covariant _AmbientBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isOled != isOled ||
        oldDelegate.targetBlobs != targetBlobs ||
        oldDelegate.startBlobs != startBlobs;
  }
}

