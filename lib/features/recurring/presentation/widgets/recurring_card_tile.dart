import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/categories/domain/entities/category.dart';
import 'package:so_thu_chi/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

/// Card tile representing a single recurring transaction schedule.
class RecurringCardTile extends StatelessWidget {
  const RecurringCardTile({
    super.key,
    required this.item,
    required this.categoriesMap,
    required this.accountsMap,
    required this.locale,
    required this.hideBalance,
    this.isPaused = false,
    this.onExecute,
    required this.onEdit,
    required this.onTogglePause,
    required this.onDelete,
  });

  final RecurringTransaction item;
  final Map<String, Category> categoriesMap;
  final Map<String, Account> accountsMap;
  final String locale;
  final bool hideBalance;
  final bool isPaused;
  final VoidCallback? onExecute;
  final VoidCallback onEdit;
  final ValueChanged<bool> onTogglePause;
  final VoidCallback onDelete;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    final isExpense = item.type == TransactionType.expense;
    final accentColor = isExpense ? AppleTokens.rubyExpense : AppleTokens.jadePrimary;
    final category = categoriesMap[item.categoryId];
    final wallet = accountsMap[item.accountId];
    final categoryColor = category != null ? Color(category.color) : accentColor;

    return ApplePressable(
      onTap: () => context.push(AppRoutes.recurringDetail(item.id)),
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isPaused ? 0.75 : 1.0,
        child: AppleGlassCard(
          borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
          borderColor: item.isDue && !isPaused
              ? AppleTokens.systemOrange.withValues(alpha: isDark ? 0.6 : 0.45)
              : accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Row: Category Squircle Badge + Title/Amount + Popup Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Icon Badge with Gradient & Glow
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          (isPaused ? AppleTokens.systemGray : categoryColor)
                              .withValues(alpha: isDark ? 0.95 : 0.9),
                          (isPaused ? AppleTokens.systemGray : categoryColor)
                              .withValues(alpha: isDark ? 0.75 : 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                      boxShadow: [
                        BoxShadow(
                          color: (isPaused ? AppleTokens.systemGray : categoryColor)
                              .withValues(alpha: isDark ? 0.35 : 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      category != null
                          ? AppIconCatalog.resolve(category.icon)
                          : (isExpense
                              ? CupertinoIcons.arrow_up_right
                              : CupertinoIcons.arrow_down_left),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title + Amount + Optional Note
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${isExpense ? '-' : '+'}${item.money.format(locale: locale, masked: hideBalance)}',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isPaused ? AppleTokens.systemGray : accentColor,
                            fontFeatures: AppTheme.tabularFigures,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (item.note.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '“${item.note.trim()}”',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Actions: ApplePopupMenuButton
                  ApplePopupMenuButton<String>(
                    tooltip: l10n.moreOptions,
                    onSelected: (action) {
                      if (action == 'edit') {
                        onEdit();
                      } else if (action == 'pause') {
                        onTogglePause(!item.isPaused);
                      } else if (action == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (ctx) => [
                      ApplePopupMenuItem(
                        value: 'edit',
                        icon: CupertinoIcons.pencil,
                        title: l10n.edit,
                      ),
                      ApplePopupMenuItem(
                        value: 'pause',
                        icon: item.isPaused
                            ? CupertinoIcons.play_fill
                            : CupertinoIcons.pause_fill,
                        title: item.isPaused
                            ? l10n.recurringResume
                            : l10n.recurringPause,
                      ),
                      ApplePopupMenuItem(
                        value: 'delete',
                        icon: CupertinoIcons.trash,
                        title: l10n.recurringDelete,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Badges Wrap: Frequency + Next Due Date + Wallet + Auto Mode
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  // 1. Frequency badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.repeat,
                          size: 11,
                          color: accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _intervalLabel(item.interval, l10n),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Next Due badge (with orange/green alert if due today)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.isDue && !isPaused
                          ? (isExpense
                              ? AppleTokens.systemOrange.withValues(alpha: 0.16)
                              : AppleTokens.emeraldIncome.withValues(alpha: 0.16))
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.04)),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isDue && !isPaused
                              ? (isExpense
                                  ? CupertinoIcons.exclamationmark_circle_fill
                                  : CupertinoIcons.arrow_down_circle_fill)
                              : CupertinoIcons.calendar,
                          size: 11,
                          color: item.isDue && !isPaused
                              ? (isExpense ? AppleTokens.systemOrange : AppleTokens.emeraldIncome)
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.isDue && !isPaused
                              ? (isExpense ? l10n.recurringDueTodayExpense : l10n.recurringDueTodayIncome)
                              : (isExpense
                                  ? l10n.recurringNextDue(AppDateUtils.formatDayHeader(
                                      item.nextDueDate,
                                      locale: locale,
                                      todayLabel: l10n.today,
                                      yesterdayLabel: l10n.yesterday,
                                    ))
                                  : l10n.recurringNextIncomeDue(AppDateUtils.formatDayHeader(
                                      item.nextDueDate,
                                      locale: locale,
                                      todayLabel: l10n.today,
                                      yesterdayLabel: l10n.yesterday,
                                    ))),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: item.isDue && !isPaused
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: item.isDue && !isPaused
                                ? (isExpense ? AppleTokens.systemOrange : AppleTokens.emeraldIncome)
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Wallet badge
                  if (wallet != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Color(wallet.color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExpense ? CupertinoIcons.creditcard : CupertinoIcons.arrow_down_circle,
                            size: 11,
                            color: Color(wallet.color),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            wallet.name,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(wallet.color),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 4. Auto Mode badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: (item.autoExecute
                              ? AppleTokens.systemGreen
                              : AppleTokens.systemGray)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.autoExecute
                              ? CupertinoIcons.bolt_fill
                              : CupertinoIcons.hand_draw,
                          size: 11,
                          color: item.autoExecute
                              ? AppleTokens.systemGreen
                              : AppleTokens.systemGray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.autoExecute
                              ? (isExpense ? 'Tự động thanh toán' : 'Tự động nhận tiền')
                              : 'Thủ công',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: item.autoExecute
                                ? AppleTokens.systemGreen
                                : AppleTokens.systemGray,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 5. If Paused badge
                  if (isPaused)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppleTokens.systemGray.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.pause_fill,
                            size: 11,
                            color: AppleTokens.systemGray,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.recurringPause,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppleTokens.systemGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Bottom Action Button: If Due -> Mark Paid or Mark Received
              if (onExecute != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: AppleButton.primary(
                    color: isExpense ? AppleTokens.rubyExpense : AppleTokens.jadeDark,
                    label: isExpense ? l10n.recurringMarkPaid : l10n.recurringMarkReceived,
                    icon: Icon(
                      isExpense
                          ? CupertinoIcons.checkmark_alt
                          : CupertinoIcons.arrow_down_circle_fill,
                      size: 16,
                    ),
                    onPressed: onExecute,
                  ),
                ),
              ],

              // Quick Action Button: If Paused -> Quick Resume
              if (isPaused) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ApplePressable(
                    onTap: () => onTogglePause(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppleTokens.jadePrimary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        border: Border.all(
                          color: AppleTokens.jadePrimary.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.play_fill,
                            size: 11,
                            color: AppleTokens.jadePrimary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            l10n.recurringResume,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppleTokens.jadePrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
