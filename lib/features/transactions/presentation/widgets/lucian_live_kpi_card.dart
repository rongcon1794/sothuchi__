import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

/// Available KPI Metric modes inspired by Lucian Element #098
enum LucianKpiMetric {
  balance,
  income,
  expense,
}

/// Lucian Labs #098: Realtime Live KPI & Cashflow Hero Card.
///
/// Features:
/// 1. Breathing live pulse status ring (`u098-live`).
/// 2. Rolling tabular numeral display with privacy masking.
/// 3. Dynamic comparison delta badge (`u098-bd`) with micro up/down arrows.
/// 4. Smooth cubic-bezier sparkline with luminous gradient area fill.
/// 5. Segmented metric switcher tabs (`u098-tabs`) for Net Balance, Income, and Expense.
class LucianLiveKpiCard extends StatefulWidget {
  const LucianLiveKpiCard({
    super.key,
    required this.totalBalance,
    required this.monthSummary,
    this.transactions = const <TransactionEntity>[],
    required this.locale,
    required this.hideBalance,
    required this.onToggleVisibility,
    this.initialMetric = LucianKpiMetric.balance,
    this.onNavigateTransactions,
  });

  final Money totalBalance;
  final MonthlyCashflowSummary monthSummary;
  final List<TransactionEntity> transactions;
  final String locale;
  final bool hideBalance;
  final VoidCallback onToggleVisibility;
  final LucianKpiMetric initialMetric;
  final VoidCallback? onNavigateTransactions;

  @override
  State<LucianLiveKpiCard> createState() => _LucianLiveKpiCardState();
}

class LucianSparkPoint {
  const LucianSparkPoint({
    required this.date,
    required this.rawValue,
    required this.normalizedY,
  });

  final DateTime date;
  final double rawValue;
  final double normalizedY;
}

class _LucianLiveKpiCardState extends State<LucianLiveKpiCard>
    with SingleTickerProviderStateMixin {
  late LucianKpiMetric _activeMetric;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int? _scrubbedIndex;
  Timer? _scrubResetTimer;

  @override
  void initState() {
    super.initState();
    _activeMetric = widget.initialMetric;

    // Continuous breathing pulse animation for the live status dot
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
      _pulseController.repeat();
    } else {
      _pulseController.value = 0.5;
    }

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scrubResetTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _switchMetric(LucianKpiMetric metric) {
    if (_activeMetric == metric) return;
    HapticFeedback.selectionClick();
    _scrubResetTimer?.cancel();
    setState(() {
      _activeMetric = metric;
      _scrubbedIndex = null;
    });
  }

  void _onScrub(double localX, double totalWidth, int count) {
    if (count < 2 || totalWidth <= 0) return;
    _scrubResetTimer?.cancel();
    final step = totalWidth / (count - 1);
    final index = (localX / step).round().clamp(0, count - 1);
    if (index != _scrubbedIndex) {
      unawaited(HapticFeedback.selectionClick());
      setState(() => _scrubbedIndex = index);
    }
  }

  void _scheduleScrubReset() {
    _scrubResetTimer?.cancel();
    _scrubResetTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() => _scrubbedIndex = null);
      }
    });
  }

  void _resetScrub() {
    _scrubResetTimer?.cancel();
    if (_scrubbedIndex != null && mounted) {
      setState(() => _scrubbedIndex = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    // Resolve color by active metric
    final (accentColor, metricTitle, activeMoney) = switch (_activeMetric) {
      LucianKpiMetric.balance => (
          LucianTokens.resolveAccent(isDark),
          l10n.totalBalance.toUpperCase(),
          widget.totalBalance,
        ),
      LucianKpiMetric.income => (
          LucianTokens.resolveMint(isDark),
          l10n.income.toUpperCase(),
          widget.monthSummary.income,
        ),
      LucianKpiMetric.expense => (
          LucianTokens.resolveDanger(isDark),
          l10n.expense.toUpperCase(),
          widget.monthSummary.expense,
        ),
    };

    // Calculate dynamic savings rate / net delta accurately
    final totalFlow = widget.monthSummary.income.minorUnits +
        widget.monthSummary.expense.minorUnits;
    final hasFlow = totalFlow > 0;
    final incomeUnits = widget.monthSummary.income.minorUnits;
    final expenseUnits = widget.monthSummary.expense.minorUnits;
    final netUnits = widget.monthSummary.net.minorUnits;

    final String deltaLabel;
    final bool isDeltaPositive;
    if (_activeMetric == LucianKpiMetric.balance) {
      if (netUnits > 0) {
        final rate = incomeUnits > 0
            ? ((netUnits / incomeUnits) * 100).round()
            : 100;
        deltaLabel = '+$rate% tích lũy tháng';
        isDeltaPositive = true;
      } else if (netUnits < 0) {
        if (incomeUnits > 0) {
          final rate = ((netUnits.abs() / incomeUnits) * 100).round();
          deltaLabel = '-$rate% thâm hụt';
        } else {
          deltaLabel = 'Chi ròng tháng này';
        }
        isDeltaPositive = false;
      } else {
        deltaLabel = hasFlow ? 'Thu chi cân bằng' : 'Số dư ổn định';
        isDeltaPositive = true;
      }
    } else if (_activeMetric == LucianKpiMetric.income) {
      if (incomeUnits > 0 && totalFlow > 0) {
        final incShare = ((incomeUnits / totalFlow) * 100).round();
        deltaLabel = '$incShare% dòng tiền vào';
      } else {
        deltaLabel = 'Chưa có thu nhập tháng';
      }
      isDeltaPositive = true;
    } else {
      if (expenseUnits > 0 && totalFlow > 0) {
        final expShare = ((expenseUnits / totalFlow) * 100).round();
        deltaLabel = '$expShare% tổng chi xuất';
        isDeltaPositive = false;
      } else {
        deltaLabel = 'Chưa có chi tiêu tháng';
        isDeltaPositive = true;
      }
    }

    // Sparkline points derived from current month cashflow
    final sparkData = _generateSparkData();
    final sparkPoints = sparkData.map((p) => p.normalizedY).toList();
    final scrubbedPoint = (_scrubbedIndex != null &&
            _scrubbedIndex! >= 0 &&
            _scrubbedIndex! < sparkData.length)
        ? sparkData[_scrubbedIndex!]
        : null;

    final displayMoney = scrubbedPoint != null
        ? Money(
            minorUnits: scrubbedPoint.rawValue.round(),
            currencyCode: widget.totalBalance.currencyCode,
          )
        : activeMoney;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? (context.isOled
                ? AppleTokens.bgOledCard
                : LucianTokens.surfaceDark)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
        border: Border.all(
          color: isDark
              ? (context.isOled
                  ? AppleTokens.bgOledBorder
                  : Colors.white.withValues(alpha: 0.12))
              : const Color(0xFF16151B).withValues(alpha: 0.08),
          width: AppleTokens.hairline,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.55)
                : const Color(0xFF281E50).withValues(alpha: 0.07),
            blurRadius: 28,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header: Live Pulse Dot + Metric Label + Visibility Toggle
          Row(
            children: [
              // Live Breathing Pulse Dot
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 8 + (10 * _pulseAnimation.value),
                        height: 8 + (10 * _pulseAnimation.value),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(
                            alpha: (1.0 - _pulseAnimation.value) * 0.45,
                          ),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.6),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        metricTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: isDark
                              ? LucianTokens.ink2Dark
                              : LucianTokens.ink2Light,
                        ),
                      ),
                    ),
                    if (scrubbedPoint != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: isDark ? 0.22 : 0.14),
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.35),
                            width: AppleTokens.hairline,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.calendar, size: 10.5, color: accentColor),
                            const SizedBox(width: 4),
                            Text(
                              '${scrubbedPoint.date.day.toString().padLeft(2, '0')}/${scrubbedPoint.date.month.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Visibility Toggle Button
              IconButton(
                tooltip: widget.hideBalance ? l10n.showBalance : l10n.hideBalance,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: widget.onToggleVisibility,
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? (context.isOled
                            ? AppleTokens.bgOledSecondary
                            : LucianTokens.surface2Dark)
                        : LucianTokens.surface2Light,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      width: AppleTokens.hairline,
                    ),
                  ),
                  child: Icon(
                    widget.hideBalance
                        ? CupertinoIcons.eye_slash
                        : CupertinoIcons.eye,
                    size: 15,
                    color: isDark
                        ? LucianTokens.ink2Dark
                        : LucianTokens.ink2Light,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Large Hero Amount with Smooth Animated Number
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: LucianTokens.spring,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey('kpi_${_activeMetric.name}_${widget.hideBalance}_${_scrubbedIndex ?? -1}'),
                child: Text(
                  displayMoney.format(
                    locale: widget.locale,
                    masked: widget.hideBalance,
                    showPlusSign: _activeMetric == LucianKpiMetric.income,
                    showMinusSign: _activeMetric == LucianKpiMetric.expense,
                  ),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.15,
                    color: isDark ? Colors.white : LucianTokens.inkLight,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // 3. Dynamic Delta Badge
          Row(
            children: [
              Flexible(
                child: Container(
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: (isDeltaPositive
                            ? LucianTokens.mintLight
                            : LucianTokens.dangerLight)
                        .withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    border: Border.all(
                      color: (isDeltaPositive
                              ? LucianTokens.mintLight
                              : LucianTokens.dangerLight)
                          .withValues(alpha: isDark ? 0.35 : 0.25),
                      width: AppleTokens.hairline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDeltaPositive
                            ? CupertinoIcons.arrow_up_right
                            : CupertinoIcons.arrow_down_right,
                        size: 11,
                        color: isDeltaPositive
                            ? (isDark ? LucianTokens.mintDark : LucianTokens.mintLight)
                            : (isDark
                                ? LucianTokens.dangerDark
                                : LucianTokens.dangerLight),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          deltaLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: isDeltaPositive
                                ? (isDark ? LucianTokens.mintDark : LucianTokens.mintLight)
                                : (isDark
                                    ? LucianTokens.dangerDark
                                    : LucianTokens.dangerLight),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4. Lucian Sparkline Bezier Trend Curve with Touch Scrubbing
          SizedBox(
            height: 52,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) =>
                      _onScrub(details.localPosition.dx, constraints.maxWidth, sparkData.length),
                  onHorizontalDragUpdate: (details) =>
                      _onScrub(details.localPosition.dx, constraints.maxWidth, sparkData.length),
                  onHorizontalDragEnd: (_) => _scheduleScrubReset(),
                  onTapDown: (details) =>
                      _onScrub(details.localPosition.dx, constraints.maxWidth, sparkData.length),
                  onTapUp: (_) => _scheduleScrubReset(),
                  onTapCancel: () => _resetScrub(),
                  child: CustomPaint(
                    painter: _LucianSparklinePainter(
                      points: sparkPoints,
                      lineColor: accentColor,
                      isDark: isDark,
                      selectedIndex: _scrubbedIndex,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 5. Segmented Metric Switcher Tabs (Lucian #098-tabs)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark
                  ? (context.isOled
                      ? AppleTokens.bgOledSecondary
                      : LucianTokens.surface2Dark)
                  : LucianTokens.surface2Light,
              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                width: AppleTokens.hairline,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricTab(
                    label: l10n.totalBalance,
                    metric: LucianKpiMetric.balance,
                    isSelected: _activeMetric == LucianKpiMetric.balance,
                    isDark: isDark,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: _buildMetricTab(
                    label: l10n.income,
                    metric: LucianKpiMetric.income,
                    isSelected: _activeMetric == LucianKpiMetric.income,
                    isDark: isDark,
                    theme: theme,
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: _buildMetricTab(
                    label: l10n.expense,
                    metric: LucianKpiMetric.expense,
                    isSelected: _activeMetric == LucianKpiMetric.expense,
                    isDark: isDark,
                    theme: theme,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTab({
    required String label,
    required LucianKpiMetric metric,
    required bool isSelected,
    required bool isDark,
    required ThemeData theme,
  }) {
    final activeColor = switch (metric) {
      LucianKpiMetric.balance => LucianTokens.resolveAccent(isDark),
      LucianKpiMetric.income => LucianTokens.resolveMint(isDark),
      LucianKpiMetric.expense => LucianTokens.resolveDanger(isDark),
    };

    return ApplePressable(
      onTap: () => _switchMetric(metric),
      scaleDown: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: LucianTokens.ease,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? LucianTokens.surfaceDark : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppleTokens.radiusControl - 2),
          border: isSelected
              ? Border.all(
                  color: activeColor.withValues(alpha: 0.45),
                  width: 1.0,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.2,
                color: isSelected
                    ? activeColor
                    : (isDark ? LucianTokens.ink3Dark : LucianTokens.ink3Light),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<LucianSparkPoint> _generateSparkData() {
    final now = DateTime.now();
    final currentDay = now.day;
    final currency = widget.totalBalance.currencyCode;

    // Timeline: If early in the month (< 7 days), sample the last 7 calendar days.
    // Otherwise use all days from day 1 to today in the current month.
    final days = <DateTime>[];
    if (currentDay < 7) {
      final todayMidnight = DateTime(now.year, now.month, now.day);
      for (var i = 6; i >= 0; i--) {
        days.add(todayMidnight.subtract(Duration(days: i)));
      }
    } else {
      for (var d = 1; d <= currentDay; d++) {
        days.add(DateTime(now.year, now.month, d));
      }
    }

    // Filter transactions relevant to the active currency and exclude internal transfers
    final currencyTxs = widget.transactions
        .where((tx) => tx.currency == currency && tx.type != TransactionType.transfer)
        .toList();

    final rawValues = <double>[];

    if (_activeMetric == LucianKpiMetric.balance) {
      final currentBalanceMinor = widget.totalBalance.minorUnits.toDouble();

      for (final day in days) {
        final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
        // Transactions strictly AFTER this day's end must be subtracted from currentBalance
        var futureNet = 0.0;
        for (final tx in currencyTxs) {
          if (tx.date.isAfter(endOfDay)) {
            if (tx.type == TransactionType.income) {
              futureNet += tx.amount;
            } else if (tx.type == TransactionType.expense) {
              futureNet -= tx.amount;
            }
          }
        }
        final balanceAtDay = currentBalanceMinor - futureNet;
        rawValues.add(balanceAtDay);
      }
    } else if (_activeMetric == LucianKpiMetric.income) {
      // Cumulative income across the month (or 7-day window if early in month)
      final rangeStart = currentDay < 7 ? days.first : DateTime(now.year, now.month, 1);
      for (final day in days) {
        final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
        var cumIncome = 0.0;
        for (final tx in currencyTxs) {
          if (tx.type == TransactionType.income &&
              !tx.date.isBefore(rangeStart) &&
              !tx.date.isAfter(endOfDay)) {
            cumIncome += tx.amount;
          }
        }
        rawValues.add(cumIncome);
      }
    } else {
      // Cumulative expense across the month (or 7-day window if early in month)
      final rangeStart = currentDay < 7 ? days.first : DateTime(now.year, now.month, 1);
      for (final day in days) {
        final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
        var cumExpense = 0.0;
        for (final tx in currencyTxs) {
          if (tx.type == TransactionType.expense &&
              !tx.date.isBefore(rangeStart) &&
              !tx.date.isAfter(endOfDay)) {
            cumExpense += tx.amount;
          }
        }
        rawValues.add(cumExpense);
      }
    }

    if (rawValues.isEmpty) {
      return List.generate(
        7,
        (i) => LucianSparkPoint(
          date: now.subtract(Duration(days: 6 - i)),
          rawValue: 0.0,
          normalizedY: 0.5,
        ),
      );
    }

    final minVal = rawValues.reduce(math.min);
    final maxVal = rawValues.reduce(math.max);

    return List.generate(rawValues.length, (i) {
      final v = rawValues[i];
      final double normY;
      if (minVal == maxVal) {
        normY = (minVal == 0) ? 0.15 : 0.5;
      } else {
        final ratio = (v - minVal) / (maxVal - minVal);
        normY = 0.15 + (0.70 * ratio);
      }
      return LucianSparkPoint(
        date: days[i],
        rawValue: v,
        normalizedY: normY,
      );
    });
  }
}

/// Custom painter for smooth bezier sparkline with area gradient and glowing head.
class _LucianSparklinePainter extends CustomPainter {
  const _LucianSparklinePainter({
    required this.points,
    required this.lineColor,
    required this.isDark,
    this.selectedIndex,
  });

  final List<double> points;
  final Color lineColor;
  final bool isDark;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final width = size.width;
    final height = size.height;
    final stepX = width / (points.length - 1);

    final linePath = Path();
    final fillPath = Path();

    final List<Offset> coords = [];
    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      // Invert Y coordinate so 1.0 is at top
      final y = height - (points[i].clamp(0.05, 0.95) * height);
      coords.add(Offset(x, y));
    }

    linePath.moveTo(coords[0].dx, coords[0].dy);
    fillPath.moveTo(coords[0].dx, height);
    fillPath.lineTo(coords[0].dx, coords[0].dy);

    for (var i = 0; i < coords.length - 1; i++) {
      final p0 = coords[i];
      final p1 = coords[i + 1];
      final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY1 = p0.dy;
      final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY2 = p1.dy;

      linePath.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
      fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
    }

    fillPath.lineTo(coords.last.dx, height);
    fillPath.close();

    // 1. Draw area gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: isDark ? 0.35 : 0.22),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 2. Draw smooth stroke line
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // 3. Draw glowing head circle at latest data point
    final last = coords.last;
    final glowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(last, 6.0, glowPaint);

    final headPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(last, 3.5, headPaint);

    final centerDotPaint = Paint()
      ..color = isDark ? LucianTokens.surfaceDark : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(last, 1.5, centerDotPaint);

    // 4. Interactive touch scrub cursor and active highlight point
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < coords.length) {
      final scrubPt = coords[selectedIndex!];

      // Vertical luminous guideline
      final cursorPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.05),
            lineColor.withValues(alpha: 0.85),
            lineColor.withValues(alpha: 0.15),
          ],
        ).createShader(Rect.fromLTWH(scrubPt.dx - 1, 0, 2, height))
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(scrubPt.dx, 0),
        Offset(scrubPt.dx, height),
        cursorPaint,
      );

      // Active focal glowing head
      final scrubGlowPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(scrubPt, 8.5, scrubGlowPaint);

      final scrubHeadPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(scrubPt, 4.5, scrubHeadPaint);

      final scrubCenterPaint = Paint()
        ..color = isDark ? LucianTokens.surfaceDark : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(scrubPt, 2.0, scrubCenterPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LucianSparklinePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.points != points ||
        oldDelegate.isDark != isDark ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
