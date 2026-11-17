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

/// Redesigned Debt & Loan Detail Screen.
///
/// Features Apple HIG navigation, executive Glassmorphic Hero Overview,
/// accurate progress bar with [LucianProgressBar], clean metadata cards,
/// and quick action buttons.
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
    final isVi = locale == 'vi';
    final hideBalance = settings?.hideBalance ?? false;

    return debtsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CupertinoActivityIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: const AppleAppBar(),
        body: Center(child: Text(context.localizeError(err))),
      ),
      data: (debts) {
        final debt = debts.where((d) => d.id == debtId).firstOrNull;
        if (debt == null) {
          return Scaffold(
            appBar: const AppleAppBar(),
            body: SafeArea(
              top: false,
              bottom: false,
              child: Center(
                child: Text(
                  isVi ? 'Không tìm thấy khoản nợ' : 'Debt not found',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          );
        }

        final isLent = debt.type == DebtType.lent;
        final accentColor = debt.isSettled
            ? AppleTokens.systemGray
            : (isLent ? AppleTokens.emeraldIncome : AppleTokens.systemOrange);

        final initials = debt.personName.trim().isNotEmpty
            ? debt.personName
                .trim()
                .split(' ')
                .map((e) => e.isNotEmpty ? e[0] : '')
                .take(2)
                .join()
                .toUpperCase()
            : '?';

        final linkedAccount =
            debt.accountId != null ? accountsMap[debt.accountId!] : null;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppleAppBar(
            titleText: debt.personName,
            isLandscape: isLandscape,
            actions: [
              AppleIconButton(
                tooltip: l10n.debtEdit,
                icon: CupertinoIcons.pencil,
                size: isLandscape ? 32 : 36,
                iconSize: isLandscape ? 16 : 18,
                onTap: () => DebtFormSheet.show(context, initialDebt: debt),
              ),
              const SizedBox(width: 4),
              AppleIconButton(
                tooltip: l10n.debtDelete,
                icon: CupertinoIcons.trash,
                foregroundColor: AppleTokens.systemRed,
                size: isLandscape ? 32 : 36,
                iconSize: isLandscape ? 16 : 18,
                onTap: () => _handleDelete(context, ref, debt),
              ),
              const SizedBox(width: 8),
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
                    // 1. Hero Card: Person, Status, Remaining Amount & Progress
                    AppleGlassCard(
                      borderRadius:
                          BorderRadius.circular(AppleTokens.radiusHero),
                      padding: const EdgeInsets.all(18),
                      borderColor: debt.isOverdue
                          ? AppleTokens.systemRed.withValues(alpha: isDark ? 0.45 : 0.35)
                          : accentColor.withValues(alpha: isDark ? 0.30 : 0.20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      accentColor.withValues(
                                        alpha: isDark ? 0.35 : 0.22,
                                      ),
                                      accentColor.withValues(
                                        alpha: isDark ? 0.16 : 0.08,
                                      ),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppleTokens.radiusControl,
                                  ),
                                  border: Border.all(
                                    color: accentColor.withValues(
                                      alpha: isDark ? 0.4 : 0.28,
                                    ),
                                    width: 1.2,
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
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                              letterSpacing: -0.3,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accentColor.withValues(
                                              alpha: isDark ? 0.20 : 0.12,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(
                                              AppleTokens.radiusPill,
                                            ),
                                          ),
                                          child: Text(
                                            debt.isSettled
                                                ? l10n.debtFilterSettled
                                                    .toUpperCase()
                                                : (isLent
                                                    ? l10n.debtLent
                                                        .toUpperCase()
                                                    : l10n.debtBorrowed
                                                        .toUpperCase()),
                                            style: TextStyle(
                                              color: accentColor,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 9.5,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (debt.phoneNumber != null &&
                                        debt.phoneNumber!.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.phone_fill,
                                            size: 11,
                                            color: theme
                                                .colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            debt.phoneNumber!,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (debt.isSettled)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppleTokens.emeraldIncome
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      AppleTokens.radiusPill,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        CupertinoIcons.checkmark_circle_fill,
                                        size: 13,
                                        color: AppleTokens.emeraldIncome,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.debtFilterSettled,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppleTokens.emeraldIncome,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          if (debt.isOverdue) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppleTokens.systemRed
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppleTokens.radiusControl,
                                ),
                                border: Border.all(
                                  color: AppleTokens.systemRed
                                      .withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.exclamationmark_triangle_fill,
                                    color: AppleTokens.systemRed,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      isVi
                                          ? 'Khoản nợ đã quá hạn cần thanh toán!'
                                          : 'This debt is overdue for payment!',
                                      style: const TextStyle(
                                        color: AppleTokens.systemRed,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),
                          Text(
                            debt.isSettled
                                ? l10n.debtFilterSettled
                                : '${l10n.debtRemaining}:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              debt.remainingMoney.format(
                                locale: locale,
                                masked: hideBalance,
                              ),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 26,
                                letterSpacing: -0.5,
                                fontFeatures: AppTheme.tabularFigures,
                                color: accentColor,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),
                          // Progress Bar & Paid Amount
                          LucianProgressBar(
                            value: debt.progress,
                            height: 6,
                            activeColor: accentColor,
                            showGlow: true,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${isVi ? 'Đã trả' : 'Paid'}: ${debt.paidMoney.format(locale: locale, masked: hideBalance)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: AppTheme.tabularFigures,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${isVi ? 'Tổng' : 'Total'}: ${debt.totalMoney.format(locale: locale, masked: hideBalance)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: AppTheme.tabularFigures,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 2. Action Buttons Row
                    Row(
                      children: [
                        if (!debt.isSettled) ...[
                          Expanded(
                            child: AppleButton(
                              icon: isLent
                                  ? CupertinoIcons.arrow_down_circle_fill
                                  : CupertinoIcons.arrow_up_circle_fill,
                              label: isLent ? l10n.debtCollect : l10n.debtRepay,
                              color: accentColor,
                              textColor: Colors.white,
                              onPressed: () =>
                                  DebtRepaymentSheet.show(context, debt),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: AppleButton(
                            variant: AppleButtonVariant.secondary,
                            icon: CupertinoIcons.pencil,
                            label: l10n.debtEdit,
                            onPressed: () =>
                                DebtFormSheet.show(context, initialDebt: debt),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 3. Metadata Detail Card
                    AppleGlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius:
                          BorderRadius.circular(AppleTokens.radiusCard),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const AppleSquircleBadge(
                                icon: CupertinoIcons.info_circle_fill,
                                backgroundColor: AppleTokens.systemIndigo,
                                size: 20,
                                iconSize: 10,
                                radius: 5,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isVi ? 'Chi tiết khoản nợ' : 'Debt details',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (debt.dueDate != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isVi ? 'Ngày hẹn thanh toán' : 'Due date',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: debt.isOverdue
                                        ? AppleTokens.systemRed
                                            .withValues(alpha: 0.12)
                                        : (isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.08)
                                            : Colors.black
                                                .withValues(alpha: 0.05)),
                                    borderRadius: BorderRadius.circular(
                                      AppleTokens.radiusPill,
                                    ),
                                  ),
                                  child: Text(
                                    AppDateUtils.formatFullDate(
                                      debt.dueDate!,
                                      locale: locale,
                                    ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: debt.isOverdue
                                          ? AppleTokens.systemRed
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (linkedAccount != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isVi ? 'Ví ghi nhận' : 'Recorded wallet',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: Color(linkedAccount.color),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      linkedAccount.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        color: Color(linkedAccount.color),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (debt.note.isNotEmpty) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isVi ? 'Ghi chú' : 'Note',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    debt.note,
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isVi ? 'Ngày tạo' : 'Created date',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                AppDateUtils.formatFullDate(
                                  debt.createdAt,
                                  locale: locale,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
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
            ),
          ),
        );
      },
    );
  }
}
