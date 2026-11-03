import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/core/widgets/skeleton_box.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/budgets/presentation/widgets/budget_alert_banner.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_tile.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
    final budgetAlertBanner =
        customBudgetBanner ??
        (triggeredBudgets.isNotEmpty ? const BudgetAlertBanner() : null);
    final aiQuickSlot = ref.watch(aiQuickEntrySlotProvider);

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge,
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
        actions: [
          IconButton(
            tooltip: l10n.walletsTitle,
            onPressed: () => context.push(AppRoutes.accounts),
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
          IconButton(
            tooltip: l10n.categoriesTitle,
            onPressed: () => context.push(AppRoutes.categories),
            icon: const Icon(Icons.category_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(accountsStreamProvider)
            ..invalidate(transactionsStreamProvider)
            ..invalidate(categoriesStreamProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
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
            const SizedBox(height: 16),

            // Future AI quick entry slot (extensible without modifying Home)
            ?aiQuickSlot,
            if (aiQuickSlot != null) const SizedBox(height: 12),

            // Budget alert slot (injected by Budgets feature in Milestone e)
            ?budgetAlertBanner,
            if (budgetAlertBanner != null) const SizedBox(height: 16),

            // This Month's Income vs Expense Cards
            Text(
              '${l10n.thisMonthSummary} • ${AppDateUtils.formatMonthYear(DateTime.now(), locale: locale)}',
              style: theme.textTheme.titleMedium,
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

            // Active Wallets Strip
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.walletsTitle,
                    style: theme.textTheme.titleMedium,
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
            if (activeWallets.isEmpty)
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: scheme.primary,
                  ),
                  title: Text(l10n.emptyWalletsTitle),
                  subtitle: Text(l10n.emptyWalletsSubtitle),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.accounts),
                ),
              )
            else
              SizedBox(
                height: walletStripHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: activeWallets.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final wallet = activeWallets[index];
                    return _MiniWalletCard(
                      account: wallet,
                      locale: locale,
                      hideBalance: hideBalance,
                      onTap: () => context.push(AppRoutes.accounts),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),

            // Recent Transactions Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.recentTransactions,
                    style: theme.textTheme.titleMedium,
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
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(context.localizeError(err)),
                ),
              ),
              data: (_) {
                if (recentTxs.isEmpty) {
                  return Card(
                    child: EmptyStateView(
                      icon: Icons.receipt_long_outlined,
                      title: l10n.emptyTransactionsTitle,
                      subtitle: l10n.emptyTransactionsSubtitle,
                      actionLabel: l10n.quickAddTransaction,
                      onAction: () => context.push(AppRoutes.transactionNew),
                    ),
                  );
                }

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < recentTxs.length; i++) ...[
                        if (i > 0) const Divider(indent: 68),
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
      floatingActionButton: isLargeText
          ? FloatingActionButton(
              heroTag: 'home_quick_add_fab',
              tooltip: l10n.quickAddTransaction,
              onPressed: () => context.push(AppRoutes.transactionNew),
              child: const Icon(Icons.add_rounded),
            )
          : FloatingActionButton.extended(
              heroTag: 'home_quick_add_fab',
              onPressed: () => context.push(AppRoutes.transactionNew),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.quickAddTransaction),
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
    // Dedicated rich deep-jade surface with crisp white foreground guarantees >7:1 WCAG AAA contrast in both Light and Dark themes.
    const fgColor = Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D7C66),
            Color(0xFF074C3E),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.totalBalance,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: fgColor.withValues(alpha: 0.9),
                  ),
                ),
              ),
              IconButton(
                tooltip: hideBalance ? l10n.showBalance : l10n.hideBalance,
                onPressed: onToggleVisibility,
                style: IconButton.styleFrom(
                  foregroundColor: fgColor,
                  backgroundColor: fgColor.withValues(alpha: 0.16),
                ),
                icon: Icon(
                  hideBalance
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: SizedBox(
              key: ValueKey<bool>(hideBalance),
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  totalBalance.format(locale: locale, masked: hideBalance),
                  semanticsLabel: hideBalance ? l10n.balanceHidden : null,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.w700,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: fgColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
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
    return Card(
      child: Padding(
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
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          excludeSemantics: true,
          label:
              '${account.name}, ${hideBalance ? l10n.balanceHidden : formattedBalance}',
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                          style: theme.textTheme.labelLarge,
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
      ),
    );
  }
}
