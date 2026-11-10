import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';

/// Interactive Apple-style Daily Spending Heatmap & Cashflow Pulse Rhythm.
///
/// Features:
/// 1. Dynamic Spending Pulse Waveform: Continuous horizontal daily cashflow stem chart
///    with average benchmark line, intensity gradients, and peak beacons.
/// 2. Squircle Calendar Matrix: Tactical day tiles with haptic feedback.
/// 3. Interactive Day Inspector Hero: Realtime spending analysis with benchmark comparisons.
/// 4. 4-Pillar Monthly Spending Rhythm Strip (Peak, Daily Avg, Active Days, Frugal Days).
class AppleSpendingHeatmap extends StatefulWidget {
  const AppleSpendingHeatmap({
    super.key,
    required this.report,
    required this.locale,
    required this.hideBalance,
    this.monthlyBudgetMinor,
  });

  final MonthlyReportData report;
  final String locale;
  final bool hideBalance;
  final int? monthlyBudgetMinor;

  @override
  State<AppleSpendingHeatmap> createState() => _AppleSpendingHeatmapState();
}

class _AppleSpendingHeatmapState extends State<AppleSpendingHeatmap> {
  int? _selectedDay;

  void _onScrubDay(double localX, double totalWidth, int totalDays) {
    if (totalDays <= 0 || totalWidth <= 0) return;
    final dayWidth = totalWidth / totalDays;
    final day = (localX / dayWidth).floor() + 1;
    final clampedDay = day.clamp(1, totalDays);
    if (_selectedDay != clampedDay) {
      HapticFeedback.selectionClick();
      setState(() => _selectedDay = clampedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final report = widget.report;
    final totalDays = report.daysInMonth;
    final avgMinor = report.averageDailyExpenseMinor;
    final benchmarkMinor = report.activeDailyExpenseMinor;
    final int? dailyBudget = (widget.monthlyBudgetMinor != null &&
            widget.monthlyBudgetMinor! > 0 &&
            totalDays > 0)
        ? (widget.monthlyBudgetMinor! / totalDays).round()
        : null;

    // First day of month weekday (1 = Mon, 7 = Sun)
    final firstWeekday =
        DateTime(report.selectedMonth.year, report.selectedMonth.month, 1).weekday;
    final leadingEmptyCount = (firstWeekday - 1) % 7;

    final selectedAmount = _selectedDay != null
        ? (report.dailyExpenseMinor[_selectedDay!] ?? 0)
        : null;

    final frugalDaysCount = math.max(
      0,
      report.elapsedDaysInMonth - report.activeSpendingDaysCount,
    );

    return AppleGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Title and Peak Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppleTokens.jadePrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.waveform_path,
                  size: 16,
                  color: AppleTokens.jadePrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.reportsSpendingHeatmap,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (report.peakSpendingDay > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppleTokens.systemRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    border: Border.all(
                      color: AppleTokens.systemRed.withValues(alpha: 0.25),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppleTokens.systemRed,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Đỉnh: Ngày ${report.peakSpendingDay}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppleTokens.systemRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // 1. Creative Daily Spending Rhythm Waveform (Biểu đồ nhịp điệu chi tiêu hằng ngày)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? (context.isOled
                      ? AppleTokens.bgOledSecondary.withValues(alpha: 0.6)
                      : AppleTokens.bgDarkSecondary.withValues(alpha: 0.6))
                  : AppleTokens.bgLightSecondary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                width: AppleTokens.hairline,
              ),
            ),
            child: SizedBox(
              height: 52,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (details) =>
                        _onScrubDay(details.localPosition.dx, constraints.maxWidth, totalDays),
                    onTapDown: (details) =>
                        _onScrubDay(details.localPosition.dx, constraints.maxWidth, totalDays),
                    child: CustomPaint(
                      painter: _DailySpendingPulsePainter(
                        dailyExpenseMinor: report.dailyExpenseMinor,
                        daysInMonth: totalDays,
                        avgMinor: avgMinor,
                        benchmarkMinor: benchmarkMinor,
                        dailyBudgetMinor: dailyBudget,
                        peakSpendingDay: report.peakSpendingDay,
                        selectedDay: _selectedDay,
                        isDark: isDark,
                      ),
                      size: Size.infinite,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Responsive Calendar & Inspector Area
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideScreen = constraints.maxWidth >= 600;

              if (isWideScreen) {
                // Wide Landscape / Tablet: Side-by-side layout (Grid on left, Inspector & Stats on right)
                const gridWidth = 350.0;
                const cellGap = 6.0;
                const itemSize = (gridWidth - (6 * cellGap)) / 7;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Compact Calendar Grid
                    SizedBox(
                      width: gridWidth,
                      child: Column(
                        children: [
                          _buildWeekdayHeader(itemSize),
                          const SizedBox(height: 8),
                          _buildCalendarGrid(
                            itemSize: itemSize,
                            leadingEmptyCount: leadingEmptyCount,
                            totalDays: totalDays,
                            avgMinor: avgMinor,
                            benchmarkMinor: benchmarkMinor,
                            dailyBudget: dailyBudget,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Right Column: Day Inspector & Month Overview
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWideInspectorPanel(
                            theme: theme,
                            isDark: isDark,
                            selectedAmount: selectedAmount,
                            avgMinor: avgMinor,
                            benchmarkMinor: benchmarkMinor,
                            dailyBudget: dailyBudget,
                          ),
                          const SizedBox(height: 14),
                          _buildSpendingPillarsStrip(
                            report: report,
                            totalDays: totalDays,
                            avgMinor: avgMinor,
                            frugalDays: frugalDaysCount,
                            isDark: isDark,
                            theme: theme,
                          ),
                          const SizedBox(height: 14),
                          _buildLegend(theme, isDark),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Mobile Portrait: Constrained centered grid (never stretching wider than 420px)
              final gridWidth = constraints.maxWidth.clamp(280.0, 420.0);
              const cellGap = 6.0;
              final itemSize = (gridWidth - (6 * cellGap)) / 7;

              return Column(
                children: [
                  Center(
                    child: SizedBox(
                      width: gridWidth,
                      child: Column(
                        children: [
                          _buildWeekdayHeader(itemSize),
                          const SizedBox(height: 8),
                          _buildCalendarGrid(
                            itemSize: itemSize,
                            leadingEmptyCount: leadingEmptyCount,
                            totalDays: totalDays,
                            avgMinor: avgMinor,
                            benchmarkMinor: benchmarkMinor,
                            dailyBudget: dailyBudget,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Smooth Animated Compact Day Detail Card (Portrait)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        alignment: Alignment.topCenter,
                        child: child,
                      ),
                    ),
                    child: _selectedDay != null
                        ? Padding(
                            key: ValueKey('day_detail_$_selectedDay'),
                            padding: const EdgeInsets.only(top: 14),
                            child: _buildPortraitDetailCard(
                              theme: theme,
                              isDark: isDark,
                              selectedAmount: selectedAmount,
                              avgMinor: avgMinor,
                              dailyBudget: dailyBudget,
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('day_detail_none')),
                  ),

                  const SizedBox(height: 14),
                  _buildSpendingPillarsStrip(
                    report: report,
                    totalDays: totalDays,
                    avgMinor: avgMinor,
                    frugalDays: frugalDaysCount,
                    isDark: isDark,
                    theme: theme,
                  ),
                  const SizedBox(height: 14),
                  _buildLegend(theme, isDark),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// 4-Pillar Monthly Spending Rhythm Strip (Peak, Daily Avg, Active Days, Frugal Days).
  Widget _buildSpendingPillarsStrip({
    required MonthlyReportData report,
    required int totalDays,
    required int avgMinor,
    required int frugalDays,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? (context.isOled
                ? AppleTokens.bgOledSecondary.withValues(alpha: 0.4)
                : AppleTokens.bgDarkSecondary.withValues(alpha: 0.4))
            : AppleTokens.bgLightSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPillarItem(
              icon: CupertinoIcons.flame_fill,
              iconColor: AppleTokens.systemRed,
              label: 'Đỉnh chi',
              value: report.peakSpendingDay > 0 ? 'N${report.peakSpendingDay}' : '—',
              theme: theme,
            ),
          ),
          Container(width: 1, height: 28, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          Expanded(
            child: _buildPillarItem(
              icon: CupertinoIcons.chart_bar_alt_fill,
              iconColor: AppleTokens.systemOrange,
              label: 'TB/ngày',
              value: Money(minorUnits: avgMinor, currencyCode: report.currencyCode)
                  .format(locale: widget.locale, masked: widget.hideBalance),
              theme: theme,
            ),
          ),
          Container(width: 1, height: 28, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          Expanded(
            child: _buildPillarItem(
              icon: CupertinoIcons.calendar,
              iconColor: AppleTokens.systemBlue,
              label: 'Có chi',
              value: '${report.activeSpendingDaysCount} ngày',
              theme: theme,
            ),
          ),
          Container(width: 1, height: 28, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
          Expanded(
            child: _buildPillarItem(
              icon: CupertinoIcons.shield_fill,
              iconColor: AppleTokens.jadePrimary,
              label: 'Tiết kiệm',
              value: '$frugalDays ngày',
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 12, color: iconColor),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5,
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            fontFeatures: AppTheme.tabularFigures,
          ),
        ),
      ],
    );
  }

  /// Aligned weekday column headers (T2 .. CN) matching cell width exactly.
  Widget _buildWeekdayHeader(double itemSize) {
    const weekdays = [
      ('T2', false),
      ('T3', false),
      ('T4', false),
      ('T5', false),
      ('T6', false),
      ('T7', false),
      ('CN', true),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final (name, isWeekend) in weekdays)
          SizedBox(
            width: itemSize,
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isWeekend
                    ? AppleTokens.systemRed.withValues(alpha: 0.75)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  /// Calendar rows with tactile Apple pressable cells.
  Widget _buildCalendarGrid({
    required double itemSize,
    required int leadingEmptyCount,
    required int totalDays,
    required int avgMinor,
    required int benchmarkMinor,
    required int? dailyBudget,
    required bool isDark,
  }) {
    final report = widget.report;
    final totalCells = leadingEmptyCount + totalDays;
    final totalRows = (totalCells / 7).ceil();
    final cellRadius = BorderRadius.circular(8);

    return RepaintBoundary(
      child: Column(
        children: [
        for (var r = 0; r < totalRows; r++) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var c = 0; c < 7; c++) ...[
                Builder(
                  builder: (context) {
                    final cellIndex = r * 7 + c;
                    final dayNumber = cellIndex - leadingEmptyCount + 1;
                    if (cellIndex < leadingEmptyCount || dayNumber > totalDays) {
                      return SizedBox(width: itemSize, height: itemSize);
                    }

                    final dayExpense = report.dailyExpenseMinor[dayNumber] ?? 0;
                    final isSelected = _selectedDay == dayNumber;
                    final cellColor = _resolveHeatmapColor(
                      expense: dayExpense,
                      benchmarkExpense: benchmarkMinor,
                      dailyBudget: dailyBudget,
                      isDark: isDark,
                    );

                    return ApplePressable(
                      borderRadius: cellRadius,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedDay = isSelected ? null : dayNumber;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        width: itemSize,
                        height: itemSize,
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: cellRadius,
                          border: isSelected
                              ? Border.all(
                                  color: isDark ? Colors.white : AppleTokens.jadeDark,
                                  width: 2,
                                )
                              : Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.05),
                                  width: 0.5,
                                ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (isDark ? Colors.white : AppleTokens.jadeDark)
                                        .withValues(alpha: 0.22),
                                    blurRadius: 4,
                                    spreadRadius: 0.5,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected || dayExpense > 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? Colors.white : AppleTokens.jadeDark)
                                : _resolveTextColor(
                                    expense: dayExpense,
                                    benchmarkExpense: benchmarkMinor,
                                    dailyBudget: dailyBudget,
                                    isDark: isDark,
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          if (r < totalRows - 1) const SizedBox(height: 6),
        ],
      ],
    ),
  );
}

  /// Right inspector panel on wide screens (Landscape/Tablet).
  Widget _buildWideInspectorPanel({
    required ThemeData theme,
    required bool isDark,
    required int? selectedAmount,
    required int avgMinor,
    required int benchmarkMinor,
    required int? dailyBudget,
  }) {
    final report = widget.report;

    if (_selectedDay != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? (context.isOled
                  ? AppleTokens.bgOledSecondary
                  : AppleTokens.bgDarkPrimary)
              : AppleTokens.bgLightSecondary,
          borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
          border: Border.all(
            color: AppleTokens.jadePrimary.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  CupertinoIcons.calendar_today,
                  size: 16,
                  color: AppleTokens.jadePrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ngày $_selectedDay/${report.selectedMonth.month}:',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const Spacer(),
                ApplePressable(
                  onTap: () => setState(() => _selectedDay = null),
                  child: Icon(
                    CupertinoIcons.clear_circled_solid,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Tổng chi trong ngày:',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              selectedAmount != null && selectedAmount > 0
                  ? Money(
                      minorUnits: selectedAmount,
                      currencyCode: report.currencyCode,
                    ).format(
                      locale: widget.locale,
                      masked: widget.hideBalance,
                    )
                  : context.l10n.heatmapNoSpending,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: selectedAmount != null && selectedAmount > 0
                    ? AppleTokens.systemRed
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (selectedAmount != null && selectedAmount > 0) ...[
              const SizedBox(height: 8),
              _buildComparisonBadge(
                expense: selectedAmount,
                avgExpense: benchmarkMinor > 0 ? benchmarkMinor : avgMinor,
                dailyBudget: dailyBudget,
              ),
            ],
          ],
        ),
      );
    }

    // Default overview when no day is selected on wide screen
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
              const Icon(
                CupertinoIcons.info_circle,
                size: 15,
                color: AppleTokens.jadePrimary,
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.heatmapMonthlySummary,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (dailyBudget != null && dailyBudget > 0) ...[
            _buildStatRow(
              theme,
              'Ngân sách TB/ngày:',
              '${Money(minorUnits: dailyBudget, currencyCode: report.currencyCode).format(
                locale: widget.locale,
                masked: widget.hideBalance,
              )}/ngày',
            ),
            const SizedBox(height: 4),
          ],
          _buildStatRow(
            theme,
            'Chi tiêu TB/ngày:',
            '${Money(minorUnits: avgMinor, currencyCode: report.currencyCode).format(
              locale: widget.locale,
              masked: widget.hideBalance,
            )}${report.elapsedDaysInMonth < report.daysInMonth ? ' (${report.elapsedDaysInMonth} ngày đã qua)' : ''}',
          ),
          const SizedBox(height: 4),
          _buildStatRow(
            theme,
            'Ngày chi nhiều nhất:',
            report.peakSpendingDay > 0
                ? 'Ngày ${report.peakSpendingDay} (${Money(minorUnits: report.peakSpendingAmountMinor, currencyCode: report.currencyCode).format(locale: widget.locale, masked: widget.hideBalance)})'
                : context.l10n.heatmapNone,
          ),
          const SizedBox(height: 4),
          _buildStatRow(
            theme,
            'Số ngày phát sinh chi:',
            report.elapsedDaysInMonth < report.daysInMonth
                ? '${report.activeSpendingDaysCount} / ${report.elapsedDaysInMonth} ngày'
                : '${report.activeSpendingDaysCount} / ${report.daysInMonth} ngày',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(ThemeData theme, String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonBadge({
    required int expense,
    required int avgExpense,
    required int? dailyBudget,
  }) {
    if (dailyBudget != null && dailyBudget > 0) {
      final diffPercent = (((expense - dailyBudget) / dailyBudget) * 100).round();
      final isOverBudget = expense > dailyBudget;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: (isOverBudget ? AppleTokens.systemRed : AppleTokens.jadePrimary)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
        ),
        child: Text(
          isOverBudget
              ? 'Vượt NS ngày +$diffPercent%'
              : (diffPercent == 0
                  ? 'Đạt đúng 100% NS ngày'
                  : 'Trong NS ngày (${diffPercent.abs()}%)'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isOverBudget ? AppleTokens.systemRed : AppleTokens.jadePrimary,
          ),
        ),
      );
    }

    if (avgExpense <= 0) return const SizedBox.shrink();

    final diffPercent = (((expense - avgExpense) / avgExpense) * 100).round();
    final isHigher = diffPercent > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isHigher ? AppleTokens.systemRed : AppleTokens.jadePrimary)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
      ),
      child: Text(
        isHigher
            ? 'Cao hơn TB ngày +$diffPercent%'
            : 'Thấp hơn TB ngày ${diffPercent.abs()}%',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isHigher ? AppleTokens.systemRed : AppleTokens.jadePrimary,
        ),
      ),
    );
  }

  /// Compact single-card detail for portrait mode.
  Widget _buildPortraitDetailCard({
    required ThemeData theme,
    required bool isDark,
    required int? selectedAmount,
    required int avgMinor,
    required int? dailyBudget,
  }) {
    final report = widget.report;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? (context.isOled
                ? AppleTokens.bgOledSecondary
                : AppleTokens.bgDarkPrimary)
            : AppleTokens.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
        border: Border.all(
          color: AppleTokens.jadePrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.calendar_today,
                size: 16,
                color: AppleTokens.jadePrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Ngày $_selectedDay/${report.selectedMonth.month}:',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const Spacer(),
              Text(
                selectedAmount != null && selectedAmount > 0
                    ? Money(
                        minorUnits: selectedAmount,
                        currencyCode: report.currencyCode,
                      ).format(
                        locale: widget.locale,
                        masked: widget.hideBalance,
                      )
                    : context.l10n.heatmapNoSpending,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selectedAmount != null && selectedAmount > 0
                      ? AppleTokens.systemRed
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              ApplePressable(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedDay = null);
                },
                child: Icon(
                  CupertinoIcons.clear_circled_solid,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          if (selectedAmount != null && selectedAmount > 0) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: _buildComparisonBadge(
                expense: selectedAmount,
                avgExpense: avgMinor,
                dailyBudget: dailyBudget,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 4-tier spending intensity legend.
  Widget _buildLegend(ThemeData theme, bool isDark) {
    final isVi = widget.locale.startsWith('vi');

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 6,
      children: [
        _buildLegendItem(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          label: isVi ? 'Không chi tiêu' : 'Zero',
          theme: theme,
        ),
        _buildLegendItem(
          color: AppleTokens.jadePrimary.withValues(alpha: isDark ? 0.45 : 0.38),
          label: isVi ? 'Thấp' : 'Low',
          theme: theme,
        ),
        _buildLegendItem(
          color: AppleTokens.systemOrange.withValues(alpha: isDark ? 0.70 : 0.65),
          label: isVi ? 'Trung bình' : 'Medium',
          theme: theme,
        ),
        _buildLegendItem(
          color: AppleTokens.systemRed.withValues(alpha: isDark ? 0.88 : 0.85),
          label: isVi ? 'Cao' : 'High',
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Color gradation based on spending relative to daily average benchmark.
  Color _resolveHeatmapColor({
    required int expense,
    required int benchmarkExpense,
    required int? dailyBudget,
    required bool isDark,
  }) {
    if (expense == 0) {
      return isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.05);
    }

    if (dailyBudget != null && dailyBudget > 0) {
      // User has configured a budget: low, medium, high relative to daily quota
      final ratio = expense / dailyBudget;
      if (ratio < 0.65) {
        return AppleTokens.jadePrimary.withValues(alpha: isDark ? 0.45 : 0.38);
      } else if (ratio <= 1.0) {
        return AppleTokens.systemOrange.withValues(alpha: isDark ? 0.70 : 0.65);
      } else {
        return AppleTokens.systemRed.withValues(alpha: isDark ? 0.88 : 0.85);
      }
    }

    // Default when no budget: relative to benchmark (active daily average)
    if (benchmarkExpense <= 0) {
      return AppleTokens.jadePrimary.withValues(alpha: isDark ? 0.45 : 0.38);
    }

    final ratio = expense / benchmarkExpense;
    if (ratio < 0.65) {
      return AppleTokens.jadePrimary.withValues(alpha: isDark ? 0.45 : 0.38);
    } else if (ratio <= 1.35) {
      return AppleTokens.systemOrange.withValues(alpha: isDark ? 0.70 : 0.65);
    } else {
      return AppleTokens.systemRed.withValues(alpha: isDark ? 0.88 : 0.85);
    }
  }

  Color _resolveTextColor({
    required int expense,
    required int benchmarkExpense,
    required int? dailyBudget,
    required bool isDark,
  }) {
    if (expense == 0) {
      return isDark ? Colors.white54 : Colors.black45;
    }

    if (dailyBudget != null && dailyBudget > 0) {
      final ratio = expense / dailyBudget;
      if (ratio < 0.65) {
        return isDark ? Colors.white : AppleTokens.jadeDark;
      }
      return Colors.white;
    }

    if (benchmarkExpense <= 0) return Colors.white;

    final ratio = expense / benchmarkExpense;
    if (ratio < 0.65) {
      return isDark ? Colors.white : AppleTokens.jadeDark;
    }
    return Colors.white;
  }
}

/// Custom painter for the creative Daily Spending Pulse Rhythm Waveform.
class _DailySpendingPulsePainter extends CustomPainter {
  _DailySpendingPulsePainter({
    required this.dailyExpenseMinor,
    required this.daysInMonth,
    required this.avgMinor,
    required this.benchmarkMinor,
    this.dailyBudgetMinor,
    required this.peakSpendingDay,
    required this.selectedDay,
    required this.isDark,
  });

  final Map<int, int> dailyExpenseMinor;
  final int daysInMonth;
  final int avgMinor;
  final int benchmarkMinor;
  final int? dailyBudgetMinor;
  final int peakSpendingDay;
  final int? selectedDay;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (daysInMonth <= 0 || size.width <= 0 || size.height <= 0) return;

    var maxExpense = 0;
    for (final exp in dailyExpenseMinor.values) {
      if (exp > maxExpense) maxExpense = exp;
    }
    if (maxExpense <= 0) maxExpense = 1;

    final cellWidth = size.width / daysInMonth;
    final barWidth = math.max(3.0, (cellWidth * 0.65).clamp(3.0, 9.0));
    final baselineY = size.height - 4.0;
    final availableHeight = size.height - 14.0;

    // Draw guideline: daily budget guideline if configured, otherwise daily average
    final hasBudget = dailyBudgetMinor != null && dailyBudgetMinor! > 0;
    final targetGuideline = hasBudget ? dailyBudgetMinor! : avgMinor;

    if (targetGuideline > 0 && maxExpense > 0) {
      final guideRatio = (targetGuideline / maxExpense).clamp(0.08, 0.92);
      final guideY = baselineY - (availableHeight * guideRatio);
      final dashPaint = Paint()
        ..color = hasBudget
            ? AppleTokens.systemOrange.withValues(alpha: isDark ? 0.75 : 0.65)
            : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.22)
        ..strokeWidth = hasBudget ? 1.2 : 1.0
        ..style = PaintingStyle.stroke;

      const dashWidth = 4.0;
      const dashSpace = 3.0;
      double startX = 0.0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, guideY),
          Offset(math.min(startX + dashWidth, size.width), guideY),
          dashPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    final trackPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    for (var day = 1; day <= daysInMonth; day++) {
      final centerX = (day - 0.5) * cellWidth;
      final expense = dailyExpenseMinor[day] ?? 0;
      final isSelected = selectedDay == day;
      final isPeak = day == peakSpendingDay && expense > 0;

      // Ghost track
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, baselineY - (availableHeight / 2)),
          width: barWidth,
          height: availableHeight,
        ),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(trackRect, trackPaint);

      if (expense == 0) {
        // Zero expense day: subtle resting dot
        final dotPaint = Paint()
          ..color = (isDark ? Colors.white : Colors.black)
              .withValues(alpha: isSelected ? 0.7 : 0.15)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(centerX, baselineY - 2), barWidth / 2, dotPaint);
      } else {
        final ratio = (expense / maxExpense).clamp(0.12, 1.0);
        final barHeight = availableHeight * ratio;
        final topY = baselineY - barHeight;

        // Gradient based on spending level
        final Color topColor;
        final Color bottomColor;

        if (hasBudget) {
          final budgetRatio = expense / dailyBudgetMinor!;
          if (budgetRatio > 1.0) {
            topColor = AppleTokens.rubyExpense;
            bottomColor = const Color(0xFFFF6961);
          } else if (budgetRatio >= 0.65) {
            topColor = AppleTokens.systemOrange;
            bottomColor = const Color(0xFFFFCC00);
          } else {
            topColor = AppleTokens.emeraldIncome;
            bottomColor = const Color(0xFF00C7BE);
          }
        } else {
          final effectiveBenchmark = benchmarkMinor > 0 ? benchmarkMinor : avgMinor;
          if (effectiveBenchmark > 0 && expense > effectiveBenchmark * 1.35) {
            topColor = AppleTokens.rubyExpense;
            bottomColor = const Color(0xFFFF6961);
          } else if (effectiveBenchmark > 0 && expense >= effectiveBenchmark * 0.65) {
            topColor = AppleTokens.systemOrange;
            bottomColor = const Color(0xFFFFCC00);
          } else {
            topColor = AppleTokens.emeraldIncome;
            bottomColor = const Color(0xFF00C7BE);
          }
        }

        final barRect = Rect.fromCenter(
          center: Offset(centerX, baselineY - (barHeight / 2)),
          width: barWidth,
          height: barHeight,
        );
        final barRRect = RRect.fromRectAndRadius(
          barRect,
          Radius.circular(barWidth / 2),
        );

        final barPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [bottomColor, topColor],
          ).createShader(barRect);

        canvas.drawRRect(barRRect, barPaint);

        // Peak day radiant beacon
        if (isPeak) {
          final beaconPaint = Paint()
            ..color = AppleTokens.rubyExpense.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
          canvas.drawCircle(Offset(centerX, topY), barWidth * 0.9, beaconPaint);

          final innerBeacon = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(centerX, topY), barWidth / 2.3, innerBeacon);
        }

        // Selected day halo
        if (isSelected) {
          final selectPaint = Paint()
            ..color = isDark ? Colors.white : AppleTokens.jadeDark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              barRect.inflate(2.0),
              Radius.circular((barWidth / 2) + 2),
            ),
            selectPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DailySpendingPulsePainter oldDelegate) {
    return oldDelegate.dailyExpenseMinor != dailyExpenseMinor ||
        oldDelegate.selectedDay != selectedDay ||
        oldDelegate.daysInMonth != daysInMonth ||
        oldDelegate.avgMinor != avgMinor ||
        oldDelegate.benchmarkMinor != benchmarkMinor ||
        oldDelegate.dailyBudgetMinor != dailyBudgetMinor ||
        oldDelegate.peakSpendingDay != peakSpendingDay ||
        oldDelegate.isDark != isDark;
  }
}
