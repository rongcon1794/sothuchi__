import 'dart:async';
import 'dart:math' as math;
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
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

/// Apple-grade Detail View Screen for a single [TransactionEntity].
///
/// Follows the 3-tier view pattern (List -> Detail -> Edit), presenting
/// comprehensive transaction details, hero amount, category & account chips,
/// and primary actions (Chỉnh sửa, Xóa, Sao chép).
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
  });

  final String transactionId;

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity tx,
  ) async {
    final l10n = context.l10n;
    final isVi = l10n.localeName.startsWith('vi');
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(isVi ? 'Xóa giao dịch' : 'Delete transaction'),
        message: Text(
          isVi
              ? 'Bạn có chắc chắn muốn xóa giao dịch này? Bạn có thể hoàn tác ngay sau khi xóa.'
              : 'Are you sure you want to delete this transaction? You can undo right after deleting.',
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
      final messenger = ScaffoldMessenger.of(context);
      final res = await ref
          .read(transactionsActionControllerProvider.notifier)
          .softDelete(tx.id);

      if (!context.mounted) return;
      if (res.isSuccess) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
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
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              context.localizeError(
                res.errorOrNull ?? (isVi ? 'Đã có lỗi xảy ra' : 'Unknown error'),
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleDirectHoldDelete(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity tx,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final res = await ref
        .read(transactionsActionControllerProvider.notifier)
        .softDelete(tx.id);

    if (!context.mounted) return;
    if (res.isSuccess) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
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
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.localizeError(res.errorOrNull ?? ''),
          ),
        ),
      );
    }
  }

  void _handleDuplicate(BuildContext context, TransactionEntity tx) {
    unawaited(HapticFeedback.lightImpact());
    context.push(
      AppRoutes.transactionNew,
      extra: TransactionDraft(
        amountMinorUnits: tx.amount,
        currencyCode: tx.currency,
        kind: switch (tx.type) {
          TransactionType.income => TransactionDraftKind.income,
          TransactionType.expense => TransactionDraftKind.expense,
          TransactionType.transfer => TransactionDraftKind.transfer,
        },
        accountId: tx.accountId,
        toAccountId: tx.toAccountId,
        categoryId: tx.categoryId,
        note: tx.note,
        date: DateTime.now(),
        tags: tx.tags,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLandscape = context.isLandscape;

    final txsAsync = ref.watch(transactionsStreamProvider);
    final accountsMap = ref.watch(accountsMapProvider);
    final categoriesMap = ref.watch(categoriesMapProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final isVi = locale.toLowerCase().startsWith('vi');
    final hideBalance = settings?.hideBalance ?? false;

    return txsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CupertinoActivityIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(CupertinoIcons.chevron_left, size: 24),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text(context.localizeError(err))),
      ),
      data: (transactions) {
        final tx = transactions.where((t) => t.id == transactionId).firstOrNull;
        if (tx == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(CupertinoIcons.chevron_left, size: 24),
                onPressed: () => context.pop(),
              ),
            ),
            body: SafeArea(
              top: false,
              bottom: false,
              child: Center(
                child: Text(
                  isVi ? 'Không tìm thấy giao dịch' : 'Transaction not found',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          );
        }

        final sourceAccount = accountsMap[tx.accountId];
        final destAccount = tx.toAccountId != null ? accountsMap[tx.toAccountId!] : null;
        final category = categoriesMap[tx.categoryId];

        // Type color & badge
        final (typeColor, typeBgColor, typeIcon, typeLabel) = switch (tx.type) {
          TransactionType.expense => (
              const Color(0xFFF43F5E),
              const Color(0xFFF43F5E).withValues(alpha: isDark ? 0.22 : 0.12),
              CupertinoIcons.arrow_up_right,
              l10n.expense,
            ),
          TransactionType.income => (
              const Color(0xFF10B981),
              const Color(0xFF10B981).withValues(alpha: isDark ? 0.22 : 0.12),
              CupertinoIcons.arrow_down_left,
              l10n.income,
            ),
          TransactionType.transfer => (
              AppleTokens.cobaltTransfer,
              AppleTokens.cobaltTransfer.withValues(alpha: isDark ? 0.22 : 0.12),
              CupertinoIcons.arrow_right_arrow_left,
              l10n.transfer,
            ),
        };

        final formattedAmount = hideBalance
            ? tx.money.format(locale: locale, masked: true)
            : switch (tx.type) {
                TransactionType.expense =>
                  '- ${tx.money.format(locale: locale)}',
                TransactionType.income =>
                  '+ ${tx.money.format(locale: locale)}',
                TransactionType.transfer =>
                  tx.money.format(locale: locale),
              };

        final timeStr =
            '${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}';
        final fullDateStr =
            '${AppDateUtils.formatFullDate(tx.date, locale: locale)} • $timeStr';

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
              isVi ? 'Chi tiết giao dịch' : 'Transaction Details',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                tooltip: isVi ? 'Sao chép giao dịch' : 'Duplicate transaction',
                icon: const Icon(CupertinoIcons.doc_on_doc, size: 20),
                onPressed: () => _handleDuplicate(context, tx),
              ),
              IconButton(
                tooltip: l10n.edit,
                icon: const Icon(CupertinoIcons.pencil, size: 20),
                onPressed: () => context.push(AppRoutes.transactionEdit(tx.id)),
              ),
              IconButton(
                tooltip: l10n.delete,
                icon: const Icon(
                  CupertinoIcons.trash,
                  color: AppleTokens.systemRed,
                  size: 20,
                ),
                onPressed: () => _handleDelete(context, ref, tx),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.isWideScreen ? 1024 : 720),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, isLandscape ? 6 : 12, 16, 40),
                children: [
                  // 1. Hero Amount & Type Card
                  AppleGlassCard(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: isLandscape ? 14 : 24,
                    ),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
                    child: Column(
                      children: [
                        // Type Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: typeBgColor,
                            borderRadius:
                                BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(typeIcon, size: 14, color: typeColor),
                              const SizedBox(width: 6),
                              Text(
                                typeLabel,
                                style: TextStyle(
                                  color: typeColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Formatted Hero Amount
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formattedAmount,
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: typeColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.0,
                              fontFeatures: AppTheme.tabularFigures,
                            ),
                          ),
                        ),

                        // Prominent Note Card if present
                        if (tx.note.trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(
                                AppleTokens.radiusCard,
                              ),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFE2E8F0),
                                width: AppleTokens.hairline,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  CupertinoIcons.text_quote,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tx.note.trim(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.90)
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Transaction Details Group (Apple Grouped List)
                  AppleGlassCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    child: Column(
                      children: [
                        // Category Item (if not transfer)
                        if (category != null) ...[
                          _DetailRowItem(
                            icon: AppIconCatalog.resolve(category.icon),
                            iconColor: Color(category.color),
                            iconBgColor:
                                Color(category.color).withValues(alpha: 0.16),
                            title: isVi ? 'Danh mục' : 'Category',
                            value: DefaultCategoryLocalization.resolveName(
                              l10n,
                              categoryId: category.id,
                              fallbackName: category.name,
                            ),
                            trailingChevron: true,
                            onTap: () => context.push(
                              AppRoutes.categoryDetail(category.id),
                            ),
                          ),
                          _buildDivider(isDark),
                        ],

                        // Source Account / Wallet
                        if (sourceAccount != null) ...[
                          _DetailRowItem(
                            icon: AppIconCatalog.resolve(sourceAccount.icon),
                            iconColor: Color(sourceAccount.color),
                            iconBgColor:
                                Color(sourceAccount.color).withValues(alpha: 0.16),
                            title: tx.type == TransactionType.transfer
                                ? (isVi ? 'Ví chuyển (nguồn)' : 'Source wallet')
                                : (isVi ? 'Ví thanh toán' : 'Wallet'),
                            value: sourceAccount.name,
                            subtitle: hideBalance
                                ? null
                                : '${isVi ? 'Số dư hiện tại' : 'Current balance'}: ${sourceAccount.balanceMoney.format(locale: locale)}',
                            trailingChevron: true,
                            onTap: () => context.push(
                              AppRoutes.accountDetail(sourceAccount.id),
                            ),
                          ),
                          _buildDivider(isDark),
                        ],

                        // Destination Account (for transfer)
                        if (tx.type == TransactionType.transfer &&
                            destAccount != null) ...[
                          _DetailRowItem(
                            icon: AppIconCatalog.resolve(destAccount.icon),
                            iconColor: Color(destAccount.color),
                            iconBgColor:
                                Color(destAccount.color).withValues(alpha: 0.16),
                            title: isVi ? 'Ví nhận (đích)' : 'Destination wallet',
                            value: destAccount.name,
                            subtitle: hideBalance
                                ? null
                                : '${isVi ? 'Số dư hiện tại' : 'Current balance'}: ${destAccount.balanceMoney.format(locale: locale)}',
                            trailingChevron: true,
                            onTap: () => context.push(
                              AppRoutes.accountDetail(destAccount.id),
                            ),
                          ),
                          _buildDivider(isDark),
                        ],

                        // Date & Time
                        _DetailRowItem(
                          icon: CupertinoIcons.calendar,
                          iconColor: theme.colorScheme.primary,
                          iconBgColor: theme.colorScheme.primary
                              .withValues(alpha: 0.14),
                          title: isVi ? 'Thời gian giao dịch' : 'Transaction time',
                          value: fullDateStr,
                        ),

                        // Tags (if present)
                        if (tx.tags.isNotEmpty) ...[
                          _buildDivider(isDark),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.tag,
                                    size: 18,
                                    color: Colors.amber,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isVi ? 'Nhãn đã gắn' : 'Tags',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          for (final tag in tx.tags)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 9,
                                                vertical: 3.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.white
                                                        .withValues(alpha: 0.08)
                                                    : const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  AppleTokens.radiusPill,
                                                ),
                                              ),
                                              child: Text(
                                                '#$tag',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF475569),
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
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Primary Actions (Chỉnh sửa, Xóa, Sao chép)
                  Row(
                    children: [
                      // Sửa button
                      Expanded(
                        child: AppleButton(
                          label: l10n.edit,
                          icon: const Icon(CupertinoIcons.pencil, size: 18),
                          onPressed: () =>
                              context.push(AppRoutes.transactionEdit(tx.id)),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Lucian Element #003: Hold to Delete Button (with Tap fallback)
                      Expanded(
                        child: LucianHoldToDeleteButton(
                          label: l10n.delete,
                          holdingLabel: isVi ? 'Giữ...' : 'Hold...',
                          confirmedLabel: isVi ? 'Đã xóa!' : 'Deleted!',
                          onTap: () => _handleDelete(context, ref, tx),
                          onConfirmed: () =>
                              _handleDirectHoldDelete(context, ref, tx),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Duplicate action button
                  AppleButton(
                    label: isVi
                        ? 'Sao chép thành giao dịch mới'
                        : 'Duplicate as new transaction',
                    icon: const Icon(CupertinoIcons.doc_on_doc, size: 16),
                    variant: AppleButtonVariant.outline,
                    onPressed: () => _handleDuplicate(context, tx),
                  ),
                  const SizedBox(height: 16),

                  // 4. Subtle Metadata Footer
                  Center(
                    child: Text(
                      '${isVi ? 'Mã giao dịch' : 'Transaction ID'}: #${tx.id.substring(0, math.min(10, tx.id.length))}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                        letterSpacing: 0.3,
                      ),
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

  Widget _buildDivider(bool isDark) => Divider(
        height: AppleTokens.hairline,
        indent: 66,
        color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
      );
}

class _DetailRowItem extends StatelessWidget {
  const _DetailRowItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.value,
    this.subtitle,
    this.trailingChevron = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String value;
  final String? subtitle;
  final bool trailingChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailingChevron)
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
        ],
      ),
    );

    if (onTap != null) {
      return ApplePressable(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}
