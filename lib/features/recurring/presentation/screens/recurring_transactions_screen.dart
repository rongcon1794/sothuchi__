import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
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
    final locale = Localizations.localeOf(context).languageCode;
    final recurringAsync = ref.watch(recurringStreamProvider);
    final dueList = ref.watch(dueRecurringListProvider);
    final monthlyTotal = ref.watch(monthlyRecurringEstimateProvider);
    final categoriesMap = ref.watch(categoriesMapProvider);
    final accountsMap = ref.watch(accountsMapProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final hideBalance = settings?.hideBalance ?? false;

    return Scaffold(
      backgroundColor: isDark ? AppleTokens.bgDarkPrimary : AppleTokens.bgLightPrimary,
      appBar: AppBar(
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
      body: recurringAsync.when(
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, AppleTokens.scrollBottomPaddingWithFab),
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
                    child: AppleGlassCard(
                      borderColor: AppleTokens.systemOrange.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppleSquircleBadge(
                                icon: categoriesMap[item.categoryId] != null
                                    ? AppIconCatalog.resolve(categoriesMap[item.categoryId]!.icon)
                                    : CupertinoIcons.tag,
                                backgroundColor: categoriesMap[item.categoryId] != null
                                    ? Color(categoriesMap[item.categoryId]!.color)
                                    : AppleTokens.systemOrange,
                                size: 40,
                                iconSize: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${l10n.recurringNextDue(AppDateUtils.formatDayHeader(item.nextDueDate, locale: locale, todayLabel: l10n.today, yesterdayLabel: l10n.yesterday))} • ${accountsMap[item.accountId]?.name ?? ''}',
                                      style: const TextStyle(fontSize: 12, color: AppleTokens.systemGray),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                item.money.format(locale: locale, masked: hideBalance),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppleTokens.rubyExpense,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppleTokens.jadePrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppleTokens.radiusPill)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () => _handleExecute(item),
                              icon: const Icon(CupertinoIcons.checkmark_alt, size: 16),
                              label: Text(l10n.recurringMarkPaid, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
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
                  child: Center(child: Text(l10n.emptyTransactionsTitle, style: const TextStyle(color: AppleTokens.systemGray))),
                ),
              for (final item in activeItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ApplePressable(
                    onTap: () => RecurringFormSheet.show(context, existing: item),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    child: AppleGlassCard(
                      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                      child: Row(
                        children: [
                          AppleSquircleBadge(
                            icon: categoriesMap[item.categoryId] != null
                                ? AppIconCatalog.resolve(categoriesMap[item.categoryId]!.icon)
                                : CupertinoIcons.repeat,
                            backgroundColor: categoriesMap[item.categoryId] != null
                                ? Color(categoriesMap[item.categoryId]!.color)
                                : AppleTokens.systemBlue,
                            size: 42,
                            iconSize: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightSecondary,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _intervalLabel(item.interval, l10n),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppleTokens.systemBlue),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        l10n.recurringNextDue(AppDateUtils.formatDayHeader(item.nextDueDate, locale: locale, todayLabel: l10n.today, yesterdayLabel: l10n.yesterday)),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, color: AppleTokens.systemGray),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                item.money.format(locale: locale, masked: hideBalance),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: item.type == TransactionType.income
                                      ? AppleTokens.emeraldIncome
                                      : AppleTokens.rubyExpense,
                                ),
                              ),
                              PopupMenuButton<String>(
                                tooltip: l10n.moreOptions,
                                padding: EdgeInsets.zero,
                                icon: const Icon(CupertinoIcons.ellipsis, size: 16, color: AppleTokens.systemGray),
                                onSelected: (action) {
                                  if (action == 'edit') {
                                    RecurringFormSheet.show(context, existing: item);
                                  } else if (action == 'pause') {
                                    ref.read(recurringActionControllerProvider.notifier).togglePause(item.id, true);
                                  } else if (action == 'delete') {
                                    _confirmDelete(item);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                                  PopupMenuItem(value: 'pause', child: Text(l10n.recurringPause)),
                                  PopupMenuItem(value: 'delete', child: Text(l10n.recurringDelete, style: const TextStyle(color: AppleTokens.systemRed))),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppleGlassCard(
                      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                      child: Row(
                        children: [
                          const Opacity(
                            opacity: 0.5,
                            child: AppleSquircleBadge(
                              icon: CupertinoIcons.pause_fill,
                              backgroundColor: AppleTokens.systemGray,
                              size: 40,
                              iconSize: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppleTokens.systemGray),
                                ),
                                Text(l10n.recurringPause, style: const TextStyle(fontSize: 12, color: AppleTokens.systemGray)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => ref.read(recurringActionControllerProvider.notifier).togglePause(item.id, false),
                            child: Text(l10n.recurringResume),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
            ),
          );
        },
      ),
    );
  }
}
