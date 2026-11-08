import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

enum AppleButtonVariant {
  primary,
  secondary,
  outline,
  destructive,
}

/// Unified Apple HIG button component delivering spring tactile interaction,
/// built-in loading state, and standardized styling across the entire app.
class AppleButton extends StatelessWidget {
  const AppleButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = AppleButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
    this.borderRadius,
    this.color,
    this.textColor,
    this.padding,
  });

  const AppleButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
    this.borderRadius,
    this.color,
    this.textColor,
    this.padding,
  }) : variant = AppleButtonVariant.primary;

  const AppleButton.secondary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
    this.borderRadius,
    this.color,
    this.textColor,
    this.padding,
  }) : variant = AppleButtonVariant.secondary;

  const AppleButton.outline({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
    this.borderRadius,
    this.color,
    this.textColor,
    this.padding,
  }) : variant = AppleButtonVariant.outline;

  const AppleButton.destructive({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
    this.borderRadius,
    this.color,
    this.textColor,
    this.padding,
  }) : variant = AppleButtonVariant.destructive;

  final dynamic label; // String or Widget
  final dynamic icon; // IconData or Widget
  final VoidCallback? onPressed;
  final AppleButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final BorderRadius? borderRadius;
  final Color? color;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = onPressed != null && !isLoading;
    final radius = borderRadius ?? BorderRadius.circular(AppleTokens.radiusControl);

    Color bg;
    Color fg;
    Border? border;

    switch (variant) {
      case AppleButtonVariant.primary:
        bg = color ?? theme.colorScheme.primary;
        fg = textColor ?? Colors.white;
        border = null;
        break;
      case AppleButtonVariant.secondary:
        bg = color ??
            (isDark
                ? (context.isOled
                    ? AppleTokens.bgOledSecondary
                    : AppleTokens.bgDarkSecondary)
                : AppleTokens.bgLightSecondary);
        fg = textColor ?? (isDark ? Colors.white : Colors.black87);
        border = Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: AppleTokens.hairline,
        );
        break;
      case AppleButtonVariant.outline:
        bg = color ?? Colors.transparent;
        fg = textColor ?? (isDark ? Colors.white : theme.colorScheme.primary);
        border = Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.22)
              : theme.colorScheme.primary.withValues(alpha: 0.35),
          width: 1.0,
        );
        break;
      case AppleButtonVariant.destructive:
        bg = color ?? AppleTokens.systemRed.withValues(alpha: isDark ? 0.2 : 0.12);
        fg = textColor ?? AppleTokens.systemRed;
        border = Border.all(
          color: AppleTokens.systemRed.withValues(alpha: isDark ? 0.35 : 0.25),
          width: AppleTokens.hairline,
        );
        break;
    }

    if (!isEnabled) {
      bg = bg.withValues(alpha: 0.4);
      fg = fg.withValues(alpha: 0.5);
    }

    Widget labelWidget;
    if (label is Widget) {
      labelWidget = label as Widget;
    } else {
      labelWidget = Text(
        label.toString(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: -0.2,
        ),
      );
    }

    Widget content;
    if (isLoading) {
      content = KeyedSubtree(
        key: const ValueKey('apple_btn_loading'),
        child: CupertinoActivityIndicator(
          color: fg,
          radius: 9,
        ),
      );
    } else if (icon != null) {
      Widget iconWidget;
      if (icon is IconData) {
        iconWidget = Icon(icon as IconData, size: 18, color: fg);
      } else {
        iconWidget = icon as Widget;
      }
      content = KeyedSubtree(
        key: const ValueKey('apple_btn_icon_label'),
        child: Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 8),
            Flexible(child: labelWidget),
          ],
        ),
      );
    } else {
      content = KeyedSubtree(
        key: const ValueKey('apple_btn_label'),
        child: labelWidget,
      );
    }

    final animatedContent = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: content,
    );

    Widget button = Container(
      height: height,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: border,
        boxShadow: variant == AppleButtonVariant.primary && isEnabled
            ? [
                BoxShadow(
                  color: bg.withValues(alpha: isDark ? 0.28 : 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: animatedContent,
    );

    if (isFullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return ApplePressable(
      onTap: isEnabled
          ? () {
              HapticFeedback.lightImpact();
              onPressed!();
            }
          : null,
      scaleDown: 0.97,
      borderRadius: radius,
      child: button,
    );
  }
}
