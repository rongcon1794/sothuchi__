import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/theme/tokens/app_semantic_colors.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

/// Standard Apple HIG Selector Tile for forms (picking Wallets, Categories, Dates, Cycles, etc.)
/// Provides:
/// - Squircle icon badge with customizable background & icon color
/// - Title and Value / Placeholder text
/// - Optional clear button [✕]
/// - Trailing chevron
/// - Tactile spring press feedback
class AppleSelectorRow extends StatelessWidget {
  const AppleSelectorRow({
    super.key,
    required this.title,
    required this.onTap,
    this.valueText,
    this.placeholder,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.onClear,
    this.trailing,
    this.showChevron = true,
  });

  final String title;
  final VoidCallback onTap;
  final String? valueText;
  final String? placeholder;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final VoidCallback? onClear;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasValue = valueText != null && valueText!.trim().isNotEmpty;
    final effectiveColor = iconColor ?? theme.colorScheme.primary;
    final effectiveBgColor = iconBackgroundColor ??
        effectiveColor.withValues(alpha: isDark ? 0.22 : 0.12);

    return ApplePressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
          border: Border.all(
            color: colors.inputBorder,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: effectiveBgColor,
                  borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 20,
                    color: effectiveColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue ? valueText! : (placeholder ?? ''),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                      color: hasValue ? colors.textPrimary : colors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasValue && onClear != null) ...[
              ApplePressable(
                scaleDown: 0.88,
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    CupertinoIcons.clear_circled_solid,
                    size: 18,
                    color: colors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (trailing != null)
              trailing!
            else if (showChevron)
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: colors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}
