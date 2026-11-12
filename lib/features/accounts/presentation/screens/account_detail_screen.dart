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
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/accounts/presentation/widgets/wallet_form_sheet.dart';
import 'package:so_thu_chi/features/categories/presentation/controllers/categories_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({
    super.key,
    required this.accountId,
  });

  final String accountId;

  String _typeLabel(AppLocalizations l10n, AccountType type) => switch (type) {
    AccountType.cash => l10n.walletTypeCash,
    AccountType.bank => l10n.walletTypeBank,
    AccountType.ewallet => l10n.walletTypeEwallet,
    AccountType.card => l10n.walletTypeCard,
  };

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Account account) async {
    final l10n = context.l10n;
    final isVi = l10n.localeName.startsWith('vi');
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('${l10n.delete} ${account.name}'),
        message: Text(
          isVi
              ? 'Bạn có chắc chắn muốn xóa ví này? Giao dịch liên quan sẽ không bị mất.'
              : 'Are you sure you want to delete this wallet? Related transactions will not be lost.',
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
      final res = await ref.read(accountsActionControllerProvider.notifier).deleteWallet(account.id);
      if (!context.mounted) return;
      await res.fold(
        onSuccess: (_) async {
          final settings = ref.read(settingsControllerProvider).value;
          if (settings?.defaultWalletId == account.id) {
            final otherAccounts = ref
                .read(accountsStreamProvider)
                .value
                ?.where((a) => a.id != account.id && a.deletedAt == null)
                .toList();
            final nextDefaultId =
                (otherAccounts != null && otherAccounts.isNotEmpty)
                    ? otherAccounts.first.id
                    : null;
            await ref
                .read(settingsControllerProvider.notifier)
                .setDefaultWalletId(nextDefaultId);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isVi
                      ? 'Đã xóa ví "${account.name}"'
                      : 'Deleted wallet "${account.name}"',
                ),
              ),
            );
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
        },
        onFailure: (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.localizeError(err))),
          );
        },
      );
    }
  }

  Future<void> _handleToggleArchive(BuildContext context, WidgetRef ref, Account account) async {
    unawaited(HapticFeedback.lightImpact());
    final res = await ref
        .read(accountsActionControllerProvider.notifier)
        .toggleArchive(accountId: account.id, archived: !account.archived);
    if (!context.mounted) return;
    res.fold(
      onSuccess: (_) {},
      onFailure: (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.localizeError(err))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLandscape = context.isLandscape;
    final isWide = context.isWideScreen;

    final accountsAsync = ref.watch(accountsStreamProvider);
    final allTxs = ref.watch(transactionsStreamProvider).value ?? const <TransactionEntity>[];
    final categoriesMap = ref.watch(categoriesMapProvider);
    final accountsMap = ref.watch(accountsMapProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final hideBalance = settings?.hideBalance ?? false;

    return accountsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CupertinoActivityIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.localizeError(err))),
      ),
      data: (accounts) {
        final account = accounts.where((a) => a.id == accountId).firstOrNull;
        if (account == null) {
          return Scaffold(
            appBar: AppBar(),
            body: SafeArea(
              top: false,
              bottom: false,
              child: Center(
                child: Text(
                  l10n.emptyWalletsTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          );
        }

        final walletColor = AppIconCatalog.contrastSafeColor(
          Color(account.color),
          theme.brightness,
        );

        // Filter transactions for this wallet
        final walletTxs = allTxs
            .where((t) => t.accountId == account.id || t.toAccountId == account.id)
            .toList(growable: false);

        // Calculate wallet statistics
        var totalIncomeMinor = 0;
        var totalExpenseMinor = 0;
        for (final tx in walletTxs) {
          if (tx.currency != account.currency) continue;
          if (tx.type == TransactionType.income) {
            totalIncomeMinor += tx.amount;
          } else if (tx.type == TransactionType.expense) {
            totalExpenseMinor += tx.amount;
          } else if (tx.type == TransactionType.transfer) {
            if (tx.accountId == account.id) {
              totalExpenseMinor += tx.amount;
            } else if (tx.toAccountId == account.id) {
              totalIncomeMinor += tx.amount;
            }
          }
        }

        final incomeMoney = Money(minorUnits: totalIncomeMinor, currencyCode: account.currency);
        final expenseMoney = Money(minorUnits: totalExpenseMinor, currencyCode: account.currency);
        final netMoney = Money(minorUnits: totalIncomeMinor - totalExpenseMinor, currencyCode: account.currency);

        final isDefault = ref.watch(
          settingsControllerProvider.select((s) => s.value?.defaultWalletId == account.id),
        );

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
              account.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              ApplePopupMenuButton<String>(
                tooltip: l10n.moreOptions,
                onSelected: (val) async {
                  if (val == 'edit') {
                    await WalletFormSheet.show(context, existing: account);
                  } else if (val == 'set_default') {
                    unawaited(HapticFeedback.mediumImpact());
                    await ref.read(settingsControllerProvider.notifier).setDefaultWalletId(account.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            locale.startsWith('vi')
                                ? 'Đã chọn "${account.name}" làm ví mặc định chi tiêu'
                                : 'Selected "${account.name}" as default spending wallet',
                          ),
                        ),
                      );
                    }
                  } else if (val == 'archive') {
                    await _handleToggleArchive(context, ref, account);
                  } else if (val == 'delete') {
                    await _handleDelete(context, ref, account);
                  }
                },
                itemBuilder: (_) => [
                  if (!isDefault)
                    ApplePopupMenuItem(
                      value: 'set_default',
                      icon: CupertinoIcons.star_fill,
                      title: locale.startsWith('vi')
                          ? 'Đặt làm ví mặc định'
                          : 'Set as default wallet',
                    ),
                  ApplePopupMenuItem(
                    value: 'edit',
                    icon: CupertinoIcons.pencil,
                    title: l10n.edit,
                  ),
                  ApplePopupMenuItem(
                    value: 'archive',
                    icon: account.archived
                        ? CupertinoIcons.arrow_counterclockwise
                        : CupertinoIcons.archivebox,
                    title: account.archived ? l10n.unarchiveWallet : l10n.archiveWallet,
                  ),
                  ApplePopupMenuItem(
                    value: 'delete',
                    icon: CupertinoIcons.trash,
                    title: l10n.delete,
                    isDestructive: true,
                  ),
                ],
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
                  // Hero Card: Wallet Emblem, Balance & Status
                  AppleGlassCard(
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    padding: const EdgeInsets.all(16),
                    borderColor: walletColor.withValues(alpha: 0.3),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [walletColor.withValues(alpha: 0.18), Colors.black45]
                          : [walletColor.withValues(alpha: 0.10), Colors.white],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row: Squircle Emblem + Info & Badges + Eye toggle
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: walletColor.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                                border: Border.all(
                                  color: walletColor.withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                AppIconCatalog.resolve(account.icon),
                                color: walletColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          account.name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            decoration: account.archived ? TextDecoration.lineThrough : null,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (account.archived) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppleTokens.systemGray.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                          ),
                                          child: Text(
                                            l10n.archivedWallets,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                      if (isDefault) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFB800).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                            border: Border.all(
                                              color: const Color(0xFFFFB800).withValues(alpha: 0.5),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFFB800)),
                                              const SizedBox(width: 3),
                                              Text(
                                                locale.startsWith('vi') ? 'Mặc định' : 'Default',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFFFFB800),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_typeLabel(l10n, account.type)} • ${account.currency}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              tooltip: hideBalance ? l10n.showBalance : l10n.hideBalance,
                              icon: Icon(
                                hideBalance ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                                size: 19,
                              ),
                              onPressed: () => ref.read(settingsControllerProvider.notifier).toggleHideBalance(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Current Balance Section
                        Text(
                          l10n.currentBalance,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account.balanceMoney.format(locale: locale, masked: hideBalance),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontFeatures: AppTheme.tabularFigures,
                            color: walletColor,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Real-Time 14-Day Balance Trend Sparkline with Touch Scrubbing
                        _WalletBalanceTrendSparkline(
                          account: account,
                          walletTxs: walletTxs,
                          walletColor: walletColor,
                          locale: locale,
                          hideBalance: hideBalance,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        // Cashflow Tri-Stat Strip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.28)
                                : Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.income,
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppleTokens.systemGray),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      incomeMoney.format(locale: locale, masked: hideBalance),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppleTokens.emeraldIncome,
                                        fontFeatures: AppTheme.tabularFigures,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 22, color: AppleTokens.separatorLight),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.expense,
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppleTokens.systemGray),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      expenseMoney.format(locale: locale, masked: hideBalance),
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppleTokens.rubyExpense,
                                        fontFeatures: AppTheme.tabularFigures,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 22, color: AppleTokens.separatorLight),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.netBalance,
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppleTokens.systemGray),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      netMoney.format(locale: locale, masked: hideBalance),
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: netMoney.minorUnits >= 0 ? AppleTokens.emeraldIncome : AppleTokens.rubyExpense,
                                        fontFeatures: AppTheme.tabularFigures,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                            ),
                          ),
                          icon: const Icon(CupertinoIcons.plus_circle, size: 18),
                          label: Text(
                            l10n.quickAddTransaction,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          onPressed: () {
                            context.push(
                              AppRoutes.transactionNew,
                              extra: TransactionDraft(
                                accountId: account.id,
                                currencyCode: account.currency,
                              ),
                            );
                          },
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
                        icon: const Icon(CupertinoIcons.pencil, size: 18),
                        label: Text(
                          l10n.edit,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                        onPressed: () => WalletFormSheet.show(context, existing: account),
                      ),
                      const SizedBox(width: 10),
                      IconButton.outlined(
                        tooltip: l10n.delete,
                        style: IconButton.styleFrom(
                          side: BorderSide(
                            color: AppleTokens.systemRed.withValues(alpha: isDark ? 0.4 : 0.25),
                          ),
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                          ),
                        ),
                        icon: const Icon(
                          CupertinoIcons.trash,
                          color: AppleTokens.systemRed,
                          size: 18,
                        ),
                        onPressed: () => _handleDelete(context, ref, account),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Transaction History Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${l10n.transactionsTitle} (${walletTxs.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Transaction History List
                  if (walletTxs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: EmptyStateView(
                        icon: CupertinoIcons.tray,
                        title: locale.startsWith('vi')
                            ? 'Chưa có giao dịch trên ví này'
                            : 'No transactions on this wallet yet',
                        subtitle: locale.startsWith('vi')
                            ? 'Mọi giao dịch thu/chi hoặc chuyển tiền liên quan đến ${account.name} sẽ hiển thị ở đây.'
                            : 'All income, expense, or transfer transactions for ${account.name} will appear here.',
                        actionLabel: l10n.quickAddTransaction,
                        onAction: () {
                          context.push(
                            AppRoutes.transactionNew,
                            extra: TransactionDraft(
                              accountId: account.id,
                              currencyCode: account.currency,
                            ),
                          );
                        },
                      ),
                    )
                  else
                    AppleGlassCard(
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                      child: Column(
                        children: [
                          for (var i = 0; i < walletTxs.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: AppleTokens.hairline,
                                indent: 68,
                                color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                              ),
                            TransactionTile(
                              transaction: walletTxs[i],
                              category: categoriesMap[walletTxs[i].categoryId],
                              sourceAccount: accountsMap[walletTxs[i].accountId],
                              destinationAccount: walletTxs[i].toAccountId != null
                                  ? accountsMap[walletTxs[i].toAccountId!]
                                  : null,
                              locale: locale,
                              hideAmount: hideBalance,
                              showDate: true,
                              onTap: () => context.push(
                                AppRoutes.transactionDetail(walletTxs[i].id),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
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

class _WalletPoint {
  const _WalletPoint({
    required this.date,
    required this.balanceMinor,
    required this.normalizedY,
  });

  final DateTime date;
  final double balanceMinor;
  final double normalizedY;
}

class _WalletBalanceTrendSparkline extends StatefulWidget {
  const _WalletBalanceTrendSparkline({
    required this.account,
    required this.walletTxs,
    required this.walletColor,
    required this.locale,
    required this.hideBalance,
    required this.isDark,
  });

  final Account account;
  final List<TransactionEntity> walletTxs;
  final Color walletColor;
  final String locale;
  final bool hideBalance;
  final bool isDark;

  @override
  State<_WalletBalanceTrendSparkline> createState() =>
      _WalletBalanceTrendSparklineState();
}

class _WalletBalanceTrendSparklineState
    extends State<_WalletBalanceTrendSparkline> {
  int? _scrubbedIndex;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _onScrub(double localX, double totalWidth, int count) {
    if (totalWidth <= 0 || count <= 1) return;
    _resetTimer?.cancel();
    final clampedX = localX.clamp(0.0, totalWidth);
    final index =
        ((clampedX / totalWidth) * (count - 1)).round().clamp(0, count - 1);
    if (index != _scrubbedIndex) {
      HapticFeedback.selectionClick();
      setState(() => _scrubbedIndex = index);
    }
  }

  void _scheduleReset() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _scrubbedIndex = null);
    });
  }

  List<_WalletPoint> _buildPoints() {
    final now = DateTime.now();
    final days = List.generate(
      14,
      (i) => DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 13 - i)),
    );

    final currencyTxs = widget.walletTxs
        .where((tx) => tx.currency == widget.account.currency)
        .toList(growable: false);

    final currentBalanceMinor = widget.account.balance.toDouble();
    final rawBalances = <double>[];

    for (final day in days) {
      final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
      var futureNet = 0.0;
      for (final tx in currencyTxs) {
        if (tx.date.isAfter(endOfDay)) {
          if (tx.type == TransactionType.income) {
            futureNet += tx.amount;
          } else if (tx.type == TransactionType.expense) {
            futureNet -= tx.amount;
          } else if (tx.type == TransactionType.transfer) {
            if (tx.accountId == widget.account.id) {
              futureNet -= tx.amount;
            } else if (tx.toAccountId == widget.account.id) {
              futureNet += tx.amount;
            }
          }
        }
      }
      rawBalances.add(currentBalanceMinor - futureNet);
    }

    final minVal = rawBalances.reduce(math.min);
    final maxVal = rawBalances.reduce(math.max);

    return List.generate(rawBalances.length, (i) {
      final b = rawBalances[i];
      final double normY;
      if (minVal == maxVal) {
        normY = 0.5;
      } else {
        final ratio = (b - minVal) / (maxVal - minVal);
        normY = 0.15 + (0.70 * ratio);
      }
      return _WalletPoint(
        date: days[i],
        balanceMinor: b,
        normalizedY: normY,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final points = _buildPoints();
    final scrubbedPoint = (_scrubbedIndex != null &&
            _scrubbedIndex! >= 0 &&
            _scrubbedIndex! < points.length)
        ? points[_scrubbedIndex!]
        : null;

    final firstBalance = points.first.balanceMinor;
    final lastBalance = points.last.balanceMinor;
    final delta = lastBalance - firstBalance;

    final isVi = widget.locale.toLowerCase().startsWith('vi');
    final String trendLabel;
    final Color trendColor;
    if (delta > 0) {
      final pct = firstBalance > 0
          ? ((delta / firstBalance) * 100).round()
          : 100;
      trendLabel = isVi ? '+$pct% trong 14 ngày' : '+$pct% in 14 days';
      trendColor = AppleTokens.emeraldIncome;
    } else if (delta < 0) {
      final pct = firstBalance > 0
          ? ((delta.abs() / firstBalance) * 100).round()
          : 100;
      trendLabel = isVi ? '-$pct% trong 14 ngày' : '-$pct% in 14 days';
      trendColor = AppleTokens.rubyExpense;
    } else {
      trendLabel = isVi ? 'Số dư ổn định 14 ngày' : 'Stable balance (14d)';
      trendColor = widget.walletColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status Row (Scrubbing info OR 14-day delta)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (scrubbedPoint != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.calendar,
                      size: 12, color: widget.walletColor),
                  const SizedBox(width: 4),
                  Text(
                    '${scrubbedPoint.date.day.toString().padLeft(2, '0')}/${scrubbedPoint.date.month.toString().padLeft(2, '0')}: ',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: widget.walletColor,
                    ),
                  ),
                  Text(
                    Money(
                      minorUnits: scrubbedPoint.balanceMinor.round(),
                      currencyCode: widget.account.currency,
                    ).format(locale: widget.locale, masked: widget.hideBalance),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFeatures: AppTheme.tabularFigures,
                      color: widget.walletColor,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                isVi ? 'Biến động 14 ngày qua' : '14-day balance trend',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:
                    trendColor.withValues(alpha: widget.isDark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                border: Border.all(
                  color: trendColor.withValues(alpha: 0.35),
                  width: AppleTokens.hairline,
                ),
              ),
              child: Text(
                trendLabel,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: trendColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Interactive Scrubbing Chart Canvas
        SizedBox(
          height: 40,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (d) => _onScrub(
                    d.localPosition.dx, constraints.maxWidth, points.length),
                onHorizontalDragUpdate: (d) => _onScrub(
                    d.localPosition.dx, constraints.maxWidth, points.length),
                onHorizontalDragEnd: (_) => _scheduleReset(),
                onTapDown: (d) => _onScrub(
                    d.localPosition.dx, constraints.maxWidth, points.length),
                onTapUp: (_) => _scheduleReset(),
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _WalletDetailSparklinePainter(
                      points: points.map((p) => p.normalizedY).toList(growable: false),
                      color: widget.walletColor,
                      selectedIndex: _scrubbedIndex,
                      isDark: widget.isDark,
                    ),
                    size: Size.infinite,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WalletDetailSparklinePainter extends CustomPainter {
  const _WalletDetailSparklinePainter({
    required this.points,
    required this.color,
    required this.isDark,
    this.selectedIndex,
  });

  final List<double> points;
  final Color color;
  final bool isDark;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final width = size.width;
    final height = size.height;
    final stepX = width / (points.length - 1);

    final List<Offset> coords = [];
    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = height - (points[i].clamp(0.08, 0.92) * height);
      coords.add(Offset(x, y));
    }

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: isDark ? 0.28 : 0.20),
          color.withValues(alpha: 0.01),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.75 : 0.65)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    final fillPath = Path();

    linePath.moveTo(coords[0].dx, coords[0].dy);
    fillPath.moveTo(coords[0].dx, height);
    fillPath.lineTo(coords[0].dx, coords[0].dy);

    for (var i = 0; i < coords.length - 1; i++) {
      final p0 = coords[i];
      final p1 = coords[i + 1];
      final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY1 = p0.dy;
      final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY2 = p1.dy;

      linePath.cubicTo(
          controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
      fillPath.cubicTo(
          controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
    }

    fillPath.lineTo(coords.last.dx, height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    // If scrubbed, draw vertical guide line and indicator
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < coords.length) {
      final active = coords[selectedIndex!];
      final cursorPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.25)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
          Offset(active.dx, 0), Offset(active.dx, height), cursorPaint);

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      final pointPaint = Paint()
        ..color = isDark ? Colors.white : color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(active, 5.0, glowPaint);
      canvas.drawCircle(active, 3.0, pointPaint);
    } else {
      // Latest point dot
      final last = coords.last;
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;
      final pointPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(last, 4.0, glowPaint);
      canvas.drawCircle(last, 2.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WalletDetailSparklinePainter oldDelegate) {
    if (oldDelegate.color != color ||
        oldDelegate.isDark != isDark ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.points.length != points.length) {
      return true;
    }
    for (var i = 0; i < points.length; i++) {
      if (oldDelegate.points[i] != points[i]) return true;
    }
    return false;
  }
}

