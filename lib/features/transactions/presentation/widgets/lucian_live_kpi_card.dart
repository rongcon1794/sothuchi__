import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
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
    required this.locale,
    required this.hideBalance,
    required this.onToggleVisibility,
    this.initialMetric = LucianKpiMetric.balance,
    this.onNavigateTransactions,
  });

  final Money totalBalance;
  final MonthlyCashflowSummary monthSummary;
  final String locale;
  final bool hideBalance;
  final VoidCallback onToggleVisibility;
  final LucianKpiMetric initialMetric;
  final VoidCallback? onNavigateTransactions;

  @override
  State<LucianLiveKpiCard> createState() => _LucianLiveKpiCardState();
}

class _LucianLiveKpiCardState extends State<LucianLiveKpiCard>
    with SingleTickerProviderStateMixin {
  late LucianKpiMetric _activeMetric;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _activeMetric = widget.initialMetric;

    // Continuous breathing pulse animation for the live status dot
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
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
    _pulseController.dispose();
    super.dispose();
  }

  void _switchMetric(LucianKpiMetric metric) {
    if (_activeMetric == metric) return;
    HapticFeedback.selectionClick();
    setState(() => _activeMetric = metric);
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

    // Calculate dynamic savings rate / net delta
    final totalFlow = widget.monthSummary.income.minorUnits +
        widget.monthSummary.expense.minorUnits;
    final hasFlow = totalFlow > 0;
    final savingsRate = widget.monthSummary.income.minorUnits > 0
        ? ((widget.monthSummary.net.minorUnits /
                    widget.monthSummary.income.minorUnits) *
                100)
            .round()
        : 0;

    final String deltaLabel;
    final bool isDeltaPositive;
    if (_activeMetric == LucianKpiMetric.balance) {
      if (widget.monthSummary.net.minorUnits >= 0) {
        deltaLabel = hasFlow ? '+$savingsRate% tích lũy tháng' : 'Số dư sẵn sàng';
        isDeltaPositive = true;
      } else {
        deltaLabel = '${widget.monthSummary.net.minorUnits < 0 ? "-" : "+"}$savingsRate% thâm hụt';
        isDeltaPositive = false;
      }
    } else if (_activeMetric == LucianKpiMetric.income) {
      final incShare = hasFlow
          ? ((widget.monthSummary.income.minorUnits / totalFlow) * 100).round()
          : 0;
      deltaLabel = '$incShare% dòng tiền vào';
      isDeltaPositive = true;
    } else {
      final expShare = hasFlow
          ? ((widget.monthSummary.expense.minorUnits / totalFlow) * 100).round()
          : 0;
      deltaLabel = '$expShare% tổng chi xuất';
      isDeltaPositive = false;
    }

    // Sparkline points derived from current month cashflow
    final sparkPoints = _generateSparklineData();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? LucianTokens.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
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
                child: Text(
                  metricTitle,
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
                        ? LucianTokens.surface2Dark
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
                key: ValueKey('kpi_${_activeMetric.name}_${widget.hideBalance}'),
                child: Text(
                  activeMoney.format(
                    locale: widget.locale,
                    masked: widget.hideBalance,
                    showPlusSign: _activeMetric == LucianKpiMetric.income,
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

          // 4. Lucian Sparkline Bezier Trend Curve
          SizedBox(
            height: 48,
            child: CustomPaint(
              painter: _LucianSparklinePainter(
                points: sparkPoints,
                lineColor: accentColor,
                isDark: isDark,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 12),

          // 5. Segmented Metric Switcher Tabs (Lucian #098-tabs)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark
                  ? LucianTokens.surface2Dark
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

  List<double> _generateSparklineData() {
    // Generate normalized curve values (0.0 to 1.0)
    final inc = widget.monthSummary.income.minorUnits.toDouble();
    final exp = widget.monthSummary.expense.minorUnits.toDouble();
    final net = widget.monthSummary.net.minorUnits.toDouble();

    if (_activeMetric == LucianKpiMetric.balance) {
      const base = 0.5;
      final shift = net >= 0 ? 0.35 : -0.25;
      return [base - 0.15, base - 0.05, base + 0.05, base + shift * 0.6, base + shift];
    } else if (_activeMetric == LucianKpiMetric.income) {
      return [0.2, 0.35, 0.5, 0.65, inc > 0 ? 0.85 : 0.2];
    } else {
      return [0.15, 0.3, 0.45, 0.6, exp > 0 ? 0.75 : 0.15];
    }
  }
}

/// Custom painter for smooth bezier sparkline with area gradient and glowing head.
class _LucianSparklinePainter extends CustomPainter {
  const _LucianSparklinePainter({
    required this.points,
    required this.lineColor,
    required this.isDark,
  });

  final List<double> points;
  final Color lineColor;
  final bool isDark;

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
  }

  @override
  bool shouldRepaint(covariant _LucianSparklinePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.points != points ||
        oldDelegate.isDark != isDark;
  }
}
