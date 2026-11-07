// Lucian UX/UI Prompt #099 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#099
// Adapted for Flutter with smooth sweep animation, luminous gradient arc, and centered progress readout.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Lucian Labs Element #099: Activity Ring with dynamic luminous gradient arc.
///
/// Features:
/// - Smooth radial sweep animation using [LucianTokens.spring] curve.
/// - Rounded stroke caps with soft shadowed tip.
/// - Adaptive gradient arc supporting multiple stops.
/// - Optional centered child (e.g. icon or rolling percentage).
class LucianActivityRing extends StatefulWidget {
  const LucianActivityRing({
    super.key,
    required this.progress,
    this.size = 54.0,
    this.strokeWidth = 5.5,
    this.primaryColor,
    this.secondaryColor,
    this.backgroundColor,
    this.child,
    this.showGlow = false,
  });

  /// Progress fraction (`0.0` to `1.0` or higher).
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? backgroundColor;
  final Widget? child;
  final bool showGlow;

  @override
  State<LucianActivityRing> createState() => _LucianActivityRingState();
}

class _LucianActivityRingState extends State<LucianActivityRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  double _lastProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: LucianTokens.ease),
    );
    _controller.forward();
    _lastProgress = widget.progress;
  }

  @override
  void didUpdateWidget(covariant LucianActivityRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _animation = Tween<double>(
        begin: _lastProgress,
        end: widget.progress,
      ).animate(
        CurvedAnimation(parent: _controller, curve: LucianTokens.ease),
      );
      _controller.forward(from: 0.0);
      _lastProgress = widget.progress;
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

    final primary = widget.primaryColor ??
        (isDark ? LucianTokens.accentDark : LucianTokens.accentLight);
    final secondary = widget.secondaryColor ??
        (isDark ? LucianTokens.mintDark : LucianTokens.mintLight);
    final trackColor = widget.backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06));

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _LucianRingPainter(
                    progress: _animation.value,
                    strokeWidth: widget.strokeWidth,
                    primaryColor: primary,
                    secondaryColor: secondary,
                    backgroundColor: trackColor,
                    showGlow: widget.showGlow,
                  ),
                );
              },
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _LucianRingPainter extends CustomPainter {
  _LucianRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.showGlow,
  });

  final double progress;
  final double strokeWidth;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final bool showGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    final trackPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.001) return;

    final clampedProgress = progress.clamp(0.0, 1.0);
    final sweepAngle = 2 * math.pi * clampedProgress;
    const startAngle = -math.pi / 2;

    // Glow shadow if requested
    if (showGlow) {
      final glowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.35)
        ..strokeWidth = strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );
    }

    // Active Gradient Arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: 2 * math.pi,
      colors: [primaryColor, secondaryColor, primaryColor],
      transform: const GradientRotation(-math.pi / 2),
    );

    final arcPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _LucianRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.showGlow != showGlow;
  }
}

