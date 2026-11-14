import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
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
  int _selectedFilter = 0; // 0 = Tất cả, 1 = Đang nuôi, 2 = Hoàn thành

  Widget _buildFilterPills({
    required int totalCount,
    required int activeCount,
    required int completedCount,
    required bool isDark,
  }) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    final filters = [
      (index: 0, label: '${isVi ? 'Tất cả' : 'All'} ($totalCount)'),
      (index: 1, label: '${isVi ? 'Đang nuôi' : 'Active'} ($activeCount)'),
      (index: 2, label: '${isVi ? 'Hoàn thành' : 'Completed'} ($completedCount)'),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _selectedFilter == f.index;
          return ApplePressable(
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              setState(() => _selectedFilter = f.index);
            },
            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark
                        ? AppleTokens.bgDarkSecondary
                        : AppleTokens.bgLightSecondary),
                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                          ? AppleTokens.separatorDark
                          : AppleTokens.separatorLight),
                  width: 0.8,
                ),
              ),
              child: Text(
                f.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark ? Colors.white70 : Colors.black87),
                  height: 1.2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;
    final appBarHeight = isLandscape
        ? AppleTokens.appBarHeightLandscape
        : AppleTokens.appBarHeightPortrait;
    final scrollBottomPadding = isWide
        ? AppleTokens.scrollBottomPaddingLandscape + 42
        : AppleTokens.scrollBottomPaddingWithFab;

    final goalsAsync = ref.watch(savingsGoalsStreamProvider);
    final summary = ref.watch(savingsSummaryProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final hideBalance = settings?.hideBalance ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: const AppleBackButton(),
        title: AppleHeaderTitle(
          title: l10n.savingsTitle,
          isLandscape: isLandscape,
        ),
        actions: [
          AppleIconButton(
            icon: hideBalance ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
            size: isLandscape ? 32 : 36,
            iconSize: isLandscape ? 16 : 18,
            tooltip: hideBalance ? l10n.showBalance : l10n.hideBalance,
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              ref.read(settingsControllerProvider.notifier).toggleHideBalance();
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButtonLocation: const AppleFloatingActionButtonLocation(),
      floatingActionButton: AppleAdaptiveExpandableFab(
        heroTag: 'savings_add_fab',
        isVisible: _isFabVisible,
        isExpanded: _isFabExpanded,
        icon: const Icon(CupertinoIcons.plus),
        label: Text(l10n.savingsNewGoal),
        onPressed: () {
          unawaited(HapticFeedback.lightImpact());
          SavingsGoalFormSheet.show(context);
        },
        tooltip: l10n.savingsNewGoal,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: goalsAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (err, _) => Center(child: Text(context.localizeError(err))),
          data: (allGoals) {
            if (allGoals.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppleTokens.jadePrimary
                                  .withValues(alpha: isDark ? 0.3 : 0.18),
                              AppleTokens.systemOrange
                                  .withValues(alpha: isDark ? 0.15 : 0.08),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                AppleTokens.jadePrimary.withValues(alpha: 0.3),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.savings_rounded,
                          size: 38,
                          color: AppleTokens.jadePrimary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        l10n.savingsEmpty,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.savingsEmptySubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppleTokens.systemGray,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ApplePressable(
                        onTap: () => SavingsGoalFormSheet.show(context),
                        borderRadius:
                            BorderRadius.circular(AppleTokens.radiusPill),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppleTokens.jadePrimary,
                            borderRadius:
                                BorderRadius.circular(AppleTokens.radiusPill),
                            boxShadow: [
                              BoxShadow(
                                color: AppleTokens.jadePrimary
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.plus,
                                  size: 16, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                l10n.savingsCreateFirst,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final activeGoals = allGoals.where((g) => !g.isCompleted).toList();
            final completedGoals = allGoals.where((g) => g.isCompleted).toList();

            final displayedGoals = switch (_selectedFilter) {
              1 => activeGoals,
              2 => completedGoals,
              _ => allGoals,
            };

            final summaryHeroCard = AppleGlassCard(
              borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
              borderColor: AppleTokens.jadePrimary
                  .withValues(alpha: isDark ? 0.32 : 0.2),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppleTokens.jadePrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                l10n.savingsSummaryProgress.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: isDark
                                      ? AppleTokens.jadePrimary
                                      : const Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppleTokens.jadePrimary
                              .withValues(alpha: isDark ? 0.22 : 0.12),
                          borderRadius:
                              BorderRadius.circular(AppleTokens.radiusPill),
                        ),
                        child: Text(
                          l10n.savingsActiveCount(
                            summary.activeCount,
                            summary.completedCount,
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppleTokens.jadePrimary
                                : const Color(0xFF1B5E20),
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SavingsArcProgressIndicator(
                        progress: summary.overallProgress,
                        color: AppleTokens.jadePrimary,
                        size: 88,
                        strokeWidth: 8,
                        child: Text(
                          '${(summary.overallProgress * 100).round()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.savingsTotalSaved.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: AppleTokens.systemGray,
                              ),
                            ),
                            const SizedBox(height: 3),
                            AppleAnimatedMoneyText(
                              money: summary.savedMoney,
                              masked: hideBalance,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                fontFeatures: AppTheme.tabularFigures,
                                letterSpacing: -0.5,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0D5239),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.savingsGoalTarget(
                                summary.targetMoney.format(
                                  locale: locale,
                                  masked: hideBalance,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppleTokens.systemGray,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );

            final goalsListWidgets = <Widget>[
              // Filter Chips
              _buildFilterPills(
                totalCount: allGoals.length,
                activeCount: activeGoals.length,
                completedCount: completedGoals.length,
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              if (displayedGoals.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'vi'
                          ? (_selectedFilter == 1
                              ? 'Không có mục tiêu nào đang tích lũy'
                              : 'Chưa có mục tiêu nào hoàn thành')
                          : (_selectedFilter == 1
                              ? 'No active savings goals'
                              : 'No completed savings goals yet'),
                      style: const TextStyle(color: AppleTokens.systemGray),
                    ),
                  ),
                )
              else
                for (final goal in displayedGoals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SavingsGoalCard(
                      goal: goal,
                      hideBalance: hideBalance,
                    ),
                  ),
            ];

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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1024),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, scrollBottomPadding),
                    children: [
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 42,
                              child: summaryHeroCard,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 58,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: goalsListWidgets,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        summaryHeroCard,
                        const SizedBox(height: 18),
                        ...goalsListWidgets,
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
