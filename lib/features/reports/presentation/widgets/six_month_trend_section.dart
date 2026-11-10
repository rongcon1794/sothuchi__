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
    final isDark = theme.brightness == Brightness.dark;
    final financeColors = context.financeColors;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final bottomReserved = math.max(34.0, 26.0 * textScale);

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

    final dotFillColor = isDark
        ? (context.isOled ? AppleTokens.bgOledCard : AppleTokens.bgDarkCard)
        : AppleTokens.bgLightCard;

    final incomeSpots = <FlSpot>[
      for (var i = 0; i < bars.length; i++)
        FlSpot(i.toDouble(), bars[i].incomeMinorUnits.toDouble()),
    ];
    final expenseSpots = <FlSpot>[
      for (var i = 0; i < bars.length; i++)
        FlSpot(i.toDouble(), bars[i].expenseMinorUnits.toDouble()),
    ];

    final maxX = bars.length > 1 ? (bars.length - 1).toDouble() : 1.0;

    return Semantics(
      container: true,
      label: screenReaderSummary,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 8),
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX,
              maxY: visualMaxY,
              minY: 0,
              clipData: const FlClipData.none(),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: true,
                horizontalInterval: visualMaxY / 4,
                verticalInterval: 1,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
                getDrawingVerticalLine: (_) => FlLine(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.14),
                  strokeWidth: 1,
                  dashArray: [3, 4],
                ),
              ),
              lineTouchData: LineTouchData(
                enabled: !hideBalance,
                getTouchedSpotIndicator: (barData, spotIndexes) {
                  final lineColor = barData.color ?? theme.colorScheme.primary;
                  return spotIndexes.map((spotIndex) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                        strokeWidth: 1.2,
                        dashArray: [4, 3],
                      ),
                      FlDotData(
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 5.5,
                          color: lineColor,
                          strokeWidth: 2.5,
                          strokeColor: dotFillColor,
                        ),
                      ),
                    );
                  }).toList();
                },
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  tooltipBorderRadius: BorderRadius.circular(10),
                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  maxContentWidth: 180,
                  getTooltipColor: (_) => isDark
                      ? const Color(0xEE1C1C1E)
                      : const Color(0xEE2C2C2E),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((touchedSpot) {
                      final idx = touchedSpot.x.round();
                      if (idx < 0 || idx >= bars.length) return null;
                      final item = bars[idx];
                      final isIncome = touchedSpot.barIndex == 0;
                      final money = isIncome
                          ? item.incomeMoney
                          : item.expenseMoney;
                      final tag = isIncome ? l10n.income : l10n.expense;
                      final color = isIncome
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFFB7185);
                      return LineTooltipItem(
                        '$tag: ${money.format(locale: locale)}',
                        TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      );
                    }).toList();
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
                    interval: 1,
                    reservedSize: bottomReserved,
                    getTitlesWidget: (value, meta) {
                      if ((value - value.roundToDouble()).abs() > 0.01) {
                        return const SizedBox.shrink();
                      }
                      final idx = value.round();
                      if (idx < 0 || idx >= bars.length) {
                        return const SizedBox.shrink();
                      }
                      final item = bars[idx];
                      final label = AppDateUtils.formatShortMonth(
                        item.monthAnchor,
                        locale: locale,
                      );
                      final isNetSurplus =
                          item.incomeMinorUnits >= item.expenseMinorUnits;

                      return SideTitleWidget(
                        meta: meta,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isNetSurplus
                                    ? financeColors.income.withValues(alpha: 0.8)
                                    : financeColors.expense.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                // 1. Đường Thu nhập (Income Line)
                LineChartBarData(
                  spots: incomeSpots,
                  isCurved: true,
                  curveSmoothness: 0.32,
                  preventCurveOverShooting: true,
                  color: financeColors.income,
                  barWidth: isWide ? 3.2 : 2.8,
                  isStrokeCapRound: true,
                  isStrokeJoinRound: true,
                  dotData: FlDotData(
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: isWide ? 4.2 : 3.6,
                      color: dotFillColor,
                      strokeWidth: 2.2,
                      strokeColor: financeColors.income,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        financeColors.income.withValues(alpha: isDark ? 0.24 : 0.18),
                        financeColors.income.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // 2. Đường Chi tiêu (Expense Line)
                LineChartBarData(
                  spots: expenseSpots,
                  isCurved: true,
                  curveSmoothness: 0.32,
                  preventCurveOverShooting: true,
                  color: financeColors.expense,
                  barWidth: isWide ? 3.2 : 2.8,
                  isStrokeCapRound: true,
                  isStrokeJoinRound: true,
                  dotData: FlDotData(
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: isWide ? 4.2 : 3.6,
                      color: dotFillColor,
                      strokeWidth: 2.2,
                      strokeColor: financeColors.expense,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        financeColors.expense.withValues(alpha: isDark ? 0.20 : 0.14),
                        financeColors.expense.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            ? (context.isOled
                ? AppleTokens.bgOledSecondary.withValues(alpha: 0.6)
                : AppleTokens.bgDarkPrimary.withValues(alpha: 0.6))
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
