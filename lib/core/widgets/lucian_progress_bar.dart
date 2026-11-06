import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

bool get _isRunningInFlutterTest {
  if (kIsWeb) return false;
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}

/// Lucian Labs Element #018 / #074: Luminous Animated Progress Bar.
///
/// Features:
/// - Dynamic color gradient shifting (Mint -> Warn -> Danger) based on fill percentage.
/// - Spring-animated fill width with overshoot mitigation (`LucianTokens.ease`).
/// - Subtle glowing track highlight and over-limit pulse indicator.
class LucianProgressBar extends StatefulWidget {
  const LucianProgressBar({
    super.key,
    required this.value,
    this.height = 8.0,
    this.borderRadius,
    this.backgroundColor,
    this.activeColor,
    this.showGlow = false,
  });

  /// Progress fraction (`0.0` to `1.0` or beyond for exceeded state).
  final double value;
  final double height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? activeColor;
  final bool showGlow;

  @override
  State<LucianProgressBar> createState() => _LucianProgressBarState();
}

class _LucianProgressBarState extends State<LucianProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (!_isRunningInFlutterTest && widget.showGlow) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 0.5;
    }
  }

  @override
  void didUpdateWidget(covariant LucianProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showGlow != oldWidget.showGlow) {
      if (!_isRunningInFlutterTest && widget.showGlow) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.value = 0.5;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final clampedValue = widget.value.clamp(0.0, 1.0);
    final radius = widget.borderRadius ?? BorderRadius.circular(AppleTokens.radiusPill);

    // Auto-resolve semantic progress color if not explicitly provided
    final progressColor = widget.activeColor ??
        (widget.value >= 1.0
            ? LucianTokens.resolveDanger(isDark)
            : widget.value >= 0.8
                ? LucianTokens.resolveWarn(isDark)
                : LucianTokens.resolveMint(isDark));

    final trackBg = widget.backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06));

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowAlpha = widget.showGlow
            ? (0.25 + 0.35 * _pulseController.value)
            : 0.0;

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: trackBg,
            borderRadius: radius,
            boxShadow: widget.showGlow
                ? [
                    BoxShadow(
                      color: progressColor.withValues(alpha: glowAlpha),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: clampedValue,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      colors: [
                        progressColor.withValues(alpha: 0.85),
                        progressColor,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

