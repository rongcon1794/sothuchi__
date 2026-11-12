import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

enum SmartPaceSource { budget, income, balance }

class SmartSpendingPaceResult {
  const SmartSpendingPaceResult({
    required this.safeDailyMinor,
    required this.dailyAllowanceMinor,
    required this.todaySpentMinor,
    required this.remainingLimitMinor,
    required this.daysRemaining,
    required this.currencyCode,
    required this.isOverPace,
    required this.isExceeded,
    required this.source,
  });

  final int safeDailyMinor;
  final int dailyAllowanceMinor;
  final int todaySpentMinor;
  final int remainingLimitMinor;
  final int daysRemaining;
  final String currencyCode;
  final bool isOverPace;
  final bool isExceeded;
  final SmartPaceSource source;
}

/// Computes the smart daily spending pace using:
/// 1. Active monthly budget (overall budget or sum of category budgets),
/// 2. Monthly income fallback when no budget is configured,
/// 3. Current net balance fallback when neither budget nor income exists.
///
/// Today's expenses are deducted directly from today's daily allowance rather
/// than amortized across remaining days, so spending today updates "safe to
/// spend today" 1-for-1 while remaining days rebalance tomorrow.
SmartSpendingPaceResult computeSmartSpendingPace({
  required MonthlyCashflowSummary monthSummary,
  required Money totalBalance,
  required List<BudgetProgress> budgetProgressList,
  List<TransactionEntity> transactions = const <TransactionEntity>[],
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  final daysInMonth = DateTime(effectiveNow.year, effectiveNow.month + 1, 0).day;
  final currentDay = effectiveNow.day;
  final daysRemaining = math.max(1, daysInMonth - currentDay + 1);

  int? effectiveLimitMinor;
  int effectiveSpentMinor = monthSummary.expense.minorUnits;
  String currencyCode = totalBalance.currencyCode;
  SmartPaceSource source = SmartPaceSource.balance;
  Set<String>? budgetedCategoryIds;

  if (budgetProgressList.isNotEmpty) {
    final overall =
        budgetProgressList.where((p) => p.budget.isOverall).firstOrNull;
    if (overall != null) {
      effectiveLimitMinor = overall.budget.amount;
      effectiveSpentMinor = overall.spentMinorUnits;
      currencyCode = overall.budget.currency;
      source = SmartPaceSource.budget;
    } else {
      currencyCode = budgetProgressList.first.budget.currency;
      final sameCurrency = budgetProgressList
          .where((p) => p.budget.currency == currencyCode)
          .toList(growable: false);
      effectiveLimitMinor =
          sameCurrency.fold<int>(0, (acc, p) => acc + p.budget.amount);
      effectiveSpentMinor =
          sameCurrency.fold<int>(0, (acc, p) => acc + p.spentMinorUnits);
      budgetedCategoryIds = sameCurrency
          .map((p) => p.budget.categoryId)
          .whereType<String>()
          .toSet();
      source = SmartPaceSource.budget;
    }
  } else if (monthSummary.income.minorUnits > 0) {
    effectiveLimitMinor = monthSummary.income.minorUnits;
    effectiveSpentMinor = monthSummary.expense.minorUnits;
    currencyCode = monthSummary.income.currencyCode;
    source = SmartPaceSource.income;
  }

  final todaySpentMinor = transactions
      .where(
        (tx) =>
            tx.type == TransactionType.expense &&
            tx.currency == currencyCode &&
            AppDateUtils.isSameDay(tx.date, effectiveNow) &&
            (budgetedCategoryIds == null ||
                budgetedCategoryIds.contains(tx.categoryId)),
      )
      .fold<int>(0, (sum, tx) => sum + tx.amount);

  if (effectiveLimitMinor != null && effectiveLimitMinor > 0) {
    final spentBeforeToday = math.max(0, effectiveSpentMinor - todaySpentMinor);
    final remainingBeforeToday =
        math.max(0, effectiveLimitMinor - spentBeforeToday);
    final dailyAllowanceMinor = remainingBeforeToday ~/ daysRemaining;
    final safeDailyMinor = dailyAllowanceMinor - todaySpentMinor;

    if (effectiveSpentMinor >= effectiveLimitMinor) {
      return SmartSpendingPaceResult(
        safeDailyMinor: safeDailyMinor,
        dailyAllowanceMinor: dailyAllowanceMinor,
        todaySpentMinor: todaySpentMinor,
        remainingLimitMinor: 0,
        daysRemaining: daysRemaining,
        currencyCode: currencyCode,
        isOverPace: true,
        isExceeded: true,
        source: source,
      );
    }

    final remainingLimitMinor =
        math.max(0, effectiveLimitMinor - effectiveSpentMinor);
    final expectedSpentSoFar = (effectiveLimitMinor * currentDay) / daysInMonth;
    final isOverPace =
        effectiveSpentMinor > expectedSpentSoFar || safeDailyMinor < 0;

    return SmartSpendingPaceResult(
      safeDailyMinor: safeDailyMinor,
      dailyAllowanceMinor: dailyAllowanceMinor,
      todaySpentMinor: todaySpentMinor,
      remainingLimitMinor: remainingLimitMinor,
      daysRemaining: daysRemaining,
      currencyCode: currencyCode,
      isOverPace: isOverPace,
      isExceeded: false,
      source: source,
    );
  }

  // Fallback 3: Neither budget nor monthly income is recorded.
  // Note: totalBalance is already net of all recorded expenses (including
  // this month's expenses), so we must NOT subtract effectiveSpentMinor again.
  final balanceAtStartOfToday = totalBalance.minorUnits + todaySpentMinor;
  final dailyAllowanceMinor = balanceAtStartOfToday > 0
      ? balanceAtStartOfToday ~/ daysRemaining
      : 0;
  final safeDailyMinor = dailyAllowanceMinor - todaySpentMinor;

  if (totalBalance.minorUnits <= 0) {
    final isExceeded = effectiveSpentMinor > 0 || totalBalance.minorUnits < 0;
    return SmartSpendingPaceResult(
      safeDailyMinor: safeDailyMinor,
      dailyAllowanceMinor: dailyAllowanceMinor,
      todaySpentMinor: todaySpentMinor,
      remainingLimitMinor: 0,
      daysRemaining: daysRemaining,
      currencyCode: currencyCode,
      isOverPace: isExceeded || effectiveSpentMinor > 0 || safeDailyMinor < 0,
      isExceeded: isExceeded,
      source: SmartPaceSource.balance,
    );
  }

  final impliedStartingBalance = totalBalance.minorUnits + effectiveSpentMinor;
  final expectedSpentSoFar =
      (impliedStartingBalance * currentDay) / daysInMonth;
  final isOverPace =
      effectiveSpentMinor > expectedSpentSoFar || safeDailyMinor < 0;

  return SmartSpendingPaceResult(
    safeDailyMinor: safeDailyMinor,
    dailyAllowanceMinor: dailyAllowanceMinor,
    todaySpentMinor: todaySpentMinor,
    remainingLimitMinor: totalBalance.minorUnits,
    daysRemaining: daysRemaining,
    currencyCode: currencyCode,
    isOverPace: isOverPace,
    isExceeded: false,
    source: SmartPaceSource.balance,
  );
}

class DashboardSmartSpendingPaceCard extends ConsumerWidget {
  const DashboardSmartSpendingPaceCard({
    super.key,
    required this.monthSummary,
    required this.totalBalance,
    required this.locale,
    required this.hideBalance,
    this.transactions = const <TransactionEntity>[],
    this.now,
  });

  final MonthlyCashflowSummary monthSummary;
  final Money totalBalance;
  final String locale;
  final bool hideBalance;
  final List<TransactionEntity> transactions;
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final budgetProgressList = ref.watch(currentMonthBudgetProgressProvider);
    final pace = computeSmartSpendingPace(
      monthSummary: monthSummary,
      totalBalance: totalBalance,
      budgetProgressList: budgetProgressList,
      transactions: transactions,
      now: now,
    );

    final daysRemaining = pace.daysRemaining;
    final safeDailyMoney = Money(
      minorUnits: pace.safeDailyMinor,
      currencyCode: pace.currencyCode,
    );
    final isDailyOverspent = pace.safeDailyMinor < 0;
    final paceLabel = isDailyOverspent
        ? (locale.startsWith('vi')
            ? 'Vượt mức chi hôm nay'
            : "Exceeded today's pace")
        : l10n.smartPaceSafeToSpend;
    final amountColor = isDailyOverspent
        ? AppleTokens.systemRed
        : (isDark ? Colors.white : theme.colorScheme.onSurface);

    final statusColor = pace.isExceeded
        ? AppleTokens.systemRed
        : (pace.isOverPace ? AppleTokens.systemOrange : AppleTokens.systemGreen);
    final statusIcon = pace.isExceeded
        ? CupertinoIcons.exclamationmark_triangle_fill
        : (pace.isOverPace
            ? CupertinoIcons.exclamationmark_circle_fill
            : CupertinoIcons.checkmark_circle_fill);
    final statusText = pace.isExceeded
        ? switch (pace.source) {
            SmartPaceSource.budget =>
              locale.startsWith('vi') ? 'Vượt ngân sách' : 'Over budget',
            SmartPaceSource.income =>
              locale.startsWith('vi') ? 'Vượt thu nhập' : 'Over income',
            SmartPaceSource.balance =>
              locale.startsWith('vi') ? 'Hết số dư' : 'Out of balance',
          }
        : (pace.isOverPace ? l10n.smartPaceOverPace : l10n.smartPaceOnTrack);

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
                    paceLabel,
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
                      color: amountColor,
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
                          paceLabel,
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
                              color: amountColor,
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
                              paceLabel,
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
                                  color: amountColor,
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

