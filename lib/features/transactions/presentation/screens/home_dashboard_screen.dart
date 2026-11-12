import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/core/widgets/skeleton_box.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/accounts/presentation/widgets/wallet_form_sheet.dart';
import 'package:so_thu_chi/features/auth/presentation/controllers/auth_controller.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/budgets/presentation/widgets/budget_alert_banner.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/ledger/presentation/widgets/ledger_selector_pill.dart';
import 'package:so_thu_chi/features/recurring/presentation/controllers/recurring_controller.dart';
import 'package:so_thu_chi/features/savings/presentation/controllers/savings_goals_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/dashboard_mini_cards.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/dashboard_quick_action_bar.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/dashboard_smart_spending_pace_card.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/lucian_live_kpi_card.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_tile.dart';

const Set<String> _vietnameseSurnames = {
  'nguyen', 'tran', 'le', 'pham', 'hoang', 'huynh', 'phan', 'vu', 'vo',
  'dang', 'bui', 'do', 'ho', 'ngo', 'duong', 'ly', 'dinh', 'doan', 'lam',
  'trinh', 'mai', 'dao', 'ta', 'luu', 'cao', 'truong', 'vuong', 'phung',
  'to', 'chau', 'thai', 'tang', 'luong', 'quach', 'nghiem', 'chu', 'ha',
  'diep', 'kieu', 'mac', 'thach', 'tong', 'vien', 'bach', 'la', 'au', 'ton',
  'trieu', 'nong', 'be', 'khong', 'giang', 'dong', 'khuc', 'luc', 'thieu',
  'ung', 'nhu', 'phu', 'han', 'lu', 'mach', 'sam', 'son', 'thi', 'tieu',
};

String _stripVietnameseDiacritics(String input) {
  const withDia =
      'àáảãạăằắẳẵặâầấẩẫậđèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵ';
  const withoutDia =
      'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy';
  final lower = input.toLowerCase();
  final buffer = StringBuffer();
  for (var i = 0; i < lower.length; i++) {
    final ch = lower[i];
    final idx = withDia.indexOf(ch);
    buffer.write(idx >= 0 ? withoutDia[idx] : ch);
  }
  return buffer.toString();
}

/// Extracts the user's given name ("tên") from [displayName], handling both
/// Vietnamese order ("Nguyễn Văn An" -> "An") and Western/Google order
/// ("An Nguyễn" / "Văn An Nguyễn" -> "An").
String? extractGreetingGivenName(String? displayName, {String locale = 'vi'}) {
  if (displayName == null) return null;
  final parts = displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return null;
  if (parts.length == 1) return parts.first;

  final firstNorm = _stripVietnameseDiacritics(parts.first);
  final lastNorm = _stripVietnameseDiacritics(parts.last);
  final firstIsSurname = _vietnameseSurnames.contains(firstNorm);
  final lastIsSurname = _vietnameseSurnames.contains(lastNorm);

  if (lastIsSurname && !firstIsSurname) {
    // Western / Google order: "An Nguyễn" or "Văn An Nguyễn" -> "An"
    return parts[parts.length - 2];
  }
  if (firstIsSurname) {
    // Vietnamese order: "Nguyễn Văn An" -> "An"
    return parts.last;
  }
  return locale.startsWith('vi') ? parts.last : parts.first;
}

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
    final allTxs = txStream.value ?? const <TransactionEntity>[];
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Padding(
              padding: EdgeInsets.only(right: isLandscape ? 8 : 10),
              child: SoThuChiLogo(size: isLandscape ? 24 : 34),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final hour = DateTime.now().hour;
                  final isMorning = hour >= 4 && hour < 12;
                  final isAfternoon = hour >= 12 && hour < 18;
                  final greeting = isMorning
                      ? l10n.greetingMorning
                      : (isAfternoon
                          ? l10n.greetingAfternoon
                          : l10n.greetingEvening);
                  final greetingIcon = isMorning
                      ? CupertinoIcons.sun_max_fill
                      : (isAfternoon
                          ? CupertinoIcons.sun_min_fill
                          : CupertinoIcons.moon_stars_fill);
                  final greetingColor = (isMorning || isAfternoon)
                      ? AppleTokens.systemOrange
                      : AppleTokens.systemIndigo;

                  final givenName = extractGreetingGivenName(
                    user?.displayName,
                    locale: locale,
                  );

                  final greetingLine = givenName != null
                      ? '$greeting, $givenName!'
                      : greeting;

                  if (isLandscape) {
                    return Text(
                      '${l10n.appTitle} · $greetingLine',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: -0.3,
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.appTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18.5,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            greetingIcon,
                            size: 11.5,
                            color: greetingColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              greetingLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 11.5,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                        ],
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
      body: SafeArea(
        top: false,
        bottom: false,
        child: NotificationListener<UserScrollNotification>(
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

            final heroBalanceCard = LucianLiveKpiCard(
              totalBalance: totalBalance,
              monthSummary: monthSummary,
              transactions: txStream.value ?? const <TransactionEntity>[],
              locale: locale,
              hideBalance: hideBalance,
              onToggleVisibility: () =>
                  ref.read(settingsControllerProvider.notifier).toggleHideBalance(),
              onNavigateTransactions: () => context.go(AppRoutes.transactions),
            );

            final spendingPaceCard = DashboardSmartSpendingPaceCard(
              monthSummary: monthSummary,
              totalBalance: totalBalance,
              locale: locale,
              hideBalance: hideBalance,
              transactions: allTxs,
            );

            const quickActionBar = DashboardQuickActionBar();

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
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    scrollDirection: Axis.horizontal,
                    itemCount: activeWallets.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      if (index < activeWallets.length) {
                        final wallet = activeWallets[index];
                        return DashboardMiniWalletCard(
                          account: wallet,
                          locale: locale,
                          hideBalance: hideBalance,
                          transactions: allTxs,
                          onTap: () => context.push(AppRoutes.accountDetail(wallet.id)),
                        );
                      }
                      return DashboardAddWalletCard(
                        onTap: () async {
                          final created = await WalletFormSheet.show(context);
                          if (created != null && context.mounted) {
                            await context.push(AppRoutes.accountDetail(created.id));
                          }
                        },
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
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          scrollDirection: Axis.horizontal,
                          itemCount: activeGoals.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final goal = activeGoals[index];
                            return DashboardMiniSavingsGoalCard(
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
                              showDate: true,
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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppleTokens.maxContentWidth),
                  child: ListView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                              RepaintBoundary(child: heroBalanceCard),
                              const SizedBox(height: 14),
                              RepaintBoundary(child: walletsSection),
                              const SizedBox(height: 14),
                              RepaintBoundary(child: spendingPaceCard),
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
                              RepaintBoundary(child: recentTransactionsSection),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    RepaintBoundary(child: heroBalanceCard),
                    const SizedBox(height: 12),
                    RepaintBoundary(child: spendingPaceCard),
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
                    RepaintBoundary(child: walletsSection),
                    if (savingsSection != null) ...[
                      const SizedBox(height: 20),
                      savingsSection,
                    ],
                    const SizedBox(height: 20),
                    RepaintBoundary(child: recentTransactionsSection),
                  ],
                ],
              ),
            ),
          ),
        );
          },
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

