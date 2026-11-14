import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

/// Hero summary card displaying estimated monthly recurring cashflow, income, and expenses.
class RecurringHeroOverviewCard extends StatelessWidget {
  const RecurringHeroOverviewCard({
    super.key,
    required this.monthlyNetCashflow,
    required this.monthlyIncomeTotal,
    required this.monthlyExpenseTotal,
    required this.locale,
    required this.hideBalance,
    required this.isDark,
    this.activeCount,
  });

  final int monthlyNetCashflow;
  final int monthlyIncomeTotal;
  final int monthlyExpenseTotal;
  final String locale;
  final bool hideBalance;
  final bool isDark;
  final int? activeCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppleGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      borderColor: monthlyNetCashflow >= 0
          ? AppleTokens.emeraldIncome.withValues(alpha: isDark ? 0.35 : 0.2)
          : AppleTokens.rubyExpense.withValues(alpha: isDark ? 0.35 : 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.recurringMonthlyNetCashflow,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark ? AppleTokens.jadePrimary : AppleTokens.jadeDark,
                  ),
                ),
              ),
              if (activeCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppleTokens.jadePrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.recurringActiveCount(activeCount!),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppleTokens.jadePrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                monthlyNetCashflow >= 0 ? '+' : '-',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: monthlyNetCashflow >= 0
                      ? (isDark ? AppleTokens.emeraldIncome : const Color(0xFF0D5239))
                      : AppleTokens.rubyExpense,
                ),
              ),
              const SizedBox(width: 4),
              AppleAnimatedMoneyText(
                money: Money(minorUnits: monthlyNetCashflow.abs()),
                masked: hideBalance,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: monthlyNetCashflow >= 0
                      ? (isDark ? Colors.white : const Color(0xFF0D5239))
                      : AppleTokens.rubyExpense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Dự kiến thu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.arrow_down_left,
                            size: 13, color: AppleTokens.emeraldIncome),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            l10n.recurringEstimatedMonthlyIncome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+${Money(minorUnits: monthlyIncomeTotal).format(locale: locale, masked: hideBalance)}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppleTokens.emeraldIncome,
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
              ),
              const SizedBox(width: 12),
              // Dự kiến chi (Hóa đơn)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.arrow_up_right,
                            size: 13, color: AppleTokens.rubyExpense),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            l10n.recurringEstimatedMonthlyExpense,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '-${Money(minorUnits: monthlyExpenseTotal).format(locale: locale, masked: hideBalance)}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppleTokens.rubyExpense,
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
