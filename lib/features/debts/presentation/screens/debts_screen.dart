import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
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

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  bool _isFabExpanded = true;
  bool _isFabVisible = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final debtsAsync = ref.watch(debtsStreamProvider);
    final filteredDebts = ref.watch(filteredDebtsProvider);
    final summary = ref.watch(debtSummaryProvider);
    final currentFilter = ref.watch(debtFilterModeProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final hideBalance = settings?.hideBalance ?? false;
    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;
    final appBarHeight = isLandscape
        ? AppleTokens.appBarHeightLandscape
        : AppleTokens.appBarHeightPortrait;
    final scrollBottomPadding = isWide
        ? AppleTokens.scrollBottomPaddingLandscape + 42
        : AppleTokens.scrollBottomPaddingWithFab;

    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: canPop ? 0 : 16,
        leading: canPop ? const AppleBackButton() : null,
        title: AppleHeaderTitle(
          title: l10n.debtBookTitle,
          isLandscape: isLandscape,
        ),
        actions: [
          AppleIconButton(
            icon: hideBalance ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
            size: isLandscape ? 32 : 36,
            iconSize: isLandscape ? 16 : 18,
            tooltip: hideBalance ? l10n.showBalance : l10n.hideBalance,
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              ref.read(settingsControllerProvider.notifier).toggleHideBalance();
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButtonLocation: const AppleFloatingActionButtonLocation(),
      floatingActionButton: AppleAdaptiveExpandableFab(
        heroTag: 'debts_add_fab',
        isVisible: _isFabVisible,
        isExpanded: _isFabExpanded,
        icon: const Icon(CupertinoIcons.plus),
        label: Text(l10n.debtNew),
        backgroundColor: AppleTokens.jadeDark,
        onPressed: () {
          HapticFeedback.mediumImpact();
          DebtFormSheet.show(context);
        },
        tooltip: l10n.debtNew,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: debtsAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (err, _) => Center(child: Text(context.localizeError(err))),
          data: (allDebts) {
            final activeCount = allDebts.where((d) => !d.isSettled).length;

            final summaryCardWidgets = <Widget>[
              // Unified Compact Summary Card
              _DebtSummaryCard(
                summary: summary,
                activeCount: activeCount,
                locale: locale,
                hideBalance: hideBalance,
              ),

              const SizedBox(height: 12),

              // Filter Segmented Pill
              AppleSegmentedPill<DebtFilterMode>(
                selected: currentFilter,
                segments: {
                  for (final mode in DebtFilterMode.values)
                    mode: mode.label(l10n),
                },
                onChanged: (mode) {
                  ref.read(debtFilterModeProvider.notifier).setMode(mode);
                },
              ),
            ];

            final debtListWidgets = <Widget>[
              // Consistent Section Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentFilter.label(l10n).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppleTokens.systemGray,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppleTokens.bgDarkSecondary
                            : AppleTokens.bgLightSecondary,
                        borderRadius: BorderRadius.circular(
                          AppleTokens.radiusPill,
                        ),
                      ),
                      child: Text(
                        '${filteredDebts.length} ${locale == 'vi' ? 'khoản' : (filteredDebts.length == 1 ? 'item' : 'items')}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppleTokens.systemGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (filteredDebts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 36,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.tray_fill,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentFilter == DebtFilterMode.settled
                              ? l10n.debtFilterSettled
                              : l10n.debtEmpty,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.debtEmptySubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final debt in filteredDebts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DebtCard(
                      debt: debt,
                      hideBalance: hideBalance,
                    ),
                  ),
            ];

            return NotificationListener<UserScrollNotification>(
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
                    setState(() => _isFabVisible = true);
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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1024),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      scrollBottomPadding,
                    ),
                    children: [
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 40,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: summaryCardWidgets,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 60,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: debtListWidgets,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        ...summaryCardWidgets,
                        const SizedBox(height: 14),
                        ...debtListWidgets,
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DebtSummaryCard extends StatelessWidget {
  const _DebtSummaryCard({
    required this.summary,
    required this.activeCount,
    required this.locale,
    required this.hideBalance,
  });

  final DebtSummary summary;
  final int activeCount;
  final String locale;
  final bool hideBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final netPositive = summary.netBalance.minorUnits >= 0;
    final netPrefix = summary.netBalance.minorUnits > 0 ? '+' : '';

    return AppleGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.10)
          : AppleTokens.borderLight,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryMetricColumn(
                      icon: CupertinoIcons.arrow_up_right,
                      label: l10n.debtSummaryLent,
                      amountText: summary.totalLent.format(
                        locale: locale,
                        masked: hideBalance,
                      ),
                      accentColor: AppleTokens.emeraldIncome,
                    ),
                  ),
                  VerticalDivider(
                    width: 24,
                    thickness: AppleTokens.hairline,
                    color: isDark
                        ? AppleTokens.separatorDark
                        : AppleTokens.separatorLight,
                  ),
                  Expanded(
                    child: _SummaryMetricColumn(
                      icon: CupertinoIcons.arrow_down_left,
                      label: l10n.debtSummaryBorrowed,
                      amountText: summary.totalBorrowed.format(
                        locale: locale,
                        masked: hideBalance,
                      ),
                      accentColor: AppleTokens.systemOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(
            height: AppleTokens.hairline,
            thickness: AppleTokens.hairline,
            color:
                isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        locale.startsWith('vi')
                            ? 'Chênh lệch ròng:'
                            : 'Net balance:',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '$netPrefix${summary.netBalance.format(locale: locale, masked: hideBalance)}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              fontFeatures: AppTheme.tabularFigures,
                              color: netPositive
                                  ? AppleTokens.emeraldIncome
                                  : AppleTokens.systemOrange,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (summary.overdueCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppleTokens.systemRed.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(
                          AppleTokens.radiusPill,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_triangle_fill,
                            size: 11,
                            color: AppleTokens.systemRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            locale.startsWith('vi')
                                ? '${summary.overdueCount} quá hạn'
                                : '${summary.overdueCount} overdue',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppleTokens.systemRed,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      locale.startsWith('vi')
                          ? '$activeCount đang theo dõi'
                          : '$activeCount active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetricColumn extends StatelessWidget {
  const _SummaryMetricColumn({
    required this.icon,
    required this.label,
    required this.amountText,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String amountText;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 12, color: accentColor),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            amountText,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: accentColor,
              fontFeatures: AppTheme.tabularFigures,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _DebtCard extends ConsumerWidget {
  const _DebtCard({
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
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      onTap: () => context.push(AppRoutes.debtDetail(debt.id)),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: debt.isSettled ? 0.72 : 1.0,
        child: AppleGlassCard(
          padding: const EdgeInsets.all(14),
          borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
          borderColor: debt.isOverdue
              ? AppleTokens.systemRed.withValues(alpha: isDark ? 0.55 : 0.45)
              : accentColor.withValues(alpha: isDark ? 0.35 : 0.22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row 1: Squircle Avatar + Person Info + Options Menu
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: isDark ? 0.24 : 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initialChar,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                debt.personName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.5,
                                  letterSpacing: -0.2,
                                  color:
                                      isDark ? Colors.white : Colors.black87,
                                ),
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
                                  alpha: isDark ? 0.22 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppleTokens.radiusPill,
                                ),
                              ),
                              child: Text(
                                debt.isSettled
                                    ? l10n.debtFilterSettled.toUpperCase()
                                    : (isLent
                                        ? l10n.debtLent.toUpperCase()
                                        : l10n.debtBorrowed.toUpperCase()),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          debt.phoneNumber?.isNotEmpty == true
                              ? debt.phoneNumber!
                              : (isLent
                                ? (locale.startsWith('vi') ? 'Khoản cho vay' : 'Lent')
                                : (locale.startsWith('vi') ? 'Khoản đi vay' : 'Borrowed')),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ApplePopupMenuButton<String>(
                    icon: CupertinoIcons.ellipsis_circle,
                    iconSize: 18,
                    size: 32,
                    tooltip: l10n.moreOptions,
                    onSelected: (val) {
                      if (val == 'edit') {
                        DebtFormSheet.show(context, initialDebt: debt);
                      } else if (val == 'delete') {
                        _confirmDelete(context, ref);
                      }
                    },
                    itemBuilder: (_) => [
                      ApplePopupMenuItem(
                        value: 'edit',
                        icon: CupertinoIcons.pencil,
                        title: l10n.debtEdit,
                      ),
                      ApplePopupMenuItem(
                        value: 'delete',
                        icon: CupertinoIcons.trash,
                        title: l10n.debtDelete,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(
                height: AppleTokens.hairline,
                thickness: AppleTokens.hairline,
                color: isDark
                    ? AppleTokens.separatorDark
                    : AppleTokens.separatorLight,
              ),
              const SizedBox(height: 10),

              // Row 2: Amount + Due Date / Wallet / Quick Action
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasPartialPayment
                              ? (locale.startsWith('vi') ? 'CÒN LẠI' : 'REMAINING')
                              : l10n.amount.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
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
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              fontFeatures: AppTheme.tabularFigures,
                              color: debt.isSettled
                                  ? AppleTokens.systemGray
                                  : (isDark
                                      ? Colors.white
                                      : const Color(0xFF1C1C1E)),
                            ),
                          ),
                        ),
                        if (hasPartialPayment) ...[
                          const SizedBox(height: 2),
                          Text(
                            locale.startsWith('vi')
                                ? 'Tổng ${debt.totalMoney.format(locale: locale, masked: hideBalance)} • Đã trả $paidPercent%'
                                : 'Total ${debt.totalMoney.format(locale: locale, masked: hideBalance)} • Paid $paidPercent%',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFeatures: AppTheme.tabularFigures,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ] else if (debt.isSettled) ...[
                          const SizedBox(height: 2),
                          Text(
                            locale.startsWith('vi')
                                ? 'Đã tất toán xong'
                                : 'Settled',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppleTokens.systemGray,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (debt.dueDate != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              debt.isOverdue
                                  ? CupertinoIcons.exclamationmark_circle_fill
                                  : CupertinoIcons.calendar,
                              size: 11,
                              color: debt.isOverdue
                                  ? AppleTokens.systemRed
                                  : accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              debt.isOverdue
                                  ? '${locale.startsWith('vi') ? 'Quá hạn' : 'Overdue'} ${AppDateUtils.formatShortDate(debt.dueDate!, locale: locale)}'
                                  : '${locale.startsWith('vi') ? 'Hạn' : 'Due'} ${AppDateUtils.formatShortDate(debt.dueDate!, locale: locale)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: debt.isOverdue
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: debt.isOverdue
                                    ? AppleTokens.systemRed
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      if (wallet != null) ...[
                        if (debt.dueDate != null) const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Color(wallet.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              wallet.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(wallet.color),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (debt.dueDate != null || wallet != null)
                        const SizedBox(height: 6),
                      if (!debt.isSettled)
                        ApplePressable(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            DebtRepaymentSheet.show(context, debt);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 5.5,
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
                                  size: 13.5,
                                  color: accentColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isLent ? l10n.debtCollect : l10n.debtRepay,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppleTokens.emeraldIncome.withValues(alpha: 0.12),
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
                                  fontSize: 11.5,
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

              if (debt.progress > 0 && !debt.isSettled) ...[
                const SizedBox(height: 8),
                LucianProgressBar(
                  value: debt.progress,
                  height: 4.5,
                  activeColor: accentColor,
                  showGlow: false,
                ),
              ],

              if (debt.note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '"${debt.note}"',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.debtDeleteConfirmTitle),
        content: Text(l10n.debtDeleteConfirmBody(debt.personName)),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(debtsActionControllerProvider.notifier).deleteDebt(debt.id);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
