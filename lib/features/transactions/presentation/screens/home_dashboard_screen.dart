import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
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
    final financeColors = context.financeColors;
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

    final incomeMetric = _CashflowMetricCard(
      label: l10n.income,
      amountText: monthSummary.income.format(
        locale: locale,
        showPlusSign: true,
        masked: hideBalance,
      ),
      semanticsAmount: hideBalance ? l10n.balanceHidden : null,
      icon: Icons.south_west_rounded,
      accentColor: financeColors.income,
      containerColor: financeColors.incomeContainer,
      onContainerColor: financeColors.onIncomeContainer,
    );

    final expenseMetric = _CashflowMetricCard(
      label: l10n.expense,
      amountText: monthSummary.expense.format(
        locale: locale,
        masked: hideBalance,
      ),
      semanticsAmount: hideBalance ? l10n.balanceHidden : null,
      icon: Icons.north_east_rounded,
      accentColor: financeColors.expense,
      containerColor: financeColors.expenseContainer,
      onContainerColor: financeColors.onExpenseContainer,
    );

    final walletStripHeight = math.max(96.0, 74.0 * textScale);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (user?.photoUrl != null && user!.photoUrl!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: AppleUserAvatar(
                  photoUrl: user.photoUrl,
                  displayName: user.displayName,
                  email: user.email,
                  size: 34,
                  borderRadius: 10,
                  onTap: () => context.push(AppRoutes.settings),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: SoThuChiLogo(size: 34),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.appTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (user?.displayName != null && user!.displayName!.isNotEmpty)
                    Text(
                      user.displayName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          const LedgerSelectorPill(),
          const SizedBox(width: 4),
          IconButton(
            tooltip: l10n.searchTransactionsTooltip,
            onPressed: () => context.go(AppRoutes.transactions),
            icon: const Icon(CupertinoIcons.search),
          ),
          const SizedBox(width: 4),
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
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(accountsStreamProvider)
              ..invalidate(transactionsStreamProvider)
              ..invalidate(categoriesStreamProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              AppleTokens.scrollBottomPaddingWithFab,
            ),
            children: [
              // Hero Total Balance Card
              _HeroBalanceCard(
                totalBalance: totalBalance,
                monthSummary: monthSummary,
                locale: locale,
                hideBalance: hideBalance,
                onToggleVisibility: () =>
                    ref.read(settingsControllerProvider.notifier).toggleHideBalance(),
              ),
              const SizedBox(height: 12),

              // Smart 4-Capsule Quick Actions
              const _HomeQuickActionBar(),
              const SizedBox(height: 14),

              // Due Recurring Bills Notification Banner
              if (dueBills.isNotEmpty) ...[
                ApplePressable(
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
                ),
                const SizedBox(height: 14),
              ],

              // Budget alert slot (injected by Budgets feature in Milestone e)
              ?budgetAlertBanner,
              if (budgetAlertBanner != null) const SizedBox(height: 16),

              // This Month's Income vs Expense Cards
              Text(
                '${l10n.thisMonthSummary} • ${AppDateUtils.formatMonthYear(DateTime.now(), locale: locale)}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (isLargeText)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    incomeMetric,
                    const SizedBox(height: 10),
                    expenseMetric,
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(child: incomeMetric),
                    const SizedBox(width: 12),
                    Expanded(child: expenseMetric),
                  ],
                ),
              const SizedBox(height: 20),

              // Active Wallets & Debts Strip
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
              const SizedBox(height: 20),

              // Active Savings Goals Strip
              if (activeGoals.isNotEmpty) ...[
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Heo đất & Tiết kiệm',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
                const SizedBox(height: 20),
              ],

              // Recent Transactions Header
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

              // Recent Transactions List / Loading / Empty
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
                              AppRoutes.transactionEdit(recentTxs[i].id),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
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
    final primaryDark = Color.alphaBlend(
      Colors.black.withValues(alpha: isDark ? 0.5 : 0.35),
      primary,
    );
    final primaryLight = isDark
        ? primary
        : Color.alphaBlend(Colors.white.withValues(alpha: 0.18), primary);
    const fgColor = Colors.white;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryLight, primary, primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: AppleTokens.hairline,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.35 : 0.28),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.shield_fill,
                      size: 15,
                      color: fgColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.totalBalance.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: fgColor.withValues(alpha: 0.85),
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: hideBalance ? l10n.showBalance : l10n.hideBalance,
                onPressed: onToggleVisibility,
                style: IconButton.styleFrom(
                  foregroundColor: fgColor,
                  backgroundColor: fgColor.withValues(alpha: 0.16),
                ),
                icon: AnimatedRotation(
                  turns: hideBalance ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    hideBalance
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                  semanticsLabel: hideBalance ? l10n.balanceHidden : null,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: fgColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
              border: Border.all(
                color: fgColor.withValues(alpha: 0.12),
                width: AppleTokens.hairline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  monthSummary.net.minorUnits >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 18,
                  color: fgColor,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${l10n.netBalance}: ${monthSummary.net.format(locale: locale, showPlusSign: true, masked: hideBalance)}',
                    semanticsLabel: hideBalance
                        ? '${l10n.netBalance}: ${l10n.balanceHidden}'
                        : null,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w600,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeQuickActionBar extends StatelessWidget {
  const _HomeQuickActionBar();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = [
      _ActionItemData(
        icon: CupertinoIcons.plus,
        label: l10n.homeActionTransaction,
        color: AppleTokens.jadePrimary,
        route: AppRoutes.transactionNew,
      ),
      _ActionItemData(
        icon: CupertinoIcons.creditcard,
        label: l10n.homeActionWallet,
        color: AppleTokens.systemBlue,
        route: AppRoutes.accounts,
      ),
      _ActionItemData(
        icon: CupertinoIcons.sparkles,
        label: l10n.homeActionSavings,
        color: AppleTokens.systemPink,
        route: AppRoutes.savings,
      ),
      _ActionItemData(
        icon: CupertinoIcons.repeat,
        label: l10n.homeActionRecurring,
        color: AppleTokens.systemPurple,
        route: AppRoutes.recurring,
      ),
      _ActionItemData(
        icon: CupertinoIcons.person_2,
        label: l10n.homeActionDebts,
        color: AppleTokens.systemIndigo,
        route: AppRoutes.debts,
      ),
      _ActionItemData(
        icon: CupertinoIcons.square_grid_2x2,
        label: l10n.homeActionCategories,
        color: AppleTokens.systemOrange,
        route: AppRoutes.categories,
      ),
    ];

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final barHeight = math.max(82.0, 56.0 + (26.0 * textScale));

    return SizedBox(
      height: barHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _QuickActionItem(
            icon: action.icon,
            label: action.label,
            color: action.color,
            onTap: () => context.push(action.route),
          );
        },
      ),
    );
  }
}

class _ActionItemData {
  const _ActionItemData({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String route;
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 70,
      child: ApplePressable(
        scaleDown: 0.94,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.35 : 0.2),
                  width: 0.8,
                ),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 5),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
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

class _CashflowMetricCard extends StatelessWidget {
  const _CashflowMetricCard({
    required this.label,
    required this.amountText,
    this.semanticsAmount,
    required this.icon,
    required this.accentColor,
    required this.containerColor,
    required this.onContainerColor,
  });

  final String label;
  final String amountText;
  final String? semanticsAmount;
  final IconData icon;
  final Color accentColor;
  final Color containerColor;
  final Color onContainerColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ApplePressable(
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: AppleGlassCard(
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: onContainerColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              amountText,
              semanticsLabel: semanticsAmount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w700,
                fontFeatures: AppTheme.tabularFigures,
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
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cardWidth = math.max(176.0, 140.0 * textScale);
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
        child: AppleGlassCard(
          borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
          padding: const EdgeInsets.all(12),
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
                    fontWeight: FontWeight.w700,
                    fontFeatures: AppTheme.tabularFigures,
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
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
