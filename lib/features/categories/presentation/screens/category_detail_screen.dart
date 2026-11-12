import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
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
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/categories/presentation/widgets/category_form_sheet.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_tile.dart';

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
  });

  final String categoryId;

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Category category) async {
    final l10n = context.l10n;
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('${l10n.delete} ${category.name}'),
        message: Text(
          l10n.localeName.startsWith('vi')
              ? 'Bạn có chắc chắn muốn xóa danh mục này? Các giao dịch trước đó vẫn được lưu giữ.'
              : 'Are you sure you want to delete this category? Existing transactions will be kept.',
        ),
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
      final res = await ref.read(categoriesActionControllerProvider.notifier).deleteCategory(category.id);
      if (!context.mounted) return;
      res.fold(
        onSuccess: (_) {
          context.pop();
        },
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
    final isDark = theme.brightness == Brightness.dark;
    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;

    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final allTxs = ref.watch(transactionsStreamProvider).value ?? const <TransactionEntity>[];
    final categoriesMap = ref.watch(categoriesMapProvider);
    final accountsMap = ref.watch(accountsMapProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final currency = settings?.currencyCode ?? AppCurrencies.defaultCode;
    final hideBalance = settings?.hideBalance ?? false;

    return categoriesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CupertinoActivityIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.localizeError(err))),
      ),
      data: (categories) {
        final category = categories.where((c) => c.id == categoryId).firstOrNull;
        if (category == null) {
          return Scaffold(
            appBar: AppBar(),
            body: SafeArea(
              top: false,
              bottom: false,
              child: Center(
                child: Text(
                  locale.startsWith('vi')
                      ? 'Không tìm thấy danh mục'
                      : 'Category not found',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          );
        }

        final displayName = category.isDefault
            ? DefaultCategoryLocalization.resolveName(
                l10n,
                categoryId: category.id,
                fallbackName: category.name,
              )
            : category.name;

        final badgeColor = AppIconCatalog.contrastSafeColor(
          Color(category.color),
          theme.brightness,
        );

        // Filter transactions for this category
        final categoryTxs = allTxs
            .where((t) => t.categoryId == category.id)
            .toList(growable: false);

        // Statistics
        final now = DateTime.now();
        var monthTotalMinor = 0;
        var allTimeTotalMinor = 0;
        for (final tx in categoryTxs) {
          if (tx.currency != currency) continue;
          allTimeTotalMinor += tx.amount;
          if (AppDateUtils.isSameMonth(tx.date, now)) {
            monthTotalMinor += tx.amount;
          }
        }

        final monthMoney = Money(minorUnits: monthTotalMinor, currencyCode: currency);
        final allTimeMoney = Money(minorUnits: allTimeTotalMinor, currencyCode: currency);

        final isIncome = category.type == CategoryType.income;
        final typeLabel = isIncome ? l10n.income : l10n.expense;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
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
              displayName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                tooltip: l10n.edit,
                icon: const Icon(CupertinoIcons.pencil, size: 20),
                onPressed: () => CategoryFormSheet.show(
                  context,
                  initialType: category.type,
                  existing: category,
                ),
              ),
              IconButton(
                tooltip: l10n.delete,
                icon: const Icon(CupertinoIcons.trash, color: AppleTokens.systemRed, size: 20),
                onPressed: () => _handleDelete(context, ref, category),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Center(
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
                  // Hero Card: Category Badge & Monthly Spend
                  AppleGlassCard(
                    borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
                    padding: const EdgeInsets.all(20),
                    borderColor: badgeColor.withValues(alpha: 0.35),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [badgeColor.withValues(alpha: 0.22), Colors.black54]
                          : [badgeColor.withValues(alpha: 0.14), Colors.white],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                                border: Border.all(
                                  color: badgeColor.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                AppIconCatalog.resolve(category.icon),
                                color: badgeColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          displayName,
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (category.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppleTokens.systemBlue.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                          ),
                                          child: Text(
                                            l10n.defaultCategoryBadge,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppleTokens.systemBlue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isIncome
                                          ? AppleTokens.emeraldIncome.withValues(alpha: 0.14)
                                          : AppleTokens.rubyExpense.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                    ),
                                    child: Text(
                                      typeLabel,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: isIncome ? AppleTokens.emeraldIncome : AppleTokens.rubyExpense,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          isIncome
                              ? (locale.startsWith('vi')
                                  ? 'Thu nhập tháng này'
                                  : 'Income this month')
                              : (locale.startsWith('vi')
                                  ? 'Chi tiêu tháng này'
                                  : 'Expense this month'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          monthMoney.format(locale: locale, masked: hideBalance),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontFeatures: AppTheme.tabularFigures,
                            color: isIncome ? AppleTokens.emeraldIncome : AppleTokens.rubyExpense,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // All-time & Count Strip
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locale.startsWith('vi')
                                          ? 'Tổng tích lũy'
                                          : 'All-time total',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppleTokens.systemGray),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      allTimeMoney.format(locale: locale, masked: hideBalance),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isIncome ? AppleTokens.emeraldIncome : AppleTokens.rubyExpense,
                                        fontFeatures: AppTheme.tabularFigures,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 26, color: AppleTokens.separatorLight),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locale.startsWith('vi')
                                          ? 'Số lần giao dịch'
                                          : 'Transactions',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppleTokens.systemGray),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      locale.startsWith('vi')
                                          ? '${categoryTxs.length} giao dịch'
                                          : '${categoryTxs.length} transactions',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        fontFeatures: AppTheme.tabularFigures,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
                                categoryId: category.id,
                                kind: isIncome
                                    ? TransactionDraftKind.income
                                    : TransactionDraftKind.expense,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                          ),
                        ),
                        icon: const Icon(CupertinoIcons.pencil, size: 18),
                        label: Text(
                          l10n.edit,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        onPressed: () => CategoryFormSheet.show(
                          context,
                          initialType: category.type,
                          existing: category,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppleTokens.systemRed,
                          side: BorderSide(
                            color: AppleTokens.systemRed.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                          ),
                        ),
                        icon: const Icon(CupertinoIcons.trash, size: 18, color: AppleTokens.systemRed),
                        label: Text(
                          l10n.delete,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: AppleTokens.systemRed,
                          ),
                        ),
                        onPressed: () => _handleDelete(context, ref, category),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Transaction History Header
                  Text(
                    '${l10n.transactionsTitle} (${categoryTxs.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Transactions List
                  if (categoryTxs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: EmptyStateView(
                        icon: CupertinoIcons.tray,
                        title: locale.startsWith('vi')
                            ? 'Chưa có giao dịch'
                            : 'No transactions yet',
                        subtitle: locale.startsWith('vi')
                            ? 'Chưa có khoản thu chi nào được phân loại vào danh mục $displayName.'
                            : 'No transactions have been categorized under $displayName yet.',
                        actionLabel: l10n.quickAddTransaction,
                        onAction: () {
                          context.push(
                            AppRoutes.transactionNew,
                            extra: TransactionDraft(
                              categoryId: category.id,
                              kind: isIncome
                                  ? TransactionDraftKind.income
                                  : TransactionDraftKind.expense,
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
                          for (var i = 0; i < categoryTxs.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: AppleTokens.hairline,
                                indent: 68,
                                color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                              ),
                            TransactionTile(
                              transaction: categoryTxs[i],
                              category: categoriesMap[categoryTxs[i].categoryId],
                              sourceAccount: accountsMap[categoryTxs[i].accountId],
                              destinationAccount: categoryTxs[i].toAccountId != null
                                  ? accountsMap[categoryTxs[i].toAccountId!]
                                  : null,
                              locale: locale,
                              hideAmount: hideBalance,
                              showDate: true,
                              onTap: () => context.push(
                                AppRoutes.transactionDetail(categoryTxs[i].id),
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
      );
      },
    );
  }
}

