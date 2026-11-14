import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/theme/tokens/app_semantic_colors.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

/// Search input and transaction type segmented selector bar (All, Expense, Income, Transfer)
/// with active filter badges summary.
class TransactionSearchTypeBar extends StatelessWidget {
  const TransactionSearchTypeBar({
    super.key,
    required this.searchController,
    required this.filter,
    required this.isLandscape,
    required this.categoriesMap,
    required this.accountsMap,
    required this.locale,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onTypeSelected,
    required this.onClearAll,
  });

  final TextEditingController searchController;
  final TransactionFilter filter;
  final bool isLandscape;
  final Map<String, Category> categoriesMap;
  final Map<String, Account> accountsMap;
  final String locale;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final ValueChanged<TransactionType?> onTypeSelected;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = context.semanticColors;
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Responsive Search & Type Filter Bar
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppleTokens.maxContentWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, isLandscape ? 4 : 4, 16, isLandscape ? 4 : 6),
              child: Row(
                children: [
                  Expanded(
                    child: AppleSearchBar(
                      controller: searchController,
                      hintText: l10n.searchTransactionsHint,
                      isLandscape: isLandscape,
                      onChanged: onSearchChanged,
                      onClear: onSearchClear,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: isLandscape ? 34 : 40,
                    padding: const EdgeInsets.all(3),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: colors.inputBackground,
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                      border: Border.all(
                        color: colors.inputBorder,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypeIconButton(
                          type: null,
                          tooltip: l10n.all,
                          icon: CupertinoIcons.square_grid_2x2,
                          iconColor: null,
                          theme: theme,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 2),
                        _buildTypeIconButton(
                          type: TransactionType.expense,
                          tooltip: l10n.expense,
                          icon: CupertinoIcons.arrow_up_right,
                          iconColor: AppleTokens.rubyExpense,
                          theme: theme,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 2),
                        _buildTypeIconButton(
                          type: TransactionType.income,
                          tooltip: l10n.income,
                          icon: CupertinoIcons.arrow_down_left,
                          iconColor: AppleTokens.emeraldIncome,
                          theme: theme,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 2),
                        _buildTypeIconButton(
                          type: TransactionType.transfer,
                          tooltip: l10n.transfer,
                          icon: CupertinoIcons.arrow_right_arrow_left,
                          iconColor: AppleTokens.cobaltTransfer,
                          theme: theme,
                          isDark: isDark,
                        ),
                        if (filter.hasActiveFilters) ...[
                          const SizedBox(width: 3),
                          Container(
                            width: 1,
                            height: isLandscape ? 16 : 20,
                            color: colors.divider,
                          ),
                          const SizedBox(width: 3),
                          Tooltip(
                            message: l10n.clearFilters,
                            child: ApplePressable(
                              onTap: () {
                                unawaited(HapticFeedback.lightImpact());
                                searchController.clear();
                                onClearAll();
                              },
                              child: Container(
                                width: isLandscape ? 28 : 34,
                                height: isLandscape ? 28 : 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppleTokens.systemRed.withValues(alpha: isDark ? 0.2 : 0.1),
                                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                ),
                                child: const Icon(
                                  Icons.filter_alt_off_rounded,
                                  size: 15,
                                  color: AppleTokens.systemRed,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Active Filter Summary Pill
        if (filter.hasActiveFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppleTokens.maxContentWidth),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list_rounded, size: 13, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _getActiveFilterSummary(l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          searchController.clear();
                          onClearAll();
                        },
                        child: const Icon(
                          CupertinoIcons.clear_circled_solid,
                          size: 14,
                          color: AppleTokens.systemRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getActiveFilterSummary(AppLocalizations l10n) {
    final parts = <String>[];
    final effectiveAccounts = filter.effectiveAccountIds;
    if (effectiveAccounts.isNotEmpty) {
      if (effectiveAccounts.length == 1) {
        final accId = effectiveAccounts.first;
        if (accountsMap.containsKey(accId)) {
          parts.add(accountsMap[accId]!.name);
        }
      } else {
        parts.add(
          locale.startsWith('vi')
              ? '${effectiveAccounts.length} ví'
              : '${effectiveAccounts.length} wallets',
        );
      }
    }

    final effectiveCategories = filter.effectiveCategoryIds;
    if (effectiveCategories.isNotEmpty) {
      if (effectiveCategories.length == 1) {
        final catId = effectiveCategories.first;
        if (categoriesMap.containsKey(catId)) {
          parts.add(
            DefaultCategoryLocalization.resolveName(
              l10n,
              categoryId: catId,
              fallbackName: categoriesMap[catId]!.name,
            ),
          );
        }
      } else {
        parts.add(
          locale.startsWith('vi')
              ? '${effectiveCategories.length} danh mục'
              : '${effectiveCategories.length} categories',
        );
      }
    }

    if (filter.startDate != null && filter.endDate != null) {
      parts.add(
        '${AppDateUtils.formatShortDate(filter.startDate!, locale: locale)} - ${AppDateUtils.formatShortDate(filter.endDate!, locale: locale)}',
      );
    }
    if (parts.isEmpty) return l10n.filterActiveCount(1);
    return parts.join(' · ');
  }

  Widget _buildTypeIconButton({
    required TransactionType? type,
    required String tooltip,
    required IconData icon,
    required Color? iconColor,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isSelected = filter.type == type;
    final activeColor = iconColor ?? theme.colorScheme.primary;
    final size = isLandscape ? 28.0 : 34.0;
    final iconSize = isLandscape ? 13.5 : 15.5;

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: ApplePressable(
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          onTypeSelected(isSelected ? null : type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: isDark ? 0.30 : 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            border: Border.all(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.55)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: isSelected
                ? activeColor
                : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ),
    );
  }
}
