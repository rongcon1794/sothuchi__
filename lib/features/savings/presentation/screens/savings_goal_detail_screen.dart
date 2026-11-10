import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/savings/domain/entities/savings_goal.dart';
import 'package:so_thu_chi/features/savings/presentation/controllers/savings_goals_controller.dart';
import 'package:so_thu_chi/features/savings/presentation/widgets/savings_arc_progress.dart';
import 'package:so_thu_chi/features/savings/presentation/widgets/savings_deposit_sheet.dart';
import 'package:so_thu_chi/features/savings/presentation/widgets/savings_goal_form_sheet.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

class SavingsGoalDetailScreen extends ConsumerWidget {
  const SavingsGoalDetailScreen({
    super.key,
    required this.goalId,
  });

  final String goalId;

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
        return CupertinoIcons.cube_box;
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, SavingsGoal goal) async {
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
      await ref.read(savingsGoalsActionControllerProvider.notifier).deleteGoal(goal.id);
      if (context.mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;

    final goalsAsync = ref.watch(savingsGoalsStreamProvider);
    final accountsMap = ref.watch(accountsMapProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final hideBalance = settings?.hideBalance ?? false;

    return goalsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CupertinoActivityIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.localizeError(err))),
      ),
      data: (goals) {
        final goal = goals.where((g) => g.id == goalId).firstOrNull;
        if (goal == null) {
          return Scaffold(
            appBar: AppBar(),
            body: SafeArea(
              top: false,
              bottom: false,
              child: Center(
                child: Text(
                  'Không tìm thấy mục tiêu',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          );
        }

        final accentColor = Color(goal.color);
        final linkedAccount = goal.linkedAccountId != null ? accountsMap[goal.linkedAccountId!] : null;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            toolbarHeight: isLandscape
                ? AppleTokens.appBarHeightLandscape
                : AppleTokens.appBarHeightPortrait,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.chevron_left, size: 24),
              onPressed: () => context.pop(),
            ),
            title: Text(
              goal.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                tooltip: l10n.edit,
                icon: const Icon(CupertinoIcons.pencil, size: 20),
                onPressed: () => SavingsGoalFormSheet.show(context, existing: goal),
              ),
              IconButton(
                tooltip: l10n.delete,
                icon: const Icon(CupertinoIcons.trash, color: AppleTokens.systemRed, size: 20),
                onPressed: () => _handleDelete(context, ref, goal),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  isWide ? AppleTokens.scrollBottomPaddingLandscape + 20 : 32,
                ),
                children: [
                  // Hero Card: Arc Progress, Target & Current
                  AppleGlassCard(
                    borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
                    padding: const EdgeInsets.all(20),
                    borderColor: goal.isCompleted
                        ? AppleTokens.systemGreen.withValues(alpha: 0.4)
                        : accentColor.withValues(alpha: 0.35),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [accentColor.withValues(alpha: 0.2), Colors.black54]
                          : [accentColor.withValues(alpha: 0.12), Colors.white],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            AppleSquircleBadge(
                              icon: _resolveIcon(goal.icon),
                              backgroundColor: accentColor,
                              size: 48,
                              iconSize: 24,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (goal.note.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      goal.note,
                                      style: const TextStyle(fontSize: 12.5, color: AppleTokens.systemGray),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (goal.isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppleTokens.systemGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                ),
                                child: Text(
                                  l10n.savingsGoalCompleted,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppleTokens.systemGreen,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Arc Progress
                        Center(
                          child: SavingsArcProgressIndicator(
                            progress: goal.progress,
                            size: 140,
                            strokeWidth: 12,
                            color: accentColor,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${goal.progressPercent}%',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    fontFeatures: AppTheme.tabularFigures,
                                  ),
                                ),
                                Text(
                                  goal.isCompleted ? l10n.savingsGoalCompleted : l10n.savingsSummaryProgress,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppleTokens.systemGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Money Stats Grid
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.savingsTotalSaved,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppleTokens.systemGray),
                                    ),
                                    const SizedBox(height: 3),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        goal.currentMoney.format(locale: locale, masked: hideBalance),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: accentColor,
                                          fontFeatures: AppTheme.tabularFigures,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 30, color: AppleTokens.separatorLight),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.savingsGoalTarget(''),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppleTokens.systemGray),
                                    ),
                                    const SizedBox(height: 3),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        goal.targetMoney.format(locale: locale, masked: hideBalance),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          fontFeatures: AppTheme.tabularFigures,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 30, color: AppleTokens.separatorLight),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.savingsRemaining,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppleTokens.systemGray),
                                    ),
                                    const SizedBox(height: 3),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        goal.remainingMoney.format(locale: locale, masked: hideBalance),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          fontFeatures: AppTheme.tabularFigures,
                                        ),
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
                  ),

                  const SizedBox(height: 16),

                  // Deposit & Withdraw Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                            ),
                          ),
                          icon: const Icon(CupertinoIcons.plus_circle, size: 18),
                          label: Text(
                            l10n.savingsDeposit,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          onPressed: () => SavingsDepositSheet.show(context, goal: goal, isWithdraw: false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                            ),
                          ),
                          icon: const Icon(CupertinoIcons.minus_circle, size: 18),
                          label: Text(
                            l10n.savingsWithdraw,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          onPressed: () => SavingsDepositSheet.show(context, goal: goal, isWithdraw: true),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Timeline & Planning Metadata Card
                  AppleGlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kế hoạch tích lũy',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        if (goal.deadline != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.savingsDeadline, style: const TextStyle(color: AppleTokens.systemGray)),
                              Text(
                                AppDateUtils.formatFullDate(goal.deadline!, locale: locale),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (goal.daysRemaining != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Thời gian còn lại', style: TextStyle(color: AppleTokens.systemGray)),
                                Text(
                                  '${goal.daysRemaining} ngày',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (goal.recommendedDailySavings != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Cần gom / ngày', style: TextStyle(color: AppleTokens.systemGray)),
                                Text(
                                  Money(minorUnits: goal.recommendedDailySavings!, currencyCode: goal.currency).format(locale: locale),
                                  style: TextStyle(fontWeight: FontWeight.w700, color: accentColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (goal.recommendedMonthlySavings != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Cần gom / tháng', style: TextStyle(color: AppleTokens.systemGray)),
                                Text(
                                  Money(minorUnits: goal.recommendedMonthlySavings!, currencyCode: goal.currency).format(locale: locale),
                                  style: TextStyle(fontWeight: FontWeight.w700, color: accentColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                        if (linkedAccount != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l10n.savingsLinkedWallet, style: const TextStyle(color: AppleTokens.systemGray)),
                              Text(
                                linkedAccount.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ngày tạo', style: TextStyle(color: AppleTokens.systemGray)),
                            Text(
                              AppDateUtils.formatFullDate(goal.createdAt, locale: locale),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      },
    );
  }
}

