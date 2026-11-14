import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:so_thu_chi/features/recurring/presentation/controllers/recurring_controller.dart';
import 'package:so_thu_chi/features/recurring/presentation/widgets/recurring_card_tile.dart';
import 'package:so_thu_chi/features/recurring/presentation/widgets/recurring_form_sheet.dart';
import 'package:so_thu_chi/features/recurring/presentation/widgets/recurring_hero_overview_card.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

class RecurringTransactionsScreen extends ConsumerStatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  ConsumerState<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends ConsumerState<RecurringTransactionsScreen> {
  bool _isFabExpanded = true;
  bool _isFabVisible = true;
  int _selectedTab = 0; // 0: Tất cả, 1: Hóa đơn & Chi trả, 2: Thu nhập định kỳ

  Future<void> _handleExecute(RecurringTransaction item) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final isIncome = item.type == TransactionType.income;
    unawaited(HapticFeedback.mediumImpact());
    final res = await ref
        .read(recurringActionControllerProvider.notifier)
        .executeRecurring(item.id);

    if (!mounted) return;
    res.fold(
      onSuccess: (_) {
        unawaited(HapticFeedback.lightImpact());
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isIncome
                  ? l10n.recurringIncomeRecordedSuccess(item.title)
                  : l10n.recurringRecordedSuccess(item.title),
            ),
            backgroundColor: isIncome ? AppleTokens.emeraldIncome : AppleTokens.jadeDark,
          ),
        );
      },
      onFailure: (err) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.localizeError(err))),
        );
      },
    );
  }

  Future<void> _confirmDelete(RecurringTransaction item) async {
    final l10n = context.l10n;
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.recurringDeleteConfirmTitle),
        message: Text(l10n.recurringDeleteConfirmBody(item.title)),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.recurringDelete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(recurringActionControllerProvider.notifier).deleteRecurring(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;
    final scrollBottomPadding = isWide
        ? AppleTokens.scrollBottomPaddingLandscape + 42
        : AppleTokens.scrollBottomPaddingWithFab;

    final locale = Localizations.localeOf(context).languageCode;
    final recurringAsync = ref.watch(recurringStreamProvider);
    final dueExpenses = ref.watch(dueRecurringExpensesProvider);
    final dueIncomes = ref.watch(dueRecurringIncomesProvider);
    final monthlyExpenseTotal = ref.watch(monthlyRecurringExpenseEstimateProvider);
    final monthlyIncomeTotal = ref.watch(monthlyRecurringIncomeEstimateProvider);
    final monthlyNetCashflow = ref.watch(monthlyRecurringNetCashflowProvider);
    final categoriesMap = ref.watch(categoriesMapProvider);
    final accountsMap = ref.watch(accountsMapProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final hideBalance = settings?.hideBalance ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppleAppBar(
        titleText: l10n.recurringTitle,
        isLandscape: isLandscape,
        showBackButton: true,
      ),
      floatingActionButtonLocation: const AppleFloatingActionButtonLocation(),
      floatingActionButton: AppleAdaptiveExpandableFab(
        heroTag: 'recurring_add_fab',
        isVisible: _isFabVisible,
        isExpanded: _isFabExpanded,
        icon: const Icon(CupertinoIcons.plus),
        label: Text(l10n.recurringNew),
        backgroundColor: AppleTokens.jadeDark,
        onPressed: () {
          HapticFeedback.lightImpact();
          RecurringFormSheet.show(context);
        },
        tooltip: l10n.recurringNew,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: recurringAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (err, _) => Center(child: Text(context.localizeError(err))),
          data: (allItems) {
            if (allItems.isEmpty) {
              return EmptyStateView(
                icon: CupertinoIcons.repeat,
                title: l10n.recurringEmpty,
                subtitle: l10n.recurringEmptySubtitle,
                actionLabel: l10n.recurringNew,
                onAction: () => RecurringFormSheet.show(context),
              );
            }

            final activeItems = allItems.where((i) => !i.isPaused).toList();
            final pausedItems = allItems.where((i) => i.isPaused).toList();

            final filteredActive = _selectedTab == 0
                ? activeItems
                : (_selectedTab == 1
                    ? activeItems.where((i) => i.type == TransactionType.expense).toList()
                    : activeItems.where((i) => i.type == TransactionType.income).toList());

            final filteredPaused = _selectedTab == 0
                ? pausedItems
                : (_selectedTab == 1
                    ? pausedItems.where((i) => i.type == TransactionType.expense).toList()
                    : pausedItems.where((i) => i.type == TransactionType.income).toList());

            final showDueExpenses =
                (_selectedTab == 0 || _selectedTab == 1) && dueExpenses.isNotEmpty;
            final showDueIncomes =
                (_selectedTab == 0 || _selectedTab == 2) && dueIncomes.isNotEmpty;

            final totalExpensesCount =
                allItems.where((i) => i.type == TransactionType.expense).length;
            final totalIncomesCount =
                allItems.where((i) => i.type == TransactionType.income).length;

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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppleTokens.maxContentWidth),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, scrollBottomPadding),
                    children: [
                      // 1. Hero Monthly Forecast Cash Flow Card
                      RecurringHeroOverviewCard(
                        monthlyNetCashflow: monthlyNetCashflow,
                        monthlyIncomeTotal: monthlyIncomeTotal,
                        monthlyExpenseTotal: monthlyExpenseTotal,
                        locale: locale,
                        hideBalance: hideBalance,
                        isDark: isDark,
                        activeCount: activeItems.length,
                      ),
                      const SizedBox(height: 16),

                      // 2. High-Precision Tab Filter (Tất cả / Hóa đơn / Thu nhập)
                      AppleGlassCard(
                        padding: const EdgeInsets.all(4),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        child: Row(
                          children: [
                            _buildFilterTab(
                              index: 0,
                              label: l10n.recurringTabAll,
                              count: allItems.length,
                              isSelected: _selectedTab == 0,
                              isDark: isDark,
                            ),
                            _buildFilterTab(
                              index: 1,
                              label: l10n.recurringTabBills,
                              count: totalExpensesCount,
                              isSelected: _selectedTab == 1,
                              isDark: isDark,
                              accentColor: AppleTokens.rubyExpense,
                            ),
                            _buildFilterTab(
                              index: 2,
                              label: l10n.recurringTabIncome,
                              count: totalIncomesCount,
                              isSelected: _selectedTab == 2,
                              isDark: isDark,
                              accentColor: AppleTokens.emeraldIncome,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 3. Due Bills Section (Khoản chi / Hóa đơn đến hạn thanh toán)
                      if (showDueExpenses) ...[
                        Row(
                          children: [
                            const Icon(CupertinoIcons.exclamationmark_triangle_fill,
                                color: AppleTokens.systemOrange, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${l10n.recurringDueBillsSection} (${dueExpenses.length})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppleTokens.systemOrange,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (final item in dueExpenses)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RepaintBoundary(
                              child: RecurringCardTile(
                                item: item,
                                categoriesMap: categoriesMap,
                                accountsMap: accountsMap,
                                locale: locale,
                                hideBalance: hideBalance,
                                onExecute: () => _handleExecute(item),
                                onEdit: () => RecurringFormSheet.show(context, existing: item),
                                onTogglePause: (paused) => ref
                                    .read(recurringActionControllerProvider.notifier)
                                    .togglePause(item.id, paused),
                                onDelete: () => _confirmDelete(item),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],

                      // 4. Due Incomes Section (Kỳ thu nhập đến ngày nhận tiền)
                      if (showDueIncomes) ...[
                        Row(
                          children: [
                            const Icon(CupertinoIcons.arrow_down_circle_fill,
                                color: AppleTokens.emeraldIncome, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${l10n.recurringDueIncomes} (${dueIncomes.length})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppleTokens.emeraldIncome,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (final item in dueIncomes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RepaintBoundary(
                              child: RecurringCardTile(
                                item: item,
                                categoriesMap: categoriesMap,
                                accountsMap: accountsMap,
                                locale: locale,
                                hideBalance: hideBalance,
                                onExecute: () => _handleExecute(item),
                                onEdit: () => RecurringFormSheet.show(context, existing: item),
                                onTogglePause: (paused) => ref
                                    .read(recurringActionControllerProvider.notifier)
                                    .togglePause(item.id, paused),
                                onDelete: () => _confirmDelete(item),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],

                      // 5. Active recurring list
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: Text(
                          l10n.recurringActiveSection,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppleTokens.systemGray,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (filteredActive.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              l10n.emptyTransactionsTitle,
                              style: const TextStyle(color: AppleTokens.systemGray),
                            ),
                          ),
                        ),
                      for (final item in filteredActive)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: RepaintBoundary(
                            child: RecurringCardTile(
                              item: item,
                              categoriesMap: categoriesMap,
                              accountsMap: accountsMap,
                              locale: locale,
                              hideBalance: hideBalance,
                              onEdit: () => RecurringFormSheet.show(context, existing: item),
                              onTogglePause: (paused) => ref
                                  .read(recurringActionControllerProvider.notifier)
                                  .togglePause(item.id, paused),
                              onDelete: () => _confirmDelete(item),
                            ),
                          ),
                        ),

                      // 6. Paused Section
                      if (filteredPaused.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          child: Text(
                            l10n.recurringPausedSection,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppleTokens.systemGray,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        for (final item in filteredPaused)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RepaintBoundary(
                              child: RecurringCardTile(
                                item: item,
                                categoriesMap: categoriesMap,
                                accountsMap: accountsMap,
                                locale: locale,
                                hideBalance: hideBalance,
                                isPaused: true,
                                onEdit: () => RecurringFormSheet.show(context, existing: item),
                                onTogglePause: (paused) => ref
                                    .read(recurringActionControllerProvider.notifier)
                                    .togglePause(item.id, paused),
                                onDelete: () => _confirmDelete(item),
                              ),
                            ),
                          ),
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

  Widget _buildFilterTab({
    required int index,
    required String label,
    required int count,
    required bool isSelected,
    required bool isDark,
    Color? accentColor,
  }) {
    final activeColor = accentColor ?? AppleTokens.jadeDark;
    return Expanded(
      child: ApplePressable(
        onTap: () {
          if (_selectedTab != index) {
            unawaited(HapticFeedback.selectionClick());
            setState(() => _selectedTab = index);
          }
        },
        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF2C2C2E) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (accentColor ?? (isDark ? Colors.white : Colors.black87))
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.16)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? activeColor
                        : (isDark ? Colors.white54 : Colors.black45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
