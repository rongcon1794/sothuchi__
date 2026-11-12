import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';

/// Redesigned multi-segmented proportion bar displaying how the monthly
/// budget is distributed across configured expense categories.
class BudgetAllocationBar extends StatelessWidget {
  const BudgetAllocationBar({
    super.key,
    required this.progressList,
    required this.categoriesMap,
  });

  final List<BudgetProgress> progressList;
  final Map<String, Category> categoriesMap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final totalBudget = progressList.fold<int>(0, (sum, p) => sum + p.budget.amount);
    if (totalBudget <= 0) return const SizedBox.shrink();

    return AppleGlassCard(
      padding: const EdgeInsets.all(15),
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AppleSquircleBadge(
                    icon: CupertinoIcons.chart_bar_fill,
                    backgroundColor: scheme.primary,
                    size: 26,
                    iconSize: 13,
                    radius: 7,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.localeName.startsWith('vi') ? 'Phân bổ ngân sách' : 'Budget Allocation',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Text(
                  '${progressList.length} ${l10n.localeName.startsWith('vi') ? 'danh mục' : 'categories'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Multi-segmented proportion bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            child: SizedBox(
              height: 7,
              child: Row(
                children: [
                  for (int i = 0; i < progressList.length; i++) ...[
                    Builder(
                      builder: (context) {
                        final item = progressList[i];
                        final ratio = (item.budget.amount / totalBudget).clamp(0.01, 1.0);
                        final cat = item.budget.categoryId != null
                            ? categoriesMap[item.budget.categoryId!]
                            : null;
                        final rawColor = item.budget.isOverall
                            ? scheme.primary
                            : Color(cat?.color ?? 0xFF0D7C66);
                        final safeColor = AppIconCatalog.contrastSafeColor(
                          rawColor,
                          theme.brightness,
                        );

                        return Expanded(
                          flex: (ratio * 1000).toInt().clamp(1, 1000),
                          child: Container(
                            color: safeColor,
                            margin: EdgeInsets.only(
                              right: i < progressList.length - 1 ? 1.5 : 0,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Category distribution tags
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final item in progressList.take(6)) ...[
                Builder(
                  builder: (context) {
                    final percent = totalBudget > 0
                        ? ((item.budget.amount * 100) ~/ totalBudget)
                        : 0;
                    final cat = item.budget.categoryId != null
                        ? categoriesMap[item.budget.categoryId!]
                        : null;
                    final name = item.budget.isOverall
                        ? l10n.overallMonthlyBudget
                        : DefaultCategoryLocalization.resolveName(
                            l10n,
                            categoryId: item.budget.categoryId!,
                            fallbackName: cat?.name ?? l10n.categoryBudget,
                          );
                    final rawColor = item.budget.isOverall
                        ? scheme.primary
                        : Color(cat?.color ?? 0xFF0D7C66);
                    final safeColor = AppIconCatalog.contrastSafeColor(
                      rawColor,
                      theme.brightness,
                    );

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: safeColor.withValues(alpha: isDark ? 0.14 : 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: safeColor.withValues(alpha: isDark ? 0.22 : 0.14),
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: BoxDecoration(
                              color: safeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$name ($percent%)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
