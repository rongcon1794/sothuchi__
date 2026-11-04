import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/date_formatter.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/debts/domain/entities/debt.dart';
import 'package:so_thu_chi/features/debts/presentation/controllers/debts_controller.dart';
import 'package:so_thu_chi/features/debts/presentation/widgets/debt_form_sheet.dart';
import 'package:so_thu_chi/features/debts/presentation/widgets/debt_repayment_sheet.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  bool _isFabExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final debtsAsync = ref.watch(debtsStreamProvider);
    final filteredDebts = ref.watch(filteredDebtsProvider);
    final summary = ref.watch(debtSummaryProvider);
    final currentFilter = ref.watch(debtFilterModeProvider);

    return Scaffold(
      backgroundColor: isDark ? AppleTokens.bgDarkPrimary : AppleTokens.bgLightPrimary,
      appBar: AppBar(
        title: const Text('Sổ Ghi Nợ', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle_fill, color: AppleTokens.systemBlue, size: 28),
            tooltip: 'Thêm khoản nợ',
            onPressed: () {
              HapticFeedback.lightImpact();
              DebtFormSheet.show(context);
            },
          ),
        ],
      ),
      floatingActionButtonLocation: const AppleFloatingActionButtonLocation(),
      floatingActionButton: AppleAdaptiveExpandableFab(
        heroTag: 'debts_add_fab',
        isExpanded: _isFabExpanded,
        icon: const Icon(CupertinoIcons.plus),
        label: const Text('Ghi nợ mới'),
        backgroundColor: AppleTokens.jadeDark,
        onPressed: () {
          HapticFeedback.mediumImpact();
          DebtFormSheet.show(context);
        },
        tooltip: 'Ghi nợ mới',
      ),
      body: debtsAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (err, _) => Center(child: Text(context.localizeError(err))),
        data: (allDebts) {
          return NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.reverse && _isFabExpanded) {
                setState(() => _isFabExpanded = false);
              } else if (notification.direction == ScrollDirection.forward && !_isFabExpanded) {
                setState(() => _isFabExpanded = true);
              } else if (notification.metrics.pixels <= 30 && !_isFabExpanded) {
                setState(() => _isFabExpanded = true);
              }
              return false;
            },
            child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // Summary Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
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
                                      Text(
                                        'Người nợ tôi',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      summary.totalLent.format(locale: 'vi'),
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
                                      Text(
                                        'Tôi nợ người ta',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      summary.totalBorrowed.format(locale: 'vi'),
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
                            mode: mode.labelVi,
                        },
                        onChanged: (mode) {
                          ref
                              .read(debtFilterModeProvider.notifier)
                              .setMode(mode);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Empty State
              if (filteredDebts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
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
                                ? 'Chưa có khoản nợ nào được thanh toán hết'
                                : 'Không có khoản nợ nào',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ghi lại các khoản cho vay hoặc đi vay để luôn kiểm soát tốt dòng tiền của bạn.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                // Debts Inset Grouped List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final debt = filteredDebts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DebtCard(debt: debt),
                        );
                      },
                      childCount: filteredDebts.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppleTokens.scrollBottomPaddingWithFab),
              ),
            ],
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

    final isLent = debt.type == DebtType.lent;
    final accentColor = debt.isSettled
        ? AppleTokens.systemGray
        : (isLent ? AppleTokens.systemGreen : AppleTokens.systemOrange);

    final initials = debt.personName.trim().isNotEmpty
        ? debt.personName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';

    return AppleGlassCard(
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
                            isLent ? 'Cho vay' : 'Đi vay',
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
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.pencil, size: 16),
                        SizedBox(width: 8),
                        Text('Sửa thông tin'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.trash, size: 16, color: AppleTokens.systemRed),
                        SizedBox(width: 8),
                        Text('Xóa khoản nợ', style: TextStyle(color: AppleTokens.systemRed)),
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
                debt.isSettled ? 'Đã hoàn tất' : 'Còn lại:',
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
                    debt.remainingMoney.format(locale: 'vi'),
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
                  'Tổng nợ: ${debt.totalMoney.format(locale: 'vi')}',
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
                          : 'Hạn: ${AppDateUtils.formatVnDate(debt.dueDate!)}',
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
              'Ghi chú: ${debt.note}',
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
                      isLent ? 'Ghi nhận thu tiền nợ' : 'Ghi nhận trả bớt nợ',
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
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa khoản nợ của ${debt.personName}?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(debtsActionControllerProvider.notifier).deleteDebt(debt.id);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
