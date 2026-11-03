import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';

/// Displays an accessible warning banner whenever one or more budgets in the
/// active list have crossed their configured `alertThreshold`.
class BudgetAlertBanner extends ConsumerWidget {
  const BudgetAlertBanner({
    super.key,
    this.progressOverride,
    this.navigateOnTap = true,
  });

  final List<BudgetProgress>? progressOverride;
  final bool navigateOnTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<BudgetProgress> triggered =
        progressOverride ?? ref.watch(currentMonthTriggeredBudgetsProvider);
    if (triggered.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final financeColors = context.financeColors;
    final categoriesMap = ref.watch(categoriesMapProvider);

    // Highlight the most critical (highest usedPercent) budget warning first.
    final sorted = [...triggered]
      ..sort((a, b) => b.usedPercent.compareTo(a.usedPercent));
    final top = sorted.first;
    final isExceeded = top.isExceeded;

    final bgColor = isExceeded
        ? financeColors.expenseContainer
        : financeColors.warningContainer;
    final fgColor = isExceeded
        ? financeColors.onExpenseContainer
        : financeColors.onWarningContainer;
    final iconColor = isExceeded
        ? financeColors.expense
        : financeColors.warning;

    final scopeName = top.budget.isOverall
        ? l10n.overallMonthlyBudget
        : DefaultCategoryLocalization.resolveName(
            l10n,
            categoryId: top.budget.categoryId!,
            fallbackName:
                categoriesMap[top.budget.categoryId!]?.name ??
                l10n.categoryBudget,
          );

    final message = l10n.budgetWarningBanner(scopeName, top.usedPercent);

    return Semantics(
      liveRegion: true,
      button: navigateOnTap,
      excludeSemantics: true,
      label: message,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: navigateOnTap ? () => context.go(AppRoutes.budgets) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isExceeded
                      ? Icons.error_outline_rounded
                      : Icons.warning_amber_rounded,
                  color: iconColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (navigateOnTap)
                  Icon(Icons.chevron_right_rounded, color: fgColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

