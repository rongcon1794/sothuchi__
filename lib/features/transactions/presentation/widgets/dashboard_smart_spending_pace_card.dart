import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

class DashboardSmartSpendingPaceCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentDay = now.day;
    final daysRemaining = math.max(1, daysInMonth - currentDay + 1);

    // 1. Inspect current month budgets
    final budgetProgressList = ref.watch(currentMonthBudgetProgressProvider);

    int? effectiveLimitMinor;
    int effectiveSpentMinor = monthSummary.expense.minorUnits;
    String currencyCode = totalBalance.currencyCode;
    bool hasBudget = false;

    if (budgetProgressList.isNotEmpty) {
      final overall = budgetProgressList.where((p) => p.budget.isOverall).firstOrNull;
      if (overall != null) {
        effectiveLimitMinor = overall.budget.amount;
        effectiveSpentMinor = overall.spentMinorUnits;
        currencyCode = overall.budget.currency;
        hasBudget = true;
      } else {
        effectiveLimitMinor = budgetProgressList.fold<int>(0, (acc, p) => acc + p.budget.amount);
        effectiveSpentMinor = budgetProgressList.fold<int>(0, (acc, p) => acc + p.spentMinorUnits);
        currencyCode = budgetProgressList.first.budget.currency;
        hasBudget = true;
      }
    } else if (monthSummary.income.minorUnits > 0) {
      // 2. Fallback to monthly income when no budget is configured
      effectiveLimitMinor = monthSummary.income.minorUnits;
      effectiveSpentMinor = monthSummary.expense.minorUnits;
      currencyCode = monthSummary.income.currencyCode;
    }

    int safeDailyMinor;
    bool isOverPace;
    bool isExceeded = false;

    if (effectiveLimitMinor != null && effectiveLimitMinor > 0) {
      if (effectiveSpentMinor >= effectiveLimitMinor) {
        // Exceeded: 0 safe spending left this month
        safeDailyMinor = 0;
        isOverPace = true;
        isExceeded = true;
      } else {
        final remainingMinor = effectiveLimitMinor - effectiveSpentMinor;
        safeDailyMinor = remainingMinor ~/ daysRemaining;

        // Pace: Check if current spending is ahead of normal pro-rata day pace
        final expectedSpentSoFar = (effectiveLimitMinor * currentDay) / daysInMonth;
        isOverPace = effectiveSpentMinor > expectedSpentSoFar;
      }
    } else {
      // 3. Neither budget nor income is recorded
      if (totalBalance.minorUnits <= 0 || effectiveSpentMinor >= totalBalance.minorUnits) {
        safeDailyMinor = 0;
        isOverPace = effectiveSpentMinor > 0;
        isExceeded = effectiveSpentMinor > 0 && totalBalance.minorUnits <= 0;
      } else {
        final remainingBalance = totalBalance.minorUnits - effectiveSpentMinor;
        safeDailyMinor = remainingBalance ~/ daysRemaining;
        isOverPace = false;
      }
    }

    final safeDailyMoney = Money(minorUnits: safeDailyMinor, currencyCode: currencyCode);

    final statusColor = isExceeded
        ? AppleTokens.systemRed
        : (isOverPace ? AppleTokens.systemOrange : AppleTokens.systemGreen);
    final statusIcon = isExceeded
        ? CupertinoIcons.exclamationmark_triangle_fill
        : (isOverPace
            ? CupertinoIcons.exclamationmark_circle_fill
            : CupertinoIcons.checkmark_circle_fill);
    final statusText = isExceeded
        ? (hasBudget
            ? (locale.startsWith('vi') ? 'Vượt ngân sách' : 'Over budget')
            : (locale.startsWith('vi') ? 'Vượt thu nhập' : 'Over income'))
        : (isOverPace ? l10n.smartPaceOverPace : l10n.smartPaceOnTrack);

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
                  AppleAnimatedMoneyText(
                    money: safeDailyMoney,
                    locale: locale,
                    masked: hideBalance,
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
                          child: AppleAnimatedMoneyText(
                            money: safeDailyMoney,
                            locale: locale,
                            masked: hideBalance,
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
                              child: AppleAnimatedMoneyText(
                                money: safeDailyMoney,
                                locale: locale,
                                masked: hideBalance,
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

