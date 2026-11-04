import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
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
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  bool _isFabVisible = true;

  Future<void> _openBudgetForm(
    BuildContext context, {
    required DateTime selectedMonth,
    Budget? existing,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _BudgetFormBottomSheet(
        monthStart: selectedMonth,
        existing: existing,
      ),
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetsTitle)),
      body: Column(
        children: [
          // Month Switcher Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: AppleGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    IconButton(
                      tooltip: l10n.previousMonth,
                      onPressed: () => ref
                          .read(selectedBudgetMonthProvider.notifier)
                          .previousMonth(),
                      icon: const Icon(Icons.chevron_left_rounded),
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
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.nextMonth,
                      onPressed: () => ref
                          .read(selectedBudgetMonthProvider.notifier)
                          .nextMonth(),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if (notification.direction == ScrollDirection.reverse && _isFabVisible) {
                  setState(() => _isFabVisible = false);
                } else if (notification.direction == ScrollDirection.forward && !_isFabVisible) {
                  setState(() => _isFabVisible = true);
                } else if (notification.metrics.pixels <= 30 && !_isFabVisible) {
                  setState(() => _isFabVisible = true);
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

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      AppleTokens.scrollBottomPaddingWithFab,
                    ),
                    children: [
                      if (triggered.isNotEmpty) ...[
                        BudgetAlertBanner(
                          progressOverride: triggered,
                          navigateOnTap: false,
                        ),
                        const SizedBox(height: 16),
                      ],
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
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: const AppleFloatingActionButtonLocation(),
      floatingActionButton: ScrollReactiveFab(
        visible: _isFabVisible,
        child: isLargeText
            ? FloatingActionButton(
                heroTag: 'budgets_add_fab',
                tooltip: l10n.addBudget,
                onPressed: () =>
                    _openBudgetForm(context, selectedMonth: selectedMonth),
                child: const Icon(Icons.add_rounded),
              )
            : FloatingActionButton.extended(
                heroTag: 'budgets_add_fab',
                onPressed: () =>
                    _openBudgetForm(context, selectedMonth: selectedMonth),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addBudget),
              ),
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

    return AppleGlassCard(
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
          ],
        ),
    );
  }
}

class _BudgetFormBottomSheet extends ConsumerStatefulWidget {
  const _BudgetFormBottomSheet({
    required this.monthStart,
    this.existing,
  });

  final DateTime monthStart;
  final Budget? existing;

  @override
  ConsumerState<_BudgetFormBottomSheet> createState() =>
      _BudgetFormBottomSheetState();
}

class _BudgetFormBottomSheetState
    extends ConsumerState<_BudgetFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedCategoryId; // null => Overall Monthly Budget
  int _threshold = 80;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      final locale =
          ref.read(settingsControllerProvider).value?.localeCode ?? 'vi';
      _selectedCategoryId = existing.categoryId;
      _threshold = existing.alertThreshold;
      _amountController.text = existing.limitMoney.toInputString(
        locale: locale,
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final settings = ref.read(settingsControllerProvider).value;
    final currency =
        widget.existing?.currency ??
        settings?.currencyCode ??
        AppCurrencies.defaultCode;
    final parsed = Money.tryParse(
      _amountController.text,
      currencyCode: currency,
    );
    if (parsed == null || parsed.minorUnits <= 0) return;

    final messenger = ScaffoldMessenger.of(context);
    final res = await ref
        .read(budgetsActionControllerProvider.notifier)
        .upsertBudget(
          existingId: widget.existing?.id,
          categoryId: _selectedCategoryId,
          amount: parsed.minorUnits,
          currency: currency,
          monthStart: widget.monthStart,
          alertThreshold: _threshold,
        );

    if (!mounted) return;
    res.fold(
      onSuccess: (_) => Navigator.of(context).pop(),
      onFailure: (err) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.localizeError(err))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final currencyCode =
        widget.existing?.currency ??
        settings?.currencyCode ??
        AppCurrencies.defaultCode;
    final currencyInfo = AppCurrencies.byCode(currencyCode);
    final expenseCategories = ref.watch(expenseCategoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing != null ? l10n.editBudget : l10n.addBudget,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Scope Selector (Overall or Specific Expense Category)
              DropdownButtonFormField<String?>(
                isExpanded: true,
                initialValue: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: l10n.budgetScope,
                  prefixIcon: const Icon(Icons.layers_outlined),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      l10n.overallMonthlyBudget,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  for (final cat in expenseCategories)
                    DropdownMenuItem<String?>(
                      value: cat.id,
                      child: Text(
                        DefaultCategoryLocalization.resolveName(
                          l10n,
                          categoryId: cat.id,
                          fallbackName: cat.name,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 16),

              // Monthly Limit Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: currencyInfo.decimalDigits > 0,
                ),
                inputFormatters: [
                  MoneyInputFormatter(
                    currencyCode: currencyCode,
                    locale: locale,
                  ),
                ],
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFeatures: AppTheme.tabularFigures,
                ),
                decoration: InputDecoration(
                  labelText: l10n.budgetLimit,
                  suffixText: currencyInfo.symbol,
                  hintText: '0',
                ),
                validator: (val) {
                  final m = Money.tryParse(
                    val ?? '',
                    currencyCode: currencyCode,
                  );
                  if (m == null || m.minorUnits <= 0) {
                    return l10n.amountRequiredError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Alert Threshold Slider (50% .. 100%)
              Text(
                l10n.alertThresholdLabel(_threshold),
                style: theme.textTheme.titleSmall,
              ),
              Slider(
                value: _threshold.toDouble(),
                min: 50,
                max: 100,
                divisions: 10,
                label: '$_threshold%',
                semanticFormatterCallback: (val) => '${val.round()}%',
                onChanged: (val) => setState(() => _threshold = val.round()),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
