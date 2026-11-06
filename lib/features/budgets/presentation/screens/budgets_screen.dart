import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import 'package:so_thu_chi/core/widgets/skeleton_box.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/budgets/presentation/widgets/budget_alert_banner.dart';
import 'package:so_thu_chi/features/budgets/presentation/widgets/budget_form_sheet.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  bool _isFabExpanded = true;
  bool _isFabVisible = true;

  Future<void> _openBudgetForm(
    BuildContext context, {
    required DateTime selectedMonth,
    Budget? existing,
  }) async {
    await BudgetFormBottomSheet.show(
      context,
      monthStart: selectedMonth,
      existing: existing,
    );
  }

  Future<void> _deleteBudget(
    BuildContext context,
    String budgetId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await ref
        .read(budgetsActionControllerProvider.notifier)
        .deleteBudget(budgetId);
    if (!context.mounted) return;
    res.fold(
      onSuccess: (_) {},
      onFailure: (err) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.localizeError(err))),
        );
      },
    );
  }

  Widget _buildHeaderMonthSwitcher({
    required DateTime selectedMonth,
    required String locale,
    required AppLocalizations l10n,
    required ThemeData theme,
  }) {
    return AppleGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
      child: SizedBox(
        height: 30,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.previousMonth,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                HapticFeedback.selectionClick();
                ref.read(selectedBudgetMonthProvider.notifier).previousMonth();
              },
              icon: const Icon(Icons.chevron_left_rounded, size: 18),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                AppDateUtils.formatMonthYear(selectedMonth, locale: locale),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.nextMonth,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                HapticFeedback.selectionClick();
                ref.read(selectedBudgetMonthProvider.notifier).nextMonth();
              },
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final isLargeText = textScale >= 1.35;
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final hideBalance = settings?.hideBalance ?? false;

    final selectedMonth = ref.watch(selectedBudgetMonthProvider);
    final budgetsStream = ref.watch(budgetsStreamProvider);
    final progressList = ref.watch(selectedMonthBudgetProgressProvider);
    final categoriesMap = ref.watch(categoriesMapProvider);
    final triggered = progressList
        .where((p) => p.isWarningTriggered)
        .toList(growable: false);

    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isLandscape
            ? AppleTokens.appBarHeightLandscape
            : AppleTokens.appBarHeightPortrait,
        title: Text(l10n.budgetsTitle),
        actions: [
          if (isLandscape) ...[
            Center(
              child: _buildHeaderMonthSwitcher(
                selectedMonth: selectedMonth,
                locale: locale,
                l10n: l10n,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
      body: Column(
        children: [
          // Month Switcher Bar (only shown in portrait mode; merged into AppBar in landscape)
          if (!isLandscape)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: AppleGlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                    child: SizedBox(
                      height: 42,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            tooltip: l10n.previousMonth,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 36,
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(selectedBudgetMonthProvider.notifier)
                                  .previousMonth();
                            },
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              size: 22,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              AppDateUtils.formatMonthYear(
                                selectedMonth,
                                locale: locale,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.nextMonth,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 36,
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              ref
                                  .read(selectedBudgetMonthProvider.notifier)
                                  .nextMonth();
                            },
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

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
              child: budgetsStream.when(
                loading: () => const SkeletonListView(itemCount: 3),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(context.localizeError(err)),
                  ),
                ),
                data: (_) {
                  if (progressList.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.pie_chart_outline_rounded,
                      title: l10n.emptyBudgetsTitle,
                      subtitle: l10n.emptyBudgetsSubtitle,
                      actionLabel: l10n.addBudget,
                      onAction: () => _openBudgetForm(
                        context,
                        selectedMonth: selectedMonth,
                      ),
                    );
                  }

                  final overviewWidgets = <Widget>[
                    _BudgetOverviewCard(
                      progressList: progressList,
                      selectedMonth: selectedMonth,
                      locale: locale,
                      hideBalance: hideBalance,
                    ),
                    if (triggered.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      BudgetAlertBanner(
                        progressOverride: triggered,
                        navigateOnTap: false,
                      ),
                    ],
                  ];

                  final budgetCardsList = <Widget>[
                    for (final item in progressList) ...[
                      _BudgetProgressCard(
                        progress: item,
                        category: item.budget.categoryId != null
                            ? categoriesMap[item.budget.categoryId!]
                            : null,
                        locale: locale,
                        hideBalance: hideBalance,
                        onEdit: () => _openBudgetForm(
                          context,
                          selectedMonth: selectedMonth,
                          existing: item.budget,
                        ),
                        onDelete: () =>
                            _deleteBudget(context, item.budget.id),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ];

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1024),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          4,
                          16,
                          isWide
                              ? AppleTokens.scrollBottomPaddingLandscape + 50
                              : AppleTokens.scrollBottomPaddingWithFab,
                        ),
                        children: [
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 42,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: overviewWidgets,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 58,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: budgetCardsList,
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            ...overviewWidgets,
                            const SizedBox(height: 16),
                            ...budgetCardsList,
                          ],
                        ],
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
        heroTag: 'budgets_add_fab',
        isVisible: _isFabVisible,
        isExpanded: _isFabExpanded && !isLargeText,
        icon: const Icon(CupertinoIcons.plus),
        label: Text(l10n.addBudget),
        onPressed: () => _openBudgetForm(context, selectedMonth: selectedMonth),
        tooltip: l10n.addBudget,
      ),
    );
  }
}

class _BudgetOverviewCard extends StatelessWidget {
  const _BudgetOverviewCard({
    required this.progressList,
    required this.selectedMonth,
    required this.locale,
    required this.hideBalance,
  });

  final List<BudgetProgress> progressList;
  final DateTime selectedMonth;
  final String locale;
  final bool hideBalance;

  @override
  Widget build(BuildContext context) {
    if (progressList.isEmpty) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currency = progressList.first.budget.currency;

    final totalLimit = progressList.fold<int>(0, (acc, p) => acc + p.budget.amount);
    final totalSpent = progressList.fold<int>(0, (acc, p) => acc + p.spentMinorUnits);
    final totalRemaining = totalLimit > totalSpent ? totalLimit - totalSpent : 0;
    final usedPercent = totalLimit > 0 ? ((totalSpent * 100) ~/ totalLimit).clamp(0, 999) : 0;
    final clampedRatio = (usedPercent / 100.0).clamp(0.0, 1.0);

    final now = DateTime.now();
    final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final daysLeft = isCurrentMonth ? (daysInMonth - now.day + 1).clamp(1, daysInMonth) : daysInMonth;

    final safeDailyMinor = daysLeft > 0 ? totalRemaining ~/ daysLeft : 0;
    final safeDailyMoney = Money(minorUnits: safeDailyMinor, currencyCode: currency);
    final totalLimitMoney = Money(minorUnits: totalLimit, currencyCode: currency);
    final totalSpentMoney = Money(minorUnits: totalSpent, currencyCode: currency);

    final isExceeded = totalSpent > totalLimit;
    final barColor = isExceeded
        ? AppleTokens.systemRed
        : (usedPercent >= 80 ? AppleTokens.systemOrange : AppleTokens.jadeDark);

    return AppleGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.overallMonthlyBudget,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Text(
                  locale.startsWith('vi') ? '$usedPercent% tổng' : '$usedPercent% total',
                  style: TextStyle(
                    color: barColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.budgetSpentOf(
              totalSpentMoney.format(locale: locale, masked: hideBalance),
              totalLimitMoney.format(locale: locale, masked: hideBalance),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontFeatures: AppTheme.tabularFigures,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            child: LinearProgressIndicator(
              value: clampedRatio,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          if (isCurrentMonth) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.calendar, size: 14, color: AppleTokens.systemBlue),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.budgetRemainingDays(daysLeft),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.flame_fill, size: 14, color: AppleTokens.systemOrange),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.budgetDailyRecommended(safeDailyMoney.format(locale: locale, masked: hideBalance)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetProgressCard extends StatelessWidget {
  const _BudgetProgressCard({
    required this.progress,
    this.category,
    required this.locale,
    required this.hideBalance,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetProgress progress;
  final Category? category;
  final String locale;
  final bool hideBalance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final financeColors = context.financeColors;

    final isOverall = progress.budget.isOverall;
    final title = isOverall
        ? l10n.overallMonthlyBudget
        : DefaultCategoryLocalization.resolveName(
            l10n,
            categoryId: progress.budget.categoryId!,
            fallbackName: category?.name ?? l10n.categoryBudget,
          );

    final iconData = isOverall
        ? Icons.account_balance_wallet_rounded
        : AppIconCatalog.resolve(category?.icon ?? 'other');
    final rawBadgeColor = isOverall
        ? scheme.primary
        : Color(category?.color ?? 0xFF0D7C66);
    final badgeColor = AppIconCatalog.contrastSafeColor(
      rawBadgeColor,
      theme.brightness,
    );

    final barColor = progress.isExceeded
        ? financeColors.expense
        : (progress.isWarningTriggered
              ? financeColors.warning
              : financeColors.income);

    final pillBgColor = progress.isExceeded
        ? financeColors.expenseContainer
        : (progress.isWarningTriggered
              ? financeColors.warningContainer
              : financeColors.incomeContainer);
    final pillFgColor = progress.isExceeded
        ? financeColors.onExpenseContainer
        : (progress.isWarningTriggered
              ? financeColors.onWarningContainer
              : financeColors.onIncomeContainer);

    // Visual progress fraction strictly at UI rendering boundary.
    final clampedRatio = progress.usedPercent.clamp(0, 100) / 100.0;

    final spentText = progress.spentMoney.format(
      locale: locale,
      masked: hideBalance,
    );
    final limitText = progress.budget.limitMoney.format(
      locale: locale,
      masked: hideBalance,
    );
    final diffText = progress.remainingOrExceededMoney.format(
      locale: locale,
      masked: hideBalance,
    );

    return ApplePressable(
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      onTap: () => context.push(AppRoutes.budgetDetail(progress.budget.id)),
      child: AppleGlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        borderColor: progress.isExceeded
            ? AppleTokens.systemRed.withValues(alpha: 0.4)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: badgeColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      Text(
                        l10n.budgetSpentOf(spentText, limitText),
                        semanticsLabel: hideBalance
                            ? l10n.balanceHidden
                            : null,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: pillBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${progress.usedPercent}%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: pillFgColor,
                      fontWeight: FontWeight.w700,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.moreOptions,
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                    PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: clampedRatio,
                minHeight: 10,
                semanticsLabel: title,
                semanticsValue: '${progress.usedPercent}%',
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  progress.isExceeded
                      ? l10n.budgetExceededBy(diffText)
                      : l10n.budgetRemaining(diffText),
                  semanticsLabel: hideBalance ? l10n.balanceHidden : null,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: progress.isExceeded
                        ? financeColors.expense
                        : scheme.onSurfaceVariant,
                    fontWeight: progress.isExceeded
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
                Text(
                  l10n.alertThresholdLabel(progress.budget.alertThreshold),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (!progress.isExceeded && progress.remainingMinorUnits > 0) ...[
              const SizedBox(height: 6),
              Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final isCurrent = progress.budget.startDate.year == now.year &&
                      progress.budget.startDate.month == now.month;
                  final daysInMonth = DateTime(
                    progress.budget.startDate.year,
                    progress.budget.startDate.month + 1,
                    0,
                  ).day;
                  final daysLeft = isCurrent
                      ? (daysInMonth - now.day + 1).clamp(1, daysInMonth)
                      : daysInMonth;
                  final dailyMinor = daysLeft > 0
                      ? progress.remainingMinorUnits ~/ daysLeft
                      : 0;
                  final dailyText = Money(
                    minorUnits: dailyMinor,
                    currencyCode: progress.budget.currency,
                  ).format(locale: locale, masked: hideBalance);

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.flame_fill,
                        size: 11,
                        color: AppleTokens.systemOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.budgetDailyRecommended(dailyText),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurfaceVariant,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
