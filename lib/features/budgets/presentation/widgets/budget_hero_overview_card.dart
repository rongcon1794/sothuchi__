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
    final daysPassed = (daysInMonth - daysLeft + 1).clamp(1, daysInMonth);
    final timePercent = ((daysPassed * 100) ~/ daysInMonth).clamp(0, 100);

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

    // Spending Pace evaluation
    final String paceHeadline;
    if (isExceeded) {
      paceHeadline = isVi
          ? 'Đã vượt hạn mức ngân sách tháng!'
          : 'Monthly budget has been exceeded!';
    } else if (usedPercent > timePercent + 12) {
      paceHeadline = isVi
          ? 'Tốc độ chi tiêu nhanh hơn tiến độ tháng ($usedPercent% chi / $timePercent% tháng)'
          : 'Spending pace is faster than elapsed month ($usedPercent% spent / $timePercent% time)';
    } else {
      paceHeadline = isVi
          ? 'Tiến độ rất tốt: Đang chi tiêu chậm hơn tiến độ tháng'
          : 'Great pacing: You are spending under the monthly timeline';
    }

    return AppleGlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      borderColor: isExceeded ? AppleTokens.systemRed.withValues(alpha: 0.35) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar: Title + Health Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: barColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 18,
                        color: barColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.overallMonthlyBudget,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: barColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: barColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Central Visual Section: Activity Ring & 3-Stat Financial Breakdown
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Apple Activity Ring
              LucianActivityRing(
                progress: clampedRatio,
                size: 94,
                strokeWidth: 9.0,
                primaryColor: barColor,
                secondaryColor: ringSecondaryColor,
                showGlow: isExceeded || usedPercent >= 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isVi ? '$usedPercent% tổng' : '$usedPercent% total',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: barColor,
                        fontFeatures: AppTheme.tabularFigures,
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isVi ? 'đã dùng' : 'used',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 18),

              // 3 Key Financial Stat Rows
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Limit
                    _MetricTile(
                      label: l10n.budgetLimit,
                      amountText: totalLimitMoney.format(locale: locale, masked: hideBalance),
                      color: scheme.onSurface,
                      icon: Icons.layers_outlined,
                      hideBalance: hideBalance,
                    ),
                    const SizedBox(height: 8),
                    // Spent
                    _MetricTile(
                      label: isVi ? 'Đã chi tiêu' : 'Spent',
                      amountText: totalSpentMoney.format(locale: locale, masked: hideBalance),
                      color: financeColors.expense,
                      icon: Icons.arrow_upward_rounded,
                      hideBalance: hideBalance,
                    ),
                    const SizedBox(height: 8),
                    // Remaining or Exceeded
                    _MetricTile(
                      label: isExceeded ? (isVi ? 'Bội chi' : 'Over budget') : (isVi ? 'Còn lại' : 'Remaining'),
                      amountText: isExceeded
                          ? totalExceededMoney.format(locale: locale, masked: hideBalance)
                          : totalRemainingMoney.format(locale: locale, masked: hideBalance),
                      color: isExceeded ? financeColors.expense : financeColors.income,
                      icon: isExceeded ? Icons.warning_amber_rounded : Icons.shield_outlined,
                      hideBalance: hideBalance,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Pacing & Runway Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isExceeded
                          ? CupertinoIcons.exclamationmark_circle
                          : CupertinoIcons.sparkles,
                      size: 14,
                      color: barColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        paceHeadline,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isCurrentMonth) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Days left pill
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: isDark ? 0.4 : 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.today_rounded, size: 14, color: AppleTokens.systemBlue),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  l10n.budgetRemainingDays(daysLeft),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Daily safe pace pill
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: isDark ? 0.4 : 0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.flame_fill, size: 14, color: AppleTokens.systemOrange),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  l10n.budgetDailyRecommended(
                                    safeDailyMoney.format(locale: locale, masked: hideBalance),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.amountText,
    required this.color,
    required this.icon,
    required this.hideBalance,
  });

  final String label;
  final String amountText;
  final Color color;
  final IconData icon;
  final bool hideBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amountText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
