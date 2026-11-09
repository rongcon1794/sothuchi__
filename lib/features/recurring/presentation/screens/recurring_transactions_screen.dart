import 'dart:async';
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
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:so_thu_chi/features/recurring/presentation/controllers/recurring_controller.dart';
import 'package:so_thu_chi/features/recurring/presentation/widgets/recurring_form_sheet.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

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

  String _intervalLabel(RecurringInterval interval, AppLocalizations l10n) {
    switch (interval) {
      case RecurringInterval.daily:
        return l10n.recurringIntervalDaily;
      case RecurringInterval.weekly:
        return l10n.recurringIntervalWeekly;
      case RecurringInterval.biweekly:
        return l10n.recurringIntervalBiweekly;
      case RecurringInterval.monthly:
        return l10n.recurringIntervalMonthly;
      case RecurringInterval.yearly:
        return l10n.recurringIntervalYearly;
    }
  }

  Future<void> _handleExecute(RecurringTransaction item) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
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
            content: Text(l10n.recurringRecordedSuccess(item.title)),
            backgroundColor: AppleTokens.jadeDark,
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
    final appBarHeight = isLandscape
        ? AppleTokens.appBarHeightLandscape
        : AppleTokens.appBarHeightPortrait;
    final scrollBottomPadding = isWide
        ? AppleTokens.scrollBottomPaddingLandscape + 42
        : AppleTokens.scrollBottomPaddingWithFab;

    final locale = Localizations.localeOf(context).languageCode;
    final recurringAsync = ref.watch(recurringStreamProvider);
    final dueList = ref.watch(dueRecurringListProvider);
    final monthlyTotal = ref.watch(monthlyRecurringEstimateProvider);
    final categoriesMap = ref.watch(categoriesMapProvider);
    final accountsMap = ref.watch(accountsMapProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final hideBalance = settings?.hideBalance ?? false;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        title: Text(l10n.recurringTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, size: 24),
          onPressed: () => context.pop(),
        ),
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
              // Hero Monthly Estimate Card
              AppleGlassCard(
                borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [Color(0xFF0F2B22), Color(0xFF061A14)]
                      : const [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
                ),
                borderColor: AppleTokens.jadePrimary.withValues(alpha: 0.25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.recurringEstimatedMonthly,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isDark ? AppleTokens.jadePrimary : AppleTokens.jadeDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppleTokens.jadePrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l10n.recurringActiveCount(activeItems.length),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppleTokens.jadePrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AppleAnimatedMoneyText(
                      money: Money(minorUnits: monthlyTotal),
                      masked: hideBalance,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0D5239),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Due / Overdue Section
              if (dueList.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppleTokens.systemOrange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.recurringDueBills} (${dueList.length})',
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
                for (final item in dueList)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRecurringCard(
                      context: context,
                      ref: ref,
                      item: item,
                      categoriesMap: categoriesMap,
                      accountsMap: accountsMap,
                      isDark: isDark,
                      theme: theme,
                      l10n: l10n,
                      locale: locale,
                      hideBalance: hideBalance,
                      onExecute: () => _handleExecute(item),
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // Active recurring list
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
              if (activeItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      l10n.emptyTransactionsTitle,
                      style: const TextStyle(color: AppleTokens.systemGray),
                    ),
                  ),
                ),
              for (final item in activeItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRecurringCard(
                    context: context,
                    ref: ref,
                    item: item,
                    categoriesMap: categoriesMap,
                    accountsMap: accountsMap,
                    isDark: isDark,
                    theme: theme,
                    l10n: l10n,
                    locale: locale,
                    hideBalance: hideBalance,
                  ),
                ),

              // Paused Section
              if (pausedItems.isNotEmpty) ...[
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
                for (final item in pausedItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRecurringCard(
                      context: context,
                      ref: ref,
                      item: item,
                      categoriesMap: categoriesMap,
                      accountsMap: accountsMap,
                      isDark: isDark,
                      theme: theme,
                      l10n: l10n,
                      locale: locale,
                      hideBalance: hideBalance,
                      isPaused: true,
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

  Widget _buildRecurringCard({
    required BuildContext context,
    required WidgetRef ref,
    required RecurringTransaction item,
    required Map<String, Category> categoriesMap,
    required Map<String, Account> accountsMap,
    required bool isDark,
    required ThemeData theme,
    required AppLocalizations l10n,
    required String locale,
    required bool hideBalance,
    bool isPaused = false,
    VoidCallback? onExecute,
  }) {
    final isExpense = item.type == TransactionType.expense;
    final accentColor = isExpense ? AppleTokens.rubyExpense : AppleTokens.jadePrimary;
    final category = categoriesMap[item.categoryId];
    final wallet = accountsMap[item.accountId];
    final categoryColor = category != null ? Color(category.color) : accentColor;

    return ApplePressable(
      onTap: () => context.push(AppRoutes.recurringDetail(item.id)),
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isPaused ? 0.75 : 1.0,
        child: AppleGlassCard(
          borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
          borderColor: item.isDue && !isPaused
              ? AppleTokens.systemOrange.withValues(alpha: isDark ? 0.6 : 0.45)
              : accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Row: Category Squircle Badge + Title/Amount + Popup Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Icon Badge with Gradient & Glow
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          (isPaused ? AppleTokens.systemGray : categoryColor)
                              .withValues(alpha: isDark ? 0.95 : 0.9),
                          (isPaused ? AppleTokens.systemGray : categoryColor)
                              .withValues(alpha: isDark ? 0.75 : 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                      boxShadow: [
                        BoxShadow(
                          color: (isPaused ? AppleTokens.systemGray : categoryColor)
                              .withValues(alpha: isDark ? 0.35 : 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      category != null
                          ? AppIconCatalog.resolve(category.icon)
                          : (isExpense
                              ? CupertinoIcons.arrow_up_right
                              : CupertinoIcons.arrow_down_left),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title + Amount + Optional Note
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${isExpense ? '-' : '+'}${item.money.format(locale: locale, masked: hideBalance)}',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isPaused ? AppleTokens.systemGray : accentColor,
                            fontFeatures: AppTheme.tabularFigures,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (item.note.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '“${item.note.trim()}”',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Actions: ApplePopupMenuButton
                  ApplePopupMenuButton<String>(
                    tooltip: l10n.moreOptions,
                    onSelected: (action) {
                      if (action == 'edit') {
                        RecurringFormSheet.show(context, existing: item);
                      } else if (action == 'pause') {
                        ref
                            .read(recurringActionControllerProvider.notifier)
                            .togglePause(item.id, !item.isPaused);
                      } else if (action == 'delete') {
                        _confirmDelete(item);
                      }
                    },
                    itemBuilder: (ctx) => [
                      ApplePopupMenuItem(
                        value: 'edit',
                        icon: CupertinoIcons.pencil,
                        title: l10n.edit,
                      ),
                      ApplePopupMenuItem(
                        value: 'pause',
                        icon: item.isPaused
                            ? CupertinoIcons.play_fill
                            : CupertinoIcons.pause_fill,
                        title: item.isPaused
                            ? l10n.recurringResume
                            : l10n.recurringPause,
                      ),
                      ApplePopupMenuItem(
                        value: 'delete',
                        icon: CupertinoIcons.trash,
                        title: l10n.recurringDelete,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Badges Wrap: Frequency + Next Due Date + Wallet + Auto Mode
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  // 1. Frequency badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.repeat,
                          size: 11,
                          color: accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _intervalLabel(item.interval, l10n),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Next Due badge (with orange alert if due today)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.isDue && !isPaused
                          ? AppleTokens.systemOrange.withValues(alpha: 0.16)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.04)),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isDue && !isPaused
                              ? CupertinoIcons.exclamationmark_circle_fill
                              : CupertinoIcons.calendar,
                          size: 11,
                          color: item.isDue && !isPaused
                              ? AppleTokens.systemOrange
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.isDue && !isPaused
                              ? 'Đến hạn hôm nay'
                              : l10n.recurringNextDue(AppDateUtils.formatDayHeader(
                                  item.nextDueDate,
                                  locale: locale,
                                  todayLabel: l10n.today,
                                  yesterdayLabel: l10n.yesterday,
                                )),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: item.isDue && !isPaused
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: item.isDue && !isPaused
                                ? AppleTokens.systemOrange
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Wallet badge
                  if (wallet != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Color(wallet.color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.creditcard,
                            size: 11,
                            color: Color(wallet.color),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            wallet.name,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(wallet.color),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 4. Auto Mode badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: (item.autoExecute
                              ? AppleTokens.systemGreen
                              : AppleTokens.systemGray)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.autoExecute
                              ? CupertinoIcons.bolt_fill
                              : CupertinoIcons.hand_draw,
                          size: 11,
                          color: item.autoExecute
                              ? AppleTokens.systemGreen
                              : AppleTokens.systemGray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.autoExecute ? 'Tự động' : 'Thủ công',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: item.autoExecute
                                ? AppleTokens.systemGreen
                                : AppleTokens.systemGray,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 5. If Paused badge
                  if (isPaused)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppleTokens.systemGray.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.pause_fill,
                            size: 11,
                            color: AppleTokens.systemGray,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.recurringPause,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppleTokens.systemGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Bottom Action Button: If Due -> Mark Paid
              if (onExecute != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AppleButton.primary(
                    color: AppleTokens.jadePrimary,
                    label: l10n.recurringMarkPaid,
                    icon: const Icon(CupertinoIcons.checkmark_alt, size: 16),
                    onPressed: onExecute,
                  ),
                ),
              ],

              // Quick Action Button: If Paused -> Quick Resume
              if (isPaused) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ApplePressable(
                    onTap: () => ref
                        .read(recurringActionControllerProvider.notifier)
                        .togglePause(item.id, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppleTokens.jadePrimary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        border: Border.all(
                          color: AppleTokens.jadePrimary.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.play_fill,
                            size: 11,
                            color: AppleTokens.jadePrimary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            l10n.recurringResume,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppleTokens.jadePrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
