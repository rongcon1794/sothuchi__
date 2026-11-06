import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/contracts/transaction_draft_contract.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/features/budgets/domain/entities/budget.dart';
import 'package:so_thu_chi/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:so_thu_chi/features/budgets/presentation/widgets/budget_form_sheet.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_tile.dart';

class BudgetDetailScreen extends ConsumerWidget {
  const BudgetDetailScreen({
    super.key,
    required this.budgetId,
  });

  final String budgetId;

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Budget budget) async {
    final l10n = context.l10n;
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.delete),
        message: const Text('Bạn có chắc chắn muốn xóa ngân sách này? Các giao dịch chi tiêu vẫn được giữ nguyên.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      unawaited(HapticFeedback.mediumImpact());
      final res = await ref.read(budgetsActionControllerProvider.notifier).deleteBudget(budget.id);
      if (!context.mounted) return;
      res.fold(
        onSuccess: (_) => context.pop(),
        onFailure: (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.localizeError(err))),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final financeColors = context.financeColors;
    final isDark = theme.brightness == Brightness.dark;
    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;

    final budgetsAsync = ref.watch(budgetsStreamProvider);
    final allTxs = ref.watch(transactionsStreamProvider).value ?? const <TransactionEntity>[];
    final categoriesMap = ref.watch(categoriesMapProvider);
    final accountsMap = ref.watch(accountsMapProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final hideBalance = settings?.hideBalance ?? false;

    return budgetsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CupertinoActivityIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.localizeError(err))),
      ),
      data: (budgets) {
        final budget = budgets.where((b) => b.id == budgetId).firstOrNull;
        if (budget == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                'Không tìm thấy ngân sách',
                style: theme.textTheme.titleMedium,
              ),
            ),
          );
        }

        final category = budget.categoryId != null ? categoriesMap[budget.categoryId!] : null;
        final isOverall = budget.isOverall;
        final title = isOverall
            ? l10n.overallMonthlyBudget
            : DefaultCategoryLocalization.resolveName(
                l10n,
                categoryId: budget.categoryId!,
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

        // Filter transactions contributing to this budget
        final budgetTxs = allTxs.where((tx) {
          if (tx.type != TransactionType.expense) return false;
          if (tx.currency != budget.currency) return false;
          if (!AppDateUtils.isSameMonth(tx.date, budget.startDate)) return false;
          if (isOverall) return true;
          return tx.categoryId == budget.categoryId;
        }).toList(growable: false);

        var spentMinor = 0;
        for (final tx in budgetTxs) {
          spentMinor += tx.amount;
        }

        final progress = BudgetProgress(
          budget: budget,
          spentMinorUnits: spentMinor,
        );

        final clampedRatio = progress.usedPercent.clamp(0, 100) / 100.0;
        final spentText = progress.spentMoney.format(locale: locale, masked: hideBalance);
        final limitText = progress.budget.limitMoney.format(locale: locale, masked: hideBalance);
        final diffText = progress.remainingOrExceededMoney.format(locale: locale, masked: hideBalance);

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

        // Daily recommendation
        final now = DateTime.now();
        final isCurrentMonth = budget.startDate.year == now.year && budget.startDate.month == now.month;
        final daysInMonth = DateTime(budget.startDate.year, budget.startDate.month + 1, 0).day;
        final daysLeft = isCurrentMonth ? (daysInMonth - now.day + 1).clamp(1, daysInMonth) : daysInMonth;
        final dailyMinor = daysLeft > 0 ? progress.remainingMinorUnits ~/ daysLeft : 0;
        final dailyMoney = Money(minorUnits: dailyMinor, currencyCode: budget.currency);

        return Scaffold(
          backgroundColor: isDark ? AppleTokens.bgDarkPrimary : AppleTokens.bgLightPrimary,
          appBar: AppBar(
            toolbarHeight: isLandscape
                ? AppleTokens.appBarHeightLandscape
                : AppleTokens.appBarHeightPortrait,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.chevron_left, size: 24),
              onPressed: () => context.pop(),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                tooltip: l10n.edit,
                icon: const Icon(CupertinoIcons.pencil, size: 20),
                onPressed: () => BudgetFormBottomSheet.show(
                  context,
                  monthStart: budget.startDate,
                  existing: budget,
                ),
              ),
              IconButton(
                tooltip: l10n.delete,
                icon: const Icon(CupertinoIcons.trash, color: AppleTokens.systemRed, size: 20),
                onPressed: () => _handleDelete(context, ref, budget),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  isWide ? AppleTokens.scrollBottomPaddingLandscape + 20 : 32,
                ),
                children: [
                  // Hero Card: Budget Status & Gauge
                  AppleGlassCard(
                    borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
                    padding: const EdgeInsets.all(20),
                    borderColor: progress.isExceeded
                        ? AppleTokens.systemRed.withValues(alpha: 0.4)
                        : badgeColor.withValues(alpha: 0.35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                                border: Border.all(
                                  color: badgeColor.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(iconData, color: badgeColor, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    AppDateUtils.formatMonthYear(budget.startDate, locale: locale),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: pillBgColor,
                                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                              ),
                              child: Text(
                                '${progress.usedPercent}%',
                                style: TextStyle(
                                  color: pillFgColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  fontFeatures: AppTheme.tabularFigures,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: clampedRatio,
                            minHeight: 12,
                            backgroundColor: scheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.budgetSpentOf(spentText, limitText),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                            Text(
                              progress.isExceeded
                                  ? l10n.budgetExceededBy(diffText)
                                  : l10n.budgetRemaining(diffText),
                              style: TextStyle(
                                color: progress.isExceeded ? financeColors.expense : scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                          ],
                        ),
                        if (isCurrentMonth && !progress.isExceeded) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                            ),
                            child: Row(
                              children: [
                                const Icon(CupertinoIcons.flame_fill, size: 16, color: AppleTokens.systemOrange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    l10n.budgetDailyRecommended(dailyMoney.format(locale: locale, masked: hideBalance)),
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  l10n.budgetRemainingDays(daysLeft),
                                  style: const TextStyle(fontSize: 12, color: AppleTokens.systemGray),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                            ),
                          ),
                          icon: const Icon(CupertinoIcons.plus_circle, size: 18),
                          label: Text(
                            l10n.quickAddTransaction,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          onPressed: () {
                            context.push(
                              AppRoutes.transactionNew,
                              extra: TransactionDraft(
                                categoryId: budget.categoryId,
                                kind: TransactionDraftKind.expense,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                          ),
                        ),
                        icon: const Icon(CupertinoIcons.pencil, size: 18),
                        label: Text(
                          l10n.edit,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        onPressed: () => BudgetFormBottomSheet.show(
                          context,
                          monthStart: budget.startDate,
                          existing: budget,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Transactions in this budget
                  Text(
                    '${l10n.transactionsTitle} (${budgetTxs.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (budgetTxs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: EmptyStateView(
                        icon: CupertinoIcons.tray,
                        title: 'Chưa có khoản chi nào',
                        subtitle: 'Các giao dịch chi tiêu trong tháng áp dụng vào ngân sách này sẽ hiển thị ở đây.',
                        actionLabel: l10n.quickAddTransaction,
                        onAction: () {
                          context.push(
                            AppRoutes.transactionNew,
                            extra: TransactionDraft(
                              categoryId: budget.categoryId,
                              kind: TransactionDraftKind.expense,
                            ),
                          );
                        },
                      ),
                    )
                  else
                    AppleGlassCard(
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                      child: Column(
                        children: [
                          for (var i = 0; i < budgetTxs.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: AppleTokens.hairline,
                                indent: 68,
                                color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                              ),
                            TransactionTile(
                              transaction: budgetTxs[i],
                              category: categoriesMap[budgetTxs[i].categoryId],
                              sourceAccount: accountsMap[budgetTxs[i].accountId],
                              destinationAccount: budgetTxs[i].toAccountId != null
                                  ? accountsMap[budgetTxs[i].toAccountId!]
                                  : null,
                              locale: locale,
                              hideAmount: hideBalance,
                              onTap: () => context.push(
                                AppRoutes.transactionDetail(budgetTxs[i].id),
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
        );
      },
    );
  }
}

