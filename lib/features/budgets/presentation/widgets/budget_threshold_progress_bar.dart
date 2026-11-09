import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// An Apple-style animated progress bar featuring a visual threshold notch marker
/// and luminous gradient track for budget monitoring.
class BudgetThresholdProgressBar extends StatelessWidget {
  const BudgetThresholdProgressBar({
    super.key,
    required this.progress,
    required this.threshold,
    required this.activeColor,
    this.secondaryColor,
    this.height = 10.0,
    this.showGlow = false,
  });

  /// The spending ratio (0.0 to 1.0 or higher).
  final double progress;

  /// The alert threshold ratio (e.g. 0.8 for 80%).
  final double threshold;

  /// The primary tint of the active progress bar.
  final Color activeColor;

  /// Optional gradient secondary color.
  final Color? secondaryColor;

  /// Track thickness in dp.
  final double height;

  /// Whether to render a soft ambient glow (e.g. when warning or exceeded).
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final clampedRatio = progress.clamp(0.0, 1.0);
    final clampedThreshold = threshold.clamp(0.05, 0.95);

    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final endColor = secondaryColor ??
        (progress >= 1.0
            ? AppleTokens.systemRed
            : (progress >= threshold
                ? AppleTokens.systemOrange
                : activeColor.withValues(alpha: 0.85)));

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final thresholdX = totalWidth * clampedThreshold;

        return SizedBox(
          height: height + 6,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              // Ambient glow behind the active bar
              if (showGlow)
                Positioned(
                  left: 0,
                  top: 3,
                  width: totalWidth * clampedRatio,
                  height: height,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(height / 2),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.45),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),

              // Background track
              Container(
                height: height,
                width: totalWidth,
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),

              // Active animated fill
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                widthFactor: clampedRatio,
                heightFactor: 1.0,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height / 2),
                    gradient: LinearGradient(
                      colors: [activeColor, endColor],
                    ),
                  ),
                ),
              ),

              // Alert Threshold vertical marker line
              Positioned(
                left: thresholdX - 1,
                top: 0,
                bottom: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 2,
                      height: height + 6,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
