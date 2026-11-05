import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';

/// Interactive Apple-style Daily Spending Heatmap.
/// Adapts gracefully between mobile portrait and wide landscape/tablet screens:
/// - Narrow screens (<600px): Clean vertical stack with constrained centered grid (max 420px).
/// - Wide screens (>=600px): Two-column side-by-side layout (compact grid on left, inspector & insights on right).
class AppleSpendingHeatmap extends StatefulWidget {
  const AppleSpendingHeatmap({
    super.key,
    required this.report,
    required this.locale,
    required this.hideBalance,
  });

  final MonthlyReportData report;
  final String locale;
  final bool hideBalance;

  @override
  State<AppleSpendingHeatmap> createState() => _AppleSpendingHeatmapState();
}

class _AppleSpendingHeatmapState extends State<AppleSpendingHeatmap> {
  int? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final report = widget.report;
    final totalDays = report.daysInMonth;
    final avgMinor = report.averageDailyExpenseMinor;

    // First day of month weekday (1 = Mon, 7 = Sun)
    final firstWeekday =
        DateTime(report.selectedMonth.year, report.selectedMonth.month, 1).weekday;
    final leadingEmptyCount = (firstWeekday - 1) % 7;

    final selectedAmount = _selectedDay != null
        ? (report.dailyExpenseMinor[_selectedDay!] ?? 0)
        : null;

    return AppleGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bản đồ Chi tiêu theo Ngày',
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
                  ),
                  child: Text(
                    'Đỉnh: Ngày ${report.peakSpendingDay}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppleTokens.systemRed,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Chạm vào ngày để xem số tiền đã chi tiêu chi tiết',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

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
                          ),
                          const SizedBox(height: 16),
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
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Compact Day Detail Card (Portrait)
                  if (_selectedDay != null) ...[
                    const SizedBox(height: 14),
                    _buildPortraitDetailCard(
                      theme: theme,
                      isDark: isDark,
                      selectedAmount: selectedAmount,
                      avgMinor: avgMinor,
                    ),
                  ],

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
    required bool isDark,
  }) {
    final report = widget.report;
    final totalCells = leadingEmptyCount + totalDays;
    final totalRows = (totalCells / 7).ceil();
    final cellRadius = BorderRadius.circular(8);

    return Column(
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
                      avgExpense: avgMinor,
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
                                : _resolveTextColor(dayExpense, avgMinor, isDark),
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
    );
  }

  /// Right inspector panel on wide screens (Landscape/Tablet).
  Widget _buildWideInspectorPanel({
    required ThemeData theme,
    required bool isDark,
    required int? selectedAmount,
    required int avgMinor,
  }) {
    final report = widget.report;

    if (_selectedDay != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppleTokens.bgDarkPrimary : AppleTokens.bgLightSecondary,
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
                  : 'Không có chi tiêu',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: selectedAmount != null && selectedAmount > 0
                    ? AppleTokens.systemRed
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (selectedAmount != null && selectedAmount > 0 && avgMinor > 0) ...[
              const SizedBox(height: 8),
              _buildComparisonBadge(selectedAmount, avgMinor),
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
              const Icon(
                CupertinoIcons.info_circle,
                size: 15,
                color: AppleTokens.jadePrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'Tổng quan Chi tiêu Tháng',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            theme,
            'Chi tiêu TB/ngày:',
            Money(minorUnits: avgMinor, currencyCode: report.currencyCode).format(
              locale: widget.locale,
              masked: widget.hideBalance,
            ),
          ),
          const SizedBox(height: 4),
          _buildStatRow(
            theme,
            'Ngày chi nhiều nhất:',
            report.peakSpendingDay > 0
                ? 'Ngày ${report.peakSpendingDay} (${Money(minorUnits: report.peakSpendingAmountMinor, currencyCode: report.currencyCode).format(locale: widget.locale, masked: widget.hideBalance)})'
                : 'Không có',
          ),
          const SizedBox(height: 4),
          _buildStatRow(
            theme,
            'Số ngày phát sinh chi:',
            '${report.activeSpendingDaysCount} / ${report.daysInMonth} ngày',
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

  Widget _buildComparisonBadge(int expense, int avgExpense) {
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
  }) {
    final report = widget.report;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppleTokens.bgDarkPrimary : AppleTokens.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
        border: Border.all(
          color: AppleTokens.jadePrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
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
                : 'Không có chi tiêu',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: selectedAmount != null && selectedAmount > 0
                  ? AppleTokens.systemRed
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Ít',
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 6),
        _LegendBox(color: _heatColorLevel1(isDark)),
        const SizedBox(width: 4),
        _LegendBox(color: _heatColorLevel2(isDark)),
        const SizedBox(width: 4),
        _LegendBox(color: _heatColorLevel3(isDark)),
        const SizedBox(width: 4),
        _LegendBox(color: _heatColorLevel4(isDark)),
        const SizedBox(width: 6),
        Text(
          'Nhiều',
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  static Color _heatColorLevel1(bool isDark) =>
      isDark ? AppleTokens.bgDarkTertiary : const Color(0xFFF1F5F9);

  static Color _heatColorLevel2(bool isDark) =>
      AppleTokens.jadePrimary.withValues(alpha: isDark ? 0.28 : 0.22);

  static Color _heatColorLevel3(bool isDark) =>
      AppleTokens.systemOrange.withValues(alpha: isDark ? 0.55 : 0.45);

  static Color _heatColorLevel4(bool isDark) =>
      AppleTokens.systemRed.withValues(alpha: isDark ? 0.85 : 0.75);

  Color _resolveHeatmapColor({
    required int expense,
    required int avgExpense,
    required bool isDark,
  }) {
    if (expense == 0) return _heatColorLevel1(isDark);
    if (avgExpense <= 0) return _heatColorLevel2(isDark);

    final ratio = expense / avgExpense;
    if (ratio < 0.6) return _heatColorLevel2(isDark);
    if (ratio <= 1.4) return _heatColorLevel3(isDark);
    return _heatColorLevel4(isDark);
  }

  Color _resolveTextColor(int expense, int avgExpense, bool isDark) {
    if (expense == 0) {
      return isDark
          ? Colors.white.withValues(alpha: 0.35)
          : Colors.black.withValues(alpha: 0.35);
    }
    if (avgExpense > 0 && expense / avgExpense > 1.4) {
      return Colors.white;
    }
    return isDark ? Colors.white : Colors.black87;
  }
}

class _LegendBox extends StatelessWidget {
  const _LegendBox({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
