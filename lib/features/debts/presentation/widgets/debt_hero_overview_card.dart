import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/debts/domain/entities/debt.dart';

/// Hero summary card displaying total lent, total borrowed, net balance, and overdue alert badge.
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
    final netPositive = summary.netBalance.minorUnits >= 0;
    final netPrefix = summary.netBalance.minorUnits > 0 ? '+' : '';

    return AppleGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.10)
          : AppleTokens.borderLight,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryMetricColumn(
                      icon: CupertinoIcons.arrow_up_right,
                      label: l10n.debtSummaryLent,
                      amountText: summary.totalLent.format(
                        locale: locale,
                        masked: hideBalance,
                      ),
                      accentColor: AppleTokens.emeraldIncome,
                    ),
                  ),
                  VerticalDivider(
                    width: 24,
                    thickness: AppleTokens.hairline,
                    color: isDark
                        ? AppleTokens.separatorDark
                        : AppleTokens.separatorLight,
                  ),
                  Expanded(
                    child: _SummaryMetricColumn(
                      icon: CupertinoIcons.arrow_down_left,
                      label: l10n.debtSummaryBorrowed,
                      amountText: summary.totalBorrowed.format(
                        locale: locale,
                        masked: hideBalance,
                      ),
                      accentColor: AppleTokens.systemOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: AppleTokens.hairline,
            thickness: AppleTokens.hairline,
            color:
                isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        locale.startsWith('vi')
                            ? 'Chênh lệch ròng:'
                            : 'Net balance:',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$netPrefix${summary.netBalance.format(locale: locale, masked: hideBalance)}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              fontFeatures: AppTheme.tabularFigures,
                              color: netPositive
                                  ? AppleTokens.emeraldIncome
                                  : AppleTokens.systemOrange,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (summary.overdueCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppleTokens.systemRed.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(
                          AppleTokens.radiusPill,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_triangle_fill,
                            size: 11,
                            color: AppleTokens.systemRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            locale.startsWith('vi')
                                ? '${summary.overdueCount} quá hạn'
                                : '${summary.overdueCount} overdue',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppleTokens.systemRed,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      locale.startsWith('vi')
                          ? '$activeCount đang theo dõi'
                          : '$activeCount active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetricColumn extends StatelessWidget {
  const _SummaryMetricColumn({
    required this.icon,
    required this.label,
    required this.amountText,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String amountText;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 12, color: accentColor),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            amountText,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: accentColor,
              fontFeatures: AppTheme.tabularFigures,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}

