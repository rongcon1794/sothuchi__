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
              constraints: const BoxConstraints(maxWidth: AppleTokens.maxContentWidth),
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
                  constraints: const BoxConstraints(maxWidth: AppleTokens.maxContentWidth),
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
                        constraints: const BoxConstraints(maxWidth: AppleTokens.maxContentWidth),
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
                      constraints: const BoxConstraints(maxWidth: AppleTokens.maxContentWidth),
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

