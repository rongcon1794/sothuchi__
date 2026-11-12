import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Accessible, balanced grid icon and color selector meeting >= 48x48dp touch targets.
/// Enhanced with group filter pills, symmetrical responsive grids, and squircle glow.
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
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final colorCols = constraints.maxWidth >= 580 ? 14 : 7;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: AppIconCatalog.palette.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: colorCols,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final colorValue = AppIconCatalog.palette[index];
                final isSelected = colorValue == widget.selectedColor;
                final color = AppIconCatalog.contrastSafeColor(
                  Color(colorValue),
                  theme.brightness,
                );
                final checkColor =
                    ThemeData.estimateBrightnessForColor(color) ==
                            Brightness.dark
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
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: isSelected ? 36 : 30,
                        height: isSelected ? 36 : 30,
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
                                size: 17,
                                color: checkColor,
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 18),
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
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final iconCols = (constraints.maxWidth / 58).floor().clamp(5, 10);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: visibleKeys.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: iconCols,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final key = visibleKeys[index];
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
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor.withValues(
                                alpha: isDark ? 0.28 : 0.16,
                              )
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
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        AppIconCatalog.resolve(key),
                        color: isSelected
                            ? activeColor
                            : scheme.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
