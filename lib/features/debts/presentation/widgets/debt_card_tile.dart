import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/debts/domain/entities/debt.dart';
import 'package:so_thu_chi/features/debts/presentation/widgets/debt_repayment_sheet.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';

/// Streamlined, beautiful Apple Glassmorphic Card Tile for a single Debt/Loan record.
///
/// Features:
/// - Squircle Avatar with dual-tone gradient background & type badge indicator
/// - Clear typography: Name, subtitle, status tag
/// - High-contrast balance with tabular figures & partial paid percentage
/// - Dynamic Due Date badge with overdue alert styling
/// - 1-tap quick repayment action button ("Thu nợ" / "Trả nợ")
class DebtCardTile extends ConsumerWidget {
  const DebtCardTile({
    super.key,
    required this.debt,
    required this.hideBalance,
  });

  final Debt debt;
  final bool hideBalance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final isVi = locale.startsWith('vi');
    final accountsMap = ref.watch(accountsMapProvider);
    final wallet = debt.accountId != null ? accountsMap[debt.accountId!] : null;

    final isLent = debt.type == DebtType.lent;
    final accentColor = debt.isSettled
        ? AppleTokens.systemGray
        : (isLent ? AppleTokens.emeraldIncome : AppleTokens.systemOrange);

    final trimmedName = debt.personName.trim();
    final initialChar = trimmedName.isNotEmpty
        ? trimmedName[0].toUpperCase()
        : '?';

    final hasPartialPayment =
        debt.remainingAmount < debt.amount && !debt.isSettled;
    final paidPercent = (debt.progress * 100).toInt();

    return ApplePressable(
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      onTap: () => context.push(AppRoutes.debtDetail(debt.id)),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: debt.isSettled ? 0.72 : 1.0,
        child: AppleGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
          borderColor: debt.isOverdue
              ? AppleTokens.systemRed.withValues(alpha: isDark ? 0.45 : 0.35)
              : accentColor.withValues(alpha: isDark ? 0.25 : 0.16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row 1: Squircle Avatar + Person Info + Balance
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Squircle Avatar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withValues(alpha: isDark ? 0.35 : 0.20),
                              accentColor.withValues(alpha: isDark ? 0.16 : 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                          border: Border.all(
                            color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
                            width: 1.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initialChar,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -1.5,
                        right: -1.5,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            debt.isSettled
                                ? CupertinoIcons.checkmark_alt
                                : (isLent
                                    ? CupertinoIcons.arrow_up_right
                                    : CupertinoIcons.arrow_down_left),
                            size: 7.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),

                  // 2. Person Name & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          debt.personName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2,
                            decoration: debt.isSettled
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          debt.phoneNumber?.isNotEmpty == true
                              ? debt.phoneNumber!
                              : (wallet != null
                                  ? wallet.name
                                  : (isLent
                                      ? (isVi ? 'Khoản cho vay' : 'Lent')
                                      : (isVi ? 'Khoản đi vay' : 'Borrowed'))),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 3. Amount Display & Status Tag
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          debt.isSettled
                              ? debt.totalMoney.format(
                                  locale: locale,
                                  masked: hideBalance,
                                )
                              : debt.remainingMoney.format(
                                  locale: locale,
                                  masked: hideBalance,
                                ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            fontFeatures: AppTheme.tabularFigures,
                            color: debt.isSettled
                                ? AppleTokens.systemGray
                                : accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5.5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(
                            alpha: isDark ? 0.20 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppleTokens.radiusPill,
                          ),
                        ),
                        child: Text(
                          debt.isSettled
                              ? l10n.debtFilterSettled.toUpperCase()
                              : (hasPartialPayment
                                  ? (isVi
                                      ? 'ĐÃ TRẢ $paidPercent%'
                                      : 'PAID $paidPercent%')
                                  : (isLent
                                      ? l10n.debtLent.toUpperCase()
                                      : l10n.debtBorrowed.toUpperCase())),
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Progress bar if partially paid
              if (debt.progress > 0 && !debt.isSettled) ...[
                const SizedBox(height: 9),
                LucianProgressBar(
                  value: debt.progress,
                  height: 3.5,
                  activeColor: accentColor,
                  showGlow: false,
                ),
              ],

              // Row 2: Due Date / Note on Left & Quick Repayment Button on Right
              const SizedBox(height: 9),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Due date badge or note
                  if (debt.dueDate != null)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.5,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: debt.isOverdue
                              ? AppleTokens.systemRed.withValues(alpha: 0.12)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04)),
                          borderRadius:
                              BorderRadius.circular(AppleTokens.radiusPill),
                          border: debt.isOverdue
                              ? Border.all(
                                  color: AppleTokens.systemRed.withValues(alpha: 0.3),
                                  width: 0.8,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              debt.isOverdue
                                  ? CupertinoIcons.exclamationmark_triangle_fill
                                  : CupertinoIcons.calendar,
                              size: 9.5,
                              color: debt.isOverdue
                                  ? AppleTokens.systemRed
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3.5),
                            Flexible(
                              child: Text(
                                debt.isOverdue
                                    ? '${isVi ? 'Quá hạn' : 'Overdue'} ${AppDateUtils.formatShortDate(debt.dueDate!, locale: locale)}'
                                    : '${isVi ? 'Hạn' : 'Due'} ${AppDateUtils.formatShortDate(debt.dueDate!, locale: locale)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: debt.isOverdue
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: debt.isOverdue
                                      ? AppleTokens.systemRed
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (debt.note.isNotEmpty)
                    Flexible(
                      child: Text(
                        '"${debt.note}"',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  const SizedBox(width: 6),

                  // Quick Action Button
                  if (!debt.isSettled)
                    ApplePressable(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        DebtRepaymentSheet.show(context, debt);
                      },
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(
                            alpha: isDark ? 0.22 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppleTokens.radiusPill,
                          ),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLent
                                  ? CupertinoIcons.arrow_down_circle_fill
                                  : CupertinoIcons.arrow_up_circle_fill,
                              size: 12,
                              color: accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isLent ? l10n.debtCollect : l10n.debtRepay,
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppleTokens.emeraldIncome.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(
                          AppleTokens.radiusPill,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.checkmark_circle_fill,
                            size: 11,
                            color: AppleTokens.emeraldIncome,
                          ),
                          const SizedBox(width: 3.5),
                          Text(
                            l10n.debtFilterSettled,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppleTokens.emeraldIncome,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
