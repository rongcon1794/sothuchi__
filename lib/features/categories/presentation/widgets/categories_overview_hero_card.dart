import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

/// Redesigned Apple Glass Hero Categories Overview Card.
class CategoriesOverviewHeroCard extends StatelessWidget {
  const CategoriesOverviewHeroCard({
    super.key,
    required this.expenseCount,
    required this.incomeCount,
    required this.defaultCount,
    required this.customCount,
    required this.totalTransactions,
    required this.locale,
    required this.isDark,
  });

  final int expenseCount;
  final int incomeCount;
  final int defaultCount;
  final int customCount;
  final int totalTransactions;
  final String locale;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCategories = expenseCount + incomeCount;
    final isVi = locale.startsWith('vi');

    return AppleGlassCard(
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.25),
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.square_grid_2x2,
                  color: theme.colorScheme.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isVi ? 'TỔNG QUAN PHÂN LOẠI' : 'CATEGORIES OVERVIEW',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: AppleTokens.systemGray,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isVi
                          ? '$totalCategories danh mục khả dụng'
                          : '$totalCategories categories available',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metric Pills Strip: Expense vs Income counts
          Row(
            children: [
              // Expense badge
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppleTokens.rubyExpense.withValues(alpha: isDark ? 0.20 : 0.08),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                    border: Border.all(
                      color: AppleTokens.rubyExpense.withValues(alpha: isDark ? 0.35 : 0.20),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.trending_down_rounded,
                        size: 16,
                        color: AppleTokens.rubyExpense,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isVi ? '$expenseCount Khoản chi' : '$expenseCount Expense',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppleTokens.rubyExpense,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Income badge
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppleTokens.emeraldIncome.withValues(alpha: isDark ? 0.20 : 0.08),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                    border: Border.all(
                      color: AppleTokens.emeraldIncome.withValues(alpha: isDark ? 0.35 : 0.20),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        size: 16,
                        color: AppleTokens.emeraldIncome,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isVi ? '$incomeCount Khoản thu' : '$incomeCount Income',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppleTokens.emeraldIncome,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Visual Proportion Ratio Bar
          if (totalCategories > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    if (expenseCount > 0)
                      Expanded(
                        flex: expenseCount,
                        child: Container(color: AppleTokens.rubyExpense),
                      ),
                    if (incomeCount > 0)
                      Expanded(
                        flex: incomeCount,
                        child: Container(color: AppleTokens.emeraldIncome),
                      ),
                  ],
                ),
              ),
            ),
          ],

          // Category Telemetry Strip (Default Templates, Custom Categories, Categorized Txs)
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
            ),
            child: Row(
              children: [
                // 1. Default categories
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        size: 14,
                        color: AppleTokens.systemBlue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVi ? 'Mẫu chuẩn' : 'Templates',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: AppleTokens.systemGray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$defaultCount',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                ),
                const SizedBox(width: 10),

                // 2. Custom categories
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.pencil_circle_fill,
                        size: 14,
                        color: AppleTokens.systemPurple,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVi ? 'Tùy chỉnh' : 'Custom',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: AppleTokens.systemGray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$customCount',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                ),
                const SizedBox(width: 10),

                // 3. Categorized transactions
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.doc_text_fill,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVi ? 'Đã gán GD' : 'Assigned',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: AppleTokens.systemGray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$totalTransactions GD',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
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

