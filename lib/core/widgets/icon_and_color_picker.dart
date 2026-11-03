import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';

/// Accessible icon and color selector meeting >= 48x48dp touch target standards.
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
                      duration: const Duration(milliseconds: 180),
                      width: isSelected ? 38 : 32,
                      height: isSelected ? 38 : 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: scheme.onSurface, width: 2.5)
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
                borderRadius: BorderRadius.circular(12),
                onTap: () => onIconChanged(key),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.16)
                        : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? activeColor : Colors.transparent,
                      width: 1.8,
                    ),
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
