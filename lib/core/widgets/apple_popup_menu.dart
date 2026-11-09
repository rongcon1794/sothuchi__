import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Signature Apple HIG Popup Menu Button and Items.
/// Delivers frosted glass surface, subtle hairline border, soft drop shadow,
/// consistent 42dp item height, aligned iconography, and destructive red styling.
class ApplePopupMenuButton<T> extends StatelessWidget {
  const ApplePopupMenuButton({
    super.key,
    required this.itemBuilder,
    this.onSelected,
    this.tooltip,
    this.icon,
    this.iconSize = 16,
    this.iconColor,
    this.backgroundColor,
    this.size = 32,
    this.child,
    this.elevation = 10,
    this.padding = EdgeInsets.zero,
  });

  final PopupMenuItemBuilder<T> itemBuilder;
  final PopupMenuItemSelected<T>? onSelected;
  final String? tooltip;
  final IconData? icon;
  final double iconSize;
  final Color? iconColor;
  final Color? backgroundColor;
  final double size;
  final Widget? child;
  final double elevation;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04));

    final trigger = child ??
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: defaultBg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            icon ?? CupertinoIcons.ellipsis,
            size: iconSize,
            color: iconColor ?? AppleTokens.systemGray,
          ),
        );

    return PopupMenuButton<T>(
      tooltip: tooltip,
      onOpened: () => HapticFeedback.lightImpact(),
      onSelected: onSelected,
      itemBuilder: itemBuilder,
      padding: padding,
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 260),
      elevation: elevation,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.6 : 0.18),
      color: isDark ? AppleTokens.bgDarkCard : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        side: BorderSide(
          color: isDark
              ? AppleTokens.separatorDark
              : AppleTokens.separatorLight,
          width: AppleTokens.hairline,
        ),
      ),
      child: trigger,
    );
  }
}

/// Refined Apple-style popup menu item with aligned icons, typography, and destructive styling.
class ApplePopupMenuItem<T> extends PopupMenuItem<T> {
  ApplePopupMenuItem({
    super.key,
    super.value,
    super.onTap,
    super.enabled = true,
    IconData? icon,
    Widget? iconWidget,
    required String title,
    bool isDestructive = false,
    Widget? trailing,
  }) : super(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final textColor = isDestructive
                  ? AppleTokens.rubyExpense
                  : (isDark ? Colors.white : Colors.black87);
              final iconColor = isDestructive
                  ? AppleTokens.rubyExpense
                  : (isDark ? Colors.white70 : AppleTokens.systemGray);

              return Row(
                children: [
                  if (iconWidget != null) ...[
                    iconWidget,
                    const SizedBox(width: 10),
                  ] else if (icon != null) ...[
                    Icon(icon, size: 18, color: iconColor),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing,
                  ],
                ],
              );
            },
          ),
        );
}

/// Hairline separator for Apple popup menus.
class ApplePopupMenuDivider extends PopupMenuEntry<Never> {
  const ApplePopupMenuDivider({super.key});

  @override
  final double height = 1;

  @override
  bool represents(void value) => false;

  @override
  State<ApplePopupMenuDivider> createState() => _ApplePopupMenuDividerState();
}

class _ApplePopupMenuDividerState extends State<ApplePopupMenuDivider> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      thickness: AppleTokens.hairline,
      color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
    );
  }
}
