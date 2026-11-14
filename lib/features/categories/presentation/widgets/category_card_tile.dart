import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';

/// Reusable Apple Glass tile displaying a single category with squircle icon, stats, and action menu.
class CategoryCardTile extends StatelessWidget {
  const CategoryCardTile({
    super.key,
    required this.cat,
    required this.theme,
    required this.isDark,
    required this.txCount,
    required this.monthSpendMinor,
    required this.currency,
    required this.locale,
    required this.hideBalance,
    required this.onEdit,
    required this.onDelete,
  });

  final Category cat;
  final ThemeData theme;
  final bool isDark;
  final int txCount;
  final int monthSpendMinor;
  final String currency;
  final String locale;
  final bool hideBalance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = AppIconCatalog.contrastSafeColor(
      Color(cat.color),
      theme.brightness,
    );
    final displayName = cat.isDefault
        ? DefaultCategoryLocalization.resolveName(
            l10n,
            categoryId: cat.id,
            fallbackName: cat.name,
          )
        : cat.name;

    final isIncome = cat.type == CategoryType.income;
    final monthMoney = Money(minorUnits: monthSpendMinor, currencyCode: currency);

    return ApplePressable(
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      onTap: () {
        unawaited(HapticFeedback.lightImpact());
        context.push(AppRoutes.categoryDetail(cat.id));
      },
      child: AppleGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        child: Row(
          children: [
            // Squircle Badge with glowing border and subtle shadow
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.22 : 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.40 : 0.28),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.22 : 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                AppIconCatalog.resolve(cat.icon),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Middle Column: Title & Metadata Badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Default or Custom badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                        decoration: BoxDecoration(
                          color: cat.isDefault
                              ? AppleTokens.systemBlue.withValues(alpha: 0.12)
                              : AppleTokens.systemPurple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        ),
                        child: Text(
                          cat.isDefault
                              ? l10n.defaultCategoryBadge
                              : (locale.startsWith('vi') ? 'Tùy chỉnh' : 'Custom'),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: cat.isDefault
                                ? AppleTokens.systemBlue
                                : AppleTokens.systemPurple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Transaction count indicator
                      Flexible(
                        child: Text(
                          txCount > 0
                              ? (locale.startsWith('vi') ? '$txCount GD' : '$txCount tx')
                              : (locale.startsWith('vi') ? 'Chưa dùng' : 'Unused'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFeatures: AppTheme.tabularFigures,
                            color: AppleTokens.systemGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right Column: Month Spend & Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (monthSpendMinor > 0)
                  Text(
                    isIncome
                        ? '+${monthMoney.format(locale: locale, masked: hideBalance)}'
                        : '-${monthMoney.format(locale: locale, masked: hideBalance)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      fontFeatures: AppTheme.tabularFigures,
                      color: isIncome ? AppleTokens.emeraldIncome : AppleTokens.rubyExpense,
                    ),
                  )
                else
                  Text(
                    '0 ${currency == 'VND' ? '₫' : currency}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white24 : Colors.black26,
                    ),
                  ),
                const SizedBox(height: 2),
                ApplePopupMenuButton<String>(
                  tooltip: l10n.moreOptions,
                  iconSize: 18,
                  size: 26,
                  onSelected: (value) {
                    if (value == 'detail') {
                      context.push(AppRoutes.categoryDetail(cat.id));
                    } else if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (ctx) => [
                    ApplePopupMenuItem(
                      value: 'detail',
                      icon: CupertinoIcons.chart_bar_alt_fill,
                      title: locale.startsWith('vi')
                          ? 'Xem báo cáo chi tiết'
                          : 'View detailed report',
                    ),
                    ApplePopupMenuItem(
                      value: 'edit',
                      icon: Icons.edit_outlined,
                      title: l10n.edit,
                    ),
                    ApplePopupMenuItem(
                      value: 'delete',
                      icon: CupertinoIcons.trash,
                      title: l10n.delete,
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
