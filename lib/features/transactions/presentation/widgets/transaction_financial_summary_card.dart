import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

/// Financial summary card displayed at the top of the Transactions screen.
/// Summarizes Income, Expense, Net Balance, and total transaction count.
class TransactionFinancialSummaryCard extends StatelessWidget {
  const TransactionFinancialSummaryCard({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.netAmount,
    required this.totalCount,
    required this.currency,
    required this.locale,
    required this.hideBalance,
    required this.isLandscape,
  });

  final int totalIncome;
  final int totalExpense;
  final int netAmount;
  final int totalCount;
  final String currency;
  final String locale;
  final bool hideBalance;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(bottom: isLandscape ? 8 : 10),
      child: AppleGlassCard(
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 12 : 14,
          vertical: isLandscape ? 8 : 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.chart_pie,
                  size: isLandscape ? 11 : 12,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  l10n.transactionCountTotal(totalCount).toUpperCase(),
                  style: TextStyle(
                    fontSize: isLandscape ? 10 : 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: isLandscape ? 6 : 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildSummarySegment(
                    color: AppleTokens.emeraldIncome,
                    label: l10n.income,
                    amount: Money(minorUnits: totalIncome, currencyCode: currency)
                        .format(locale: locale, showPlusSign: true, masked: hideBalance),
                    theme: theme,
                    isLandscape: isLandscape,
                  ),
                ),
                Container(
                  width: 1,
                  height: isLandscape ? 22 : 26,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: _buildSummarySegment(
                    color: AppleTokens.rubyExpense,
                    label: l10n.expense,
                    amount: Money(minorUnits: totalExpense, currencyCode: currency)
                        .format(locale: locale, showMinusSign: true, masked: hideBalance),
                    theme: theme,
                    isLandscape: isLandscape,
                  ),
                ),
                Container(
                  width: 1,
                  height: isLandscape ? 22 : 26,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: _buildSummarySegment(
                    color: netAmount >= 0 ? AppleTokens.emeraldIncome : AppleTokens.rubyExpense,
                    label: l10n.netBalance,
                    amount: Money(minorUnits: netAmount, currencyCode: currency)
                        .format(locale: locale, showPlusSign: true, masked: hideBalance),
                    theme: theme,
                    isLandscape: isLandscape,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySegment({
    required Color color,
    required String label,
    required String amount,
    required ThemeData theme,
    required bool isLandscape,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 5.5,
              height: 5.5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isLandscape ? 10 : 10.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            amount,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isLandscape ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: AppTheme.tabularFigures,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}

