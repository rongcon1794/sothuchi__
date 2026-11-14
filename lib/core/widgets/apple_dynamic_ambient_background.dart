import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Global notifier provider for the active ambient background palette index (0..4).
/// Allows any sub-screen or route to smoothly synchronize ambient lights without rebuild glitches.
final ambientBackgroundIndexProvider = NotifierProvider<AmbientBackgroundIndexNotifier, int>(
  AmbientBackgroundIndexNotifier.new,
);

class AmbientBackgroundIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    final clamped = index.clamp(0, AppleDynamicAmbientBackground.tabPalettes.length - 1);
    if (state != clamped) {
      state = clamped;
    }
  }
}

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

/// Inherited scope providing the active ambient palette index down the widget tree.
class AppleAmbientTheme extends InheritedWidget {
  const AppleAmbientTheme({
    super.key,
    required this.paletteIndex,
    required super.child,
  });

  final int paletteIndex;

  /// Retrieves the ambient palette index from the nearest ancestor, defaulting to 0.
  static int of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppleAmbientTheme>();
    return scope?.paletteIndex ?? 0;
  }

  @override
  bool updateShouldNotify(AppleAmbientTheme oldWidget) {
    return paletteIndex != oldWidget.paletteIndex;
  }
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
    this.duration = const Duration(milliseconds: 320),
    this.curve = Curves.easeOutCubic,
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
    // 0: Overview (Soft Jade Mint / Soft Morning Sky / Warm Honey Amber)
    [
      AmbientBlobSpec(
        alignment: Alignment(0.80, -0.65),
        radiusFactor: 0.85,
        lightColor: Color(0xFF34D399), // Soft Mint Emerald
        darkColor: Color(0xFF059669),
      ),
      AmbientBlobSpec(
        alignment: Alignment(-0.75, 0.35),
        radiusFactor: 0.80,
        lightColor: Color(0xFF38BDF8), // Soft Sky Azure
        darkColor: Color(0xFF0284C7),
      ),
      AmbientBlobSpec(
        alignment: Alignment(0.40, 0.85),
        radiusFactor: 0.70,
        lightColor: Color(0xFFFBBF24), // Warm Honey Amber
        darkColor: Color(0xFFD97706),
      ),
    ],
    // 1: Transactions (Soft Ocean Blue / Soft Lavender Violet / Soft Aqua)
    [
      AmbientBlobSpec(
        alignment: Alignment(-0.80, -0.60),
        radiusFactor: 0.85,
        lightColor: Color(0xFF60A5FA), // Soft Ocean Blue
        darkColor: Color(0xFF2563EB),
      ),
      AmbientBlobSpec(
        alignment: Alignment(0.80, 0.35),
        radiusFactor: 0.80,
        lightColor: Color(0xFF818CF8), // Soft Lavender Violet
        darkColor: Color(0xFF4F46E5),
      ),
      AmbientBlobSpec(
        alignment: Alignment(-0.25, 0.85),
        radiusFactor: 0.65,
        lightColor: Color(0xFF38BDF8), // Soft Aqua Ice
        darkColor: Color(0xFF0D9488),
      ),
    ],
    // 2: Budgets (Soft Seafoam Teal / Soft Apricot / Soft Spring Sage)
    [
      AmbientBlobSpec(
        alignment: Alignment(0.10, -0.70),
        radiusFactor: 0.85,
        lightColor: Color(0xFF2DD4BF), // Soft Seafoam Teal
        darkColor: Color(0xFF0D9488),
      ),
      AmbientBlobSpec(
        alignment: Alignment(0.80, 0.50),
        radiusFactor: 0.75,
        lightColor: Color(0xFFFB923C), // Soft Apricot
        darkColor: Color(0xFFD97706),
      ),
      AmbientBlobSpec(
        alignment: Alignment(-0.75, 0.25),
        radiusFactor: 0.70,
        lightColor: Color(0xFF4ADE80), // Soft Spring Leaf
        darkColor: Color(0xFF10B981),
      ),
    ],
    // 3: Reports (Soft Lilac / Soft Blush Rose / Muted Indigo)
    [
      AmbientBlobSpec(
        alignment: Alignment(0.80, -0.65),
        radiusFactor: 0.85,
        lightColor: Color(0xFFA78BFA), // Soft Lilac Violet
        darkColor: Color(0xFF7C3AED),
      ),
      AmbientBlobSpec(
        alignment: Alignment(-0.80, 0.40),
        radiusFactor: 0.75,
        lightColor: Color(0xFFFB7185), // Soft Blush Rose
        darkColor: Color(0xFFE11D48),
      ),
      AmbientBlobSpec(
        alignment: Alignment(0.20, 0.85),
        radiusFactor: 0.70,
        lightColor: Color(0xFF818CF8), // Muted Royal Blue
        darkColor: Color(0xFF4338CA),
      ),
    ],
    // 4: Settings (Soft Slate Violet / Soft Powder Blue / Soft Mineral Sage)
    [
      AmbientBlobSpec(
        alignment: Alignment(-0.60, -0.70),
        radiusFactor: 0.80,
        lightColor: Color(0xFF818CF8), // Soft Slate Violet
        darkColor: Color(0xFF4F46E5),
      ),
      AmbientBlobSpec(
        alignment: Alignment(0.75, 0.40),
        radiusFactor: 0.75,
        lightColor: Color(0xFF38BDF8), // Soft Powder Blue
        darkColor: Color(0xFF0284C7),
      ),
      AmbientBlobSpec(
        alignment: Alignment(-0.20, 0.85),
        radiusFactor: 0.65,
        lightColor: Color(0xFF94A3B8), // Soft Mineral Sage
        darkColor: Color(0xFF64748B),
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

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, _) {
              return CustomPaint(
                painter: _AmbientBackgroundPainter(
                  startBlobs: _startPalette,
                  targetBlobs: _targetPalette,
                  progress: _animation.value,
                  baseColor: baseColor,
                  isDark: isDark,
                  isOled: isOled,
                ),
              );
            },
          ),
        ),
        AppleAmbientTheme(
          paletteIndex: widget.currentIndex,
          child: widget.child,
        ),
      ],
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

    // 2. Subtle directional gradient wash for vertical depth
    final topTint = isDark
        ? const Color(0xFF0F111C).withValues(alpha: 0.35)
        : Colors.white.withValues(alpha: 0.40);
    final bottomTint = isDark
        ? const Color(0xFF040508).withValues(alpha: 0.40)
        : const Color(0xFFECE9E2).withValues(alpha: 0.30);

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

    // 3. Draw animated ambient orbs
    final maxDim = math.max(size.width, size.height);
    final count = math.min(startBlobs.length, targetBlobs.length);

    // Harmonious, gentle, non-distracting ambient opacity
    final centerAlpha = isDark ? 0.085 : 0.055;
    final midAlpha = isDark ? 0.038 : 0.024;

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

