import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
    final l10n = context.l10n;
    final debtsAsync = ref.watch(debtsStreamProvider);
    final filteredDebts = ref.watch(filteredDebtsProvider);
    final summary = ref.watch(debtSummaryProvider);
    final currentFilter = ref.watch(debtFilterModeProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;
    final appBarHeight = isLandscape
        ? AppleTokens.appBarHeightLandscape
        : AppleTokens.appBarHeightPortrait;
    final scrollBottomPadding = isWide
        ? AppleTokens.scrollBottomPaddingLandscape + 42
        : AppleTokens.scrollBottomPaddingWithFab;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        title: Text(l10n.debtBookTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          final summaryCardWidgets = <Widget>[
            // Top Dual Stats (Cho vay vs Đi vay)
            Row(
              children: [
                Expanded(
                  child: AppleGlassCard(
                    padding: const EdgeInsets.all(14),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    borderColor: AppleTokens.systemGreen.withValues(alpha: 0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const AppleSquircleBadge(
                              icon: CupertinoIcons.arrow_up_right,
                              color: AppleTokens.systemGreen,
                              size: 26,
                              iconSize: 15,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.debtSummaryLent,
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
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            summary.totalLent.format(locale: locale),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppleTokens.systemGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppleGlassCard(
                    padding: const EdgeInsets.all(14),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    borderColor: AppleTokens.systemOrange.withValues(alpha: 0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const AppleSquircleBadge(
                              icon: CupertinoIcons.arrow_down_left,
                              color: AppleTokens.systemOrange,
                              size: 26,
                              iconSize: 15,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.debtSummaryBorrowed,
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
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            summary.totalBorrowed.format(locale: locale),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppleTokens.systemOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Overdue Alert Banner
            if (summary.overdueCount > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppleTokens.systemRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                  border: Border.all(
                    color: AppleTokens.systemRed.withValues(alpha: 0.3),
                    width: AppleTokens.hairline,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: AppleTokens.systemRed, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Có ${summary.overdueCount} khoản nợ đã đến hạn cần thanh toán!',
                        style: const TextStyle(
                          color: AppleTokens.systemRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Filter Segmented Pill
            AppleSegmentedPill<DebtFilterMode>(
              selected: currentFilter,
              segments: {
                for (final mode in DebtFilterMode.values)
                  mode: mode.label(l10n),
              },
              onChanged: (mode) {
                ref
                    .read(debtFilterModeProvider.notifier)
                    .setMode(mode);
              },
            ),
          ];

          final debtListWidgets = <Widget>[
            if (filteredDebts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.tray_fill,
                        size: 54,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
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
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final debt in filteredDebts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DebtCard(debt: debt),
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
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.fromLTRB(16, 8, 16, scrollBottomPadding),
                  children: [
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 42,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: summaryCardWidgets,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 58,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: debtListWidgets,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      ...summaryCardWidgets,
                      const SizedBox(height: 12),
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

class _DebtCard extends ConsumerWidget {
  const _DebtCard({required this.debt});

  final Debt debt;

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

    final initials = debt.personName.trim().isNotEmpty
        ? debt.personName
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    return ApplePressable(
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      onTap: () => context.push(AppRoutes.debtDetail(debt.id)),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: debt.isSettled ? 0.72 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      accentColor.withValues(alpha: 0.22),
                      accentColor.withValues(alpha: 0.08),
                      AppleTokens.bgDarkCard,
                    ]
                  : [
                      accentColor.withValues(alpha: 0.14),
                      accentColor.withValues(alpha: 0.05),
                      Colors.white,
                    ],
            ),
            borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
            border: Border.all(
              color: debt.isOverdue
                  ? AppleTokens.systemRed.withValues(alpha: isDark ? 0.6 : 0.45)
                  : accentColor.withValues(alpha: isDark ? 0.40 : 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Avatar, Name & Subtitle, Type Badge, Popup Menu
              Row(
                children: [
                  // 44x44 Squircle Avatar Badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor,
                          accentColor.withValues(alpha: 0.75),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(AppleTokens.radiusControl),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Person Name & Contact / Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                debt.personName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Type Badge Pill: CHO VAY / ĐI VAY / ĐÃ XONG
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: accentColor
                                    .withValues(alpha: isDark ? 0.28 : 0.15),
                                borderRadius: BorderRadius.circular(
                                    AppleTokens.radiusPill),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                debt.isSettled
                                    ? l10n.debtFilterSettled.toUpperCase()
                                    : (isLent
                                        ? l10n.debtLent.toUpperCase()
                                        : l10n.debtBorrowed.toUpperCase()),
                                style: TextStyle(
                                  fontSize: 10,
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
                              : (isLent ? 'Khoản cho vay' : 'Khoản đi vay'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Options Popover Menu
                  ApplePopupMenuButton<String>(
                    icon: CupertinoIcons.ellipsis_circle,
                    iconSize: 18,
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

              // Amount Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      debt.isSettled
                          ? 'ĐÃ TẤT TOÁN XONG'
                          : (debt.remainingAmount < debt.amount
                              ? 'CÒN LẠI (${(debt.progress * 100).toInt()}% ĐÃ TRẢ)'
                              : l10n.amount.toUpperCase()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                  if (debt.remainingAmount < debt.amount && !debt.isSettled) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Tổng: ${debt.totalMoney.format(locale: locale)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  debt.remainingMoney.format(locale: locale),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    fontFeatures: AppTheme.tabularFigures,
                    color: debt.isSettled
                        ? AppleTokens.systemGray
                        : (isDark ? Colors.white : const Color(0xFF1C1C1E)),
                  ),
                ),
              ),

              // Repayment Progress Bar (only if partial payment made)
              if (debt.progress > 0 && !debt.isSettled) ...[
                const SizedBox(height: 6),
                LucianProgressBar(
                  value: debt.progress,
                  height: 6,
                  activeColor: accentColor,
                  showGlow: false,
                ),
              ],

              const SizedBox(height: 10),

              // Metadata Pills Wrap (Due date, Wallet, Note snippet)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  // Due Date Chip
                  if (debt.dueDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: debt.isOverdue
                            ? AppleTokens.systemRed.withValues(alpha: 0.16)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04)),
                        borderRadius:
                            BorderRadius.circular(AppleTokens.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            debt.isOverdue
                                ? CupertinoIcons.exclamationmark_circle_fill
                                : CupertinoIcons.calendar,
                            size: 11,
                            color: debt.isOverdue
                                ? AppleTokens.systemRed
                                : (isDark ? Colors.white70 : Colors.black54),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            debt.isOverdue
                                ? 'Quá hạn: ${AppDateUtils.formatShortDate(debt.dueDate!, locale: locale)}'
                                : 'Hạn: ${AppDateUtils.formatShortDate(debt.dueDate!, locale: locale)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: debt.isOverdue
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: debt.isOverdue
                                  ? AppleTokens.systemRed
                                  : (isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Wallet Chip
                  if (wallet != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(wallet.color).withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppleTokens.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.creditcard_fill,
                            size: 11,
                            color: Color(wallet.color),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            wallet.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(wallet.color),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Note Snippet Chip
                  if (debt.note.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.04),
                        borderRadius:
                            BorderRadius.circular(AppleTokens.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.doc_text,
                            size: 11,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          const SizedBox(width: 4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(
                              debt.note,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Quick Repay Button if not yet settled
              if (!debt.isSettled) ...[
                const SizedBox(height: 12),
                ApplePressable(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    DebtRepaymentSheet.show(context, debt);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          accentColor.withValues(alpha: isDark ? 0.22 : 0.14),
                      borderRadius:
                          BorderRadius.circular(AppleTokens.radiusPill),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLent
                              ? CupertinoIcons.arrow_down_circle_fill
                              : CupertinoIcons.arrow_up_circle_fill,
                          size: 15,
                          color: accentColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isLent ? l10n.debtCollect : l10n.debtRepay,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
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
