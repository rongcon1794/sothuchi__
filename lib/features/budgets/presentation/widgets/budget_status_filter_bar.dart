import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';

enum BudgetFilterStatus { all, warning, exceeded, safe }

/// An Apple-style horizontal filter bar with tactile spring response and dynamic count badges.
class BudgetStatusFilterBar extends StatelessWidget {
  const BudgetStatusFilterBar({
    super.key,
    required this.selectedFilter,
    required this.progressList,
    required this.onSelectFilter,
  });

  final BudgetFilterStatus selectedFilter;
  final List<BudgetProgress> progressList;
  final ValueChanged<BudgetFilterStatus> onSelectFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isVi = l10n.localeName.startsWith('vi');

    final allCount = progressList.length;
    final warningCount = progressList.where((p) => p.isWarningTriggered && !p.isExceeded).length;
    final exceededCount = progressList.where((p) => p.isExceeded).length;
    final safeCount = progressList.where((p) => !p.isWarningTriggered && !p.isExceeded).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _FilterChip(
            label: isVi ? 'Tất cả' : 'All',
            count: allCount,
            isSelected: selectedFilter == BudgetFilterStatus.all,
            activeColor: Theme.of(context).colorScheme.primary,
            onTap: () => onSelectFilter(BudgetFilterStatus.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: isVi ? 'Cảnh báo' : 'Warning',
            count: warningCount,
            isSelected: selectedFilter == BudgetFilterStatus.warning,
            activeColor: AppleTokens.systemOrange,
            onTap: () => onSelectFilter(BudgetFilterStatus.warning),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: isVi ? 'Vượt mức' : 'Exceeded',
            count: exceededCount,
            isSelected: selectedFilter == BudgetFilterStatus.exceeded,
            activeColor: AppleTokens.systemRed,
            onTap: () => onSelectFilter(BudgetFilterStatus.exceeded),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: isVi ? 'An toàn' : 'On Track',
            count: safeCount,
            isSelected: selectedFilter == BudgetFilterStatus.safe,
            activeColor: AppleTokens.jadeDark,
            onTap: () => onSelectFilter(BudgetFilterStatus.safe),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isSelected
        ? activeColor.withValues(alpha: isDark ? 0.22 : 0.14)
        : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04));

    final textColor = isSelected
        ? activeColor
        : scheme.onSurfaceVariant;

    return ApplePressable(
      scaleDown: 0.94,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: isDark ? 0.40 : 0.25)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: isDark ? 0.30 : 0.18)
                    : (isDark ? Colors.white12 : Colors.black12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
