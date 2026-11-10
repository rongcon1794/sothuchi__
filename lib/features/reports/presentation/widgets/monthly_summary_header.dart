import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';

/// Compact, Apple-style monthly summary header showing:
/// Income, Expense, Net Balance, and Savings Rate.
class MonthlySummaryHeader extends StatelessWidget {
  const MonthlySummaryHeader({
    super.key,
    required this.report,
    required this.locale,
    required this.hideBalance,
  });

  final MonthlyReportData report;
  final String locale;
  final bool hideBalance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final financeColors = context.financeColors;

    final incStat = SummaryStatColumn(
      label: l10n.income,
      value: report.incomeMoney.format(
        locale: locale,
        showPlusSign: true,
        masked: hideBalance,
      ),
      semanticsValue: hideBalance ? l10n.balanceHidden : null,
      valueColor: financeColors.income,
    );

    final expStat = SummaryStatColumn(
      label: l10n.expense,
      value: report.expenseMoney.format(
        locale: locale,
        masked: hideBalance,
      ),
      semanticsValue: hideBalance ? l10n.balanceHidden : null,
      valueColor: financeColors.expense,
    );

    final netStat = SummaryStatColumn(
      label: l10n.netBalance,
      value: report.netMoney.format(
        locale: locale,
        showPlusSign: true,
        masked: hideBalance,
      ),
      semanticsValue: hideBalance ? l10n.balanceHidden : null,
      valueColor: report.netMinor >= 0
          ? financeColors.income
          : financeColors.expense,
    );

    final rateStat = SummaryStatColumn(
      label: l10n.savingsRate,
      value: hideBalance ? '••%' : '${report.savingsRatePercent}%',
      semanticsValue: hideBalance ? l10n.balanceHidden : null,
      valueColor: theme.colorScheme.onSurface,
    );

    final momPercent = report.expenseChangeVsPreviousMonthPercent;
    Widget? momBadge;
    if (momPercent != null && !hideBalance) {
      final isUp = momPercent > 0;
      final badgeColor = isUp ? AppleTokens.systemRed : AppleTokens.jadeDark;
      final badgeBg = isUp
          ? AppleTokens.systemRed.withValues(alpha: 0.10)
          : AppleTokens.jadeDark.withValues(alpha: 0.10);
      final arrowIcon =
          isUp ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_right;
      final trendText = isUp
          ? '${l10n.reportsSpendingIncreased} ${momPercent.abs()}%'
          : '${l10n.reportsSpendingDecreased} ${momPercent.abs()}%';

      momBadge = Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(arrowIcon, size: 11, color: badgeColor),
                const SizedBox(width: 4),
                Text(
                  '${l10n.reportsVsLastMonth}: $trendText',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildVerticalDivider() {
      return Container(
        width: 1,
        height: 28,
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
      );
    }

    Widget buildHorizontalDivider() {
      return Container(
        height: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
      );
    }

    return AppleGlassCard(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 540;

          if (isWide) {
            // Landscape/Tablet: All 4 in 1 clean horizontal row
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?momBadge,
                Row(
                  children: [
                    Expanded(child: incStat),
                    buildVerticalDivider(),
                    Expanded(child: expStat),
                    buildVerticalDivider(),
                    Expanded(child: netStat),
                    buildVerticalDivider(),
                    Expanded(child: rateStat),
                  ],
                ),
              ],
            );
          }

          // Portrait: 2x2 grid with subtle dividers
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?momBadge,
              Row(
                children: [
                  Expanded(child: incStat),
                  buildVerticalDivider(),
                  Expanded(child: expStat),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: buildHorizontalDivider(),
              ),
              Row(
                children: [
                  Expanded(child: netStat),
                  buildVerticalDivider(),
                  Expanded(child: rateStat),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class SummaryStatColumn extends StatelessWidget {
  const SummaryStatColumn({
    super.key,
    required this.label,
    required this.value,
    this.semanticsValue,
    required this.valueColor,
  });

  final String label;
  final String value;
  final String? semanticsValue;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          semanticsLabel: semanticsValue,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: valueColor,
            fontFeatures: AppTheme.tabularFigures,
          ),
        ),
      ],
    );
  }
}
