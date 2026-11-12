import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';

/// Redesigned, state-of-the-art Apple HIG Monthly Budget Overview Hero Card.
///
/// Features a prominent Hero Amount, interactive Activity Ring, dynamic
/// status pill, sleek progress indicator, and an integrated 3-metric KPI strip.
class BudgetHeroOverviewCard extends StatelessWidget {
  const BudgetHeroOverviewCard({
    super.key,
    required this.progressList,
    required this.selectedMonth,
    required this.locale,
    required this.hideBalance,
  });

  final List<BudgetProgress> progressList;
  final DateTime selectedMonth;
  final String locale;
  final bool hideBalance;

  @override
  Widget build(BuildContext context) {
    if (progressList.isEmpty) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final financeColors = context.financeColors;
    final isDark = theme.brightness == Brightness.dark;
    final currency = progressList.first.budget.currency;
    final isVi = locale.startsWith('vi');

    final totalLimit = progressList.fold<int>(0, (acc, p) => acc + p.budget.amount);
    final totalSpent = progressList.fold<int>(0, (acc, p) => acc + p.spentMinorUnits);
    final isExceeded = totalSpent > totalLimit;
    final totalRemaining = totalLimit > totalSpent ? totalLimit - totalSpent : 0;
    final totalExceeded = isExceeded ? totalSpent - totalLimit : 0;

    final usedPercent = totalLimit > 0 ? ((totalSpent * 100) ~/ totalLimit).clamp(0, 999) : 0;
    final clampedRatio = (usedPercent / 100.0).clamp(0.0, 1.0);

    final now = DateTime.now();
    final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final daysLeft = isCurrentMonth ? (daysInMonth - now.day + 1).clamp(1, daysInMonth) : daysInMonth;

    final safeDailyMinor = daysLeft > 0 ? totalRemaining ~/ daysLeft : 0;
    final safeDailyMoney = Money(minorUnits: safeDailyMinor, currencyCode: currency);
    final totalLimitMoney = Money(minorUnits: totalLimit, currencyCode: currency);
    final totalSpentMoney = Money(minorUnits: totalSpent, currencyCode: currency);
    final totalRemainingMoney = Money(minorUnits: totalRemaining, currencyCode: currency);
    final totalExceededMoney = Money(minorUnits: totalExceeded, currencyCode: currency);

    // Dynamic semantic styling based on budget health status
    final Color barColor;
    final Color ringSecondaryColor;
    final String statusText;
    final IconData statusIcon;

    if (isExceeded) {
      barColor = AppleTokens.systemRed;
      ringSecondaryColor = const Color(0xFFFF6B6B);
      statusText = isVi ? 'Bội chi' : 'Over budget';
      statusIcon = CupertinoIcons.xmark_octagon_fill;
    } else if (usedPercent >= 80) {
      barColor = AppleTokens.systemOrange;
      ringSecondaryColor = const Color(0xFFFFD60A);
      statusText = isVi ? 'Cận cảnh báo' : 'Near threshold';
      statusIcon = CupertinoIcons.exclamationmark_triangle_fill;
    } else {
      barColor = AppleTokens.jadeDark;
      ringSecondaryColor = AppleTokens.systemMint;
      statusText = isVi ? 'Chi tiêu an toàn' : 'On track';
      statusIcon = CupertinoIcons.checkmark_shield_fill;
    }

    return AppleGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      borderColor: isExceeded
          ? AppleTokens.systemRed.withValues(alpha: 0.35)
          : (usedPercent >= 80 ? AppleTokens.systemOrange.withValues(alpha: 0.28) : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Bar: Title + Health Status Pill
          Row(
            children: [
              AppleSquircleBadge(
                icon: CupertinoIcons.chart_pie_fill,
                backgroundColor: barColor,
                size: 32,
                iconSize: 16,
                radius: 9,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.overallMonthlyBudget.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppleTokens.systemGray,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isCurrentMonth
                          ? l10n.budgetRemainingDays(daysLeft)
                          : (isVi
                              ? 'Tháng ${selectedMonth.month}/${selectedMonth.year}'
                              : 'Month ${selectedMonth.month}/${selectedMonth.year}'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: Border.all(
                    color: barColor.withValues(alpha: isDark ? 0.36 : 0.22),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 11, color: barColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: barColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Hero Section: Remaining / Exceeded + Activity Ring
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isExceeded
                          ? (isVi ? 'ĐÃ BỘI CHI' : 'EXCEEDED BY')
                          : (isVi ? 'SỐ DƯ CÒN LẠI' : 'REMAINING BUDGET'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isExceeded
                            ? totalExceededMoney.format(locale: locale, masked: hideBalance)
                            : totalRemainingMoney.format(locale: locale, masked: hideBalance),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          fontFeatures: AppTheme.tabularFigures,
                          letterSpacing: -0.6,
                          color: isExceeded
                              ? AppleTokens.systemRed
                              : (isDark ? Colors.white : const Color(0xFF1C1C1E)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              LucianActivityRing(
                progress: clampedRatio,
                size: 56,
                strokeWidth: 5.5,
                primaryColor: barColor,
                secondaryColor: ringSecondaryColor,
                showGlow: isExceeded || usedPercent >= 80,
                child: Text(
                  '$usedPercent%\n${isVi ? 'tổng' : 'total'}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: barColor,
                    fontFeatures: AppTheme.tabularFigures,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3. Smooth Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: clampedRatio,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 4. Integrated 3-Metric KPI Mini Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.black.withValues(alpha: 0.04),
              ),
            ),
            child: Row(
              children: [
                // Cell 1: Đã chi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isVi ? 'Đã chi' : 'Spent',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppleTokens.systemGray,
                        ),
                      ),
                      const SizedBox(height: 1.5),
                      Text(
                        totalSpentMoney.format(locale: locale, masked: hideBalance),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppTheme.tabularFigures,
                          color: financeColors.expense,
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical Divider
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),

                // Cell 2: Hạn mức
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.budgetLimit,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppleTokens.systemGray,
                        ),
                      ),
                      const SizedBox(height: 1.5),
                      Text(
                        totalLimitMoney.format(locale: locale, masked: hideBalance),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppTheme.tabularFigures,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical Divider
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),

                // Cell 3: Nhịp chi ngày
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isVi ? 'Nhịp chi/ngày' : 'Daily Pace',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppleTokens.systemGray,
                        ),
                      ),
                      const SizedBox(height: 1.5),
                      Text(
                        isExceeded
                            ? (isVi ? 'Đã vượt' : 'Exceeded')
                            : safeDailyMoney.format(locale: locale, masked: hideBalance),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppTheme.tabularFigures,
                          color: isExceeded
                              ? AppleTokens.systemRed
                              : (usedPercent >= 80
                                  ? AppleTokens.systemOrange
                                  : AppleTokens.jadePrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
