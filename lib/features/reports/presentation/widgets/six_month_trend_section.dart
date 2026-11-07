import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';

class SixMonthTrendBarChart extends StatelessWidget {
  const SixMonthTrendBarChart({
    super.key,
    required this.bars,
    required this.locale,
    required this.hideBalance,
    this.isWide = false,
  });

  final List<MonthlyTrendBar> bars;
  final String locale;
  final bool hideBalance;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final financeColors = context.financeColors;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final bottomReserved = math.max(28.0, 22.0 * textScale);

    var maxMinor = 0;
    for (final bar in bars) {
      maxMinor = math.max(
        maxMinor,
        math.max(bar.incomeMinorUnits, bar.expenseMinorUnits),
      );
    }
    final visualMaxY = maxMinor <= 0 ? 100.0 : (maxMinor.toDouble() * 1.18);

    final screenReaderSummary = [
      for (final bar in bars)
        '${AppDateUtils.formatMonthYear(bar.monthAnchor, locale: locale)}: '
            '${l10n.income} ${hideBalance ? l10n.balanceHidden : bar.incomeMoney.format(locale: locale)}, '
            '${l10n.expense} ${hideBalance ? l10n.balanceHidden : bar.expenseMoney.format(locale: locale)}',
    ].join('; ');

    return Semantics(
      container: true,
      label: screenReaderSummary,
      excludeSemantics: true,
      child: BarChart(
        BarChartData(
          maxY: visualMaxY,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          barTouchData: BarTouchData(
            enabled: !hideBalance,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (groupIndex < 0 || groupIndex >= bars.length) return null;
                final item = bars[groupIndex];
                final money = rodIndex == 0
                    ? item.incomeMoney
                    : item.expenseMoney;
                return BarTooltipItem(
                  money.format(locale: locale),
                  TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: bottomReserved,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= bars.length) {
                    return const SizedBox.shrink();
                  }
                  final label = AppDateUtils.formatShortMonth(
                    bars[idx].monthAnchor,
                    locale: locale,
                  );
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < bars.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: isWide ? 6 : 4,
                barRods: [
                  BarChartRodData(
                    toY: bars[i].incomeMinorUnits.toDouble(),
                    color: financeColors.income,
                    width: isWide ? 14 : 11,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                  BarChartRodData(
                    toY: bars[i].expenseMinorUnits.toDouble(),
                    color: financeColors.expense,
                    width: isWide ? 14 : 11,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class SixMonthSummaryPanel extends StatelessWidget {
  const SixMonthSummaryPanel({
    super.key,
    required this.bars,
    required this.currencyCode,
    required this.locale,
    required this.hideBalance,
  });

  final List<MonthlyTrendBar> bars;
  final String currencyCode;
  final String locale;
  final bool hideBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final financeColors = context.financeColors;

    var totalInc = 0;
    var totalExp = 0;
    var bestNet = -9999999999;
    var bestMonth = '';

    for (final bar in bars) {
      totalInc += bar.incomeMinorUnits;
      totalExp += bar.expenseMinorUnits;
      final net = bar.incomeMinorUnits - bar.expenseMinorUnits;
      if (net > bestNet) {
        bestNet = net;
        bestMonth = AppDateUtils.formatShortMonth(bar.monthAnchor, locale: locale);
      }
    }

    final avgMonthlyExp = bars.isNotEmpty ? totalExp ~/ bars.length : 0;
    final netTotal = totalInc - totalExp;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppleTokens.bgDarkPrimary.withValues(alpha: 0.6)
            : AppleTokens.bgLightSecondary.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.chart_bar_square,
                size: 15,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                locale.startsWith('vi') ? 'Tổng quan 6 Tháng' : '6-Month Overview',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildRow(
            context,
            locale.startsWith('vi') ? 'Tổng thu 6T:' : 'Total Income 6M:',
            Money(minorUnits: totalInc, currencyCode: currencyCode).format(locale: locale, masked: hideBalance),
            financeColors.income,
          ),
          const SizedBox(height: 6),
          _buildRow(
            context,
            locale.startsWith('vi') ? 'Tổng chi 6T:' : 'Total Expense 6M:',
            Money(minorUnits: totalExp, currencyCode: currencyCode).format(locale: locale, masked: hideBalance),
            financeColors.expense,
          ),
          const SizedBox(height: 6),
          _buildRow(
            context,
            locale.startsWith('vi') ? 'Chi TB/tháng:' : 'Avg Monthly Exp:',
            Money(minorUnits: avgMonthlyExp, currencyCode: currencyCode).format(locale: locale, masked: hideBalance),
            null,
          ),
          const SizedBox(height: 6),
          _buildRow(
            context,
            locale.startsWith('vi') ? 'Thuần 6T:' : 'Net Flow 6M:',
            Money(minorUnits: netTotal, currencyCode: currencyCode).format(locale: locale, showPlusSign: true, masked: hideBalance),
            netTotal >= 0 ? financeColors.income : financeColors.expense,
          ),
          if (bestMonth.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildRow(
              context,
              locale.startsWith('vi') ? 'Tiết kiệm nhất:' : 'Top Saving Month:',
              bestMonth,
              AppleTokens.jadeDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value, Color? color) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
