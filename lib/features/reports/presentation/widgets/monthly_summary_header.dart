import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';

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
    final financeColors = context.financeColors;
    final stackSingleCol = MediaQuery.textScalerOf(context).scale(1) >= 1.5;

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
          ? AppleTokens.systemRed.withValues(alpha: 0.12)
          : AppleTokens.jadeDark.withValues(alpha: 0.12);
      final arrowIcon = isUp ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_right;
      final trendText = isUp
          ? '${l10n.reportsSpendingIncreased} ${momPercent.abs()}%'
          : '${l10n.reportsSpendingDecreased} ${momPercent.abs()}%';

      momBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(arrowIcon, size: 12, color: badgeColor),
            const SizedBox(width: 5),
            Text(
              '${l10n.reportsVsLastMonth}: $trendText',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: badgeColor,
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
          ],
        ),
      );
    }

    if (stackSingleCol) {
      return AppleGlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (momBadge != null) ...[
              Align(alignment: Alignment.centerLeft, child: momBadge),
              const SizedBox(height: 12),
            ],
            incStat,
            const SizedBox(height: 10),
            expStat,
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(),
            ),
            netStat,
            const SizedBox(height: 10),
            rateStat,
          ],
        ),
      );
    }

    return AppleGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: Column(
        children: [
          if (momBadge != null) ...[
            Align(alignment: Alignment.centerLeft, child: momBadge),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(child: incStat),
              const SizedBox(width: 8),
              Expanded(child: expStat),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            children: [
              Expanded(child: netStat),
              const SizedBox(width: 8),
              Expanded(child: rateStat),
            ],
          ),
        ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          semanticsLabel: semanticsValue,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
            fontFeatures: AppTheme.tabularFigures,
          ),
        ),
      ],
    );
  }
}
