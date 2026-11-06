// Lucian UX/UI Prompt #039 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#039
// Adapted for Flutter with spring physics, tactile haptics, and count badges.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Item descriptor for [LucianSlidingPillTabs].
class LucianTabItem<T> {
  const LucianTabItem({
    required this.value,
    required this.label,
    this.icon,
    this.badgeCount,
    this.badgeText,
    this.activeColor,
  });

  final T value;
  final String label;
  final IconData? icon;
  final int? badgeCount;
  final String? badgeText;
  final Color? activeColor;
}

/// Lucian Labs Element #039: Sliding Pill Tabs.
///
/// Features:
/// - Stretchy gliding pill indicator driven by [LucianTokens.spring] curve.
/// - Tactile haptic tick on tab selection.
/// - Integrated badge counts and optional icons.
/// - Adaptive light/dark styling with elevation and subtle inner glow.
class LucianSlidingPillTabs<T> extends StatefulWidget {
  const LucianSlidingPillTabs({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.height = 42.0,
    this.padding = const EdgeInsets.all(4.0),
    this.backgroundColor,
    this.pillColor,
    this.textStyle,
    this.selectedTextStyle,
  });

  final List<LucianTabItem<T>> items;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final Color? pillColor;
  final TextStyle? textStyle;
  final TextStyle? selectedTextStyle;

  @override
  State<LucianSlidingPillTabs<T>> createState() =>
      _LucianSlidingPillTabsState<T>();
}

class _LucianSlidingPillTabsState<T> extends State<LucianSlidingPillTabs<T>> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = widget.backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05));

    final pillBg = widget.pillColor ??
        (isDark
            ? theme.colorScheme.surface
            : Colors.white);

    final selectedIndex = widget.items.indexWhere(
      (item) => item.value == widget.selected,
    );
    final safeIndex = selectedIndex >= 0 ? selectedIndex : 0;
    final total = widget.items.length;

    return Container(
      height: widget.height + widget.padding.vertical,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
          width: 0.5,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / total;

          return Stack(
            children: [
              // Sliding Pill Indicator
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: LucianTokens.ease,
                left: safeIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Tab Buttons
              Row(
                children: [
                  for (var i = 0; i < widget.items.length; i++)
                    Expanded(
                      child: _buildTabButton(
                        item: widget.items[i],
                        isSelected: i == safeIndex,
                        isDark: isDark,
                        theme: theme,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabButton({
    required LucianTabItem<T> item,
    required bool isSelected,
    required bool isDark,
    required ThemeData theme,
  }) {
    final activeTextColor = item.activeColor ??
        (isDark ? Colors.white : theme.colorScheme.onSurface);
    final inactiveTextColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.5);

    return InkWell(
      onTap: () {
        if (!isSelected) {
          HapticFeedback.selectionClick();
          widget.onChanged(item.value);
        }
      },
      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          curve: LucianTokens.ease,
          style: (isSelected
                  ? (widget.selectedTextStyle ??
                      theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ))
                  : (widget.textStyle ??
                      theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5,
                      )))
                  ?.copyWith(
                    color: isSelected ? activeTextColor : inactiveTextColor,
                  ) ??
              TextStyle(
                color: isSelected ? activeTextColor : inactiveTextColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13.5,
              ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  size: 16,
                  color: isSelected ? activeTextColor : inactiveTextColor,
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.badgeCount != null && item.badgeCount! > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (item.activeColor?.withValues(alpha: 0.15) ??
                            theme.colorScheme.primary.withValues(alpha: 0.15))
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${item.badgeCount}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? (item.activeColor ?? theme.colorScheme.primary)
                          : inactiveTextColor,
                    ),
                  ),
                ),
              ] else if (item.badgeText != null && item.badgeText!.isNotEmpty) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (item.activeColor?.withValues(alpha: 0.15) ??
                            theme.colorScheme.primary.withValues(alpha: 0.15))
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.badgeText!,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? (item.activeColor ?? theme.colorScheme.primary)
                          : inactiveTextColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

