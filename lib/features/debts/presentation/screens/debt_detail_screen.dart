import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/debts/domain/entities/debt.dart';
import 'package:so_thu_chi/features/debts/presentation/controllers/debts_controller.dart';
import 'package:so_thu_chi/features/debts/presentation/widgets/debt_form_sheet.dart';
import 'package:so_thu_chi/features/debts/presentation/widgets/debt_repayment_sheet.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

class DebtDetailScreen extends ConsumerWidget {
  const DebtDetailScreen({
    super.key,
    required this.debtId,
  });

  final String debtId;

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Debt debt) async {
    final l10n = context.l10n;
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(l10n.debtDeleteConfirmTitle),
        message: Text(l10n.debtDeleteConfirmBody(debt.personName)),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.debtDelete),
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
      await ref.read(debtsActionControllerProvider.notifier).deleteDebt(debt.id);
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

    final debtsAsync = ref.watch(debtsStreamProvider);
    final accountsMap = ref.watch(accountsMapProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final hideBalance = settings?.hideBalance ?? false;

    return debtsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CupertinoActivityIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.localizeError(err))),
      ),
      data: (debts) {
        final debt = debts.where((d) => d.id == debtId).firstOrNull;
        if (debt == null) {
          return Scaffold(
            appBar: AppBar(),
            body: SafeArea(
              top: false,
              bottom: false,
              child: Center(
                child: Text(
                  'Không tìm thấy khoản nợ',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          );
        }

        final isLent = debt.type == DebtType.lent;
        final accentColor = debt.isSettled
            ? AppleTokens.systemGray
            : (isLent ? AppleTokens.systemGreen : AppleTokens.systemOrange);

        final initials = debt.personName.trim().isNotEmpty
            ? debt.personName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
            : '?';

        final linkedAccount = debt.accountId != null ? accountsMap[debt.accountId!] : null;

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
              debt.personName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                tooltip: l10n.debtEdit,
                icon: const Icon(CupertinoIcons.pencil, size: 20),
                onPressed: () => DebtFormSheet.show(context, initialDebt: debt),
              ),
              IconButton(
                tooltip: l10n.debtDelete,
                icon: const Icon(CupertinoIcons.trash, color: AppleTokens.systemRed, size: 20),
                onPressed: () => _handleDelete(context, ref, debt),
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
                  // Hero Card: Person, Type & Remaining Amount
                  AppleGlassCard(
                    borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
                    padding: const EdgeInsets.all(20),
                    borderColor: debt.isOverdue
                        ? AppleTokens.systemRed.withValues(alpha: 0.5)
                        : accentColor.withValues(alpha: 0.35),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [accentColor.withValues(alpha: 0.2), Colors.black54]
                          : [accentColor.withValues(alpha: 0.12), Colors.white],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                initials,
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
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
                                          debt.personName,
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: accentColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                        ),
                                        child: Text(
                                          isLent ? l10n.debtLent : l10n.debtBorrowed,
                                          style: TextStyle(
                                            color: accentColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (debt.phoneNumber != null && debt.phoneNumber!.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      debt.phoneNumber!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (debt.isSettled)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppleTokens.systemGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                ),
                                child: Text(
                                  l10n.debtFilterSettled,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppleTokens.systemGreen,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        if (debt.isOverdue) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppleTokens.systemRed.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                            ),
                            child: const Row(
                              children: [
                                Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppleTokens.systemRed, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Khoản nợ đã quá hạn cần thanh toán!',
                                  style: TextStyle(color: AppleTokens.systemRed, fontWeight: FontWeight.w700, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        Text(
                          debt.isSettled ? l10n.debtFilterSettled : '${l10n.debtRemaining}:',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          debt.remainingMoney.format(locale: locale, masked: hideBalance),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontFeatures: AppTheme.tabularFigures,
                            color: accentColor,
                          ),
                        ),

                        const SizedBox(height: 16),
                        // Progress Bar & Paid Amount
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: debt.progress,
                            minHeight: 8,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Đã trả: ${debt.paidMoney.format(locale: locale, masked: hideBalance)}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, fontFeatures: AppTheme.tabularFigures),
                            ),
                            Text(
                              'Tổng: ${debt.totalMoney.format(locale: locale, masked: hideBalance)}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, fontFeatures: AppTheme.tabularFigures),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons Row
                  Row(
                    children: [
                      if (!debt.isSettled) ...[
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: accentColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                              ),
                            ),
                            icon: const Icon(CupertinoIcons.checkmark_circle, size: 18),
                            label: Text(
                              isLent ? 'Thu nợ' : 'Trả nợ',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                            ),
                            onPressed: () => DebtRepaymentSheet.show(context, debt),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                            ),
                          ),
                          icon: const Icon(CupertinoIcons.pencil, size: 18),
                          label: Text(
                            l10n.debtEdit,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                          onPressed: () => DebtFormSheet.show(context, initialDebt: debt),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Metadata Detail Card
                  AppleGlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chi tiết khoản nợ',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        if (debt.dueDate != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ngày hẹn thanh toán', style: TextStyle(color: AppleTokens.systemGray)),
                              Text(
                                AppDateUtils.formatFullDate(debt.dueDate!, locale: locale),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: debt.isOverdue ? AppleTokens.systemRed : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (linkedAccount != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ví ghi nhận', style: TextStyle(color: AppleTokens.systemGray)),
                              Text(
                                linkedAccount.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (debt.note.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ghi chú', style: TextStyle(color: AppleTokens.systemGray)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  debt.note,
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
                            const Text('Ngày tạo', style: TextStyle(color: AppleTokens.systemGray)),
                            Text(
                              AppDateUtils.formatFullDate(debt.createdAt, locale: locale),
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

