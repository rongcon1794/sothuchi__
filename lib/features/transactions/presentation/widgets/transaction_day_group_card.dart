import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_tile.dart';

/// Card displaying transactions grouped under a single date header with net balance badge.
class TransactionDayGroupCard extends StatelessWidget {
  const TransactionDayGroupCard({
    super.key,
    required this.group,
    required this.categoriesMap,
    required this.accountsMap,
    required this.locale,
    required this.currency,
    required this.hideBalance,
    required this.isLandscape,
    required this.onTap,
    required this.onSwipeEdit,
    required this.onSwipeDelete,
  });

  final DailyTransactionGroup group;
  final Map<String, Category> categoriesMap;
  final Map<String, Account> accountsMap;
  final String locale;
  final String currency;
  final bool hideBalance;
  final bool isLandscape;
  final ValueChanged<TransactionEntity> onTap;
  final ValueChanged<TransactionEntity> onSwipeEdit;
  final Future<bool> Function(TransactionEntity) onSwipeDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final dayNet = Money(
      minorUnits: group.netMinor,
      currencyCode: currency,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: isLandscape ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 4,
              vertical: isLandscape ? 3 : 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppDateUtils.formatDayHeader(
                      group.dayStart,
                      locale: locale,
                      todayLabel: l10n.today,
                      yesterdayLabel: l10n.yesterday,
                    ),
                    style: (isLandscape
                            ? theme.textTheme.labelMedium
                            : theme.textTheme.labelLarge)
                        ?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 7 : 9,
                    vertical: isLandscape ? 2 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: (group.netMinor > 0
                            ? LucianTokens.mintLight
                            : (group.netMinor < 0
                                ? LucianTokens.dangerLight
                                : Colors.grey))
                        .withValues(alpha: isDark ? 0.15 : 0.10),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    border: Border.all(
                      color: (group.netMinor > 0
                              ? LucianTokens.resolveMint(isDark)
                              : (group.netMinor < 0
                                  ? LucianTokens.resolveDanger(isDark)
                                  : Colors.grey))
                          .withValues(alpha: isDark ? 0.25 : 0.18),
                      width: AppleTokens.hairline,
                    ),
                  ),
                  child: Text(
                    dayNet.format(
                      locale: locale,
                      showPlusSign: true,
                      masked: hideBalance,
                    ),
                    style: (isLandscape
                            ? theme.textTheme.labelSmall
                            : theme.textTheme.labelMedium)
                        ?.copyWith(
                      color: group.netMinor > 0
                          ? LucianTokens.resolveMint(isDark)
                          : (group.netMinor < 0
                              ? LucianTokens.resolveDanger(isDark)
                              : theme.colorScheme.onSurfaceVariant),
                      fontWeight: FontWeight.w700,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppleGlassCard(
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
            child: Column(
              children: [
                for (var i = 0; i < group.transactions.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: AppleTokens.hairline,
                      indent: isLandscape ? 56 : 68,
                      color: isDark
                          ? AppleTokens.separatorDark
                          : AppleTokens.separatorLight,
                    ),
                  TransactionTile(
                    transaction: group.transactions[i],
                    category: categoriesMap[group.transactions[i].categoryId],
                    sourceAccount: accountsMap[group.transactions[i].accountId],
                    destinationAccount: group.transactions[i].toAccountId != null
                        ? accountsMap[group.transactions[i].toAccountId!]
                        : null,
                    locale: locale,
                    hideAmount: hideBalance,
                    onTap: () => onTap(group.transactions[i]),
                    onSwipeEdit: () => onSwipeEdit(group.transactions[i]),
                    onSwipeDelete: () => onSwipeDelete(group.transactions[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
