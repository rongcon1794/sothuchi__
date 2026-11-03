import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/core/widgets/skeleton_box.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      showDragHandle: true,
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
    final grouped = ref.watch(groupedFilteredTransactionsProvider);
    final categoriesMap = ref.watch(categoriesMapProvider);
    final accountsMap = ref.watch(accountsMapProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionsTitle),
        actions: [
          Badge(
            isLabelVisible: filter.hasActiveFilters,
            child: IconButton(
              tooltip: l10n.filterTransactions,
              onPressed: _openFilterSheet,
              icon: const Icon(Icons.tune_rounded),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search Bar + Quick Type Filter Chips (Apple Cupertino style)
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  borderSide: const BorderSide(
                    color: AppleTokens.jadePrimary,
                    width: 1.5,
                  ),
                ),
                prefixIcon: const Icon(CupertinoIcons.search, size: 20),
                suffixIcon: filter.searchQuery.isNotEmpty
                    ? IconButton(
                        tooltip: l10n.clearFilters,
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(transactionFilterProvider.notifier)
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
                FilterChip(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  ),
                  label: Text(l10n.all),
                  selected: filter.type == null,
                  onSelected: (_) =>
                      ref.read(transactionFilterProvider.notifier).setType(null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  ),
                  label: Text(l10n.expense),
                  selected: filter.type == TransactionType.expense,
                  onSelected: (sel) => ref
                      .read(transactionFilterProvider.notifier)
                      .setType(sel ? TransactionType.expense : null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  ),
                  label: Text(l10n.income),
                  selected: filter.type == TransactionType.income,
                  onSelected: (sel) => ref
                      .read(transactionFilterProvider.notifier)
                      .setType(sel ? TransactionType.income : null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  ),
                  label: Text(l10n.transfer),
                  selected: filter.type == TransactionType.transfer,
                  onSelected: (sel) => ref
                      .read(transactionFilterProvider.notifier)
                      .setType(sel ? TransactionType.transfer : null),
                ),
                if (filter.hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppleTokens.radiusPill),
                    ),
                    avatar: const Icon(Icons.filter_alt_off_rounded, size: 16),
                    label: Text(l10n.clearFilters),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(transactionFilterProvider.notifier).clearAll();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
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

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: grouped.length,
                  itemBuilder: (context, groupIndex) {
                    final group = grouped[groupIndex];
                    final dayNet = Money(
                      minorUnits: group.netMinor,
                      currencyCode: currency,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
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
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Text(
                                  dayNet.format(
                                    locale: locale,
                                    showPlusSign: true,
                                    masked: hideBalance,
                                  ),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: group.netMinor >= 0
                                        ? context.financeColors.income
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontFeatures: AppTheme.tabularFigures,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                for (
                                  var i = 0;
                                  i < group.transactions.length;
                                  i++
                                ) ...[
                                  if (i > 0) const Divider(indent: 68),
                                  TransactionTile(
                                    transaction: group.transactions[i],
                                    category:
                                        categoriesMap[group
                                            .transactions[i]
                                            .categoryId],
                                    sourceAccount:
                                        accountsMap[group
                                            .transactions[i]
                                            .accountId],
                                    destinationAccount:
                                        group.transactions[i].toAccountId !=
                                            null
                                        ? accountsMap[group
                                              .transactions[i]
                                              .toAccountId!]
                                        : null,
                                    locale: locale,
                                    hideAmount: hideBalance,
                                    onTap: () => context.push(
                                      AppRoutes.transactionEdit(
                                        group.transactions[i].id,
                                      ),
                                    ),
                                    onSwipeEdit: () => context.push(
                                      AppRoutes.transactionEdit(
                                        group.transactions[i].id,
                                      ),
                                    ),
                                    onSwipeDelete: () =>
                                        _handleSoftDeleteWithUndo(
                                          group.transactions[i],
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'transactions_add_fab',
        tooltip: l10n.addTransaction,
        onPressed: () => context.push(AppRoutes.transactionNew),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _TransactionFilterBottomSheet extends ConsumerWidget {
  const _TransactionFilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final filter = ref.watch(transactionFilterProvider);
    final categories =
        ref.watch(categoriesStreamProvider).value ?? const [];
    final wallets = ref.watch(accountsStreamProvider).value ?? const [];
    final locale =
        ref.watch(settingsControllerProvider).value?.localeCode ?? 'vi';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.filterTransactions,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () {
                  ref.read(transactionFilterProvider.notifier).clearAll();
                  Navigator.of(context).pop();
                },
                child: Text(l10n.clearFilters),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Range
          Text(l10n.dateRange, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final now = DateTime.now();
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
              );
              if (picked != null) {
                ref
                    .read(transactionFilterProvider.notifier)
                    .setDateRange(picked.start, picked.end);
              }
            },
            icon: const Icon(Icons.date_range_rounded),
            label: Text(
              filter.startDate != null && filter.endDate != null
                  ? '${AppDateUtils.formatShortDate(filter.startDate!, locale: locale)} – ${AppDateUtils.formatShortDate(filter.endDate!, locale: locale)}'
                  : l10n.selectDateRange,
            ),
          ),
          const SizedBox(height: 18),

          // Wallet Filter
          Text(l10n.walletsTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.all),
                selected: filter.accountId == null,
                onSelected: (_) => ref
                    .read(transactionFilterProvider.notifier)
                    .setAccount(null),
              ),
              for (final wallet in wallets)
                ChoiceChip(
                  label: Text(wallet.name),
                  selected: filter.accountId == wallet.id,
                  onSelected: (sel) => ref
                      .read(transactionFilterProvider.notifier)
                      .setAccount(sel ? wallet.id : null),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Category Filter
          Text(l10n.categoriesTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.all),
                selected: filter.categoryId == null,
                onSelected: (_) => ref
                    .read(transactionFilterProvider.notifier)
                    .setCategory(null),
              ),
              for (final cat in categories)
                ChoiceChip(
                  label: Text(
                    DefaultCategoryLocalization.resolveName(
                      l10n,
                      categoryId: cat.id,
                      fallbackName: cat.name,
                    ),
                  ),
                  selected: filter.categoryId == cat.id,
                  onSelected: (sel) => ref
                      .read(transactionFilterProvider.notifier)
                      .setCategory(sel ? cat.id : null),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.confirm),
            ),
          ),
        ],
      ),
    );
  }
}

