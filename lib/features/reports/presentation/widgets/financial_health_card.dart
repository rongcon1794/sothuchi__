import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';

class FinancialHealthCard extends StatelessWidget {
  const FinancialHealthCard({
    super.key,
    required this.report,
    required this.locale,
    required this.hideBalance,
  });

  final MonthlyReportData report;
  final String locale;
  final bool hideBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scoreData = _calculateHealthScore(report);
    final score = scoreData.score;
    final rating = scoreData.rating;
    final badgeColor = scoreData.color;

    return AppleGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.heart_fill,
                  size: 18,
                  color: badgeColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sức Khỏe Tài Chính',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Đánh giá dựa trên quy chuẩn tài chính 50/30/20',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: Border.all(
                    color: badgeColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                    Text(
                      '/100',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Rating badge & bar
          Row(
            children: [
              Text(
                'Mức độ: ',
                style: TextStyle(
                  fontSize: 12.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                rating,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: isDark
                  ? AppleTokens.bgDarkTertiary
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
            ),
          ),
          const SizedBox(height: 16),

          // Insights bullets
          _InsightRow(
            icon: CupertinoIcons.sparkles,
            iconColor: AppleTokens.systemOrange,
            title: 'Tỷ lệ tích lũy',
            description: report.totalIncomeMinor > 0
                ? 'Bạn đã tích lũy ${report.savingsRatePercent}% thu nhập tháng này${report.savingsRatePercent >= 20 ? ' (Đạt chuẩn tốt)' : ' (Nên phấn đấu đạt 20%)'}.'
                : 'Chưa ghi nhận thu nhập trong tháng này.',
          ),
          const SizedBox(height: 10),
          _InsightRow(
            icon: CupertinoIcons.calendar,
            iconColor: AppleTokens.systemBlue,
            title: 'Nhịp độ chi tiêu',
            description: report.peakSpendingDay > 0
                ? 'Ngày chi cao nhất là ngày ${report.peakSpendingDay} (${Money(minorUnits: report.peakSpendingAmountMinor, currencyCode: report.currencyCode).format(locale: locale, masked: hideBalance)}).'
                : 'Không có chi tiêu nào trong tháng.',
          ),
          if (report.categorySlices.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InsightRow(
              icon: CupertinoIcons.chart_pie,
              iconColor: AppleTokens.jadeDark,
              title: 'Hạng mục chi lớn nhất',
              description:
                  '${report.categorySlices.first.fallbackName} chiếm ${report.categorySlices.first.percentage}% tổng ngân sách chi (${report.categorySlices.first.amountMoney.format(locale: locale, masked: hideBalance)}).',
            ),
          ],
        ],
      ),
    );
  }

  static _HealthScoreResult _calculateHealthScore(MonthlyReportData r) {
    if (r.totalIncomeMinor <= 0 && r.totalExpenseMinor <= 0) {
      return const _HealthScoreResult(score: 50, rating: 'Chưa đủ dữ liệu', color: AppleTokens.systemGray);
    }

    var score = 50;

    // 1. Savings rate weight (up to 30 points)
    final rate = r.savingsRatePercent;
    if (rate >= 30) {
      score += 30;
    } else if (rate >= 20) {
      score += 25;
    } else if (rate >= 10) {
      score += 15;
    } else if (rate > 0) {
      score += 5;
    } else {
      score -= 20; // deficit
    }

    // 2. Spending discipline: is there any category exceeding 70%?
    if (r.categorySlices.isNotEmpty && r.categorySlices.first.percentage > 70) {
      score -= 10;
    } else {
      score += 10;
    }

    // 3. Positive Net Cashflow
    if (r.netMinor > 0) {
      score += 10;
    }

    score = score.clamp(10, 100);

    if (score >= 80) {
      return _HealthScoreResult(score: score, rating: 'Rất Tốt', color: AppleTokens.systemGreen);
    } else if (score >= 60) {
      return _HealthScoreResult(score: score, rating: 'Khá Ổn Định', color: AppleTokens.jadeDark);
    } else if (score >= 40) {
      return _HealthScoreResult(score: score, rating: 'Trung Bình', color: AppleTokens.systemOrange);
    } else {
      return _HealthScoreResult(score: score, rating: 'Cần Cân Đối', color: AppleTokens.systemRed);
    }
  }
}

class _HealthScoreResult {
  const _HealthScoreResult({
    required this.score,
    required this.rating,
    required this.color,
  });

  final int score;
  final String rating;
  final Color color;
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppleTokens.bgDarkPrimary : AppleTokens.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
