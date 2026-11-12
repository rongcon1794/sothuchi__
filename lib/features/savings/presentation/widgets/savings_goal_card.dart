import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/savings/domain/entities/savings_goal.dart';
import 'package:so_thu_chi/features/savings/presentation/controllers/savings_goals_controller.dart';
import 'package:so_thu_chi/features/savings/presentation/widgets/savings_deposit_sheet.dart';
import 'package:so_thu_chi/features/savings/presentation/widgets/savings_goal_form_sheet.dart';

class SavingsGoalCard extends ConsumerWidget {
  const SavingsGoalCard({
    super.key,
    required this.goal,
    this.hideBalance = false,
  });

  final SavingsGoal goal;
  final bool hideBalance;

  IconData _resolveIcon(String key) =>
      AppIconCatalog.resolveSavingsIcon(key, useOutlineCard: true);

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.savingsDeleteConfirmTitle(goal.title)),
        message: Text(l10n.savingsDeleteConfirmBody),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      unawaited(HapticFeedback.mediumImpact());
      await ref
          .read(savingsGoalsActionControllerProvider.notifier)
          .deleteGoal(goal.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final accentColor = Color(goal.color);
    final safeColor = AppIconCatalog.contrastSafeColor(
      accentColor,
      isDark ? Brightness.dark : Brightness.light,
    );
    final statusSubtitle = goal.isCompleted
        ? l10n.savingsGoalCompleted
        : (goal.daysRemaining != null
            ? l10n.savingsDaysRemaining(goal.daysRemaining!)
            : l10n.savingsNoDeadline);

    return ApplePressable(
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      onTap: () => context.push(AppRoutes.savingsDetail(goal.id)),
      child: AppleGlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
        borderColor: goal.isCompleted
            ? AppleTokens.systemGreen.withValues(alpha: isDark ? 0.55 : 0.45)
            : safeColor.withValues(alpha: isDark ? 0.35 : 0.22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Soft Squircle Icon + Title & Progress Pill + Menu
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: safeColor.withValues(alpha: isDark ? 0.22 : 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: safeColor.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _resolveIcon(goal.icon),
                    color: safeColor,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              goal.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: (goal.isCompleted
                                      ? AppleTokens.systemGreen
                                      : safeColor)
                                  .withValues(alpha: isDark ? 0.22 : 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppleTokens.radiusPill),
                            ),
                            child: Text(
                              '${goal.progressPercent}%',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                fontFeatures: AppTheme.tabularFigures,
                                color: goal.isCompleted
                                    ? AppleTokens.systemGreen
                                    : safeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            goal.isCompleted
                                ? CupertinoIcons.checkmark_seal_fill
                                : CupertinoIcons.calendar,
                            size: 11,
                            color: goal.isCompleted
                                ? AppleTokens.systemGreen
                                : (isDark ? Colors.white54 : Colors.black45),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              statusSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: goal.isCompleted
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: goal.isCompleted
                                    ? AppleTokens.systemGreen
                                    : (isDark
                                        ? Colors.white60
                                        : Colors.black54),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ApplePopupMenuButton<String>(
                  icon: CupertinoIcons.ellipsis_circle,
                  iconSize: 18,
                  size: 32,
                  tooltip: l10n.moreOptions,
                  onSelected: (val) {
                    if (val == 'deposit') {
                      SavingsDepositSheet.show(
                        context,
                        goal: goal,
                        isWithdraw: false,
                      );
                    } else if (val == 'withdraw') {
                      SavingsDepositSheet.show(
                        context,
                        goal: goal,
                        isWithdraw: true,
                      );
                    } else if (val == 'edit') {
                      SavingsGoalFormSheet.show(context, existing: goal);
                    } else if (val == 'delete') {
                      _confirmDelete(context, ref);
                    }
                  },
                  itemBuilder: (ctx) => [
                    ApplePopupMenuItem(
                      value: 'deposit',
                      icon: CupertinoIcons.plus_circle,
                      title: l10n.savingsDeposit,
                    ),
                    ApplePopupMenuItem(
                      value: 'withdraw',
                      icon: CupertinoIcons.minus_circle,
                      title: l10n.savingsWithdraw,
                    ),
                    ApplePopupMenuItem(
                      value: 'edit',
                      icon: CupertinoIcons.pencil,
                      title: l10n.edit,
                    ),
                    ApplePopupMenuItem(
                      value: 'delete',
                      icon: CupertinoIcons.trash,
                      title: l10n.savingsDeleteGoal,
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(
              height: AppleTokens.hairline,
              thickness: AppleTokens.hairline,
              color:
                  isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
            ),
            const SizedBox(height: 10),

            // Row 2: Current Saved Amount + Target + Quick Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        locale == 'vi' ? 'ĐÃ TÍCH LŨY' : 'SAVED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          goal.currentMoney.format(
                            locale: locale,
                            masked: hideBalance,
                          ),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            fontFeatures: AppTheme.tabularFigures,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1C1C1E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locale == 'vi'
                            ? (goal.remainingAmount > 0
                                ? 'Mục tiêu ${goal.targetMoney.format(locale: locale, masked: hideBalance)} • Thiếu ${goal.remainingMoney.format(locale: locale, masked: hideBalance)}'
                                : 'Mục tiêu ${goal.targetMoney.format(locale: locale, masked: hideBalance)} • Đã hoàn thành')
                            : (goal.remainingAmount > 0
                                ? 'Target ${goal.targetMoney.format(locale: locale, masked: hideBalance)} • ${goal.remainingMoney.format(locale: locale, masked: hideBalance)} left'
                                : 'Target ${goal.targetMoney.format(locale: locale, masked: hideBalance)} • Completed'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFeatures: AppTheme.tabularFigures,
                          color: goal.remainingAmount > 0
                              ? (isDark ? Colors.white60 : Colors.black54)
                              : AppleTokens.systemGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (goal.daysRemaining != null &&
                        goal.remainingAmount > 0 &&
                        goal.recommendedDailySavings != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.sparkles,
                            size: 11,
                            color: safeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.savingsDailyNeeded(
                              Money(
                                minorUnits: goal.recommendedDailySavings!,
                                currencyCode: goal.currency,
                              ).format(locale: locale, masked: hideBalance),
                            ),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (goal.currentAmount > 0) ...[
                          ApplePressable(
                            onTap: () {
                              unawaited(HapticFeedback.lightImpact());
                              SavingsDepositSheet.show(
                                context,
                                goal: goal,
                                isWithdraw: true,
                              );
                            },
                            borderRadius:
                                BorderRadius.circular(AppleTokens.radiusPill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5.5,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.045),
                                borderRadius: BorderRadius.circular(
                                  AppleTokens.radiusPill,
                                ),
                              ),
                              child: Icon(
                                CupertinoIcons.minus,
                                size: 13.5,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        ApplePressable(
                          onTap: () {
                            unawaited(HapticFeedback.lightImpact());
                            SavingsDepositSheet.show(
                              context,
                              goal: goal,
                              isWithdraw: false,
                            );
                          },
                          borderRadius:
                              BorderRadius.circular(AppleTokens.radiusPill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 5.5,
                            ),
                            decoration: BoxDecoration(
                              color: safeColor.withValues(
                                alpha: isDark ? 0.22 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppleTokens.radiusPill,
                              ),
                              border: Border.all(
                                color: safeColor.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.plus_circle_fill,
                                  size: 13.5,
                                  color: safeColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  l10n.savingsDepositAction,
                                  style: TextStyle(
                                    color: safeColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),
            LucianProgressBar(
              value: goal.progress,
              height: 4.5,
              activeColor: goal.isCompleted
                  ? AppleTokens.systemGreen
                  : safeColor,
              showGlow: false,
            ),

            if (goal.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '“${goal.note}”',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
