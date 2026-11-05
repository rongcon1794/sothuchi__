import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/features/savings/presentation/controllers/savings_goals_controller.dart';
import 'package:so_thu_chi/features/savings/presentation/widgets/savings_arc_progress.dart';
import 'package:so_thu_chi/features/savings/presentation/widgets/savings_goal_card.dart';
import 'package:so_thu_chi/features/savings/presentation/widgets/savings_goal_form_sheet.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';

class SavingsGoalsScreen extends ConsumerStatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  ConsumerState<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends ConsumerState<SavingsGoalsScreen> {
  bool _isFabExpanded = true;
  bool _isFabVisible = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final goalsAsync = ref.watch(savingsGoalsStreamProvider);
    final summary = ref.watch(savingsSummaryProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final hideBalance = settings?.hideBalance ?? false;

    return Scaffold(
      backgroundColor: isDark ? AppleTokens.bgDarkPrimary : AppleTokens.bgLightPrimary,
      appBar: AppBar(
        title: Text(l10n.savingsTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, size: 24),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButtonLocation: const AppleFloatingActionButtonLocation(),
      floatingActionButton: AppleAdaptiveExpandableFab(
        heroTag: 'savings_add_fab',
        isVisible: _isFabVisible,
        isExpanded: _isFabExpanded,
        icon: const Icon(CupertinoIcons.plus),
        label: Text(l10n.savingsNewGoal),
        backgroundColor: AppleTokens.jadeDark,
        onPressed: () {
          unawaited(HapticFeedback.lightImpact());
          SavingsGoalFormSheet.show(context);
        },
        tooltip: l10n.savingsNewGoal,
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (err, _) => Center(child: Text(context.localizeError(err))),
        data: (allGoals) {
          if (allGoals.isEmpty) {
            return EmptyStateView(
              icon: CupertinoIcons.cube_box,
              title: l10n.savingsEmpty,
              subtitle: l10n.savingsEmptySubtitle,
              actionLabel: l10n.savingsCreateFirst,
              onAction: () => SavingsGoalFormSheet.show(context),
            );
          }

          final activeGoals = allGoals.where((g) => !g.isCompleted).toList();
          final completedGoals = allGoals.where((g) => g.isCompleted).toList();

          return NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.reverse) {
                if (_isFabVisible) {
                  setState(() {
                    _isFabVisible = false;
                    _isFabExpanded = false;
                  });
                }
              } else if (notification.direction == ScrollDirection.forward) {
                if (!_isFabVisible) {
                  setState(() => _isFabVisible = true);
                }
              } else if (notification.metrics.pixels <= 30) {
                if (!_isFabVisible || !_isFabExpanded) {
                  setState(() {
                    _isFabVisible = true;
                    _isFabExpanded = true;
                  });
                }
              }
              return false;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, AppleTokens.scrollBottomPaddingWithFab),
              children: [
                // Overall Summary Hero Card
                AppleGlassCard(
                  borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xFF0A2E20), Color(0xFF041710)]
                        : const [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
                  ),
                  borderColor: AppleTokens.jadePrimary.withValues(alpha: 0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              l10n.savingsSummaryProgress,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: AppleTokens.jadePrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppleTokens.jadePrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l10n.savingsActiveCount(summary.activeCount, summary.completedCount),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppleTokens.jadePrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          SavingsArcProgressIndicator(
                            progress: summary.overallProgress,
                            color: AppleTokens.jadePrimary,
                            size: 88,
                            strokeWidth: 8,
                            child: Text(
                              '${(summary.overallProgress * 100).round()}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.savingsTotalSaved, style: const TextStyle(fontSize: 12, color: AppleTokens.systemGray)),
                                const SizedBox(height: 2),
                                AppleAnimatedMoneyText(
                                  money: summary.savedMoney,
                                  masked: hideBalance,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0D5239),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.savingsGoalTarget(summary.targetMoney.format(locale: locale, masked: hideBalance)),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppleTokens.systemGray,
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
                const SizedBox(height: 22),

                // Active Goals Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text(
                    l10n.homeSavingsStripTitle.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppleTokens.systemGray,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (activeGoals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        l10n.savingsEmpty,
                        style: const TextStyle(color: AppleTokens.systemGray),
                      ),
                    ),
                  ),
                for (final goal in activeGoals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SavingsGoalCard(goal: goal, hideBalance: hideBalance),
                  ),

                // Completed Goals Section
                if (completedGoals.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.checkmark_seal_fill, color: AppleTokens.systemGreen, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${l10n.savingsGoalCompleted.toUpperCase()} (${completedGoals.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppleTokens.systemGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final goal in completedGoals)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SavingsGoalCard(goal: goal, hideBalance: hideBalance),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
