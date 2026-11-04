import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

/// Lightweight, high-performance solid card conforming to Apple HIG.
/// Provides standardized radius, surface styling, and optional pressable feedback
/// without the GPU overhead of BackdropFilter blur shaders.
class AppleCard extends StatelessWidget {
  const AppleCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.boxShadow,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(AppleTokens.radiusCard);

    final bg = backgroundColor ??
        (isDark ? AppleTokens.bgDarkCard : AppleTokens.bgLightCard);

    final border = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.1)
            : AppleTokens.borderLight);

    final shadow = boxShadow ??
        (isDark ? AppleTokens.cardShadowDark : AppleTokens.cardShadowLight);

    final Widget card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? bg : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(color: border, width: AppleTokens.hairline),
        boxShadow: shadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );

    if (onTap != null) {
      return ApplePressable(
        onTap: onTap,
        scaleDown: 0.98,
        borderRadius: radius,
        child: card,
      );
    }

    return card;
  }
}
