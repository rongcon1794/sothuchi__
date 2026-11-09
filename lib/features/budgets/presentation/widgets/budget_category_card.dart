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
/// visual threshold notch progress track, and live spending metrics.
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
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      onTap: () => context.push(AppRoutes.budgetDetail(progress.budget.id)),
      child: AppleGlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        borderColor: progress.isExceeded
            ? AppleTokens.systemRed.withValues(alpha: 0.35)
            : (progress.isWarningTriggered
                ? AppleTokens.systemOrange.withValues(alpha: 0.3)
                : null),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category Icon, Name, Scope tag, Percentage pill & popup menu
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Icon(iconData, color: badgeColor, size: 22),
                ),
                const SizedBox(width: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: pillBgColor,
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  ),
                  child: Text(
                    '${progress.usedPercent}%',
                    style: TextStyle(
                      color: pillFgColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.moreOptions,
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: scheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded, size: 18, color: AppleTokens.systemRed),
                          const SizedBox(width: 8),
                          Text(l10n.delete, style: const TextStyle(color: AppleTokens.systemRed)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Progress Bar with Threshold Notch Marker
            BudgetThresholdProgressBar(
              progress: clampedRatio,
              threshold: thresholdRatio,
              activeColor: barColor,
              height: 10,
              showGlow: progress.isExceeded || progress.isWarningTriggered,
            ),

            const SizedBox(height: 10),

            // Metrics row: Remaining/Exceeded amount & Threshold label
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
                      fontWeight: progress.isExceeded ? FontWeight.w700 : FontWeight.w600,
                      color: progress.isExceeded ? financeColors.expense : scheme.onSurface,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.alertThresholdLabel(progress.budget.alertThreshold),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),

            // Daily Burn Rate Runway (when remaining > 0)
            if (!progress.isExceeded && progress.remainingMinorUnits > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.flame_fill,
                      size: 12,
                      color: AppleTokens.systemOrange,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        l10n.budgetDailyRecommended(dailyText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
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
