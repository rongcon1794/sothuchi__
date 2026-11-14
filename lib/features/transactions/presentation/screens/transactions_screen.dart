import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/core/widgets/skeleton_box.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_day_group_card.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_filter_sheet.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_financial_summary_card.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_search_type_bar.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isFabExpanded = true;
  bool _isFabVisible = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildHeaderMonthSwitcher({
    required DateTime? selectedMonth,
  }) {
    return AppleCompactMonthSwitcher(
      isHeaderMode: true,
      selectedMonth: selectedMonth,
      allowAllOption: true,
      onPrevious: () {
        ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
        ref.read(selectedTransactionMonthProvider.notifier).previousMonth();
      },
      onNext: () {
        ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
        ref.read(selectedTransactionMonthProvider.notifier).nextMonth();
      },
      onSelectMonth: (month) {
        ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
        ref.read(selectedTransactionMonthProvider.notifier).setMonth(month);
      },
    );
  }

  Future<bool> _handleSoftDeleteWithUndo(TransactionEntity tx) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final res = await ref
        .read(transactionsActionControllerProvider.notifier)
        .softDelete(tx.id);

    if (!mounted) return res.isSuccess;
    return res.fold(
      onSuccess: (_) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.transactionDeleted),
              action: SnackBarAction(
                label: l10n.undo,
                onPressed: () {
                  ref
                      .read(transactionsActionControllerProvider.notifier)
                      .restore(tx.id);
                },
              ),
            ),
          );
        return true;
      },
      onFailure: (err) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.localizeError(err))),
        );
        return false;
      },
    );
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (_) => const TransactionFilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final currency = settings?.currencyCode ?? AppCurrencies.defaultCode;
    final hideBalance = settings?.hideBalance ?? false;

    final txStream = ref.watch(transactionsStreamProvider);
    final filter = ref.watch(transactionFilterProvider);
    final selectedMonth = ref.watch(selectedTransactionMonthProvider);
    final grouped = ref.watch(groupedFilteredTransactionsProvider);
    final categoriesMap = ref.watch(categoriesMapProvider);
    final accountsMap = ref.watch(accountsMapProvider);

    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;

    final summary = ref.watch(filteredTransactionsSummaryProvider);
    final totalIncome = summary.income;
    final totalExpense = summary.expense;
    final netAmount = summary.net;
    final totalCount = summary.count;

    final scrollBottomPadding = isWide
        ? AppleTokens.scrollBottomPaddingLandscape + 42
        : AppleTokens.scrollBottomPaddingWithFab;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppleAppBar(
        titleText: l10n.transactionsTitle,
        isLandscape: isLandscape,
        showBackButton: false,
        actions: [
          if (isLandscape) ...[
            Center(
              child: _buildHeaderMonthSwitcher(
                selectedMonth: selectedMonth,
              ),
            ),
            const SizedBox(width: 8),
          ],
          AppleIconButton(
            icon: Icons.tune_rounded,
            size: isLandscape ? 32 : 36,
            iconSize: isLandscape ? 16 : 18,
            tooltip: l10n.filterTransactions,
            badgeText: filter.hasActiveFilters ? '•' : null,
            foregroundColor: filter.hasActiveFilters ? AppleTokens.systemBlue : null,
            borderColor: filter.hasActiveFilters
                ? AppleTokens.systemBlue.withValues(alpha: 0.4)
                : null,
            backgroundColor: filter.hasActiveFilters
                ? AppleTokens.systemBlue.withValues(alpha: isDark ? 0.2 : 0.1)
                : null,
            onTap: _openFilterSheet,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
        children: [
          // Month Switcher Bar (only shown in portrait mode; merged into AppBar in landscape)
          if (!isLandscape)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
              child: Center(
                child: AppleCompactMonthSwitcher(
                  selectedMonth: selectedMonth,
                  allowAllOption: true,
                  onPrevious: () {
                    ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
                    ref.read(selectedTransactionMonthProvider.notifier).previousMonth();
                  },
                  onNext: () {
                    ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
                    ref.read(selectedTransactionMonthProvider.notifier).nextMonth();
                  },
                  onSelectMonth: (month) {
                    ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
                    ref.read(selectedTransactionMonthProvider.notifier).setMonth(month);
                  },
                ),
              ),
            ),
          // Responsive Search & Type Filter Bar
          TransactionSearchTypeBar(
            searchController: _searchController,
            filter: filter,
            isLandscape: isLandscape,
            categoriesMap: categoriesMap,
            accountsMap: accountsMap,
            locale: locale,
            onSearchChanged: (value) => ref
                .read(transactionFilterProvider.notifier)
                .setSearchQuery(value),
            onSearchClear: () => ref
                .read(transactionFilterProvider.notifier)
                .setSearchQuery(''),
            onTypeSelected: (type) => ref
                .read(transactionFilterProvider.notifier)
                .setType(type),
            onClearAll: () => ref
                .read(transactionFilterProvider.notifier)
                .clearAll(),
          ),

          SizedBox(height: isLandscape ? 2 : 4),

          // Daily Transaction Groups (with scrollable centered summary card at the top)
          Expanded(
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
              child: txStream.when(
                loading: () => const SkeletonListView(itemCount: 5),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(context.localizeError(err)),
                  ),
                ),
                data: (allTxs) {
                  if (allTxs.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.receipt_long_outlined,
                      title: l10n.emptyTransactionsTitle,
                      subtitle: l10n.emptyTransactionsSubtitle,
                      actionLabel: l10n.addTransaction,
                      onAction: () => context.push(AppRoutes.transactionNew),
                    );
                  }
                  if (grouped.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.search_off_rounded,
                      title: l10n.noMatchingTransactionsTitle,
                      subtitle: l10n.noMatchingTransactionsSubtitle,
                      actionLabel: l10n.clearFilters,
                      onAction: () {
                        _searchController.clear();
                        ref.read(transactionFilterProvider.notifier).clearAll();
                      },
                    );
                  }

                  if (isWide) {
                    // Balance day groups across 2 responsive columns on landscape/wide screens
                    final leftGroups = <DailyTransactionGroup>[];
                    final rightGroups = <DailyTransactionGroup>[];
                    int leftWeight = 0;
                    int rightWeight = 0;

                    for (final group in grouped) {
                      final weight = 1 + group.transactions.length;
                      if (leftWeight <= rightWeight) {
                        leftGroups.add(group);
                        leftWeight += weight;
                      } else {
                        rightGroups.add(group);
                        rightWeight += weight;
                      }
                    }

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: AppleTokens.maxContentWidth),
                        child: ListView(
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                          padding: EdgeInsets.fromLTRB(16, 2, 16, scrollBottomPadding),
                          children: [
                            // Scrollable financial summary card with centered content at the top
                            TransactionFinancialSummaryCard(
                              totalIncome: totalIncome,
                              totalExpense: totalExpense,
                              netAmount: netAmount,
                              totalCount: totalCount,
                              currency: currency,
                              locale: locale,
                              hideBalance: hideBalance,
                              isLandscape: isLandscape,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      for (final group in leftGroups)
                                        RepaintBoundary(
                                          child: TransactionDayGroupCard(
                                            group: group,
                                            categoriesMap: categoriesMap,
                                            accountsMap: accountsMap,
                                            locale: locale,
                                            currency: currency,
                                            hideBalance: hideBalance,
                                            isLandscape: true,
                                            onTap: (tx) => context.push(
                                              AppRoutes.transactionDetail(tx.id),
                                            ),
                                            onSwipeEdit: (tx) => context.push(
                                              AppRoutes.transactionEdit(tx.id),
                                            ),
                                            onSwipeDelete: (tx) =>
                                                _handleSoftDeleteWithUndo(tx),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      for (final group in rightGroups)
                                        RepaintBoundary(
                                          child: TransactionDayGroupCard(
                                            group: group,
                                            categoriesMap: categoriesMap,
                                            accountsMap: accountsMap,
                                            locale: locale,
                                            currency: currency,
                                            hideBalance: hideBalance,
                                            isLandscape: true,
                                            onTap: (tx) => context.push(
                                              AppRoutes.transactionDetail(tx.id),
                                            ),
                                            onSwipeEdit: (tx) => context.push(
                                              AppRoutes.transactionEdit(tx.id),
                                            ),
                                            onSwipeDelete: (tx) =>
                                                _handleSoftDeleteWithUndo(tx),
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
                    );
                  }

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: AppleTokens.maxContentWidth),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        padding: EdgeInsets.fromLTRB(16, 4, 16, scrollBottomPadding),
                        itemCount: grouped.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return TransactionFinancialSummaryCard(
                              totalIncome: totalIncome,
                              totalExpense: totalExpense,
                              netAmount: netAmount,
                              totalCount: totalCount,
                              currency: currency,
                              locale: locale,
                              hideBalance: hideBalance,
                              isLandscape: isLandscape,
                            );
                          }
                          return RepaintBoundary(
                            child: TransactionDayGroupCard(
                              group: grouped[index - 1],
                              categoriesMap: categoriesMap,
                              accountsMap: accountsMap,
                              locale: locale,
                              currency: currency,
                              hideBalance: hideBalance,
                              isLandscape: false,
                              onTap: (tx) => context.push(
                                AppRoutes.transactionDetail(tx.id),
                              ),
                              onSwipeEdit: (tx) => context.push(
                                AppRoutes.transactionEdit(tx.id),
                              ),
                              onSwipeDelete: (tx) =>
                                  _handleSoftDeleteWithUndo(tx),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
    floatingActionButtonLocation: const AppleFloatingActionButtonLocation(),
      floatingActionButton: AppleAdaptiveExpandableFab(
        heroTag: 'transactions_add_fab',
        isVisible: _isFabVisible,
        isExpanded: _isFabExpanded,
        icon: const Icon(CupertinoIcons.plus),
        label: Text(l10n.addTransaction),
        onPressed: () => context.push(AppRoutes.transactionNew),
        tooltip: l10n.addTransaction,
      ),
    );
  }
}

