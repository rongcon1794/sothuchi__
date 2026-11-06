import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/core/widgets/skeleton_box.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/budgets/presentation/widgets/budget_alert_banner.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/ledger/presentation/widgets/ledger_selector_pill.dart';
import 'package:so_thu_chi/features/recurring/presentation/controllers/recurring_controller.dart';
import 'package:so_thu_chi/features/savings/domain/entities/savings_goal.dart';
import 'package:so_thu_chi/features/savings/presentation/controllers/savings_goals_controller.dart';
import 'package:so_thu_chi/features/savings/presentation/widgets/savings_arc_progress.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_tile.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  bool _isFabExpanded = false;
  bool _isFabVisible = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isLargeText = textScale >= 1.35;

    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final hideBalance = settings?.hideBalance ?? false;

    final totalBalance = ref.watch(totalNetBalanceProvider);
    final monthSummary = ref.watch(currentMonthSummaryProvider);
    final activeWallets = ref.watch(activeAccountsProvider);
    final accountsMap = ref.watch(accountsMapProvider);
    final categoriesMap = ref.watch(categoriesMapProvider);
    final txStream = ref.watch(transactionsStreamProvider);
    final recentTxs = ref.watch(recentTransactionsProvider);
    final customBudgetBanner = ref.watch(dashboardBudgetAlertSlotProvider);
    final triggeredBudgets = ref.watch(currentMonthTriggeredBudgetsProvider);
    final dueBills = ref.watch(dueRecurringListProvider);
    final activeGoals = ref.watch(activeSavingsGoalsProvider);
    final budgetAlertBanner =
        customBudgetBanner ??
        (triggeredBudgets.isNotEmpty ? const BudgetAlertBanner() : null);

    final walletStripHeight = math.max(96.0, 74.0 * textScale);

    final isLandscape = context.isLandscape;
    final appBarHeight = isLandscape
        ? AppleTokens.appBarHeightLandscape
        : AppleTokens.appBarHeightPortrait;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        title: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(right: isLandscape ? 8 : 10),
              child: SoThuChiLogo(size: isLandscape ? 22 : 36),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final hour = DateTime.now().hour;
                  final greeting = (hour >= 4 && hour < 12)
                      ? l10n.greetingMorning
                      : (hour >= 12 && hour < 18)
                          ? l10n.greetingAfternoon
                          : l10n.greetingEvening;
                  final userFirstName = (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
                      ? user.displayName!.trim().split(' ').last
                      : null;
                  final titleText = userFirstName != null
                      ? '$greeting, $userFirstName!'
                      : l10n.appTitle;

                  if (isLandscape) {
                    return Text(
                      titleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: -0.3,
                      ),
                    );
                  }

                  final subtitleText = userFirstName != null
                      ? l10n.appTagline
                      : (user?.displayName ?? user?.email ?? l10n.appTagline);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (subtitleText.isNotEmpty)
                        Text(
                          subtitleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: LedgerSelectorPill(compact: !isLandscape),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: NotificationListener<UserScrollNotification>(
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
              setState(() {
                _isFabVisible = true;
              });
            }
          } else if (notification.metrics.pixels <= 20) {
            if (!_isFabVisible || _isFabExpanded) {
              setState(() {
                _isFabVisible = true;
                _isFabExpanded = false;
              });
            }
          }
          return false;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = context.isLandscape;
            final isWide = constraints.maxWidth >= 580 && isLandscape || constraints.maxWidth >= 720;
            final scrollBottomPadding = (isWide || isLandscape)
                ? AppleTokens.scrollBottomPaddingLandscape + 42
                : AppleTokens.scrollBottomPaddingWithFab;

            final heroBalanceCard = _HeroBalanceCard(
              totalBalance: totalBalance,
              monthSummary: monthSummary,
              locale: locale,
              hideBalance: hideBalance,
              onToggleVisibility: () =>
                  ref.read(settingsControllerProvider.notifier).toggleHideBalance(),
            );

            final spendingPaceCard = _SmartSpendingPaceCard(
              monthSummary: monthSummary,
              totalBalance: totalBalance,
              locale: locale,
              hideBalance: hideBalance,
            );

            const quickActionBar = _HomeQuickActionBar();

            final dueBillsWidget = dueBills.isNotEmpty
                ? ApplePressable(
                    onTap: () => context.push(AppRoutes.recurring),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppleTokens.systemOrange.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                        border: Border.all(
                          color: AppleTokens.systemOrange.withValues(alpha: 0.35),
                          width: AppleTokens.hairline,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.bell_fill, color: AppleTokens.systemOrange, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Bạn có ${dueBills.length} hóa đơn định kỳ cần thanh toán',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          const Icon(CupertinoIcons.chevron_right, size: 14, color: AppleTokens.systemOrange),
                        ],
                      ),
                    ),
                  )
                : null;

            final walletsSection = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.walletsTitle,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Flexible(
                      flex: 0,
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.accounts),
                        child: Text(l10n.manageWallets),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: walletStripHeight,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: activeWallets.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      if (index < activeWallets.length) {
                        final wallet = activeWallets[index];
                        return _MiniWalletCard(
                          account: wallet,
                          locale: locale,
                          hideBalance: hideBalance,
                          onTap: () => context.push(AppRoutes.accounts),
                        );
                      }
                      return _AddWalletCard(
                        onTap: () => context.push(AppRoutes.accounts),
                      );
                    },
                  ),
                ),
              ],
            );

            final savingsSection = activeGoals.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.savingsTitle,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push(AppRoutes.savings),
                            child: Text(l10n.viewAll),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 94,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: activeGoals.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final goal = activeGoals[index];
                            return _MiniSavingsGoalCard(
                              goal: goal,
                              hideBalance: hideBalance,
                              onTap: () => context.push(AppRoutes.savings),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : null;

            final recentTransactionsSection = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.recentTransactions,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Flexible(
                      flex: 0,
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.transactions),
                        child: Text(l10n.viewAll),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                txStream.when(
                  loading: () => const SkeletonListView(itemCount: 3),
                  error: (err, _) => AppleGlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    child: Text(context.localizeError(err)),
                  ),
                  data: (_) {
                    if (recentTxs.isEmpty) {
                      return AppleGlassCard(
                        padding: const EdgeInsets.all(16),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                        child: EmptyStateView(
                          icon: Icons.receipt_long_outlined,
                          title: l10n.emptyTransactionsTitle,
                          subtitle: l10n.emptyTransactionsSubtitle,
                          actionLabel: l10n.quickAddTransaction,
                          onAction: () => context.push(AppRoutes.transactionNew),
                        ),
                      );
                    }

                    return AppleGlassCard(
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                      child: Column(
                        children: [
                          for (var i = 0; i < recentTxs.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: AppleTokens.hairline,
                                indent: 68,
                                color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                              ),
                            TransactionTile(
                              transaction: recentTxs[i],
                              category: categoriesMap[recentTxs[i].categoryId],
                              sourceAccount: accountsMap[recentTxs[i].accountId],
                              destinationAccount: recentTxs[i].toAccountId != null
                                  ? accountsMap[recentTxs[i].toAccountId!]
                                  : null,
                              locale: locale,
                              hideAmount: hideBalance,
                              onTap: () => context.push(
                                AppRoutes.transactionDetail(recentTxs[i].id),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            );

            return RefreshIndicator(
              onRefresh: () async {
                ref
                  ..invalidate(accountsStreamProvider)
                  ..invalidate(transactionsStreamProvider)
                  ..invalidate(categoriesStreamProvider);
              },
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, scrollBottomPadding),
                children: [
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 48,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              heroBalanceCard,
                              const SizedBox(height: 14),
                              walletsSection,
                              const SizedBox(height: 14),
                              spendingPaceCard,
                              if (dueBillsWidget != null) ...[
                                const SizedBox(height: 14),
                                dueBillsWidget,
                              ],
                              if (budgetAlertBanner != null) ...[
                                const SizedBox(height: 14),
                                budgetAlertBanner,
                              ],
                              if (savingsSection != null) ...[
                                const SizedBox(height: 14),
                                savingsSection,
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 52,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              quickActionBar,
                              const SizedBox(height: 12),
                              recentTransactionsSection,
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    heroBalanceCard,
                    const SizedBox(height: 12),
                    spendingPaceCard,
                    const SizedBox(height: 14),
                    quickActionBar,
                    if (dueBillsWidget != null) ...[
                      const SizedBox(height: 14),
                      dueBillsWidget,
                    ],
                    if (budgetAlertBanner != null) ...[
                      const SizedBox(height: 16),
                      budgetAlertBanner,
                    ],
                    const SizedBox(height: 14),
                    walletsSection,
                    if (savingsSection != null) ...[
                      const SizedBox(height: 20),
                      savingsSection,
                    ],
                    const SizedBox(height: 20),
                    recentTransactionsSection,
                  ],
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: const AppleFloatingActionButtonLocation(),
      floatingActionButton: AppleAdaptiveExpandableFab(
        heroTag: 'home_quick_add_fab',
        isVisible: _isFabVisible,
        isExpanded: _isFabExpanded && !isLargeText,
        icon: const Icon(CupertinoIcons.plus),
        label: Text(l10n.quickAddTransaction),
        onPressed: () => context.push(AppRoutes.transactionNew),
        tooltip: l10n.quickAddTransaction,
      ),
    );
  }
}

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({
    required this.totalBalance,
    required this.monthSummary,
    required this.locale,
    required this.hideBalance,
    required this.onToggleVisibility,
  });

  final Money totalBalance;
  final MonthlyCashflowSummary monthSummary;
  final String locale;
  final bool hideBalance;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    // Card Surface Gradient
    final cardGradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(primary, const Color(0xFF1E1F24), 0.70)!,
              const Color(0xFF16171B),
              const Color(0xFF111215),
            ],
            stops: const [0.0, 0.48, 1.0],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(primary, Colors.white, 0.90)!,
              Color.lerp(primary, Colors.white, 0.96)!,
              Colors.white,
            ],
            stops: const [0.0, 0.45, 1.0],
          );

    final titleColor = isDark
        ? Colors.white70
        : const Color(0xFF64748B);

    final balanceColor = isDark
        ? Colors.white
        : const Color(0xFF0F172A);

    final eyeBgColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.04);

    final eyeIconColor = isDark
        ? Colors.white70
        : const Color(0xFF475569);

    final totalFlow =
        monthSummary.income.minorUnits + monthSummary.expense.minorUnits;
    final hasFlow = totalFlow > 0;
    final incomeRatio = hasFlow
        ? ((monthSummary.income.minorUnits / totalFlow) * 100)
            .round()
            .clamp(1, 99)
        : 50;
    final expenseRatio = 100 - incomeRatio;
    final isNetPositive = monthSummary.net.minorUnits >= 0;
    final isLandscape = context.isLandscape;
    final isLargeText = MediaQuery.textScalerOf(context).scale(1) >= 1.35;

    Widget buildIncomeBox() => ApplePressable(
          onTap: () => context.go(AppRoutes.transactions),
          borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF10B981).withValues(alpha: 0.10)
                  : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(
                  alpha: isDark ? 0.22 : 0.20,
                ),
                width: AppleTokens.hairline,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(
                        CupertinoIcons.arrow_down_left,
                        size: 10.5,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.income,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  monthSummary.income.format(
                    locale: locale,
                    showPlusSign: true,
                    masked: hideBalance,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF34D399)
                        : const Color(0xFF059669),
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
        );

    Widget buildExpenseBox() => ApplePressable(
          onTap: () => context.go(AppRoutes.transactions),
          borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFFF43F5E).withValues(alpha: 0.10)
                  : const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
              border: Border.all(
                color: const Color(0xFFF43F5E).withValues(
                  alpha: isDark ? 0.22 : 0.20,
                ),
                width: AppleTokens.hairline,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(
                        CupertinoIcons.arrow_up_right,
                        size: 10.5,
                        color: Color(0xFFF43F5E),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.expense,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFFBE123C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  monthSummary.expense.format(
                    locale: locale,
                    masked: hideBalance,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFFB7185)
                        : const Color(0xFFE11D48),
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.22 : 0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
        child: Container(
          padding: EdgeInsets.all(isLandscape ? 14 : 20),
          decoration: BoxDecoration(
            gradient: cardGradient,
            borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : primary.withValues(alpha: 0.15),
              width: AppleTokens.hairline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Header Row: Emblem + Label + Currency + Eye Action
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: isDark ? 0.22 : 0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      CupertinoIcons.shield_fill,
                      size: 13,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            l10n.totalBalance,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : primary.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: Text(
                            totalBalance.currencyCode,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip:
                        hideBalance ? l10n.showBalance : l10n.hideBalance,
                    onPressed: onToggleVisibility,
                    style: IconButton.styleFrom(
                      foregroundColor: eyeIconColor,
                      backgroundColor: eyeBgColor,
                      minimumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                    ),
                    icon: AnimatedRotation(
                      turns: hideBalance ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        hideBalance
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Hero Net Worth Balance
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: SizedBox(
                  key: ValueKey<bool>(hideBalance),
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AppleAnimatedMoneyText(
                      money: totalBalance,
                      locale: locale,
                      masked: hideBalance,
                      semanticsLabel:
                          hideBalance ? l10n.balanceHidden : null,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: balanceColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 3. Side-by-Side (or stacked on large text) Monthly Inflow vs Outflow Cards
              if (isLargeText) ...[
                buildIncomeBox(),
                const SizedBox(height: 8),
                buildExpenseBox(),
              ] else ...[
                Row(
                  children: [
                    Expanded(child: buildIncomeBox()),
                    const SizedBox(width: 10),
                    Expanded(child: buildExpenseBox()),
                  ],
                ),
              ],

              // 4. Monthly Net Cashflow & Ratio Progress Bar
              if (hasFlow) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  child: SizedBox(
                    height: 5,
                    child: Row(
                      children: [
                        Expanded(
                          flex: incomeRatio,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF34D399),
                                  Color(0xFF059669),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          flex: expenseRatio,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFF43F5E),
                                  Color(0xFFBE123C),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (isLargeText) ...[
                  Row(
                    children: [
                      Icon(
                        isNetPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 15,
                        color: isNetPositive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF43F5E),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${l10n.netBalance}: ${monthSummary.net.format(locale: locale, showPlusSign: true, masked: hideBalance)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.85)
                                : const Color(0xFF334155),
                            fontFeatures: AppTheme.tabularFigures,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.incomeRatio(incomeRatio)} • ${l10n.expenseRatio(expenseRatio)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white54
                          : const Color(0xFF64748B),
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isNetPositive
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              size: 15,
                              color: isNetPositive
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF43F5E),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${l10n.netBalance}: ${monthSummary.net.format(locale: locale, showPlusSign: true, masked: hideBalance)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : const Color(0xFF334155),
                                  fontFeatures: AppTheme.tabularFigures,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.incomeRatio(incomeRatio)} • ${l10n.expenseRatio(expenseRatio)}',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF64748B),
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartSpendingPaceCard extends StatelessWidget {
  const _SmartSpendingPaceCard({
    required this.monthSummary,
    required this.totalBalance,
    required this.locale,
    required this.hideBalance,
  });

  final MonthlyCashflowSummary monthSummary;
  final Money totalBalance;
  final String locale;
  final bool hideBalance;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = math.max(1, daysInMonth - now.day + 1);

    final remainingMinor = monthSummary.income.minorUnits > monthSummary.expense.minorUnits
        ? (monthSummary.income.minorUnits - monthSummary.expense.minorUnits)
        : math.max(0, totalBalance.minorUnits);
    final safeDailyMinor = (remainingMinor / daysRemaining).round();
    final safeDailyMoney = Money(minorUnits: safeDailyMinor, currencyCode: totalBalance.currencyCode);

    final isOverPace = monthSummary.expense.minorUnits > monthSummary.income.minorUnits &&
        monthSummary.income.minorUnits > 0;
    final statusColor = isOverPace ? AppleTokens.systemOrange : AppleTokens.systemGreen;
    final statusIcon = isOverPace
        ? CupertinoIcons.exclamationmark_circle_fill
        : CupertinoIcons.checkmark_circle_fill;
    final statusText = isOverPace ? l10n.smartPaceOverPace : l10n.smartPaceOnTrack;

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isLargeText = textScale >= 1.35;

    return ApplePressable(
      onTap: () => context.go(AppRoutes.budgets),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: AppleGlassCard(
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        borderColor: statusColor.withValues(alpha: isDark ? 0.28 : 0.2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLargeText) ...[
              Row(
                children: [
                  AppleSquircleBadge(
                    icon: CupertinoIcons.gauge,
                    color: statusColor,
                    size: 28,
                    iconSize: 15,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.smartPaceTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              LayoutBuilder(
                builder: (context, c) {
                  if (c.maxWidth < 340) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppleSquircleBadge(
                              icon: CupertinoIcons.gauge,
                              color: statusColor,
                              size: 26,
                              iconSize: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.smartPaceTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 11, color: statusColor),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  statusText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      AppleSquircleBadge(
                        icon: CupertinoIcons.gauge,
                        color: statusColor,
                        size: 28,
                        iconSize: 15,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.smartPaceTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 11, color: statusColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                statusText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
            if (isLargeText) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.smartPaceSafeToSpend,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    safeDailyMoney.format(locale: locale, masked: hideBalance),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : theme.colorScheme.onSurface,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppleTokens.bgLightSecondary,
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.12) : AppleTokens.borderLight,
                        width: AppleTokens.hairline,
                      ),
                    ),
                    child: Text(
                      l10n.smartPaceDaysLeft(daysRemaining),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppleTokens.systemGray,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              LayoutBuilder(
                builder: (context, c) {
                  final isCompactCard = c.maxWidth < 340;
                  if (isCompactCard) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.smartPaceSafeToSpend,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            safeDailyMoney.format(locale: locale, masked: hideBalance),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : theme.colorScheme.onSurface,
                              fontFeatures: AppTheme.tabularFigures,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppleTokens.bgLightSecondary,
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.12) : AppleTokens.borderLight,
                              width: AppleTokens.hairline,
                            ),
                          ),
                          child: Text(
                            l10n.smartPaceDaysLeft(daysRemaining),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppleTokens.systemGray,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.smartPaceSafeToSpend,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                safeDailyMoney.format(locale: locale, masked: hideBalance),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : theme.colorScheme.onSurface,
                                  fontFeatures: AppTheme.tabularFigures,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppleTokens.bgLightSecondary,
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.12) : AppleTokens.borderLight,
                              width: AppleTokens.hairline,
                            ),
                          ),
                          child: Text(
                            l10n.smartPaceDaysLeft(daysRemaining),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppleTokens.systemGray,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeQuickActionBar extends StatelessWidget {
  const _HomeQuickActionBar();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final actions = [
      _ActionItemData(
        icon: CupertinoIcons.plus,
        label: l10n.homeActionTransaction,
        gradient: [
          Color.lerp(primary, Colors.white, 0.28)!,
          primary,
        ],
        accentColor: primary,
        route: AppRoutes.transactionNew,
      ),
      _ActionItemData(
        icon: CupertinoIcons.creditcard,
        label: l10n.homeActionWallet,
        gradient: const [Color(0xFF38BDF8), Color(0xFF0284C7)],
        accentColor: const Color(0xFF0284C7),
        route: AppRoutes.accounts,
      ),
      _ActionItemData(
        icon: CupertinoIcons.sparkles,
        label: l10n.homeActionSavings,
        gradient: const [Color(0xFFFBBF24), Color(0xFFD97706)],
        accentColor: const Color(0xFFF59E0B),
        route: AppRoutes.savings,
      ),
      _ActionItemData(
        icon: CupertinoIcons.repeat,
        label: l10n.homeActionRecurring,
        gradient: const [Color(0xFFC084FC), Color(0xFF7E22CE)],
        accentColor: const Color(0xFF9333EA),
        route: AppRoutes.recurring,
      ),
      _ActionItemData(
        icon: CupertinoIcons.person_2,
        label: l10n.homeActionDebts,
        gradient: const [Color(0xFFFB7185), Color(0xFFE11D48)],
        accentColor: const Color(0xFFE11D48),
        route: AppRoutes.debts,
      ),
      _ActionItemData(
        icon: CupertinoIcons.square_grid_2x2,
        label: l10n.homeActionCategories,
        gradient: const [Color(0xFF2DD4BF), Color(0xFF0F766E)],
        accentColor: const Color(0xFF0D9488),
        route: AppRoutes.categories,
      ),
    ];

    final isLandscape = context.isLandscape;
    final isDark = theme.brightness == Brightness.dark;

    if (isLandscape) {
      final landscapeActions = actions.take(4).toList();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppleTokens.bgDarkCard : AppleTokens.bgLightCard,
          borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
          border: Border.all(
            color: isDark ? AppleTokens.separatorDark : AppleTokens.borderLight,
            width: AppleTokens.hairline,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < landscapeActions.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: _LandscapeQuickActionItem(
                  icon: landscapeActions[i].icon,
                  label: landscapeActions[i].label,
                  gradient: landscapeActions[i].gradient,
                  accentColor: landscapeActions[i].accentColor,
                  onTap: () => context.push(landscapeActions[i].route),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final barHeight = math.max(88.0, 60.0 + (28.0 * textScale));

    return SizedBox(
      height: barHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _QuickActionItem(
            icon: action.icon,
            label: action.label,
            gradient: action.gradient,
            accentColor: action.accentColor,
            onTap: () => context.push(action.route),
          );
        },
      ),
    );
  }
}

class _LandscapeQuickActionItem extends StatelessWidget {
  const _LandscapeQuickActionItem({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ApplePressable(
      scaleDown: 0.94,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItemData {
  const _ActionItemData({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.accentColor,
    required this.route,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final Color accentColor;
  final String route;
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 74,
      child: ApplePressable(
        scaleDown: 0.92,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.28),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniWalletCard extends StatelessWidget {
  const _MiniWalletCard({
    required this.account,
    required this.locale,
    required this.hideBalance,
    required this.onTap,
  });

  final Account account;
  final String locale;
  final bool hideBalance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cardWidth = math.max(180.0, 144.0 * textScale);
    final color = AppIconCatalog.contrastSafeColor(
      Color(account.color),
      theme.brightness,
    );
    final formattedBalance = account.balanceMoney.format(
      locale: locale,
      masked: hideBalance,
    );

    return SizedBox(
      width: cardWidth,
      child: ApplePressable(
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppleTokens.bgDarkCard : AppleTokens.bgLightCard,
            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.35 : 0.22),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.14 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Semantics(
            button: true,
            excludeSemantics: true,
            label:
                '${account.name}, ${hideBalance ? l10n.balanceHidden : formattedBalance}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        AppIconCatalog.resolve(account.icon),
                        size: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  formattedBalance,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: AppTheme.tabularFigures,
                    color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddWalletCard extends StatelessWidget {
  const _AddWalletCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cardWidth = math.max(120.0, 96.0 * textScale);

    return SizedBox(
      width: cardWidth,
      child: ApplePressable(
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppleTokens.bgDarkSecondary.withValues(alpha: 0.5)
                : AppleTokens.bgLightSecondary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
            border: Border.all(
              color: isDark ? AppleTokens.bgDarkTertiary : AppleTokens.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.plus_circle_fill,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.addWallet,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniSavingsGoalCard extends StatelessWidget {
  const _MiniSavingsGoalCard({
    required this.goal,
    required this.hideBalance,
    required this.onTap,
  });

  final SavingsGoal goal;
  final bool hideBalance;
  final VoidCallback onTap;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).languageCode;
    final accentColor = Color(goal.color);

    return ApplePressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppleTokens.bgDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.25 : 0.2),
            width: AppleTokens.hairline,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SavingsArcProgressIndicator(
              progress: goal.progress,
              color: accentColor,
              size: 48,
              strokeWidth: 4.5,
              child: Icon(
                _resolveIcon(goal.icon),
                size: 18,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    goal.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    goal.currentMoney.format(locale: locale, masked: hideBalance),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${goal.progressPercent}% / ${goal.targetMoney.format(locale: locale, masked: hideBalance)}',
                    style: const TextStyle(fontSize: 10, color: AppleTokens.systemGray),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
