import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';

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
    final firstWeekday = DateTime(report.selectedMonth.year, report.selectedMonth.month, 1).weekday;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bản đồ Chi tiêu theo Ngày',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (report.peakSpendingDay > 0)
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
          ),
          const SizedBox(height: 6),
          Text(
            'Chạm vào ngày để xem số tiền đã chi tiêu chi tiết',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Day of week labels (T2 .. CN)
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WeekdayLabel('T2'),
              _WeekdayLabel('T3'),
              _WeekdayLabel('T4'),
              _WeekdayLabel('T5'),
              _WeekdayLabel('T6'),
              _WeekdayLabel('T7'),
              _WeekdayLabel('CN', isWeekend: true),
            ],
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final itemSize = (constraints.maxWidth - (6 * 6)) / 7;
              final totalCells = leadingEmptyCount + totalDays;
              final totalRows = (totalCells / 7).ceil();

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
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedDay = isSelected ? null : dayNumber;
                                  });
                                },
                                child: Container(
                                  width: itemSize,
                                  height: itemSize,
                                  decoration: BoxDecoration(
                                    color: cellColor,
                                    borderRadius: BorderRadius.circular(8),
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
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$dayNumber',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: dayExpense > 0 ? FontWeight.w700 : FontWeight.w500,
                                      color: _resolveTextColor(dayExpense, avgMinor, isDark),
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
            },
          ),

          // Day Detail Card
          if (_selectedDay != null) ...[
            const SizedBox(height: 14),
            Container(
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
            ),
          ],

          const SizedBox(height: 14),
          // Legend
          Row(
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
          ),
        ],
      ),
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

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.text, {this.isWeekend = false});

  final String text;
  final bool isWeekend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 32,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isWeekend
              ? AppleTokens.systemRed.withValues(alpha: 0.7)
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
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

