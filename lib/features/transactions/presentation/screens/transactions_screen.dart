import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
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
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';
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
      builder: (_) => const _TransactionFilterBottomSheet(),
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
      body: Column(
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
          // Responsive Search & Type Filter Bar (rendered in body, not pinned/fixed in header)
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 1100 : 860),
              child: isLandscape
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 38,
                            child: SizedBox(
                              height: 32,
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => ref
                                    .read(transactionFilterProvider.notifier)
                                    .setSearchQuery(value),
                                style: const TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark
                                      ? AppleTokens.bgDarkSecondary
                                      : AppleTokens.bgLightSecondary,
                                  hintText: l10n.searchTransactionsHint,
                                  hintStyle: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.white38 : Colors.black38,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 0),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppleTokens.radiusPill),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: const Icon(CupertinoIcons.search, size: 14),
                                  prefixIconConstraints: const BoxConstraints(
                                      minWidth: 26, minHeight: 26),
                                  suffixIcon: filter.searchQuery.isNotEmpty
                                      ? IconButton(
                                          padding: EdgeInsets.zero,
                                          iconSize: 14,
                                          tooltip: l10n.clearFilters,
                                          onPressed: () {
                                            _searchController.clear();
                                            ref
                                                .read(transactionFilterProvider.notifier)
                                                .setSearchQuery('');
                                          },
                                          icon: const Icon(
                                            CupertinoIcons.clear_thick_circled,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 62,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTypeChip(null, l10n.all,
                                      CupertinoIcons.square_grid_2x2, null, true),
                                  const SizedBox(width: 6),
                                  _buildTypeChip(
                                      TransactionType.expense,
                                      l10n.expense,
                                      CupertinoIcons.arrow_up_right,
                                      AppleTokens.rubyExpense,
                                      true),
                                  const SizedBox(width: 6),
                                  _buildTypeChip(
                                      TransactionType.income,
                                      l10n.income,
                                      CupertinoIcons.arrow_down_left,
                                      AppleTokens.emeraldIncome,
                                      true),
                                  const SizedBox(width: 6),
                                  _buildTypeChip(
                                      TransactionType.transfer,
                                      l10n.transfer,
                                      CupertinoIcons.arrow_right_arrow_left,
                                      AppleTokens.cobaltTransfer,
                                      true),
                                  if (filter.hasActiveFilters) ...[
                                    const SizedBox(width: 6),
                                    ActionChip(
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppleTokens.radiusPill),
                                        side: BorderSide.none,
                                      ),
                                      avatar: const Icon(Icons.filter_alt_off_rounded,
                                          size: 14),
                                      label: Text(l10n.clearFilters,
                                          style: const TextStyle(fontSize: 10.5)),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref
                                            .read(transactionFilterProvider.notifier)
                                            .clearAll();
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => ref
                                .read(transactionFilterProvider.notifier)
                                .setSearchQuery(value),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark
                                  ? AppleTokens.bgDarkSecondary
                                  : AppleTokens.bgLightSecondary,
                              hintText: l10n.searchTransactionsHint,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppleTokens.radiusPill),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppleTokens.radiusPill),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppleTokens.radiusPill),
                                borderSide: const BorderSide(
                                  color: AppleTokens.jadePrimary,
                                  width: 1.5,
                                ),
                              ),
                              prefixIcon:
                                  const Icon(CupertinoIcons.search, size: 20),
                              suffixIcon: filter.searchQuery.isNotEmpty
                                  ? IconButton(
                                      tooltip: l10n.clearFilters,
                                      onPressed: () {
                                        _searchController.clear();
                                        ref
                                            .read(
                                                transactionFilterProvider.notifier)
                                            .setSearchQuery('');
                                      },
                                      icon: const Icon(
                                        CupertinoIcons.clear_thick_circled,
                                        size: 18,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _buildTypeChip(null, l10n.all,
                                  CupertinoIcons.square_grid_2x2, null, false),
                              const SizedBox(width: 8),
                              _buildTypeChip(
                                  TransactionType.expense,
                                  l10n.expense,
                                  CupertinoIcons.arrow_up_right,
                                  AppleTokens.rubyExpense,
                                  false),
                              const SizedBox(width: 8),
                              _buildTypeChip(
                                  TransactionType.income,
                                  l10n.income,
                                  CupertinoIcons.arrow_down_left,
                                  AppleTokens.emeraldIncome,
                                  false),
                              const SizedBox(width: 8),
                              _buildTypeChip(
                                  TransactionType.transfer,
                                  l10n.transfer,
                                  CupertinoIcons.arrow_right_arrow_left,
                                  AppleTokens.cobaltTransfer,
                                  false),
                              if (filter.hasActiveFilters) ...[
                                const SizedBox(width: 8),
                                ActionChip(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppleTokens.radiusPill),
                                    side: BorderSide.none,
                                  ),
                                  avatar: const Icon(Icons.filter_alt_off_rounded,
                                      size: 16),
                                  label: Text(l10n.clearFilters),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(transactionFilterProvider.notifier)
                                        .clearAll();
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // High-Density Financial Summary Snapshot Bar
          if (filteredTxs.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(16, isLandscape ? 2 : 6, 16, isLandscape ? 4 : 6),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 1100 : 860),
                  child: AppleGlassCard(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 10 : 14,
                      vertical: isLandscape ? 3 : 6,
                    ),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMetricPill(
                                  color: AppleTokens.emeraldIncome,
                                  label: l10n.income,
                                  amount: '+${Money(minorUnits: totalIncome, currencyCode: currency).format(locale: locale, masked: hideBalance)}',
                                  isLandscape: isLandscape,
                                ),
                                SizedBox(width: isLandscape ? 10 : 14),
                                _buildMetricPill(
                                  color: AppleTokens.rubyExpense,
                                  label: l10n.expense,
                                  amount: '-${Money(minorUnits: totalExpense, currencyCode: currency).format(locale: locale, masked: hideBalance)}',
                                  isLandscape: isLandscape,
                                ),
                                SizedBox(width: isLandscape ? 10 : 14),
                                _buildMetricPill(
                                  color: netAmount >= 0 ? AppleTokens.emeraldIncome : AppleTokens.rubyExpense,
                                  label: 'Ròng',
                                  amount: '${netAmount >= 0 ? '+' : ''}${Money(minorUnits: netAmount, currencyCode: currency).format(locale: locale, masked: hideBalance)}',
                                  isLandscape: isLandscape,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$totalCount ${l10n.transactionsTitle.toLowerCase()}',
                          style: TextStyle(
                            fontSize: isLandscape ? 10.5 : 11.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          SizedBox(height: isLandscape ? 2 : 4),

          // Daily Transaction Groups (2-column adaptive on landscape, single-column on portrait)
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
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(16, 2, 16, scrollBottomPadding),
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      for (final group in leftGroups)
                                        _buildDayGroupCard(
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
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      for (final group in rightGroups)
                                        _buildDayGroupCard(
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
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, scrollBottomPadding),
                        itemCount: grouped.length,
                        itemBuilder: (context, groupIndex) {
                          return _buildDayGroupCard(
                            context,
                            grouped[groupIndex],
                            categoriesMap,
                            accountsMap,
                            locale,
                            currency,
                            hideBalance,
                            isDark,
                            theme,
                            l10n,
                            false,
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

  Widget _buildTypeChip(
    TransactionType? type,
    String label,
    IconData icon,
    Color? iconColor,
    bool isLandscape,
  ) {
    final filter = ref.watch(transactionFilterProvider);
    final isSelected = filter.type == type;

    return FilterChip(
      visualDensity: isLandscape ? VisualDensity.compact : VisualDensity.standard,
      padding: EdgeInsets.symmetric(horizontal: isLandscape ? 6 : 8),
      materialTapTargetSize: isLandscape ? MaterialTapTargetSize.shrinkWrap : null,
      avatar: Icon(
        icon,
        size: isLandscape ? 13 : 14,
        color: iconColor,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
        side: BorderSide.none,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: isLandscape ? 11 : 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (sel) {
        HapticFeedback.selectionClick();
        ref
            .read(transactionFilterProvider.notifier)
            .setType(type == null ? null : (sel ? type : null));
      },
    );
  }

  Widget _buildMetricPill({
    required Color color,
    required String label,
    required String amount,
    required bool isLandscape,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isLandscape ? 6 : 7,
          height: isLandscape ? 6 : 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: isLandscape ? 10.5 : 11.5,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isLandscape ? 10.5 : 11.5,
            color: color,
            fontWeight: FontWeight.w700,
            fontFeatures: AppTheme.tabularFigures,
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

class _TransactionFilterBottomSheet extends ConsumerWidget {
  const _TransactionFilterBottomSheet();

  static _DatePreset _resolveActivePreset(
    DateTime? start,
    DateTime? end,
    DateTime? selectedMonth,
  ) {
    if (start != null && end != null) {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      if (AppDateUtils.isSameDay(start, thirtyDaysAgo) &&
          AppDateUtils.isSameDay(end, now)) {
        return _DatePreset.last30Days;
      }

      final thisYearStart = DateTime(now.year, 1, 1);
      final thisYearEnd = DateTime(now.year, 12, 31, 23, 59, 59);
      if (AppDateUtils.isSameDay(start, thisYearStart) &&
          AppDateUtils.isSameDay(end, thisYearEnd)) {
        return _DatePreset.thisYear;
      }
      return _DatePreset.custom;
    }
    if (start != null || end != null) return _DatePreset.custom;

    if (selectedMonth == null) return _DatePreset.all;
    final now = DateTime.now();
    if (AppDateUtils.isSameMonth(selectedMonth, now)) {
      return _DatePreset.thisMonth;
    }
    final lastMonth = AppDateUtils.addMonths(now, -1);
    if (AppDateUtils.isSameMonth(selectedMonth, lastMonth)) {
      return _DatePreset.lastMonth;
    }

    return _DatePreset.custom;
  }

  static void _applyPreset(_DatePreset preset, WidgetRef ref) {
    final now = DateTime.now();
    switch (preset) {
      case _DatePreset.all:
        ref.read(selectedTransactionMonthProvider.notifier).setMonth(null);
        ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
      case _DatePreset.thisMonth:
        ref.read(selectedTransactionMonthProvider.notifier).setMonth(now);
        ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
      case _DatePreset.lastMonth:
        ref.read(selectedTransactionMonthProvider.notifier).setMonth(
              AppDateUtils.addMonths(now, -1),
            );
        ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
      case _DatePreset.last30Days:
        ref.read(transactionFilterProvider.notifier).setDateRange(
              now.subtract(const Duration(days: 30)),
              now,
            );
      case _DatePreset.thisYear:
        ref.read(transactionFilterProvider.notifier).setDateRange(
              DateTime(now.year, 1, 1),
              DateTime(now.year, 12, 31, 23, 59, 59),
            );
      case _DatePreset.custom:
        break;
    }
  }

  static Future<void> _pickCustomDateRange(
    BuildContext context,
    WidgetRef ref,
    TransactionFilter filter,
  ) async {
    final now = DateTime.now();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2018),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDateRange:
          filter.startDate != null && filter.endDate != null
              ? DateTimeRange(
                  start: filter.startDate!,
                  end: filter.endDate!,
                )
              : null,
      builder: (ctx, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              surface:
                  isDark ? AppleTokens.bgDarkCard : AppleTokens.bgLightCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref
          .read(transactionFilterProvider.notifier)
          .setDateRange(picked.start, picked.end);
    }
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark
                ? const Color(0xFF8E8E93)
                : const Color(0xFF6C6C70),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filter = ref.watch(transactionFilterProvider);
    final allCategories = ref.watch(categoriesStreamProvider).value ?? const [];
    final wallets = ref.watch(accountsStreamProvider).value ?? const [];
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final hideBalance = settings?.hideBalance ?? false;

    // Filter categories dynamically based on selected transaction type
    final visibleCategories = allCategories.where((cat) {
      if (filter.type == TransactionType.expense) {
        return cat.type == CategoryType.expense;
      }
      if (filter.type == TransactionType.income) {
        return cat.type == CategoryType.income;
      }
      return true;
    }).toList(growable: false);

    final selectedMonth = ref.watch(selectedTransactionMonthProvider);

    // Calculate active filter count
    var activeFilterCount = 0;
    if (filter.type != null) activeFilterCount++;
    if (filter.startDate != null || filter.endDate != null) activeFilterCount++;
    if (filter.accountId != null) activeFilterCount++;
    if (filter.categoryId != null) activeFilterCount++;

    final activePreset = _resolveActivePreset(filter.startDate, filter.endDate, selectedMonth);
    final sheetHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: sheetHeight),
      decoration: BoxDecoration(
        color: isDark ? AppleTokens.bgDarkPrimary : AppleTokens.bgLightPrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppleTokens.radiusHero),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Drag Handle
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF3A3A3C)
                      : const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sheet Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    l10n.filterTransactions,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (activeFilterCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppleTokens.radiusPill),
                      ),
                      child: Text(
                        '$activeFilterCount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (filter.hasActiveFilters)
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(40, 32),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(transactionFilterProvider.notifier).clearAll();
                      },
                      child: Text(
                        l10n.clearFilters,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppleTokens.systemRed,
                        ),
                      ),
                    ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 32),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFE5E5EA),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.xmark,
                        size: 14,
                        color: isDark
                            ? const Color(0xFF8E8E93)
                            : const Color(0xFF6C6C70),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Divider(
              height: AppleTokens.hairline,
              color: isDark
                  ? AppleTokens.separatorDark
                  : AppleTokens.separatorLight,
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Transaction Type
                    _buildSectionHeader(
                      context: context,
                      icon: CupertinoIcons.arrow_up_arrow_down_circle,
                      title: l10n.filterTransactionType,
                    ),
                    const SizedBox(height: 10),
                    _TypeSegmentSelector(
                      selectedType: filter.type,
                      onChanged: (newType) {
                        ref
                            .read(transactionFilterProvider.notifier)
                            .setType(newType);
                      },
                    ),
                    const SizedBox(height: 22),

                    // Section 2: Date Range
                    _buildSectionHeader(
                      context: context,
                      icon: CupertinoIcons.calendar,
                      title: l10n.dateRange,
                    ),
                    const SizedBox(height: 10),
                    _DatePresetChips(
                      activePreset: activePreset,
                      onSelectPreset: (preset) {
                        HapticFeedback.selectionClick();
                        _applyPreset(preset, ref);
                      },
                    ),
                    const SizedBox(height: 10),
                    _CustomDateRangeTile(
                      startDate: filter.startDate,
                      endDate: filter.endDate,
                      locale: locale,
                      onTap: () => _pickCustomDateRange(context, ref, filter),
                    ),
                    const SizedBox(height: 22),

                    // Section 3: Wallets
                    _buildSectionHeader(
                      context: context,
                      icon: CupertinoIcons.creditcard,
                      title: l10n.walletsTitle,
                    ),
                    const SizedBox(height: 10),
                    _WalletFilterList(
                      wallets: wallets,
                      selectedAccountId: filter.accountId,
                      onSelectAccount: (accId) {
                        ref
                            .read(transactionFilterProvider.notifier)
                            .setAccount(accId);
                      },
                      locale: locale,
                      hideBalance: hideBalance,
                    ),
                    const SizedBox(height: 22),

                    // Section 4: Categories
                    _buildSectionHeader(
                      context: context,
                      icon: CupertinoIcons.square_grid_2x2,
                      title: l10n.categoriesTitle,
                    ),
                    const SizedBox(height: 10),
                    _CategoryFilterChips(
                      categories: visibleCategories,
                      selectedCategoryId: filter.categoryId,
                      onSelectCategory: (catId) {
                        ref
                            .read(transactionFilterProvider.notifier)
                            .setCategory(catId);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Action Bar
            Divider(
              height: AppleTokens.hairline,
              color: isDark
                  ? AppleTokens.separatorDark
                  : AppleTokens.separatorLight,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: AppleButton.primary(
                label: l10n.filterApply,
                color: theme.colorScheme.primary,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DatePreset {
  all,
  thisMonth,
  lastMonth,
  last30Days,
  thisYear,
  custom,
}

class _TypeSegmentSelector extends StatelessWidget {
  const _TypeSegmentSelector({
    required this.selectedType,
    required this.onChanged,
  });

  final TransactionType? selectedType;
  final ValueChanged<TransactionType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final items = <(TransactionType?, String, IconData, Color)>[
      (
        null,
        l10n.filterDateAll,
        CupertinoIcons.square_grid_2x2,
        theme.colorScheme.primary,
      ),
      (
        TransactionType.expense,
        l10n.expense,
        CupertinoIcons.arrow_down_right,
        AppleTokens.systemRed,
      ),
      (
        TransactionType.income,
        l10n.income,
        CupertinoIcons.arrow_up_left,
        AppleTokens.systemGreen,
      ),
      (
        TransactionType.transfer,
        l10n.transfer,
        CupertinoIcons.arrow_right_arrow_left,
        AppleTokens.systemBlue,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? AppleTokens.bgDarkSecondary
            : AppleTokens.bgLightSecondary,
        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : AppleTokens.borderLight,
          width: AppleTokens.hairline,
        ),
      ),
      child: Row(
        children: items.map((item) {
          final (type, label, icon, tintColor) = item;
          final isSelected = selectedType == type;
          return Expanded(
            child: ApplePressable(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(type);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppleTokens.bgDarkCard : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.3 : 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 13,
                      color: isSelected
                          ? tintColor
                          : (isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6C6C70)),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark
                                  ? const Color(0xFF8E8E93)
                                  : const Color(0xFF6C6C70)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DatePresetChips extends StatelessWidget {
  const _DatePresetChips({
    required this.activePreset,
    required this.onSelectPreset,
  });

  final _DatePreset activePreset;
  final ValueChanged<_DatePreset> onSelectPreset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final presets = <(_DatePreset, String)>[
      (_DatePreset.all, l10n.filterDateAll),
      (_DatePreset.thisMonth, l10n.filterDateThisMonth),
      (_DatePreset.lastMonth, l10n.filterDateLastMonth),
      (_DatePreset.last30Days, l10n.filterDateLast30Days),
      (_DatePreset.thisYear, l10n.filterDateThisYear),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: presets.map((p) {
          final (preset, title) = p;
          final isSelected = activePreset == preset;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ApplePressable(
              onTap: () => onSelectPreset(preset),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                          .withValues(alpha: isDark ? 0.25 : 0.12)
                      : (isDark
                          ? AppleTokens.bgDarkSecondary
                          : AppleTokens.bgLightSecondary),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isDark
                            ? const Color(0xFF2C2C2E)
                            : AppleTokens.borderLight),
                    width: isSelected ? 1.5 : AppleTokens.hairline,
                  ),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CustomDateRangeTile extends StatelessWidget {
  const _CustomDateRangeTile({
    required this.startDate,
    required this.endDate,
    required this.locale,
    required this.onTap,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final hasCustomRange = startDate != null && endDate != null;

    return ApplePressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppleTokens.bgDarkSecondary
              : AppleTokens.bgLightSecondary,
          borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
          border: Border.all(
            color: hasCustomRange
                ? theme.colorScheme.primary.withValues(alpha: 0.5)
                : (isDark ? const Color(0xFF2C2C2E) : AppleTokens.borderLight),
            width: hasCustomRange ? 1.5 : AppleTokens.hairline,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CupertinoIcons.calendar_badge_plus,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasCustomRange
                        ? '${AppDateUtils.formatShortDate(startDate!, locale: locale)} – ${AppDateUtils.formatShortDate(endDate!, locale: locale)}'
                        : l10n.selectDateRange,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          hasCustomRange ? FontWeight.w600 : FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasCustomRange ? l10n.dateRange : l10n.selectDateRange,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF6C6C70),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 15,
              color: isDark
                  ? const Color(0xFF8E8E93)
                  : const Color(0xFF6C6C70),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletFilterList extends StatelessWidget {
  const _WalletFilterList({
    required this.wallets,
    required this.selectedAccountId,
    required this.onSelectAccount,
    required this.locale,
    required this.hideBalance,
  });

  final List<Account> wallets;
  final String? selectedAccountId;
  final ValueChanged<String?> onSelectAccount;
  final String locale;
  final bool hideBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // "All Wallets" Card
          _buildCard(
            context: context,
            isSelected: selectedAccountId == null,
            iconWidget: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CupertinoIcons.creditcard,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
            title: l10n.filterAllWallets,
            subtitle: '${wallets.length} ${l10n.walletsTitle.toLowerCase()}',
            onTap: () => onSelectAccount(null),
          ),
          for (final wallet in wallets)
            _buildCard(
              context: context,
              isSelected: selectedAccountId == wallet.id,
              iconWidget: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppIconCatalog.contrastSafeColor(
                    Color(wallet.color),
                    theme.brightness,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  AppIconCatalog.resolve(wallet.icon),
                  size: 16,
                  color: Colors.white,
                ),
              ),
              title: wallet.name,
              subtitle: hideBalance
                  ? '••••••'
                  : wallet.balanceMoney.format(locale: locale),
              onTap: () => onSelectAccount(
                selectedAccountId == wallet.id ? null : wallet.id,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required bool isSelected,
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ApplePressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 136,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                    .withValues(alpha: isDark ? 0.22 : 0.10)
                : (isDark
                    ? AppleTokens.bgDarkSecondary
                    : AppleTokens.bgLightSecondary),
            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark
                      ? const Color(0xFF2C2C2E)
                      : AppleTokens.borderLight),
              width: isSelected ? 1.5 : AppleTokens.hairline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  iconWidget,
                  if (isSelected)
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.checkmark,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : const Color(0xFF6C6C70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterChips extends StatelessWidget {
  const _CategoryFilterChips({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelectCategory,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip(
          context: context,
          isSelected: selectedCategoryId == null,
          iconWidget: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              CupertinoIcons.square_grid_2x2,
              size: 13,
              color: theme.colorScheme.primary,
            ),
          ),
          label: l10n.filterAllCategories,
          onTap: () => onSelectCategory(null),
        ),
        for (final cat in categories)
          _buildChip(
            context: context,
            isSelected: selectedCategoryId == cat.id,
            iconWidget: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppIconCatalog.contrastSafeColor(
                  Color(cat.color),
                  theme.brightness,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                AppIconCatalog.resolve(cat.icon),
                size: 13,
                color: Colors.white,
              ),
            ),
            label: DefaultCategoryLocalization.resolveName(
              l10n,
              categoryId: cat.id,
              fallbackName: cat.name,
            ),
            onTap: () => onSelectCategory(
              selectedCategoryId == cat.id ? null : cat.id,
            ),
          ),
      ],
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required bool isSelected,
    required Widget iconWidget,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ApplePressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
                  .withValues(alpha: isDark ? 0.22 : 0.10)
              : (isDark
                  ? AppleTokens.bgDarkSecondary
                  : AppleTokens.bgLightSecondary),
          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark
                    ? const Color(0xFF2C2C2E)
                    : AppleTokens.borderLight),
            width: isSelected ? 1.5 : AppleTokens.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.checkmark,
                size: 13,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

