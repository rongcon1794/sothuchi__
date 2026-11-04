import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Tactile bounce wrapper delivering the signature Apple spring-press interaction.
/// Scales slightly down (`scale: 0.97`) on tap-down and triggers subtle haptics.
class ApplePressable extends StatefulWidget {
  const ApplePressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.965,
    this.enableHaptics = true,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final bool enableHaptics;
  final BorderRadius? borderRadius;

  @override
  State<ApplePressable> createState() => _ApplePressableState();
}

class _ApplePressableState extends State<ApplePressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    _controller.forward();
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(AppleTokens.radiusCard);

    return MouseRegion(
      cursor: (widget.onTap != null || widget.onLongPress != null)
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: ClipRRect(
            borderRadius: effectiveBorderRadius,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Translucent frosted-glass card inspired by Apple VisionOS & iOS 18 Design.
class AppleGlassCard extends StatelessWidget {
  const AppleGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blurSigma = 18.0,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(AppleTokens.radiusCard);
    final bg = backgroundColor ??
        (isDark
            ? AppleTokens.bgDarkCard.withValues(alpha: 0.85)
            : AppleTokens.bgLightCard.withValues(alpha: 0.88));
    final border = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05));
    final shadow = boxShadow ??
        (isDark ? AppleTokens.cardShadowDark : AppleTokens.cardShadowLight);

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gradient == null ? bg : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.all(color: border, width: AppleTokens.hairline),
      ),
      child: child,
    );

    if (blurSigma > 0) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        ),
      );
    } else {
      content = ClipRRect(borderRadius: radius, child: content);
    }

    if (margin != null || shadow.isNotEmpty) {
      content = Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: shadow,
        ),
        child: content,
      );
    }

    return content;
  }
}

/// Inset Grouped Section (Apple Settings / Apple Health standard).
class AppleListGroup extends StatelessWidget {
  const AppleListGroup({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.margin = const EdgeInsets.only(bottom: 24),
  });

  final List<Widget> children;
  final String? header;
  final String? footer;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                header!.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6C6C70),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          AppleGlassCard(
            padding: EdgeInsets.zero,
            blurSigma: 0,
            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: AppleTokens.hairline,
                      thickness: AppleTokens.hairline,
                      indent: 56,
                      color: isDark
                          ? AppleTokens.separatorDark
                          : AppleTokens.separatorLight,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
          if (footer != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                footer!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6C6C70),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Squircle Badge Icon for Apple List Tiles & Category Icons.
class AppleSquircleBadge extends StatelessWidget {
  const AppleSquircleBadge({
    super.key,
    required this.icon,
    this.backgroundColor = AppleTokens.systemBlue,
    this.color,
    this.iconColor = Colors.white,
    this.size = 32.0,
    this.iconSize = 18.0,
    this.radius = 8.0,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color? color;
  final Color iconColor;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? backgroundColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}

/// Apple Settings-style Row / Tile with haptic tap feedback.
class AppleListTile extends StatelessWidget {
  const AppleListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6C6C70),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
            if (showChevron && onTap != null) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark
                    ? const Color(0xFF545458)
                    : const Color(0xFFC7C7CC),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// iOS 17 Sliding Segmented Pill Switch with Spring Animation.
class AppleSegmentedPill<T> extends StatelessWidget {
  const AppleSegmentedPill({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.height = 36.0,
  });

  final Map<T, String> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keys = segments.keys.toList();

    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? AppleTokens.bgDarkSecondary
            : AppleTokens.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
      ),
      child: Row(
        children: [
          for (final key in keys)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (key != selected) {
                    HapticFeedback.selectionClick();
                    onChanged(key);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: key == selected
                        ? (isDark ? AppleTokens.bgDarkCard : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    boxShadow: key == selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    segments[key]!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          key == selected ? FontWeight.w600 : FontWeight.w400,
                      color: key == selected
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6C6C70)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Standard Apple HIG floating action button location.
/// Positions the FAB at the bottom trailing edge with standard Apple 16px margins,
/// and automatically lifts above keyboard insets.
class AppleFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const AppleFloatingActionButtonLocation({this.offsetFromBottom = 16.0});

  final double offsetFromBottom;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX;
    if (scaffoldGeometry.textDirection == TextDirection.rtl) {
      fabX = 16.0;
    } else {
      fabX = scaffoldGeometry.scaffoldSize.width -
          scaffoldGeometry.floatingActionButtonSize.width -
          16.0;
    }

    final double keyboardInset = scaffoldGeometry.minInsets.bottom;
    final double bottomOffset = keyboardInset > 0
        ? keyboardInset + 16.0
        : offsetFromBottom;

    final double fabY = scaffoldGeometry.scaffoldSize.height -
        scaffoldGeometry.floatingActionButtonSize.height -
        bottomOffset;

    return Offset(fabX, fabY);
  }
}


