import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
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
      case 'book':
        return CupertinoIcons.book_fill;
      case 'music':
        return CupertinoIcons.music_note_2;
      case 'piggy_bank':
      default:
        return Icons.savings_rounded;
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

    return ApplePressable(
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      onTap: () => context.push(AppRoutes.savingsDetail(goal.id)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark
                  ? Color.lerp(accentColor, const Color(0xFF1E1E22), 0.84)!
                  : Color.lerp(accentColor, Colors.white, 0.90)!,
              isDark
                  ? const Color(0xFF141416)
                  : Color.lerp(accentColor, const Color(0xFFF7F8FA), 0.96)!,
            ],
          ),
          border: Border.all(
            color: goal.isCompleted
                ? AppleTokens.systemGreen.withValues(alpha: isDark ? 0.6 : 0.5)
                : accentColor.withValues(alpha: isDark ? 0.35 : 0.22),
            width: goal.isCompleted ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: goal.isCompleted
                  ? AppleTokens.systemGreen.withValues(alpha: isDark ? 0.16 : 0.08)
                  : accentColor.withValues(alpha: isDark ? 0.18 : 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
          child: Stack(
            children: [
              // Subtle ambient radiant glow at top-right
              Positioned(
                right: -24,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                        accentColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Tier 1: Icon, Title, Badges, Menu ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Squircle Icon Badge with high-gloss gradient & shadow
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accentColor,
                                Color.lerp(accentColor, Colors.black, isDark ? 0.35 : 0.2)!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: isDark ? 0.3 : 0.45),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: isDark ? 0.4 : 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            _resolveIcon(goal.icon),
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Subtitle / Badges
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                goal.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16.5,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 5,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (goal.isCompleted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2.5,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppleTokens.systemGreen
                                            .withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(
                                          AppleTokens.radiusPill,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            CupertinoIcons.checkmark_seal_fill,
                                            size: 11,
                                            color: AppleTokens.systemGreen,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            l10n.savingsGoalCompleted,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppleTokens.systemGreen,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (goal.daysRemaining != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2.5,
                                      ),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : Colors.black.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(
                                          AppleTokens.radiusPill,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            CupertinoIcons.calendar,
                                            size: 11,
                                            color: isDark ? Colors.white60 : Colors.black54,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            l10n.savingsDaysRemaining(goal.daysRemaining!),
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white70 : Colors.black87,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (goal.note.isNotEmpty)
                                    Text(
                                      goal.note,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppleTokens.systemGray,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Progress Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${goal.progressPercent}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              fontFeatures: AppTheme.tabularFigures,
                              color: accentColor,
                              height: 1.2,
                            ),
                          ),
                        ),

                        const SizedBox(width: 4),

                        // 3-dots Menu
                        ApplePopupMenuButton<String>(
                          tooltip: l10n.moreOptions,
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

                    const SizedBox(height: 14),

                    // --- Tier 2: Balance Amounts & Progress Bar ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            goal.currentMoney.format(locale: locale, masked: hideBalance),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              fontFeatures: AppTheme.tabularFigures,
                              letterSpacing: -0.3,
                              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mục tiêu: ${goal.targetMoney.format(locale: locale, masked: hideBalance)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppleTokens.systemGray,
                            fontFeatures: AppTheme.tabularFigures,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Smooth Capsule Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Stack(
                        children: [
                          Container(
                            height: 7,
                            width: double.infinity,
                            color: accentColor.withValues(
                              alpha: isDark ? 0.18 : 0.10,
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: goal.progress,
                            child: Container(
                              height: 7,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accentColor,
                                    Color.lerp(accentColor, Colors.white, 0.25)!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${goal.progressPercent}% đã tích lũy',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                            fontFeatures: AppTheme.tabularFigures,
                          ),
                        ),
                        if (goal.remainingAmount > 0)
                          Text(
                            'Còn thiếu ${goal.remainingMoney.format(locale: locale, masked: hideBalance)}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontFeatures: AppTheme.tabularFigures,
                            ),
                          )
                        else
                          const Text(
                            'Đã hoàn thành',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppleTokens.systemGreen,
                            ),
                          ),
                      ],
                    ),

                    // --- Tier 3: Smart Insights Pill ---
                    if (goal.daysRemaining != null && goal.remainingAmount > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.035),
                          borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.sparkles,
                              color: AppleTokens.systemOrange,
                              size: 13,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${l10n.savingsDaysRemaining(goal.daysRemaining!)} • ${goal.recommendedDailySavings != null ? l10n.savingsDailyNeeded(Money(minorUnits: goal.recommendedDailySavings!).format(locale: locale)) : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // --- Tier 4: Quick Action Button ---
                    Row(
                      children: [
                        Expanded(
                          child: ApplePressable(
                            onTap: () {
                              unawaited(HapticFeedback.lightImpact());
                              SavingsDepositSheet.show(
                                context,
                                goal: goal,
                                isWithdraw: false,
                              );
                            },
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8.5),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accentColor,
                                    Color.lerp(accentColor, Colors.black, isDark ? 0.2 : 0.1)!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    CupertinoIcons.plus_circle_fill,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.savingsDepositAction,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (goal.currentAmount > 0) ...[
                          const SizedBox(width: 8),
                          ApplePressable(
                            onTap: () {
                              unawaited(HapticFeedback.lightImpact());
                              SavingsDepositSheet.show(
                                context,
                                goal: goal,
                                isWithdraw: true,
                              );
                            },
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8.5,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                border: Border.all(
                                  color: isDark
                                      ? AppleTokens.separatorDark
                                      : AppleTokens.separatorLight,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.minus_circle,
                                    size: 14,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.savingsWithdraw,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
