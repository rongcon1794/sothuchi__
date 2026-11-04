import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/core/widgets/skeleton_box.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';
import 'package:so_thu_chi/features/reports/presentation/controllers/reports_controller.dart';
import 'package:so_thu_chi/features/reports/presentation/widgets/apple_spending_heatmap.dart';
import 'package:so_thu_chi/features/reports/presentation/widgets/financial_health_card.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final hideBalance = settings?.hideBalance ?? false;

    final selectedMonth = ref.watch(selectedReportMonthProvider);
    final txStream = ref.watch(transactionsStreamProvider);
    final report = ref.watch(monthlyReportProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: Column(
        children: [
          // Month Switcher
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: AppleGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: l10n.previousMonth,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _touchedPieIndex = -1);
                        ref
                            .read(selectedReportMonthProvider.notifier)
                            .previousMonth();
                      },
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        AppDateUtils.formatMonthYear(
                          selectedMonth,
                          locale: locale,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.nextMonth,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _touchedPieIndex = -1);
                        ref
                            .read(selectedReportMonthProvider.notifier)
                            .nextMonth();
                      },
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: txStream.when(
              loading: () => const SkeletonListView(itemCount: 3),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(context.localizeError(err)),
                ),
              ),
              data: (_) {
                if (!report.hasAnyActivityInSelectedMonth &&
                    !report.hasSixMonthActivity) {
                  return EmptyStateView(
                    icon: Icons.bar_chart_rounded,
                    title: l10n.noReportDataTitle,
                    subtitle: l10n.noReportDataSubtitle,
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    AppleTokens.scrollBottomPaddingNoFab,
                  ),
                  children: [
                    // Monthly Summary Grid
                    _MonthlySummaryHeader(
                      report: report,
                      locale: locale,
                      hideBalance: hideBalance,
                    ),
                    const SizedBox(height: 16),

                    // Financial Health Insights
                    FinancialHealthCard(
                      report: report,
                      locale: locale,
                      hideBalance: hideBalance,
                    ),
                    const SizedBox(height: 16),

                    // Daily Spending Heatmap Grid
                    AppleSpendingHeatmap(
                      report: report,
                      locale: locale,
                      hideBalance: hideBalance,
                    ),
                    const SizedBox(height: 16),

                    // Donut Chart: Expense by Category
                    AppleGlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.expenseByCategory,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            if (report.categorySlices.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Center(
                                  child: Text(
                                    l10n.noReportDataTitle,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              )
                            else ...[
                              SizedBox(
                                height: 210,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ExcludeSemantics(
                                      child: PieChart(
                                        PieChartData(
                                          sectionsSpace: 2.5,
                                          centerSpaceRadius: 58,
                                          pieTouchData: PieTouchData(
                                            touchCallback:
                                                (FlTouchEvent event, response) {
                                                  setState(() {
                                                    if (!event
                                                            .isInterestedForInteractions ||
                                                        response == null ||
                                                        response
                                                                .touchedSection ==
                                                            null) {
                                                      _touchedPieIndex = -1;
                                                      return;
                                                    }
                                                    _touchedPieIndex = response
                                                        .touchedSection!
                                                        .touchedSectionIndex;
                                                  });
                                                },
                                          ),
                                          sections: [
                                            for (
                                              var i = 0;
                                              i < report.categorySlices.length;
                                              i++
                                            )
                                              _buildPieSection(
                                                slice: report.categorySlices[i],
                                                isTouched:
                                                    i == _touchedPieIndex,
                                                theme: theme,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              l10n.expense,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              report.expenseMoney.format(
                                                locale: locale,
                                                masked: hideBalance,
                                              ),
                                              semanticsLabel: hideBalance
                                                  ? l10n.balanceHidden
                                                  : null,
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    fontFeatures:
                                                        AppTheme.tabularFigures,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              for (final slice in report.categorySlices) ...[
                                _CategoryLegendRow(
                                  slice: slice,
                                  locale: locale,
                                  hideBalance: hideBalance,
                                ),
                                const SizedBox(height: 10),
                              ],
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Bar Chart: 6-Month Income vs Expense Trend
                    AppleGlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.incomeVsExpenseTrend,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 16,
                              runSpacing: 6,
                              children: [
                                _LegendDot(
                                  color: context.financeColors.income,
                                  label: l10n.income,
                                ),
                                _LegendDot(
                                  color: context.financeColors.expense,
                                  label: l10n.expense,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 230,
                              child: _SixMonthTrendBarChart(
                                bars: report.sixMonthTrend,
                                locale: locale,
                                hideBalance: hideBalance,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _buildPieSection({
    required CategorySpendSlice slice,
    required bool isTouched,
    required ThemeData theme,
  }) {
    // Convert minor units to double strictly at fl_chart visual rendering boundary.
    final visualValue = slice.amountMinorUnits.toDouble();
    final sliceColor = Color(slice.color);
    final labelColor =
        ThemeData.estimateBrightnessForColor(sliceColor) == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);

    return PieChartSectionData(
      color: sliceColor,
      value: visualValue,
      radius: isTouched ? 44 : 36,
      showTitle: slice.percentage >= 8,
      title: '${slice.percentage}%',
      titleStyle: theme.textTheme.labelSmall?.copyWith(
        color: labelColor,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _MonthlySummaryHeader extends StatelessWidget {
  const _MonthlySummaryHeader({
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

    final incStat = _SummaryStatColumn(
      label: l10n.income,
      value: report.incomeMoney.format(
        locale: locale,
        showPlusSign: true,
        masked: hideBalance,
      ),
      semanticsValue: hideBalance ? l10n.balanceHidden : null,
      valueColor: financeColors.income,
    );
    final expStat = _SummaryStatColumn(
      label: l10n.expense,
      value: report.expenseMoney.format(
        locale: locale,
        masked: hideBalance,
      ),
      semanticsValue: hideBalance ? l10n.balanceHidden : null,
      valueColor: financeColors.expense,
    );
    final netStat = _SummaryStatColumn(
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
    final rateStat = _SummaryStatColumn(
      label: l10n.savingsRate,
      value: hideBalance ? '••%' : '${report.savingsRatePercent}%',
      semanticsValue: hideBalance ? l10n.balanceHidden : null,
      valueColor: theme.colorScheme.onSurface,
    );

    if (stackSingleCol) {
      return AppleGlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

class _SummaryStatColumn extends StatelessWidget {
  const _SummaryStatColumn({
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

class _CategoryLegendRow extends StatelessWidget {
  const _CategoryLegendRow({
    required this.slice,
    required this.locale,
    required this.hideBalance,
  });

  final CategorySpendSlice slice;
  final String locale;
  final bool hideBalance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final catColor = AppIconCatalog.contrastSafeColor(
      Color(slice.color),
      theme.brightness,
    );
    final name = DefaultCategoryLocalization.resolveName(
      l10n,
      categoryId: slice.categoryId,
      fallbackName: slice.fallbackName,
    );
    final formattedAmount = slice.amountMoney.format(
      locale: locale,
      masked: hideBalance,
    );

    return Semantics(
      container: true,
      label:
          '$name, ${slice.percentage}%, ${hideBalance ? l10n.balanceHidden : formattedAmount}',
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  AppIconCatalog.resolve(slice.icon),
                  size: 18,
                  color: catColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${slice.percentage}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: AppTheme.tabularFigures,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                flex: 0,
                child: Text(
                  formattedAmount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            child: LinearProgressIndicator(
              value: (slice.percentage / 100.0).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: catColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(catColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _SixMonthTrendBarChart extends StatelessWidget {
  const _SixMonthTrendBarChart({
    required this.bars,
    required this.locale,
    required this.hideBalance,
  });

  final List<MonthlyTrendBar> bars;
  final String locale;
  final bool hideBalance;

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
                barsSpace: 4,
                barRods: [
                  BarChartRodData(
                    toY: bars[i].incomeMinorUnits.toDouble(),
                    color: financeColors.income,
                    width: 11,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                  BarChartRodData(
                    toY: bars[i].expenseMinorUnits.toDouble(),
                    color: financeColors.expense,
                    width: 11,
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
