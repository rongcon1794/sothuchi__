import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/debts/domain/entities/debt.dart';

/// Executive Apple Glassmorphic Hero Overview Card for Debt & Loan Book.
///
/// Features cohesive Apple HIG hierarchy:
/// - Header with Squircle badge and active count / overdue alert pill
/// - Prominent Net Balance ("Chênh lệch ròng") display
/// - Balanced dual metric cards for Lent ("Người nợ tôi") & Borrowed ("Tôi nợ người ta")
class DebtHeroOverviewCard extends StatelessWidget {
  const DebtHeroOverviewCard({
    super.key,
    required this.summary,
    required this.activeCount,
    required this.locale,
    required this.hideBalance,
  });

  final DebtSummary summary;
  final int activeCount;
  final String locale;
  final bool hideBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final isVi = locale.startsWith('vi');
    final netPositive = summary.netBalance.minorUnits >= 0;
    final netPrefix = summary.netBalance.minorUnits > 0 ? '+' : '';

    return AppleGlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : AppleTokens.borderLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header: Squircle Badge + Title + Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppleSquircleBadge(
                      icon: CupertinoIcons.arrow_right_arrow_left,
                      backgroundColor: netPositive
                          ? AppleTokens.emeraldIncome
                          : AppleTokens.systemOrange,
                      size: 22,
                      iconSize: 11,
                      radius: 6,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        isVi ? 'TỔNG QUAN SỔ NỢ' : 'DEBT OVERVIEW',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: isDark ? Colors.white70 : const Color(0xFF55555B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: summary.overdueCount > 0
                      ? AppleTokens.systemRed.withValues(alpha: 0.14)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: summary.overdueCount > 0
                      ? Border.all(
                          color: AppleTokens.systemRed.withValues(alpha: 0.35),
                          width: 0.8,
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (summary.overdueCount > 0) ...[
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle_fill,
                        size: 10,
                        color: AppleTokens.systemRed,
                      ),
                      const SizedBox(width: 3.5),
                    ],
                    Text(
                      summary.overdueCount > 0
                          ? (isVi
                              ? '${summary.overdueCount} quá hạn'
                              : '${summary.overdueCount} overdue')
                          : (isVi
                              ? '$activeCount khoản'
                              : '$activeCount active'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: summary.overdueCount > 0
                            ? AppleTokens.systemRed
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2. Net Balance Metric
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isVi ? 'Chênh lệch ròng:' : 'Net balance:',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$netPrefix${summary.netBalance.format(locale: locale, masked: hideBalance)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    fontFeatures: AppTheme.tabularFigures,
                    color: netPositive
                        ? AppleTokens.emeraldIncome
                        : AppleTokens.systemOrange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 3. Dual Metrics: Lent & Borrowed
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppleTokens.emeraldIncome
                        .withValues(alpha: isDark ? 0.12 : 0.06),
                    borderRadius:
                        BorderRadius.circular(AppleTokens.radiusControl),
                    border: Border.all(
                      color: AppleTokens.emeraldIncome
                          .withValues(alpha: isDark ? 0.25 : 0.18),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: AppleTokens.emeraldIncome
                                  .withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.arrow_up_right,
                              size: 9.5,
                              color: AppleTokens.emeraldIncome,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              l10n.debtSummaryLent, // "Người nợ tôi"
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          summary.totalLent
                              .format(locale: locale, masked: hideBalance),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            fontFeatures: AppTheme.tabularFigures,
                            color: AppleTokens.emeraldIncome,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppleTokens.systemOrange
                        .withValues(alpha: isDark ? 0.12 : 0.06),
                    borderRadius:
                        BorderRadius.circular(AppleTokens.radiusControl),
                    border: Border.all(
                      color: AppleTokens.systemOrange
                          .withValues(alpha: isDark ? 0.25 : 0.18),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: AppleTokens.systemOrange
                                  .withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.arrow_down_left,
                              size: 9.5,
                              color: AppleTokens.systemOrange,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              l10n.debtSummaryBorrowed, // "Tôi nợ người ta"
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          summary.totalBorrowed
                              .format(locale: locale, masked: hideBalance),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            fontFeatures: AppTheme.tabularFigures,
                            color: AppleTokens.systemOrange,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
