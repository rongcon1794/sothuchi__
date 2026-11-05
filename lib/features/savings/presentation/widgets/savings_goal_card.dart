import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/savings/domain/entities/savings_goal.dart';
import 'package:so_thu_chi/features/savings/presentation/controllers/savings_goals_controller.dart';
import 'package:so_thu_chi/features/savings/presentation/widgets/savings_arc_progress.dart';
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

  IconData _resolveIcon(String key) {
    switch (key) {
      case 'house':
        return CupertinoIcons.house;
      case 'car':
        return CupertinoIcons.car;
      case 'airplane':
        return CupertinoIcons.airplane;
      case 'shield':
        return CupertinoIcons.shield_fill;
      case 'laptop':
        return CupertinoIcons.device_laptop;
      case 'gift':
        return CupertinoIcons.gift;
      case 'heart':
        return CupertinoIcons.heart_fill;
      case 'star':
        return CupertinoIcons.star_fill;
      case 'bag':
        return CupertinoIcons.bag;
      case 'piggy_bank':
      default:
        return CupertinoIcons.cube_box;
    }
  }

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

    return AppleGlassCard(
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      borderColor: goal.isCompleted
          ? AppleTokens.systemGreen.withValues(alpha: 0.4)
          : accentColor.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              AppleSquircleBadge(
                icon: _resolveIcon(goal.icon),
                backgroundColor: accentColor,
                size: 42,
                iconSize: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (goal.note.isNotEmpty)
                      Text(
                        goal.note,
                        style: const TextStyle(fontSize: 12, color: AppleTokens.systemGray),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (goal.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppleTokens.systemGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.checkmark_seal_fill, color: AppleTokens.systemGreen, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        l10n.savingsGoalCompleted,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppleTokens.systemGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              PopupMenuButton<String>(
                icon: const Icon(CupertinoIcons.ellipsis, size: 18, color: AppleTokens.systemGray),
                onSelected: (val) {
                  if (val == 'deposit') {
                    SavingsDepositSheet.show(context, goal: goal, isWithdraw: false);
                  } else if (val == 'withdraw') {
                    SavingsDepositSheet.show(context, goal: goal, isWithdraw: true);
                  } else if (val == 'edit') {
                    SavingsGoalFormSheet.show(context, existing: goal);
                  } else if (val == 'delete') {
                    _confirmDelete(context, ref);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'deposit',
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.plus_circle, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.savingsDeposit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'withdraw',
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.minus_circle, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.savingsWithdraw),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.pencil, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.trash, color: AppleTokens.rubyExpense, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.savingsDeleteGoal, style: const TextStyle(color: AppleTokens.rubyExpense)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Arc Gauge & Values Row
          Row(
            children: [
              SavingsArcProgressIndicator(
                progress: goal.progress,
                color: accentColor,
                size: 96,
                strokeWidth: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${goal.progressPercent}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      l10n.savingsProgress,
                      style: const TextStyle(fontSize: 10, color: AppleTokens.systemGray),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.savingsTotalSaved.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      goal.currentMoney.format(locale: locale, masked: hideBalance),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.savingsTarget, style: const TextStyle(fontSize: 11, color: AppleTokens.systemGray)),
                              Text(
                                goal.targetMoney.format(locale: locale, masked: hideBalance),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(l10n.savingsRemaining, style: const TextStyle(fontSize: 11, color: AppleTokens.systemGray)),
                              Text(
                                goal.remainingMoney.format(locale: locale, masked: hideBalance),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: goal.remainingAmount > 0 ? AppleTokens.rubyExpense : AppleTokens.systemGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Smart Calculation Recommendation & Action Button
          if (goal.daysRemaining != null && goal.remainingAmount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.sparkles, color: AppleTokens.systemOrange, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.savingsDaysRemaining(goal.daysRemaining!)} • ${goal.recommendedDailySavings != null ? l10n.savingsDailyNeeded(Money(minorUnits: goal.recommendedDailySavings!).format(locale: locale)) : ''}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Quick deposit button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppleTokens.radiusPill)),
                padding: const EdgeInsets.symmetric(vertical: 9),
              ),
              onPressed: () => SavingsDepositSheet.show(context, goal: goal, isWithdraw: false),
              icon: const Icon(CupertinoIcons.plus_circle, size: 16),
              label: Text(l10n.savingsDepositAction, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
