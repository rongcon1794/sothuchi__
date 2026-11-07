import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

class DashboardSmartSpendingPaceCard extends StatelessWidget {
  const DashboardSmartSpendingPaceCard({
    super.key,
    required this.monthSummary,
    required this.totalBalance,
    required this.locale,
    required this.hideBalance,
  });

  final MonthlyCashflowSummary monthSummary;
  final Money totalBalance;
  final String locale;
  final bool hideBalance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = math.max(1, daysInMonth - now.day + 1);

    final remainingMinor = monthSummary.income.minorUnits > monthSummary.expense.minorUnits
        ? (monthSummary.income.minorUnits - monthSummary.expense.minorUnits)
        : math.max(0, totalBalance.minorUnits);
    final safeDailyMinor = (remainingMinor / daysRemaining).round();
    final safeDailyMoney = Money(minorUnits: safeDailyMinor, currencyCode: totalBalance.currencyCode);

    final isOverPace = monthSummary.expense.minorUnits > monthSummary.income.minorUnits &&
        monthSummary.income.minorUnits > 0;
    final statusColor = isOverPace ? AppleTokens.systemOrange : AppleTokens.systemGreen;
    final statusIcon = isOverPace
        ? CupertinoIcons.exclamationmark_circle_fill
        : CupertinoIcons.checkmark_circle_fill;
    final statusText = isOverPace ? l10n.smartPaceOverPace : l10n.smartPaceOnTrack;

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isLargeText = textScale >= 1.35;

    return ApplePressable(
      onTap: () => context.go(AppRoutes.budgets),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: AppleGlassCard(
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        borderColor: statusColor.withValues(alpha: isDark ? 0.28 : 0.2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLargeText) ...[
              Row(
                children: [
                  AppleSquircleBadge(
                    icon: CupertinoIcons.gauge,
                    color: statusColor,
                    size: 28,
                    iconSize: 15,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.smartPaceTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              LayoutBuilder(
                builder: (context, c) {
                  if (c.maxWidth < 340) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppleSquircleBadge(
                              icon: CupertinoIcons.gauge,
                              color: statusColor,
                              size: 26,
                              iconSize: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.smartPaceTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 11, color: statusColor),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  statusText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      AppleSquircleBadge(
                        icon: CupertinoIcons.gauge,
                        color: statusColor,
                        size: 28,
                        iconSize: 15,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.smartPaceTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 11, color: statusColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                statusText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
            if (isLargeText) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.smartPaceSafeToSpend,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    safeDailyMoney.format(locale: locale, masked: hideBalance),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : theme.colorScheme.onSurface,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppleTokens.bgLightSecondary,
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.12) : AppleTokens.borderLight,
                        width: AppleTokens.hairline,
                      ),
                    ),
                    child: Text(
                      l10n.smartPaceDaysLeft(daysRemaining),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppleTokens.systemGray,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              LayoutBuilder(
                builder: (context, c) {
                  final isCompactCard = c.maxWidth < 340;
                  if (isCompactCard) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.smartPaceSafeToSpend,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            safeDailyMoney.format(locale: locale, masked: hideBalance),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : theme.colorScheme.onSurface,
                              fontFeatures: AppTheme.tabularFigures,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppleTokens.bgLightSecondary,
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.12) : AppleTokens.borderLight,
                              width: AppleTokens.hairline,
                            ),
                          ),
                          child: Text(
                            l10n.smartPaceDaysLeft(daysRemaining),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppleTokens.systemGray,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.smartPaceSafeToSpend,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                safeDailyMoney.format(locale: locale, masked: hideBalance),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : theme.colorScheme.onSurface,
                                  fontFeatures: AppTheme.tabularFigures,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppleTokens.bgLightSecondary,
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.12) : AppleTokens.borderLight,
                              width: AppleTokens.hairline,
                            ),
                          ),
                          child: Text(
                            l10n.smartPaceDaysLeft(daysRemaining),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppleTokens.systemGray,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

