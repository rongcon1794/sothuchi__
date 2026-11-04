import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

export 'package:flutter/rendering.dart' show ScrollDirection;
export 'package:flutter/widgets.dart' show UserScrollNotification;

/// Apple-grade Adaptive Expandable/Collapsible Floating Action Button.
///
/// Anchored securely at the ergonomic thumb zone.
/// - At rest / scrolling up / top of screen: Expands smoothly to show [icon] + [label].
/// - When scrolling down: Collapses seamlessly to a compact 50x50 icon button,
///   reducing horizontal footprint by >65% so it NEVER covers underlying list content!
/// - Interactive with Apple tactile spring haptics (`ApplePressable`).
class AppleAdaptiveExpandableFab extends StatelessWidget {
  const AppleAdaptiveExpandableFab({
    super.key,
    required this.isExpanded,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isVisible = true,
    this.heroTag,
    this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.duration = const Duration(milliseconds: 240),
    this.curve = Curves.easeInOutCubic,
    this.tooltip,
  });

  final bool isExpanded;
  final bool isVisible;
  final Widget icon;
  final Widget label;
  final VoidCallback onPressed;
  final Object? heroTag;
  final Color? backgroundColor;
  final Color foregroundColor;
  final Duration duration;
  final Curve curve;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = backgroundColor ?? AppleTokens.jadePrimary;

    final content = ApplePressable(
      scaleDown: 0.94,
      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
      onTap: onPressed,
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        height: 50,
        constraints: const BoxConstraints(minWidth: 50),
        padding: EdgeInsets.symmetric(
          horizontal: isExpanded ? 18 : 13,
          vertical: 0,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    bg,
                    Color.lerp(bg, Colors.black, 0.3)!,
                  ]
                : [
                    Color.lerp(bg, Colors.white, 0.15)!,
                    bg,
                  ],
          ),
          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.22 : 0.45),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: isDark ? 0.45 : 0.38),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(
                color: foregroundColor,
                size: 22,
              ),
              child: icon,
            ),
            ClipRect(
              child: AnimatedAlign(
                duration: duration,
                curve: curve,
                alignment: Alignment.centerLeft,
                widthFactor: isExpanded ? 1.0 : 0.0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: isExpanded ? 1.0 : 0.0,
                  curve: Curves.easeIn,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: DefaultTextStyle(
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: theme.textTheme.labelLarge!.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        fontSize: 14.5,
                      ),
                      child: label,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final fabBody = AnimatedSlide(
      offset: isVisible ? Offset.zero : const Offset(0, 1.6),
      duration: duration,
      curve: isVisible ? Curves.easeOutBack : Curves.easeInOutCubic,
      child: AnimatedScale(
        scale: isVisible ? 1.0 : 0.75,
        duration: duration,
        curve: isVisible ? Curves.easeOutBack : Curves.easeInOutCubic,
        child: AnimatedOpacity(
          opacity: isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          child: IgnorePointer(
            ignoring: !isVisible,
            child: content,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: fabBody,
      );
    }
    return fabBody;
  }
}
