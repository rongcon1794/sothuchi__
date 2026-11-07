import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';

class CategorySpendPieChart extends StatefulWidget {
  const CategorySpendPieChart({
    super.key,
    required this.report,
    required this.locale,
    required this.hideBalance,
    this.height = 210,
    this.diameter = 210,
  });

  final MonthlyReportData report;
  final String locale;
  final bool hideBalance;
  final double height;
  final double diameter;

  @override
  State<CategorySpendPieChart> createState() => _CategorySpendPieChartState();
}

class _CategorySpendPieChartState extends State<CategorySpendPieChart> {
  int _touchedPieIndex = -1;

  @override
  void didUpdateWidget(covariant CategorySpendPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.report.selectedMonth != widget.report.selectedMonth) {
      _touchedPieIndex = -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final report = widget.report;
    final locale = widget.locale;
    final hideBalance = widget.hideBalance;

    final isSliceActive = _touchedPieIndex >= 0 &&
        _touchedPieIndex < report.categorySlices.length;
    final activeSlice =
        isSliceActive ? report.categorySlices[_touchedPieIndex] : null;

    return SizedBox(
      width: widget.diameter,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: PieChart(
              PieChartData(
                sectionsSpace: 3.0,
                centerSpaceRadius: 56,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      if (_touchedPieIndex != -1) {
                        setState(() => _touchedPieIndex = -1);
                      }
                      return;
                    }
                    final nextIndex =
                        response.touchedSection!.touchedSectionIndex;
                    if (_touchedPieIndex != nextIndex) {
                      unawaited(HapticFeedback.selectionClick());
                      setState(() => _touchedPieIndex = nextIndex);
                    }
                  },
                ),
                sections: [
                  for (var i = 0; i < report.categorySlices.length; i++)
                    _buildPieSection(
                      slice: report.categorySlices[i],
                      isTouched: i == _touchedPieIndex,
                      theme: theme,
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 104,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.88, end: 1.0).animate(
                      CurvedAnimation(
                        parent: anim,
                        curve: LucianTokens.spring,
                      ),
                    ),
                    child: child,
                  ),
                ),
                child: activeSlice != null
                    ? Column(
                        key: ValueKey<String>('active_${activeSlice.categoryId}'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIconCatalog.resolve(activeSlice.icon),
                            size: 18,
                            color: Color(activeSlice.color),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeSlice.fallbackName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeSlice.amountMoney.format(
                              locale: locale,
                              masked: hideBalance,
                            ),
                            semanticsLabel: hideBalance ? l10n.balanceHidden : null,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontFeatures: AppTheme.tabularFigures,
                              color: Color(activeSlice.color),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${activeSlice.percentage}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(activeSlice.color),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        key: const ValueKey<String>('summary_total'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.expense,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            report.expenseMoney.format(
                              locale: locale,
                              masked: hideBalance,
                            ),
                            semanticsLabel: hideBalance ? l10n.balanceHidden : null,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: AppTheme.tabularFigures,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${report.categorySlices.length} nhóm',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
              ),
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
      radius: isTouched ? 48 : 36,
      showTitle: slice.percentage >= 8 && !isTouched,
      title: '${slice.percentage}%',
      titleStyle: theme.textTheme.labelSmall?.copyWith(
        color: labelColor,
        fontWeight: FontWeight.w700,
      ),
      badgeWidget: isTouched
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                AppIconCatalog.resolve(slice.icon),
                size: 14,
                color: sliceColor,
              ),
            )
          : null,
      badgePositionPercentageOffset: 1.15,
    );
  }
}
