import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';

/// Accessible icon and color selector meeting >= 48x48dp touch target standards.
/// Enhanced with Lucian tactile bouncy rings and atmospheric squircle glow.
class IconAndColorPicker extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isVi = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase().startsWith('vi');
    final activeColor = AppIconCatalog.contrastSafeColor(
      Color(selectedColor),
      theme.brightness,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(colorSectionLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppIconCatalog.palette.map((colorValue) {
            final isSelected = colorValue == selectedColor;
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
              label: '$colorSectionLabel: $readableColor',
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => onColorChanged(colorValue),
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
        Text(iconSectionLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppIconCatalog.keys.map((key) {
            final isSelected = key == selectedIcon;
            final readableIcon = AppIconCatalog.iconAccessibilityLabel(
              key,
              isVi: isVi,
            );
            return Semantics(
              button: true,
              selected: isSelected,
              excludeSemantics: true,
              label: '$iconSectionLabel: $readableIcon',
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onIconChanged(key),
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
