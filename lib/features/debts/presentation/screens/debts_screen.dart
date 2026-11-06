import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/debts/domain/entities/debt.dart';
import 'package:so_thu_chi/features/debts/presentation/controllers/debts_controller.dart';
import 'package:so_thu_chi/features/debts/presentation/widgets/debt_form_sheet.dart';
import 'package:so_thu_chi/features/debts/presentation/widgets/debt_repayment_sheet.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';

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
    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;
    final appBarHeight = isLandscape
        ? AppleTokens.appBarHeightLandscape
        : AppleTokens.appBarHeightPortrait;
    final scrollBottomPadding = isWide
        ? AppleTokens.scrollBottomPaddingLandscape + 42
        : AppleTokens.scrollBottomPaddingWithFab;

    return Scaffold(
      backgroundColor: isDark ? AppleTokens.bgDarkPrimary : AppleTokens.bgLightPrimary,
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
      body: debtsAsync.when(
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

    final isLent = debt.type == DebtType.lent;
    final accentColor = debt.isSettled
        ? AppleTokens.systemGray
        : (isLent ? AppleTokens.systemGreen : AppleTokens.systemOrange);

    final initials = debt.personName.trim().isNotEmpty
        ? debt.personName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';

    return ApplePressable(
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      onTap: () => context.push(AppRoutes.debtDetail(debt.id)),
      child: AppleGlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        borderColor: debt.isOverdue
            ? AppleTokens.systemRed.withValues(alpha: 0.5)
            : (isDark ? AppleTokens.bgDarkSecondary : AppleTokens.borderLight),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Person Initials Squircle Avatar
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                ),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Person Name & Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            debt.personName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          ),
                          child: Text(
                            isLent ? l10n.debtLent : l10n.debtBorrowed,
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (debt.phoneNumber != null && debt.phoneNumber!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        debt.phoneNumber!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Options Popover Menu
              PopupMenuButton<String>(
                icon: const Icon(CupertinoIcons.ellipsis_circle, size: 20),
                onSelected: (val) {
                  if (val == 'edit') {
                    DebtFormSheet.show(context, initialDebt: debt);
                  } else if (val == 'delete') {
                    _confirmDelete(context, ref);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.pencil, size: 16),
                        const SizedBox(width: 8),
                        Text(l10n.debtEdit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.trash, size: 16, color: AppleTokens.systemRed),
                        const SizedBox(width: 8),
                        Text(l10n.debtDelete, style: const TextStyle(color: AppleTokens.systemRed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Amounts & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                debt.isSettled ? l10n.debtFilterSettled : '${l10n.debtRemaining}:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    debt.remainingMoney.format(locale: locale),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Repayment Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            child: LinearProgressIndicator(
              value: debt.progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),

          const SizedBox(height: 6),

          // Total & Due Date Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${l10n.amount}: ${debt.totalMoney.format(locale: locale)}',
                  style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (debt.dueDate != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      debt.isOverdue ? CupertinoIcons.exclamationmark_circle_fill : CupertinoIcons.calendar,
                      size: 12,
                      color: debt.isOverdue ? AppleTokens.systemRed : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      debt.isOverdue
                          ? 'Quá hạn: ${AppDateUtils.formatVnDate(debt.dueDate!)}'
                          : l10n.debtDueDate(AppDateUtils.formatVnDate(debt.dueDate!)),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: debt.isOverdue ? FontWeight.w700 : FontWeight.normal,
                        color: debt.isOverdue ? AppleTokens.systemRed : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          if (debt.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.note}: ${debt.note}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Quick Repay Button if not yet settled
          if (!debt.isSettled) ...[
            const SizedBox(height: 12),
            ApplePressable(
              onTap: () {
                HapticFeedback.lightImpact();
                DebtRepaymentSheet.show(context, debt);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.3),
                    width: AppleTokens.hairline,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLent ? CupertinoIcons.arrow_down_circle_fill : CupertinoIcons.arrow_up_circle_fill,
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
