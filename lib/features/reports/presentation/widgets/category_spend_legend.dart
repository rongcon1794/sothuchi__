import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';

class CategoryLegendRow extends StatelessWidget {
  const CategoryLegendRow({
    super.key,
    required this.slice,
    required this.locale,
    required this.hideBalance,
    this.isSelected = false,
    this.onTap,
  });

  final CategorySpendSlice slice;
  final String locale;
  final bool hideBalance;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = AppIconCatalog.contrastSafeColor(
      Color(slice.color),
      theme.brightness,
    );
    final name = DefaultCategoryLocalization.resolveName(
      l10n,
      categoryId: slice.categoryId,
      fallbackName: slice.fallbackName,
    );
    final formattedAmount = slice.amountMoney.format(
      locale: locale,
      masked: hideBalance,
    );

    final rowWidget = Semantics(
      container: true,
      label:
          '$name, ${slice.percentage}%, ${hideBalance ? l10n.balanceHidden : formattedAmount}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? catColor.withValues(alpha: isDark ? 0.20 : 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppleTokens.radiusSm),
          border: Border.all(
            color: isSelected
                ? catColor.withValues(alpha: isDark ? 0.6 : 0.45)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
        children: [
          LayoutBuilder(
            builder: (context, rowConstraints) {
              final isLargeFont = MediaQuery.textScalerOf(context).scale(14) >= 20;
              if (isLargeFont) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            AppIconCatalog.resolve(slice.icon),
                            size: 18,
                            color: catColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${slice.percentage}%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFeatures: AppTheme.tabularFigures,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            formattedAmount,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: AppTheme.tabularFigures,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      AppIconCatalog.resolve(slice.icon),
                      size: 18,
                      color: catColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${slice.percentage}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      formattedAmount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            child: LinearProgressIndicator(
              value: (slice.percentage / 100.0).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: catColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(catColor),
            ),
          ),
        ],
      ),
      ),
    );

    if (onTap != null) {
      return ApplePressable(
        borderRadius: BorderRadius.circular(AppleTokens.radiusSm),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: rowWidget,
      );
    }
    return rowWidget;
  }
}

class LegendDot extends StatelessWidget {
  const LegendDot({
    super.key,
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
