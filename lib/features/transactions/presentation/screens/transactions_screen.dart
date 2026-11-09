import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/core/widgets/skeleton_box.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_filter_sheet.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_tile.dart';

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

    final filteredTxs = ref.watch(filteredTransactionsProvider);
    int totalIncome = 0;
    int totalExpense = 0;
    for (final tx in filteredTxs) {
      if (tx.currency == currency) {
        if (tx.type == TransactionType.income) {
          totalIncome += tx.amount;
        } else if (tx.type == TransactionType.expense) {
          totalExpense += tx.amount;
        }
      }
    }
    final netAmount = totalIncome - totalExpense;
    final totalCount = filteredTxs.length;

    final scrollBottomPadding = isWide
        ? AppleTokens.scrollBottomPaddingLandscape + 42
        : AppleTokens.scrollBottomPaddingWithFab;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isLandscape
            ? AppleTokens.appBarHeightLandscape
            : AppleTokens.appBarHeightPortrait,
        title: Text(l10n.transactionsTitle),
        actions: [
          if (isLandscape) ...[
            Center(
              child: _buildHeaderMonthSwitcher(
                selectedMonth: selectedMonth,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Badge(
            isLabelVisible: filter.hasActiveFilters,
            child: IconButton(
              tooltip: l10n.filterTransactions,
              padding: isLandscape ? EdgeInsets.zero : const EdgeInsets.all(8),
              constraints: isLandscape
                  ? const BoxConstraints(minWidth: 32, minHeight: 32)
                  : null,
              onPressed: _openFilterSheet,
              icon: Icon(Icons.tune_rounded, size: isLandscape ? 19 : 24),
            ),
          ),
          const SizedBox(width: 4),
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
          // Responsive Search & Type Filter Bar (merged on the same row to optimize space)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppleTokens.maxContentWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, isLandscape ? 4 : 4, 16, isLandscape ? 4 : 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: isLandscape ? 32 : 36,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          border: Border.all(
                            color: isDark ? const Color(0xFF38383A) : const Color(0xFFD1D1D6),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(horizontal: isLandscape ? 8 : 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.search,
                              size: isLandscape ? 14 : 16,
                              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => ref
                                    .read(transactionFilterProvider.notifier)
                                    .setSearchQuery(value),
                                textAlignVertical: TextAlignVertical.center,
                                style: TextStyle(
                                  fontSize: isLandscape ? 12 : 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                  height: 1.25,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  isCollapsed: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  hintText: l10n.searchTransactionsHint,
                                  hintStyle: TextStyle(
                                    fontSize: isLandscape ? 11.5 : 12,
                                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                                    fontWeight: FontWeight.w400,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                            ),
                            if (filter.searchQuery.isNotEmpty)
                              Tooltip(
                                message: l10n.clearFilters,
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(isLandscape ? 20 : 24, isLandscape ? 20 : 24),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(transactionFilterProvider.notifier)
                                        .setSearchQuery('');
                                  },
                                  child: Icon(
                                    CupertinoIcons.clear_circled_solid,
                                    size: isLandscape ? 14 : 15,
                                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: isLandscape ? 32 : 36,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF38383A)
                              : const Color(0xFFD1D1D6),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTypeIconButton(
                            type: null,
                            tooltip: l10n.all,
                            icon: CupertinoIcons.square_grid_2x2,
                            iconColor: null,
                            isLandscape: isLandscape,
                            theme: theme,
                            isDark: isDark,
                            filter: filter,
                          ),
                          const SizedBox(width: 2),
                          _buildTypeIconButton(
                            type: TransactionType.expense,
                            tooltip: l10n.expense,
                            icon: CupertinoIcons.arrow_up_right,
                            iconColor: AppleTokens.rubyExpense,
                            isLandscape: isLandscape,
                            theme: theme,
                            isDark: isDark,
                            filter: filter,
                          ),
                          const SizedBox(width: 2),
                          _buildTypeIconButton(
                            type: TransactionType.income,
                            tooltip: l10n.income,
                            icon: CupertinoIcons.arrow_down_left,
                            iconColor: AppleTokens.emeraldIncome,
                            isLandscape: isLandscape,
                            theme: theme,
                            isDark: isDark,
                            filter: filter,
                          ),
                          const SizedBox(width: 2),
                          _buildTypeIconButton(
                            type: TransactionType.transfer,
                            tooltip: l10n.transfer,
                            icon: CupertinoIcons.arrow_right_arrow_left,
                            iconColor: AppleTokens.cobaltTransfer,
                            isLandscape: isLandscape,
                            theme: theme,
                            isDark: isDark,
                            filter: filter,
                          ),
                          if (filter.hasActiveFilters) ...[
                            const SizedBox(width: 3),
                            Container(
                              width: 1,
                              height: isLandscape ? 16 : 20,
                              color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6),
                            ),
                            const SizedBox(width: 3),
                            Tooltip(
                              message: l10n.clearFilters,
                              child: ApplePressable(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _searchController.clear();
                                  ref.read(transactionFilterProvider.notifier).clearAll();
                                },
                                child: Container(
                                  width: isLandscape ? 28 : 32,
                                  height: isLandscape ? 28 : 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppleTokens.systemRed.withValues(alpha: isDark ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                  ),
                                  child: const Icon(
                                    Icons.filter_alt_off_rounded,
                                    size: 14,
                                    color: AppleTokens.systemRed,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (filter.hasActiveFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppleTokens.maxContentWidth),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list_rounded, size: 13, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _getActiveFilterSummary(filter, categoriesMap, accountsMap, l10n, locale),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            ref.read(transactionFilterProvider.notifier).clearAll();
                          },
                          child: const Icon(
                            CupertinoIcons.clear_circled_solid,
                            size: 14,
                            color: AppleTokens.systemRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                            _buildFinancialSummaryCard(
                              totalIncome: totalIncome,
                              totalExpense: totalExpense,
                              netAmount: netAmount,
                              totalCount: totalCount,
                              currency: currency,
                              locale: locale,
                              hideBalance: hideBalance,
                              isLandscape: isLandscape,
                              isDark: isDark,
                              theme: theme,
                              l10n: l10n,
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
                                          child: _buildDayGroupCard(
                                            context,
                                            group,
                                            categoriesMap,
                                            accountsMap,
                                            locale,
                                            currency,
                                            hideBalance,
                                            isDark,
                                            theme,
                                            l10n,
                                            true,
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
                                          child: _buildDayGroupCard(
                                            context,
                                            group,
                                            categoriesMap,
                                            accountsMap,
                                            locale,
                                            currency,
                                            hideBalance,
                                            isDark,
                                            theme,
                                            l10n,
                                            true,
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
                            return _buildFinancialSummaryCard(
                              totalIncome: totalIncome,
                              totalExpense: totalExpense,
                              netAmount: netAmount,
                              totalCount: totalCount,
                              currency: currency,
                              locale: locale,
                              hideBalance: hideBalance,
                              isLandscape: isLandscape,
                              isDark: isDark,
                              theme: theme,
                              l10n: l10n,
                            );
                          }
                          return RepaintBoundary(
                            child: _buildDayGroupCard(
                              context,
                              grouped[index - 1],
                              categoriesMap,
                              accountsMap,
                              locale,
                              currency,
                              hideBalance,
                              isDark,
                              theme,
                              l10n,
                              false,
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

  String _getActiveFilterSummary(
    TransactionFilter filter,
    Map<String, Category> categoriesMap,
    Map<String, Account> accountsMap,
    AppLocalizations l10n,
    String locale,
  ) {
    final parts = <String>[];
    if (filter.accountId != null && accountsMap.containsKey(filter.accountId)) {
      parts.add(accountsMap[filter.accountId]!.name);
    }
    if (filter.categoryId != null && categoriesMap.containsKey(filter.categoryId)) {
      parts.add(categoriesMap[filter.categoryId]!.name);
    }
    if (filter.startDate != null && filter.endDate != null) {
      parts.add(
        '${AppDateUtils.formatShortDate(filter.startDate!, locale: locale)} - ${AppDateUtils.formatShortDate(filter.endDate!, locale: locale)}',
      );
    }
    if (parts.isEmpty) return l10n.filterActiveCount(1);
    return parts.join(' · ');
  }

  Widget _buildTypeIconButton({
    required TransactionType? type,
    required String tooltip,
    required IconData icon,
    required Color? iconColor,
    required bool isLandscape,
    required ThemeData theme,
    required bool isDark,
    required TransactionFilter filter,
  }) {
    final isSelected = filter.type == type;
    final activeColor = iconColor ?? theme.colorScheme.primary;
    final size = isLandscape ? 28.0 : 32.0;
    final iconSize = isLandscape ? 13.5 : 15.0;

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: ApplePressable(
        onTap: () {
          HapticFeedback.selectionClick();
          ref
              .read(transactionFilterProvider.notifier)
              .setType(isSelected ? null : type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: isDark ? 0.30 : 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            border: Border.all(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.55)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: isSelected
                ? activeColor
                : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryCard({
    required int totalIncome,
    required int totalExpense,
    required int netAmount,
    required int totalCount,
    required String currency,
    required String locale,
    required bool hideBalance,
    required bool isLandscape,
    required bool isDark,
    required ThemeData theme,
    required AppLocalizations l10n,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLandscape ? 8 : 10),
      child: AppleGlassCard(
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 12 : 14,
          vertical: isLandscape ? 8 : 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.chart_pie,
                  size: isLandscape ? 11 : 12,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  l10n.transactionCountTotal(totalCount).toUpperCase(),
                  style: TextStyle(
                    fontSize: isLandscape ? 10 : 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: isLandscape ? 6 : 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildSummarySegment(
                    color: AppleTokens.emeraldIncome,
                    label: l10n.income,
                    amount: Money(minorUnits: totalIncome, currencyCode: currency)
                        .format(locale: locale, showPlusSign: true, masked: hideBalance),
                    theme: theme,
                    isLandscape: isLandscape,
                  ),
                ),
                Container(
                  width: 1,
                  height: isLandscape ? 22 : 26,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: _buildSummarySegment(
                    color: AppleTokens.rubyExpense,
                    label: l10n.expense,
                    amount: Money(minorUnits: totalExpense, currencyCode: currency)
                        .format(locale: locale, showMinusSign: true, masked: hideBalance),
                    theme: theme,
                    isLandscape: isLandscape,
                  ),
                ),
                Container(
                  width: 1,
                  height: isLandscape ? 22 : 26,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: _buildSummarySegment(
                    color: netAmount >= 0 ? AppleTokens.emeraldIncome : AppleTokens.rubyExpense,
                    label: l10n.netBalance,
                    amount: Money(minorUnits: netAmount, currencyCode: currency)
                        .format(locale: locale, showPlusSign: true, masked: hideBalance),
                    theme: theme,
                    isLandscape: isLandscape,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySegment({
    required Color color,
    required String label,
    required String amount,
    required ThemeData theme,
    required bool isLandscape,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 5.5,
              height: 5.5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isLandscape ? 10 : 10.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            amount,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isLandscape ? 12 : 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: AppTheme.tabularFigures,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayGroupCard(
    BuildContext context,
    DailyTransactionGroup group,
    Map<String, Category> categoriesMap,
    Map<String, Account> accountsMap,
    String locale,
    String currency,
    bool hideBalance,
    bool isDark,
    ThemeData theme,
    AppLocalizations l10n,
    bool isLandscape,
  ) {
    final dayNet = Money(
      minorUnits: group.netMinor,
      currencyCode: currency,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: isLandscape ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 4,
              vertical: isLandscape ? 3 : 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppDateUtils.formatDayHeader(
                      group.dayStart,
                      locale: locale,
                      todayLabel: l10n.today,
                      yesterdayLabel: l10n.yesterday,
                    ),
                    style: (isLandscape
                            ? theme.textTheme.labelMedium
                            : theme.textTheme.labelLarge)
                        ?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 7 : 9,
                    vertical: isLandscape ? 2 : 3,
                  ),
                  decoration: BoxDecoration(
                    color: (group.netMinor > 0
                            ? LucianTokens.mintLight
                            : (group.netMinor < 0
                                ? LucianTokens.dangerLight
                                : Colors.grey))
                        .withValues(alpha: isDark ? 0.15 : 0.10),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    border: Border.all(
                      color: (group.netMinor > 0
                              ? LucianTokens.resolveMint(isDark)
                              : (group.netMinor < 0
                                  ? LucianTokens.resolveDanger(isDark)
                                  : Colors.grey))
                          .withValues(alpha: isDark ? 0.25 : 0.18),
                      width: AppleTokens.hairline,
                    ),
                  ),
                  child: Text(
                    dayNet.format(
                      locale: locale,
                      showPlusSign: true,
                      masked: hideBalance,
                    ),
                    style: (isLandscape
                            ? theme.textTheme.labelSmall
                            : theme.textTheme.labelMedium)
                        ?.copyWith(
                      color: group.netMinor > 0
                          ? LucianTokens.resolveMint(isDark)
                          : (group.netMinor < 0
                              ? LucianTokens.resolveDanger(isDark)
                              : theme.colorScheme.onSurfaceVariant),
                      fontWeight: FontWeight.w700,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppleGlassCard(
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
            child: Column(
              children: [
                for (var i = 0; i < group.transactions.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: AppleTokens.hairline,
                      indent: isLandscape ? 56 : 68,
                      color: isDark
                          ? AppleTokens.separatorDark
                          : AppleTokens.separatorLight,
                    ),
                  TransactionTile(
                    transaction: group.transactions[i],
                    category: categoriesMap[group.transactions[i].categoryId],
                    sourceAccount: accountsMap[group.transactions[i].accountId],
                    destinationAccount: group.transactions[i].toAccountId != null
                        ? accountsMap[group.transactions[i].toAccountId!]
                        : null,
                    locale: locale,
                    hideAmount: hideBalance,
                    onTap: () => context.push(
                      AppRoutes.transactionDetail(group.transactions[i].id),
                    ),
                    onSwipeEdit: () => context.push(
                      AppRoutes.transactionEdit(group.transactions[i].id),
                    ),
                    onSwipeDelete: () =>
                        _handleSoftDeleteWithUndo(group.transactions[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

