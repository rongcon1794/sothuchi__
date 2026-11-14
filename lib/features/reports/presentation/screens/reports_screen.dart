import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/core/widgets/skeleton_box.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';
import 'package:so_thu_chi/features/reports/presentation/controllers/reports_controller.dart';
import 'package:so_thu_chi/features/reports/presentation/widgets/apple_spending_heatmap.dart';
import 'package:so_thu_chi/features/reports/presentation/widgets/category_spend_legend.dart';
import 'package:so_thu_chi/features/reports/presentation/widgets/category_spend_pie_chart.dart';
import 'package:so_thu_chi/features/reports/presentation/widgets/financial_health_card.dart';
import 'package:so_thu_chi/features/reports/presentation/widgets/monthly_summary_header.dart';
import 'package:so_thu_chi/features/reports/presentation/widgets/six_month_trend_section.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int? _selectedCategoryIndex;
  DateTime? _lastMonth;

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

  Widget _buildHeaderMonthSwitcher(
    WidgetRef ref, {
    required DateTime selectedMonth,
  }) {
    return AppleCompactMonthSwitcher(
      isHeaderMode: true,
      selectedMonth: selectedMonth,
      allowAllOption: false,
      onPrevious: () {
        ref.read(selectedReportMonthProvider.notifier).previousMonth();
      },
      onNext: () {
        ref.read(selectedReportMonthProvider.notifier).nextMonth();
      },
      onSelectMonth: (month) {
        if (month != null) {
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
    final monthlyBudgetMinor = ref.watch(selectedReportMonthBudgetMinorProvider);
    if (_lastMonth != selectedMonth) {
      _lastMonth = selectedMonth;
      _selectedCategoryIndex = null;
    }
    final txStream = ref.watch(transactionsStreamProvider);
    final report = ref.watch(monthlyReportProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: isLandscape
            ? AppleTokens.appBarHeightLandscape
            : AppleTokens.appBarHeightPortrait,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: AppleHeaderTitle(
          title: l10n.reportsTitle,
          isLandscape: isLandscape,
        ),
        actions: [
          if (isLandscape) ...[
            Center(
              child: _buildHeaderMonthSwitcher(
                ref,
                selectedMonth: selectedMonth,
              ),
            ),
            const SizedBox(width: 8),
          ],
          AppleIconButton(
            icon: CupertinoIcons.share,
            size: isLandscape ? 32 : 36,
            iconSize: isLandscape ? 16 : 18,
            tooltip: l10n.reportsShareTooltip,
            onTap: () => _shareFinancialSummary(report, selectedMonth, locale),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
        children: [
          // Month Switcher (only shown in portrait mode; merged into AppBar in landscape)
          if (!isLandscape) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
              child: Center(
                child: AppleCompactMonthSwitcher(
                  selectedMonth: selectedMonth,
                  allowAllOption: false,
                  onPrevious: () {
                    ref.read(selectedReportMonthProvider.notifier).previousMonth();
                  },
                  onNext: () {
                    ref.read(selectedReportMonthProvider.notifier).nextMonth();
                  },
                  onSelectMonth: (month) {
                    if (month != null) {
                      ref.read(selectedReportMonthProvider.notifier).setMonth(month);
                    }
                  },
                ),
              ),
            ),
            // Quick Period Presets Selector Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildPeriodQuickChip(
                      label: locale.startsWith('vi') ? 'Tháng này' : 'This Month',
                      isSelected: AppDateUtils.isSameMonth(selectedMonth, DateTime.now()),
                      onTap: () {
                        ref.read(selectedReportMonthProvider.notifier).setMonth(DateTime.now());
                      },
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _buildPeriodQuickChip(
                      label: locale.startsWith('vi') ? 'Tháng trước' : 'Last Month',
                      isSelected: AppDateUtils.isSameMonth(
                        selectedMonth,
                        AppDateUtils.addMonths(DateTime.now(), -1),
                      ),
                      onTap: () {
                        ref.read(selectedReportMonthProvider.notifier).setMonth(
                              AppDateUtils.addMonths(DateTime.now(), -1),
                            );
                      },
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _buildPeriodQuickChip(
                      label: locale.startsWith('vi') ? '2 tháng trước' : '2 Months Ago',
                      isSelected: AppDateUtils.isSameMonth(
                        selectedMonth,
                        AppDateUtils.addMonths(DateTime.now(), -2),
                      ),
                      onTap: () {
                        ref.read(selectedReportMonthProvider.notifier).setMonth(
                              AppDateUtils.addMonths(DateTime.now(), -2),
                            );
                      },
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),
          ],

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

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: KeyedSubtree(
                    key: ValueKey('report_view_${selectedMonth.year}_${selectedMonth.month}'),
                    child: LayoutBuilder(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.expenseByCategory,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_selectedCategoryIndex != null)
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                  icon: const Icon(CupertinoIcons.clear_circled, size: 14),
                                  label: Text(
                                    locale.startsWith('vi') ? 'Bỏ chọn' : 'Deselect',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () {
                                    setState(() => _selectedCategoryIndex = null);
                                  },
                                ),
                            ],
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
                                      CategorySpendPieChart(
                                        report: report,
                                        locale: locale,
                                        hideBalance: hideBalance,
                                        selectedIndex: _selectedCategoryIndex,
                                        onSliceSelected: (idx) {
                                          setState(() => _selectedCategoryIndex = idx);
                                        },
                                        height: 230,
                                        diameter: 230,
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            for (var i = 0; i < report.categorySlices.length; i++) ...[
                                              CategoryLegendRow(
                                                slice: report.categorySlices[i],
                                                locale: locale,
                                                hideBalance: hideBalance,
                                                isSelected: _selectedCategoryIndex == i,
                                                onTap: () {
                                                  setState(() {
                                                    _selectedCategoryIndex =
                                                        _selectedCategoryIndex == i ? null : i;
                                                  });
                                                },
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
                                      child: CategorySpendPieChart(
                                        report: report,
                                        locale: locale,
                                        hideBalance: hideBalance,
                                        selectedIndex: _selectedCategoryIndex,
                                        onSliceSelected: (idx) {
                                          setState(() => _selectedCategoryIndex = idx);
                                        },
                                        height: 210,
                                        diameter: 210,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    for (var i = 0; i < report.categorySlices.length; i++) ...[
                                      CategoryLegendRow(
                                        slice: report.categorySlices[i],
                                        locale: locale,
                                        hideBalance: hideBalance,
                                        isSelected: _selectedCategoryIndex == i,
                                        onTap: () {
                                          setState(() {
                                            _selectedCategoryIndex =
                                                _selectedCategoryIndex == i ? null : i;
                                          });
                                        },
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
                              LegendDot(
                                color: context.financeColors.income,
                                label: l10n.income,
                              ),
                              LegendDot(
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
                                        child: SixMonthTrendBarChart(
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
                                      child: SixMonthSummaryPanel(
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
                                child: SixMonthTrendBarChart(
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
                        constraints: const BoxConstraints(maxWidth: AppleTokens.maxContentWidth),
                        child: ListView(
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          padding: EdgeInsets.fromLTRB(16, 4, 16, scrollBottomPadding),
                          children: [
                            RepaintBoundary(
                              child: MonthlySummaryHeader(
                                report: report,
                                locale: locale,
                                hideBalance: hideBalance,
                              ),
                            ),
                            const SizedBox(height: 16),
                            RepaintBoundary(
                              child: FinancialHealthCard(
                                report: report,
                                locale: locale,
                                hideBalance: hideBalance,
                              ),
                            ),
                            const SizedBox(height: 16),
                            RepaintBoundary(
                              child: AppleSpendingHeatmap(
                                report: report,
                                locale: locale,
                                hideBalance: hideBalance,
                                monthlyBudgetMinor: monthlyBudgetMinor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            RepaintBoundary(child: donutChartCard),
                            const SizedBox(height: 16),
                            RepaintBoundary(child: barChartCard),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
              },
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildPeriodQuickChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isSelected
        ? scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14)
        : (isDark
            ? AppleTokens.bgDarkSecondary.withValues(alpha: 0.6)
            : AppleTokens.bgLightSecondary.withValues(alpha: 0.8));

    final textColor = isSelected
        ? scheme.primary
        : (isDark ? Colors.white70 : Colors.black87);

    return ApplePressable(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
          border: Border.all(
            color: isSelected
                ? scheme.primary.withValues(alpha: 0.4)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
