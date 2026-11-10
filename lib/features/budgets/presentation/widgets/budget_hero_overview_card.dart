import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';

/// Hero visual card presenting the overall monthly budget health,
/// an Apple Activity Ring indicator, key financial metrics, and spending pace.
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

    // Dynamic semantic styling based on health status
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      borderColor: isExceeded ? AppleTokens.systemRed.withValues(alpha: 0.35) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Bar: Title + Health Status Pill
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: barColor.withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        Icons.pie_chart_rounded,
                        size: 15,
                        color: barColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.overallMonthlyBudget.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppleTokens.systemGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: Border.all(
                    color: barColor.withValues(alpha: isDark ? 0.40 : 0.25),
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

          const SizedBox(height: 12),

          // 2. Hero Section: Còn lại / Bội chi + Compact Activity Ring
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
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isExceeded
                            ? totalExceededMoney.format(locale: locale, masked: hideBalance)
                            : totalRemainingMoney.format(locale: locale, masked: hideBalance),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          fontFeatures: AppTheme.tabularFigures,
                          letterSpacing: -0.4,
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
                size: 52,
                strokeWidth: 5.5,
                primaryColor: barColor,
                secondaryColor: ringSecondaryColor,
                showGlow: isExceeded || usedPercent >= 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$usedPercent%\ntổng',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: barColor,
                        fontFeatures: AppTheme.tabularFigures,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 3. Smooth Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  width: double.infinity,
                  color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                ),
                FractionallySizedBox(
                  widthFactor: clampedRatio,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [barColor, ringSecondaryColor],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 4. Secondary Numbers: Đã chi vs Tổng hạn mức
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: '${isVi ? 'Đã chi' : 'Spent'}: ',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppleTokens.systemGray,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: totalSpentMoney.format(locale: locale, masked: hideBalance),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppTheme.tabularFigures,
                          color: financeColors.expense,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: '${l10n.budgetLimit}: ',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppleTokens.systemGray,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: totalLimitMoney.format(locale: locale, masked: hideBalance),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFeatures: AppTheme.tabularFigures,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          if (isCurrentMonth) ...[
            const SizedBox(height: 10),
            Container(
              height: 0.6,
              color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
            ),
            const SizedBox(height: 8),

            // 5. Clean Single-line Footer (Days left & Safe Daily Spending Pace)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.calendar,
                        size: 12,
                        color: AppleTokens.systemBlue,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          l10n.budgetRemainingDays(daysLeft),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        isExceeded
                            ? CupertinoIcons.exclamationmark_triangle_fill
                            : CupertinoIcons.flame_fill,
                        size: 12,
                        color: isExceeded ? AppleTokens.systemRed : AppleTokens.systemOrange,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          isExceeded
                              ? (isVi ? 'Đã vượt' : 'Exceeded')
                              : l10n.budgetDailyRecommended(
                                  safeDailyMoney.format(locale: locale, masked: hideBalance),
                                ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFeatures: AppTheme.tabularFigures,
                            color: isExceeded ? AppleTokens.systemRed : barColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
