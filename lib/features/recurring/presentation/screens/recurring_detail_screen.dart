import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:so_thu_chi/features/recurring/presentation/controllers/recurring_controller.dart';
import 'package:so_thu_chi/features/recurring/presentation/widgets/recurring_form_sheet.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

class RecurringDetailScreen extends ConsumerWidget {
  const RecurringDetailScreen({
    super.key,
    required this.recurringId,
  });

  final String recurringId;

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

  Future<void> _handleExecute(BuildContext context, WidgetRef ref, RecurringTransaction item) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final isIncome = item.type == TransactionType.income;
    unawaited(HapticFeedback.mediumImpact());
    final res = await ref.read(recurringActionControllerProvider.notifier).executeRecurring(item.id);

    if (!context.mounted) return;
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

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, RecurringTransaction item) async {
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

    if (confirmed == true && context.mounted) {
      unawaited(HapticFeedback.mediumImpact());
      await ref.read(recurringActionControllerProvider.notifier).deleteRecurring(item.id);
      if (context.mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;

    final recurringAsync = ref.watch(recurringStreamProvider);
    final categoriesMap = ref.watch(categoriesMapProvider);
    final accountsMap = ref.watch(accountsMapProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final hideBalance = settings?.hideBalance ?? false;

    return recurringAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CupertinoActivityIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.localizeError(err))),
      ),
      data: (items) {
        final item = items.where((i) => i.id == recurringId).firstOrNull;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: SafeArea(
              top: false,
              bottom: false,
              child: Center(
                child: Text(
                  'Không tìm thấy giao dịch định kỳ',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          );
        }

        final category = categoriesMap[item.categoryId];
        final account = accountsMap[item.accountId];
        final toAccount = item.toAccountId != null ? accountsMap[item.toAccountId!] : null;

        final categoryColor = category != null ? Color(category.color) : AppleTokens.systemBlue;
        final isIncome = item.type == TransactionType.income;

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
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                tooltip: l10n.edit,
                icon: const Icon(CupertinoIcons.pencil, size: 20),
                onPressed: () => RecurringFormSheet.show(context, existing: item),
              ),
              IconButton(
                tooltip: l10n.recurringDelete,
                icon: const Icon(CupertinoIcons.trash, color: AppleTokens.systemRed, size: 20),
                onPressed: () => _handleDelete(context, ref, item),
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
                  // Hero Card: Title, Amount, Interval & Due status
                  AppleGlassCard(
                    borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
                    padding: const EdgeInsets.all(20),
                    borderColor: item.isDue
                        ? AppleTokens.systemOrange.withValues(alpha: 0.5)
                        : categoryColor.withValues(alpha: 0.35),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [categoryColor.withValues(alpha: 0.2), Colors.black54]
                          : [categoryColor.withValues(alpha: 0.12), Colors.white],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppleSquircleBadge(
                              icon: category != null ? AppIconCatalog.resolve(category.icon) : CupertinoIcons.repeat,
                              backgroundColor: categoryColor,
                              size: 52,
                              iconSize: 26,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppleTokens.systemBlue.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                        ),
                                        child: Text(
                                          _intervalLabel(item.interval, l10n),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppleTokens.systemBlue,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: item.isPaused
                                              ? AppleTokens.systemGray.withValues(alpha: 0.18)
                                              : AppleTokens.systemGreen.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                        ),
                                        child: Text(
                                          item.isPaused ? l10n.recurringPause : 'Đang theo dõi',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: item.isPaused ? AppleTokens.systemGray : AppleTokens.systemGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (item.isDue) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppleTokens.systemOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                            ),
                            child: const Row(
                              children: [
                                Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppleTokens.systemOrange, size: 16),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Giao dịch đã đến hạn cần thanh toán / ghi sổ!',
                                    style: TextStyle(color: AppleTokens.systemOrange, fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        Text(
                          isIncome ? 'KHOẢN THU NHẬP ĐỊNH KỲ' : 'HÓA ĐƠN CHI TIÊU ĐỊNH KỲ',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isIncome ? AppleTokens.emeraldIncome : AppleTokens.rubyExpense,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.money.format(locale: locale, masked: hideBalance),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontFeatures: AppTheme.tabularFigures,
                            color: isIncome ? AppleTokens.emeraldIncome : AppleTokens.rubyExpense,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: isIncome ? AppleTokens.jadeDark : AppleTokens.rubyExpense,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                            ),
                          ),
                          icon: Icon(
                            isIncome
                                ? CupertinoIcons.arrow_down_circle_fill
                                : CupertinoIcons.creditcard_fill,
                            size: 16,
                          ),
                          label: Text(
                            isIncome ? l10n.recurringMarkReceived : l10n.recurringMarkPaid,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          onPressed: () => _handleExecute(context, ref, item),
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
                        icon: Icon(
                          item.isPaused ? CupertinoIcons.play_circle : CupertinoIcons.pause_circle,
                          size: 18,
                        ),
                        label: Text(
                          item.isPaused ? l10n.recurringResume : l10n.recurringPause,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        onPressed: () {
                          ref.read(recurringActionControllerProvider.notifier).togglePause(item.id, !item.isPaused);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Details Metadata Card
                  AppleGlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông tin lịch trình',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isIncome ? 'Ngày nhận tiếp theo' : 'Kỳ thanh toán tiếp theo',
                              style: const TextStyle(color: AppleTokens.systemGray),
                            ),
                            Text(
                              AppDateUtils.formatFullDate(item.nextDueDate, locale: locale),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: item.isDue
                                    ? (isIncome ? AppleTokens.emeraldIncome : AppleTokens.systemOrange)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (category != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isIncome ? l10n.recurringCategoryIncomeLabel : l10n.recurringCategoryLabel,
                                style: const TextStyle(color: AppleTokens.systemGray),
                              ),
                              Text(
                                DefaultCategoryLocalization.resolveName(l10n, categoryId: category.id, fallbackName: category.name),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (account != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isIncome ? l10n.recurringReceiveWalletLabel : l10n.recurringWalletLabel,
                                style: const TextStyle(color: AppleTokens.systemGray),
                              ),
                              Text(
                                account.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (toAccount != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ví nhận', style: TextStyle(color: AppleTokens.systemGray)),
                              Text(
                                toAccount.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (item.lastExecutedDate != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isIncome ? 'Lần nhận gần nhất' : 'Lần thanh toán gần nhất',
                                style: const TextStyle(color: AppleTokens.systemGray),
                              ),
                              Text(
                                AppDateUtils.formatFullDate(item.lastExecutedDate!, locale: locale),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (item.note.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ghi chú', style: TextStyle(color: AppleTokens.systemGray)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  item.note,
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l10n.recurringStartDateLabel, style: const TextStyle(color: AppleTokens.systemGray)),
                            Text(
                              AppDateUtils.formatFullDate(item.startDate, locale: locale),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
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

