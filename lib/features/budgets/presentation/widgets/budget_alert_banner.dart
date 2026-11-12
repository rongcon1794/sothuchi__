import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
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

    final card = AppleGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      backgroundColor: bgColor.withValues(alpha: theme.brightness == Brightness.dark ? 0.25 : 0.45),
      borderColor: iconColor.withValues(alpha: 0.30),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              isExceeded
                  ? CupertinoIcons.xmark_octagon_fill
                  : CupertinoIcons.exclamationmark_triangle_fill,
              color: iconColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if (navigateOnTap)
            Icon(CupertinoIcons.chevron_right, size: 16, color: fgColor),
        ],
      ),
    );

    return Semantics(
      liveRegion: true,
      button: navigateOnTap,
      excludeSemantics: true,
      label: message,
      child: navigateOnTap
          ? ApplePressable(
              borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
              onTap: () => context.go(AppRoutes.budgets),
              child: card,
            )
          : card,
    );
  }
}

