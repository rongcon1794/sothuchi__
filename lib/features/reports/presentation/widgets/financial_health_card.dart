import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/reports/domain/entities/health_score_data.dart';
import 'package:so_thu_chi/features/reports/domain/entities/monthly_report.dart';
import 'package:so_thu_chi/features/reports/presentation/screens/financial_health_detail_screen.dart';

/// Compact, Apple-style financial health status card.
/// Tapping opens [FinancialHealthDetailScreen] for comprehensive 50/30/20 insights.
class FinancialHealthCard extends StatelessWidget {
  const FinancialHealthCard({
    super.key,
    required this.report,
    required this.locale,
    required this.hideBalance,
    this.onTap,
  });

  final MonthlyReportData report;
  final String locale;
  final bool hideBalance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final scoreData = HealthScoreData.calculate(report, l10n);
    final score = scoreData.score;
    final rating = scoreData.rating;
    final badgeColor = scoreData.color;

    return ApplePressable(
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      onTap: () {
        HapticFeedback.lightImpact();
        if (onTap != null) {
          onTap!();
        } else {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => FinancialHealthDetailScreen(
                report: report,
                locale: locale,
                hideBalance: hideBalance,
              ),
            ),
          );
        }
      },
      child: AppleGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Heart icon with pulsing circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.reportsFinancialHealth,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
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
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: rating,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: badgeColor,
                                    ),
                                  ),
                                  TextSpan(
                                    text: locale.startsWith('vi')
                                        ? ' • Chuẩn 50/30/20'
                                        : ' • 50/30/20 Rule',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Score badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                      Text(
                        '/100',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Slim progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 4,
                backgroundColor: isDark
                    ? AppleTokens.bgDarkTertiary
                    : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
