import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';
import 'package:so_thu_chi/features/budgets/presentation/widgets/budget_threshold_progress_bar.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';

/// Redesigned Category Budget Card featuring Apple glassmorphism,
/// contrast-safe squircle icon badge, visual threshold notch progress track,
/// and neat responsive metric strip.
class BudgetCategoryCard extends StatelessWidget {
  const BudgetCategoryCard({
    super.key,
    required this.progress,
    this.category,
    required this.locale,
    required this.hideBalance,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetProgress progress;
  final Category? category;
  final String locale;
  final bool hideBalance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final financeColors = context.financeColors;
    final isDark = theme.brightness == Brightness.dark;

    final isOverall = progress.budget.isOverall;
    final title = isOverall
        ? l10n.overallMonthlyBudget
        : DefaultCategoryLocalization.resolveName(
            l10n,
            categoryId: progress.budget.categoryId!,
            fallbackName: category?.name ?? l10n.categoryBudget,
          );

    final iconData = isOverall
        ? Icons.account_balance_wallet_rounded
        : AppIconCatalog.resolve(category?.icon ?? 'other');
    final rawBadgeColor = isOverall
        ? scheme.primary
        : Color(category?.color ?? 0xFF0D7C66);
    final badgeColor = AppIconCatalog.contrastSafeColor(
      rawBadgeColor,
      theme.brightness,
    );

    final barColor = progress.isExceeded
        ? financeColors.expense
        : (progress.isWarningTriggered
            ? financeColors.warning
            : financeColors.income);

    final pillBgColor = progress.isExceeded
        ? financeColors.expenseContainer
        : (progress.isWarningTriggered
            ? financeColors.warningContainer
            : financeColors.incomeContainer);
    final pillFgColor = progress.isExceeded
        ? financeColors.onExpenseContainer
        : (progress.isWarningTriggered
            ? financeColors.onWarningContainer
            : financeColors.onIncomeContainer);

    // Visual progress fraction strictly at UI rendering boundary
    final clampedRatio = progress.usedPercent.clamp(0, 100) / 100.0;
    final thresholdRatio = (progress.budget.alertThreshold / 100.0).clamp(0.1, 1.0);

    final spentText = progress.spentMoney.format(
      locale: locale,
      masked: hideBalance,
    );
    final limitText = progress.budget.limitMoney.format(
      locale: locale,
      masked: hideBalance,
    );
    final diffText = progress.remainingOrExceededMoney.format(
      locale: locale,
      masked: hideBalance,
    );

    final now = DateTime.now();
    final isCurrent = progress.budget.startDate.year == now.year &&
        progress.budget.startDate.month == now.month;
    final daysInMonth = DateTime(
      progress.budget.startDate.year,
      progress.budget.startDate.month + 1,
      0,
    ).day;
    final daysLeft = isCurrent
        ? (daysInMonth - now.day + 1).clamp(1, daysInMonth)
        : daysInMonth;
    final dailyMinor = daysLeft > 0
        ? progress.remainingMinorUnits ~/ daysLeft
        : 0;
    final dailyText = Money(
      minorUnits: dailyMinor,
      currencyCode: progress.budget.currency,
    ).format(locale: locale, masked: hideBalance);

    return ApplePressable(
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      onTap: () => context.push(AppRoutes.budgetDetail(progress.budget.id)),
      child: AppleGlassCard(
        padding: const EdgeInsets.all(15),
        borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
        borderColor: progress.isExceeded
            ? AppleTokens.systemRed.withValues(alpha: 0.35)
            : (progress.isWarningTriggered
                ? AppleTokens.systemOrange.withValues(alpha: 0.28)
                : null),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Category Squircle Badge, Name & Subtitle, Percentage Pill & Popup Menu
            Row(
              children: [
                AppleSquircleBadge(
                  icon: iconData,
                  backgroundColor: badgeColor,
                  size: 38,
                  iconSize: 19,
                  radius: 10,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.budgetSpentOf(spentText, limitText),
                        semanticsLabel: hideBalance ? l10n.balanceHidden : null,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
                          fontFeatures: AppTheme.tabularFigures,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Percentage badge (maintains exact '${progress.usedPercent}%' for automated tests)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: pillBgColor,
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  ),
                  child: Text(
                    '${progress.usedPercent}%',
                    style: TextStyle(
                      color: pillFgColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                ApplePopupMenuButton<String>(
                  tooltip: l10n.moreOptions,
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    ApplePopupMenuItem(
                      value: 'edit',
                      icon: CupertinoIcons.pencil,
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

            const SizedBox(height: 12),

            // Metrics Row: Remaining / Exceeded amount & Alert Threshold Label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    progress.isExceeded
                        ? l10n.budgetExceededBy(diffText)
                        : l10n.budgetRemaining(diffText),
                    semanticsLabel: hideBalance ? l10n.balanceHidden : null,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: progress.isExceeded ? financeColors.expense : scheme.onSurface,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.alertThresholdLabel(progress.budget.alertThreshold),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress Bar with Threshold Notch Marker
            BudgetThresholdProgressBar(
              progress: clampedRatio,
              threshold: thresholdRatio,
              activeColor: barColor,
              height: 7,
              showGlow: progress.isExceeded || progress.isWarningTriggered,
            ),

            // Daily Burn Rate Runway (when remaining > 0)
            if (!progress.isExceeded && progress.remainingMinorUnits > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.025),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.flame_fill,
                      size: 12,
                      color: AppleTokens.systemOrange,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        l10n.budgetDailyRecommended(dailyText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
