import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Accessible icon and color selector meeting >= 48x48dp touch target standards.
/// Enhanced with group filter pills, Lucian tactile bouncy rings, and squircle glow.
class IconAndColorPicker extends StatefulWidget {
  const IconAndColorPicker({
    required this.selectedIcon,
    required this.selectedColor,
    required this.onIconChanged,
    required this.onColorChanged,
    required this.iconSectionLabel,
    required this.colorSectionLabel,
    super.key,
  });

  final String selectedIcon;
  final int selectedColor;
  final ValueChanged<String> onIconChanged;
  final ValueChanged<int> onColorChanged;
  final String iconSectionLabel;
  final String colorSectionLabel;

  @override
  State<IconAndColorPicker> createState() => _IconAndColorPickerState();
}

class _IconAndColorPickerState extends State<IconAndColorPicker> {
  AppIconGroup _selectedGroup = AppIconGroup.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isVi = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('vi');
    final activeColor = AppIconCatalog.contrastSafeColor(
      Color(widget.selectedColor),
      theme.brightness,
    );
    final activeChipTextColor =
        ThemeData.estimateBrightnessForColor(activeColor) == Brightness.dark
            ? Colors.white
            : Colors.black87;
    final visibleKeys = AppIconCatalog.keysForGroup(_selectedGroup);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.colorSectionLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppIconCatalog.palette.map((colorValue) {
            final isSelected = colorValue == widget.selectedColor;
            final color = AppIconCatalog.contrastSafeColor(
              Color(colorValue),
              theme.brightness,
            );
            final checkColor =
                ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                ? Colors.white
                : Colors.black87;
            final readableColor = AppIconCatalog.colorAccessibilityLabel(
              colorValue,
              isVi: isVi,
            );
            return Semantics(
              button: true,
              selected: isSelected,
              excludeSemantics: true,
              label: '${widget.colorSectionLabel}: $readableColor',
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => widget.onColorChanged(colorValue),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: isSelected ? 38 : 32,
                      height: isSelected ? 38 : 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2.5)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.55),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: checkColor,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                widget.iconSectionLabel,
                style: theme.textTheme.labelLarge,
              ),
            ),
            Text(
              '${visibleKeys.length} icon',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: AppIconGroup.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final group = AppIconGroup.values[index];
              final isActive = group == _selectedGroup;
              return GestureDetector(
                onTap: () {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _selectedGroup = group);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive
                        ? activeColor
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    border: Border.all(
                      color: isActive
                          ? activeColor
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06)),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    AppIconCatalog.groupLabel(group, isVi: isVi),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? activeChipTextColor
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: visibleKeys.map((key) {
            final isSelected = key == widget.selectedIcon;
            final readableIcon = AppIconCatalog.iconAccessibilityLabel(
              key,
              isVi: isVi,
            );
            return Semantics(
              button: true,
              selected: isSelected,
              excludeSemantics: true,
              label: '${widget.iconSectionLabel}: $readableIcon',
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => widget.onIconChanged(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withValues(alpha: isDark ? 0.28 : 0.16)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? activeColor
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06)),
                      width: isSelected ? 2.0 : 0.8,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    AppIconCatalog.resolve(key),
                    color: isSelected ? activeColor : scheme.onSurfaceVariant,
                    size: 22,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
