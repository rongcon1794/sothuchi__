import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/core/widgets/skeleton_box.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';
import 'package:so_thu_chi/features/reports/presentation/controllers/reports_controller.dart';
import 'package:so_thu_chi/features/reports/presentation/widgets/apple_spending_heatmap.dart';
import 'package:so_thu_chi/features/reports/presentation/widgets/financial_health_card.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _touchedPieIndex = -1;

  Future<void> _shareFinancialSummary(
    MonthlyReportData report,
    DateTime month,
    String locale,
  ) async {
    unawaited(HapticFeedback.lightImpact());
    final monthStr = AppDateUtils.formatMonthYear(month, locale: locale);
    final savingsRate = report.totalIncomeMinor > 0
        ? ((report.netMinor / report.totalIncomeMinor) * 100).clamp(0, 100).toStringAsFixed(1)
        : '0.0';

    final isVi = locale.startsWith('vi');
    final sb = StringBuffer()
      ..writeln(isVi
          ? '📊 BÁO CÁO TÀI CHÍNH THÁNG $monthStr — SỔ THU CHI'
          : '📊 MONTHLY FINANCIAL REPORT $monthStr — SỔ THU CHI')
      ..writeln('----------------------------------------')
      ..writeln('${isVi ? "💰 Thu nhập:" : "💰 Income:"} ${report.incomeMoney.format(locale: locale)}')
      ..writeln('${isVi ? "💸 Chi tiêu:" : "💸 Expense:"} ${report.expenseMoney.format(locale: locale)}')
      ..writeln('${isVi ? "📈 Thặng dư ròng:" : "📈 Net surplus:"} ${report.netMoney.format(locale: locale, showPlusSign: true)}')
      ..writeln('${isVi ? "🛡️ Tỷ lệ tích lũy:" : "🛡️ Savings rate:"} $savingsRate%')
      ..writeln('----------------------------------------');

    if (report.categorySlices.isNotEmpty) {
      sb.writeln(isVi ? 'TOP DANH MỤC CHI TIÊU:' : 'TOP EXPENSE CATEGORIES:');
      for (final s in report.categorySlices.take(5)) {
        sb.writeln(
          ' • ${s.fallbackName}: ${s.amountMoney.format(locale: locale)} (${s.percentage}%)',
        );
      }
      sb.writeln('----------------------------------------');
    }
    sb.writeln(isVi
        ? 'Quản lý chi tiêu thông minh cùng Sổ Thu Chi.'
        : 'Smart personal finance tracker with So Thu Chi.');

    await SharePlus.instance.share(
      ShareParams(
        text: sb.toString(),
        subject: isVi
            ? 'Báo cáo tài chính tháng $monthStr'
            : 'Financial report for month $monthStr',
      ),
    );
  }

  Widget _buildHeaderMonthSwitcher({
    required DateTime selectedMonth,
  }) {
    return AppleCompactMonthSwitcher(
      isHeaderMode: true,
      selectedMonth: selectedMonth,
      allowAllOption: false,
      onPrevious: () {
        setState(() => _touchedPieIndex = -1);
        ref.read(selectedReportMonthProvider.notifier).previousMonth();
      },
      onNext: () {
        setState(() => _touchedPieIndex = -1);
        ref.read(selectedReportMonthProvider.notifier).nextMonth();
      },
      onSelectMonth: (month) {
        if (month != null) {
          setState(() => _touchedPieIndex = -1);
          ref.read(selectedReportMonthProvider.notifier).setMonth(month);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = context.isLandscape;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final hideBalance = settings?.hideBalance ?? false;

    final selectedMonth = ref.watch(selectedReportMonthProvider);
    final txStream = ref.watch(transactionsStreamProvider);
    final report = ref.watch(monthlyReportProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isLandscape
            ? AppleTokens.appBarHeightLandscape
            : AppleTokens.appBarHeightPortrait,
        title: Text(l10n.reportsTitle),
        actions: [
          if (isLandscape) ...[
            Center(
              child: _buildHeaderMonthSwitcher(
                selectedMonth: selectedMonth,
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            tooltip: l10n.reportsShareTooltip,
            icon: const Icon(CupertinoIcons.share, size: 20),
            onPressed: () => _shareFinancialSummary(report, selectedMonth, locale),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Month Switcher (only shown in portrait mode; merged into AppBar in landscape)
          if (!isLandscape)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
              child: Center(
                child: AppleCompactMonthSwitcher(
                  selectedMonth: selectedMonth,
                  allowAllOption: false,
                  onPrevious: () {
                    setState(() => _touchedPieIndex = -1);
                    ref.read(selectedReportMonthProvider.notifier).previousMonth();
                  },
                  onNext: () {
                    setState(() => _touchedPieIndex = -1);
                    ref.read(selectedReportMonthProvider.notifier).nextMonth();
                  },
                  onSelectMonth: (month) {
                    if (month != null) {
                      setState(() => _touchedPieIndex = -1);
                      ref.read(selectedReportMonthProvider.notifier).setMonth(month);
                    }
                  },
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

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isLandscape = context.isLandscape;
                    final isWide = constraints.maxWidth >= 640 || isLandscape;
                    final scrollBottomPadding = isWide
                        ? AppleTokens.scrollBottomPaddingLandscape + 20
                        : AppleTokens.scrollBottomPaddingNoFab;

                    final donutChartCard = AppleGlassCard(
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
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isLocalWide = constraints.maxWidth >= 600;

                                if (isLocalWide) {
                                  // Wide Landscape / Tablet: Side-by-side 2-column layout
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      _buildPieChartWidget(
                                        report: report,
                                        theme: theme,
                                        locale: locale,
                                        hideBalance: hideBalance,
                                        l10n: l10n,
                                        height: 230,
                                        diameter: 230,
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            for (final slice in report.categorySlices) ...[
                                              _CategoryLegendRow(
                                                slice: slice,
                                                locale: locale,
                                                hideBalance: hideBalance,
                                              ),
                                              const SizedBox(height: 10),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                // Narrow Portrait: Centered stacked layout
                                return Column(
                                  children: [
                                    Center(
                                      child: _buildPieChartWidget(
                                        report: report,
                                        theme: theme,
                                        locale: locale,
                                        hideBalance: hideBalance,
                                        l10n: l10n,
                                        height: 210,
                                        diameter: 210,
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
                                );
                              },
                            ),
                        ],
                      ),
                    );

                    final barChartCard = AppleGlassCard(
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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isLocalWide = constraints.maxWidth >= 600;

                              if (isLocalWide) {
                                // Wide Landscape / Tablet: 2-column layout (Chart on left, 6M Summary on right)
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: SizedBox(
                                        height: 240,
                                        child: _SixMonthTrendBarChart(
                                          bars: report.sixMonthTrend,
                                          locale: locale,
                                          hideBalance: hideBalance,
                                          isWide: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      flex: 2,
                                      child: _SixMonthSummaryPanel(
                                        bars: report.sixMonthTrend,
                                        currencyCode: report.currencyCode,
                                        locale: locale,
                                        hideBalance: hideBalance,
                                      ),
                                    ),
                                  ],
                                );
                              }

                              // Narrow Portrait: Stacked
                              return SizedBox(
                                height: 230,
                                child: _SixMonthTrendBarChart(
                                  bars: report.sixMonthTrend,
                                  locale: locale,
                                  hideBalance: hideBalance,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1024),
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(16, 4, 16, scrollBottomPadding),
                          children: [
                            _MonthlySummaryHeader(
                              report: report,
                              locale: locale,
                              hideBalance: hideBalance,
                            ),
                            const SizedBox(height: 16),
                            FinancialHealthCard(
                              report: report,
                              locale: locale,
                              hideBalance: hideBalance,
                            ),
                            const SizedBox(height: 16),
                            AppleSpendingHeatmap(
                              report: report,
                              locale: locale,
                              hideBalance: hideBalance,
                            ),
                            const SizedBox(height: 16),
                            donutChartCard,
                            const SizedBox(height: 16),
                            barChartCard,
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartWidget({
    required MonthlyReportData report,
    required ThemeData theme,
    required String locale,
    required bool hideBalance,
    required AppLocalizations l10n,
    double height = 210,
    double diameter = 210,
  }) {
    final isSliceActive = _touchedPieIndex >= 0 &&
        _touchedPieIndex < report.categorySlices.length;
    final activeSlice =
        isSliceActive ? report.categorySlices[_touchedPieIndex] : null;

    return SizedBox(
      width: diameter,
      height: height,
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
          LayoutBuilder(
            builder: (context, rowConstraints) {
              final isLargeFont = MediaQuery.textScalerOf(context).scale(14) >= 20;
              if (isLargeFont) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${slice.percentage}%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFeatures: AppTheme.tabularFigures,
                          ),
                        ),
                        Flexible(
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
                  ],
                );
              }
              return Row(
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
              );
            },
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

class _SixMonthSummaryPanel extends StatelessWidget {
  const _SixMonthSummaryPanel({
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
