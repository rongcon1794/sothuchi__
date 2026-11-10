import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/reports/domain/entities/health_score_data.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';
import 'package:so_thu_chi/features/reports/presentation/controllers/reports_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';

/// Detailed Financial Health screen with 50/30/20 standard analysis,
/// scoring breakdown, spending rhythm, and personalized actionable guidance.
class FinancialHealthDetailScreen extends ConsumerWidget {
  const FinancialHealthDetailScreen({
    super.key,
    this.report,
    this.locale,
    this.hideBalance,
  });

  final MonthlyReportData? report;
  final String? locale;
  final bool? hideBalance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    // Resolve dependencies from Riverpod if not provided directly
    final currentReport = report;
    final MonthlyReportData effectiveReport =
        currentReport ?? ref.watch(monthlyReportProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final effectiveLocale = locale ?? settings?.localeCode ?? 'vi';
    final effectiveHideBalance = hideBalance ?? settings?.hideBalance ?? false;

    final scoreData = HealthScoreData.calculate(effectiveReport, l10n);
    final monthStr = AppDateUtils.formatMonthYear(
      effectiveReport.selectedMonth,
      locale: effectiveLocale,
    );

    final isLandscape = context.isLandscape;
    final appBarHeight = isLandscape
        ? AppleTokens.appBarHeightLandscape
        : AppleTokens.appBarHeightPortrait;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: const AppleBackButton(),
        title: AppleHeaderTitle(
          title: l10n.reportsFinancialHealth,
          icon: CupertinoIcons.heart_fill,
          accentColor: scoreData.color,
          badgeText: '${scoreData.score}/100 • ${scoreData.rating}',
          badgeColor: scoreData.color.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.22 : 0.12,
          ),
          badgeTextColor: scoreData.color,
          isLandscape: isLandscape,
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 680;
            final maxContentWidth = isWide ? 680.0 : double.infinity;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Hero Score Card with Activity Ring
                      _buildHeroScoreCard(
                        context: context,
                        theme: theme,
                        isDark: isDark,
                        report: effectiveReport,
                        scoreData: scoreData,
                        monthStr: monthStr,
                      ),
                      const SizedBox(height: 16),

                      // 2. 50/30/20 Standard Rule Card
                      _buildStandard503020Card(
                        context: context,
                        theme: theme,
                        isDark: isDark,
                        report: effectiveReport,
                        scoreData: scoreData,
                      ),
                      const SizedBox(height: 16),

                      // 3. Scoring Breakdown (3 Core Pillars)
                      _buildScoringBreakdownCard(
                        context: context,
                        theme: theme,
                        isDark: isDark,
                        report: effectiveReport,
                        scoreData: scoreData,
                        locale: effectiveLocale,
                        hideBalance: effectiveHideBalance,
                      ),
                      const SizedBox(height: 16),

                      // 4. Monthly Rhythm & Peak Spend
                      _buildMonthlyRhythmCard(
                        context: context,
                        theme: theme,
                        isDark: isDark,
                        report: effectiveReport,
                        locale: effectiveLocale,
                        hideBalance: effectiveHideBalance,
                      ),
                      const SizedBox(height: 16),

                      // 5. Actionable Recommendations
                      _buildRecommendationsCard(
                        context: context,
                        theme: theme,
                        isDark: isDark,
                        report: effectiveReport,
                        scoreData: scoreData,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 1. Hero Card: Displays prominent radial score ring, rating badge, and summary sentence.
  Widget _buildHeroScoreCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required MonthlyReportData report,
    required HealthScoreData scoreData,
    required String monthStr,
  }) {
    final score = scoreData.score;
    final rating = scoreData.rating;
    final badgeColor = scoreData.color;

    final summaryText = score >= 80
        ? 'Tài chính của bạn đang ở trạng thái rất lành mạnh! Tỷ lệ tích lũy và kỷ luật chi tiêu đều đạt chuẩn cao.'
        : score >= 60
            ? 'Tình hình tài chính khá ổn định và có tích lũy. Dòng tiền ròng trong tháng duy trì mức dương.'
            : score >= 40
                ? 'Sức khỏe tài chính ở mức trung bình. Bạn nên theo dõi sát các khoản chi để gia tăng tỷ lệ tích lũy.'
                : 'Cần chú ý cân đối chi tiêu! Tổng chi đang tiệm cận hoặc vượt mức thu nhập trong tháng.';

    return AppleGlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Báo cáo $monthStr',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      rating,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Central Score Activity Ring
          LucianActivityRing(
            progress: (score / 100).clamp(0.0, 1.0),
            size: 110,
            strokeWidth: 9,
            primaryColor: badgeColor,
            secondaryColor: badgeColor.withValues(alpha: 0.75),
            backgroundColor: isDark
                ? AppleTokens.bgDarkTertiary
                : const Color(0xFFE2E8F0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '/100 điểm',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Short summary paragraph
          Text(
            summaryText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. 50/30/20 Standard Rule Card: Highlights core benchmark allocation.
  Widget _buildStandard503020Card({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required MonthlyReportData report,
    required HealthScoreData scoreData,
  }) {
    final savingsRate = scoreData.savingsRate;
    final isSavingsGood = savingsRate >= 20;

    return AppleGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppleTokens.systemBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.square_grid_2x2_fill,
                  size: 16,
                  color: AppleTokens.systemBlue,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Quy chuẩn tài chính 50/30/20',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Quy tắc 50/30/20 chia thu nhập thành 3 nhóm: 50% Nhu cầu thiết yếu, 30% Sở thích cá nhân và 20% Tích lũy dự phòng.',
            style: TextStyle(
              fontSize: 12.5,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // 3-Segment visual distribution bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: 50,
                    child: Container(
                      color: AppleTokens.systemBlue.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: 30,
                    child: Container(
                      color: AppleTokens.systemOrange.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: 20,
                    child: Container(
                      color: AppleTokens.systemGreen.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildDistributionLabel(
                color: AppleTokens.systemBlue,
                label: '50% Thiết yếu',
              ),
              _buildDistributionLabel(
                color: AppleTokens.systemOrange,
                label: '30% Sở thích',
              ),
              _buildDistributionLabel(
                color: AppleTokens.systemGreen,
                label: '20% Tích lũy',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // User's current savings rate vs benchmark
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppleTokens.bgDarkSecondary.withValues(alpha: 0.5)
                  : AppleTokens.bgLightSecondary.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
              border: Border.all(
                color: (isSavingsGood ? AppleTokens.systemGreen : AppleTokens.systemOrange)
                    .withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSavingsGood
                      ? CupertinoIcons.checkmark_seal_fill
                      : CupertinoIcons.exclamationmark_circle_fill,
                  size: 18,
                  color: isSavingsGood ? AppleTokens.systemGreen : AppleTokens.systemOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSavingsGood
                        ? 'Tỷ lệ tích lũy của bạn đạt $savingsRate% (Vượt mức chuẩn 20%)'
                        : 'Tỷ lệ tích lũy hiện là $savingsRate% (Nên phấn đấu đạt mốc 20%)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSavingsGood
                          ? (isDark ? AppleTokens.systemGreen : AppleTokens.jadeDark)
                          : AppleTokens.systemOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionLabel({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  /// 3. Scoring Breakdown: Explains exact point additions/deductions for transparency.
  Widget _buildScoringBreakdownCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required MonthlyReportData report,
    required HealthScoreData scoreData,
    required String locale,
    required bool hideBalance,
  }) {
    return AppleGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppleTokens.jadePrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.chart_bar_alt_fill,
                  size: 16,
                  color: AppleTokens.jadePrimary,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Chi tiết các tiêu chí chấm điểm',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Criterion 1: Savings Rate (up to 30 pts)
          _buildCriterionTile(
            theme: theme,
            isDark: isDark,
            icon: CupertinoIcons.sparkles,
            iconColor: AppleTokens.systemGreen,
            title: '1. Tỷ lệ tích lũy',
            pointsText: '${scoreData.savingsScoreImpact > 0 ? '+${scoreData.savingsScoreImpact}' : scoreData.savingsScoreImpact} điểm',
            pointsColor: scoreData.savingsScoreImpact > 0
                ? AppleTokens.systemGreen
                : AppleTokens.systemRed,
            description: report.totalIncomeMinor > 0
                ? 'Bạn đã tích lũy ${scoreData.savingsRate}% tổng thu nhập tháng này.'
                : 'Chưa có dữ liệu thu nhập để tính tỷ lệ tích lũy.',
          ),
          const SizedBox(height: 10),

          // Criterion 2: Spending Discipline (up to 10 pts)
          _buildCriterionTile(
            theme: theme,
            isDark: isDark,
            icon: CupertinoIcons.chart_pie_fill,
            iconColor: AppleTokens.systemBlue,
            title: '2. Kỷ luật chi tiêu theo danh mục',
            pointsText: '${scoreData.disciplineScoreImpact > 0 ? '+${scoreData.disciplineScoreImpact}' : scoreData.disciplineScoreImpact} điểm',
            pointsColor: scoreData.disciplineScoreImpact > 0
                ? AppleTokens.systemGreen
                : AppleTokens.systemRed,
            description: scoreData.topCategoryName != null
                ? 'Danh mục cao nhất là "${scoreData.topCategoryName}" chiếm ${scoreData.topCategoryPercent}% tổng chi ${scoreData.isDisciplinePassed ? '(an toàn ≤70%)' : '(vượt quá 70%)'}.'
                : 'Không có chi tiêu danh mục nào vượt mức chi phối.',
          ),
          const SizedBox(height: 10),

          // Criterion 3: Net Cashflow (up to 10 pts)
          _buildCriterionTile(
            theme: theme,
            isDark: isDark,
            icon: CupertinoIcons.arrow_up_down_circle_fill,
            iconColor: AppleTokens.systemOrange,
            title: '3. Dòng tiền ròng (Net Cashflow)',
            pointsText: '${scoreData.cashflowScoreImpact > 0 ? '+${scoreData.cashflowScoreImpact}' : '0'} điểm',
            pointsColor: scoreData.isNetPositive
                ? AppleTokens.systemGreen
                : AppleTokens.systemOrange,
            description: scoreData.isNetPositive
                ? 'Thu nhập lớn hơn chi tiêu: Thặng dư ${Money(minorUnits: report.netMinor, currencyCode: report.currencyCode).format(locale: locale, masked: hideBalance)}.'
                : 'Dòng tiền chưa thặng dư trong tháng: ${Money(minorUnits: report.netMinor, currencyCode: report.currencyCode).format(locale: locale, masked: hideBalance)}.',
          ),
        ],
      ),
    );
  }

  Widget _buildCriterionTile({
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String pointsText,
    required Color pointsColor,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppleTokens.bgDarkSecondary.withValues(alpha: 0.5)
            : AppleTokens.bgLightSecondary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: pointsColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Text(
                  pointsText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: pointsColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 11.5,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Monthly Spending Rhythm & Peak stats.
  Widget _buildMonthlyRhythmCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required MonthlyReportData report,
    required String locale,
    required bool hideBalance,
  }) {
    return AppleGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppleTokens.systemRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.flame_fill,
                  size: 16,
                  color: AppleTokens.systemRed,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Nhịp độ & Điểm nhấn chi tiêu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricMiniCard(
                  theme: theme,
                  isDark: isDark,
                  label: 'Ngày chi nhiều nhất',
                  value: report.peakSpendingDay > 0
                      ? 'Ngày ${report.peakSpendingDay}'
                      : '—',
                  subValue: report.peakSpendingDay > 0
                      ? Money(
                          minorUnits: report.peakSpendingAmountMinor,
                          currencyCode: report.currencyCode,
                        ).format(locale: locale, masked: hideBalance)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricMiniCard(
                  theme: theme,
                  isDark: isDark,
                  label: 'Chi tiêu TB/ngày',
                  value: Money(
                    minorUnits: report.averageDailyExpenseMinor,
                    currencyCode: report.currencyCode,
                  ).format(locale: locale, masked: hideBalance),
                  subValue: '${report.activeSpendingDaysCount} ngày có chi',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricMiniCard({
    required ThemeData theme,
    required bool isDark,
    required String label,
    required String value,
    String? subValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppleTokens.bgDarkSecondary.withValues(alpha: 0.5)
            : AppleTokens.bgLightSecondary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 2),
            Text(
              subValue,
              style: TextStyle(
                fontSize: 10.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 5. Actionable Guidance & Recommendations.
  Widget _buildRecommendationsCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required MonthlyReportData report,
    required HealthScoreData scoreData,
  }) {
    final tips = <String>[];

    if (scoreData.savingsRate < 20) {
      tips.add(
        'Tập thói quen "trả cho mình trước" (Pay yourself first): Chuyển thẳng 10% - 20% thu nhập vào quỹ tiết kiệm ngay khi nhận lương.',
      );
    } else {
      tips.add(
        'Bạn đang duy trì tỷ lệ tiết kiệm rất tốt! Hãy cân nhắc phân bổ quỹ dư vào các mục tiêu tài chính dài hạn.',
      );
    }

    if (!scoreData.isDisciplinePassed && scoreData.topCategoryName != null) {
      tips.add(
        'Danh mục "${scoreData.topCategoryName}" đang chiếm hơn 70% tổng chi. Bạn nên thiết lập ngân sách riêng cho danh mục này để kiểm soát chặt chẽ.',
      );
    }

    if (!scoreData.isNetPositive) {
      tips.add(
        'Dòng tiền tháng này đang thâm hụt. Hãy rà soát lại các khoản chi phát sinh lớn bất thường và cắt giảm các khoản chi không cấp thiết.',
      );
    }

    tips.add(
      'Ghi chép đều đặn các khoản chi tiêu mỗi ngày giúp ứng dụng phân tích chính xác nhất nhịp độ dòng tiền của bạn.',
    );

    return AppleGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppleTokens.systemOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.lightbulb_fill,
                  size: 16,
                  color: AppleTokens.systemOrange,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Gợi ý tối ưu tài chính',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final tip in tips) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

