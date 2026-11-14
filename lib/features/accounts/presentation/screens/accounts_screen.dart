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
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/core/widgets/skeleton_box.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/accounts/presentation/widgets/transfer_between_wallets_sheet.dart';
import 'package:so_thu_chi/features/accounts/presentation/widgets/wallet_form_sheet.dart';
import 'package:so_thu_chi/features/accounts/presentation/widgets/wallet_list_tile.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

/// Redesigned Apple HIG & Lucian Accounts/Wallets Management Screen.
/// Synchronized with dynamic ambient background, frosted glass cards,
/// asset distribution telemetry, and fluid responsive grid.
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  bool _isFabExpanded = true;
  bool _isFabVisible = true;
  AccountType? _selectedTypeFilter;

  String _typeLabel(AppLocalizations l10n, AccountType type) => switch (type) {
    AccountType.cash => l10n.walletTypeCash,
    AccountType.bank => l10n.walletTypeBank,
    AccountType.ewallet => l10n.walletTypeEwallet,
    AccountType.card => l10n.walletTypeCard,
  };

  void _openWalletForm(BuildContext context, {Account? existing}) {
    unawaited(HapticFeedback.lightImpact());
    WalletFormSheet.show(context, existing: existing);
  }

  void _openTransferSheet(BuildContext context) {
    unawaited(HapticFeedback.lightImpact());
    AppleModalSheetLayout.show<void>(
      context: context,
      builder: (_) => const TransferBetweenWalletsSheet(),
    );
  }

  Future<void> _handleToggleArchive(
    BuildContext context, {
    required String accountId,
    required bool archived,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final isVi = context.l10n.localeName.startsWith('vi');
    final res = await ref
        .read(accountsActionControllerProvider.notifier)
        .toggleArchive(accountId: accountId, archived: archived);
    if (!context.mounted) return;
    res.fold(
      onSuccess: (_) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              archived
                  ? (isVi ? 'Đã lưu trữ ví' : 'Wallet archived')
                  : (isVi ? 'Đã khôi phục ví hoạt động' : 'Wallet restored'),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      onFailure: (err) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.localizeError(err))),
        );
      },
    );
  }

  Future<void> _handleDeleteWallet(
    BuildContext context,
    Account account,
  ) async {
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

  Future<void> _handleSetDefaultWallet(
    BuildContext context,
    Account account,
  ) async {
    unawaited(HapticFeedback.mediumImpact());
    final res = await ref
        .read(settingsControllerProvider.notifier)
        .setDefaultWalletId(account.id);
    if (!context.mounted) return;
    if (res.isSuccess) {
      final isVi = context.l10n.localeName.startsWith('vi');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isVi
                ? 'Đã chọn "${account.name}" làm ví mặc định chi tiêu'
                : 'Selected "${account.name}" as default spending wallet',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isVi = l10n.localeName.startsWith('vi');
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accountsAsync = ref.watch(accountsStreamProvider);
    final activeAccounts = ref.watch(activeAccountsProvider);
    final archivedAccounts = ref.watch(archivedAccountsProvider);
    final totalBalance = ref.watch(totalNetBalanceProvider);
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

    // Filtered active accounts
    final filteredAccounts = _selectedTypeFilter == null
        ? activeAccounts
        : activeAccounts
            .where((a) => a.type == _selectedTypeFilter)
            .toList(growable: false);

    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: canPop ? 0 : 16,
        leading: canPop ? const AppleBackButton() : null,
        title: AppleHeaderTitle(
          title: l10n.walletsTitle,
          isLandscape: isLandscape,
        ),
        actions: [
          if (activeAccounts.length >= 2) ...[
            ApplePressable(
              onTap: () => _openTransferSheet(context),
              borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: AppleTokens.systemBlue.withValues(alpha: isDark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: Border.all(
                    color: AppleTokens.systemBlue.withValues(alpha: 0.32),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.swap_horiz_rounded,
                      size: 16,
                      color: AppleTokens.systemBlue,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      l10n.transferBetweenWallets,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppleTokens.systemBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: NotificationListener<UserScrollNotification>(
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
          child: accountsAsync.when(
            loading: () => const SkeletonListView(),
            error: (err, _) => Center(child: Text(context.localizeError(err))),
            data: (all) {
              if (all.isEmpty) {
                return EmptyStateView(
                  icon: Icons.account_balance_wallet_outlined,
                  title: l10n.emptyWalletsTitle,
                  subtitle: l10n.emptyWalletsSubtitle,
                  actionLabel: l10n.addWallet,
                  onAction: () => _openWalletForm(context),
                );
              }

              // 1. Redesigned Apple Glass Hero Net Balance Card
              final heroCard = _buildHeroNetBalanceCard(
                context: context,
                theme: theme,
                isDark: isDark,
                totalBalance: totalBalance,
                activeAccounts: activeAccounts,
                locale: locale,
                hideBalance: hideBalance,
                l10n: l10n,
              );

              // 2. Filter Pills row
              final filterPills = _buildFilterPills(
                activeAccounts: activeAccounts,
                isDark: isDark,
                l10n: l10n,
              );

              // 3. Wallets List items
              final walletListItems = <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          AppleSquircleBadge(
                            icon: CupertinoIcons.creditcard_fill,
                            backgroundColor: scheme.primary,
                            size: 26,
                            iconSize: 13,
                            radius: 7,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.activeWallets.toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: isDark ? Colors.white70 : const Color(0xFF55555B),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        ),
                        child: Text(
                          isVi
                              ? '${filteredAccounts.length} ví'
                              : '${filteredAccounts.length} wallets',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (filteredAccounts.isEmpty)
                  AppleGlassCard(
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    child: Center(
                      child: Text(
                        isVi ? 'Không tìm thấy ví phù hợp' : 'No matching wallets found',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppleTokens.systemGray,
                        ),
                      ),
                    ),
                  )
                else
                  ...filteredAccounts.map(
                    (account) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: WalletListTile(
                        key: ValueKey('wallet_tile_${account.id}'),
                        account: account,
                        typeLabel: _typeLabel(l10n, account.type),
                        locale: locale,
                        hideBalance: hideBalance,
                        isDefault: account.id == settings?.defaultWalletId,
                        onSetDefault: () => _handleSetDefaultWallet(context, account),
                        onTap: () =>
                            context.push(AppRoutes.accountDetail(account.id)),
                        onEdit: () => _openWalletForm(context, existing: account),
                        onToggleArchive: () => _handleToggleArchive(
                          context,
                          accountId: account.id,
                          archived: true,
                        ),
                        onDelete: () => _handleDeleteWallet(context, account),
                      ),
                    ),
                  ),
                if (archivedAccounts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  AppleGlassCard(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        tilePadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.archivebox_fill,
                              size: 18,
                              color: AppleTokens.systemGray,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${l10n.archivedWallets} (${archivedAccounts.length})',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Column(
                              children: archivedAccounts
                                  .map(
                                    (account) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: WalletListTile(
                                        key: ValueKey('archived_wallet_tile_${account.id}'),
                                        account: account,
                                        typeLabel: _typeLabel(l10n, account.type),
                                        locale: locale,
                                        hideBalance: hideBalance,
                                        isDefault: account.id == settings?.defaultWalletId,
                                        onSetDefault: () => _handleSetDefaultWallet(context, account),
                                        onTap: () => context.push(
                                          AppRoutes.accountDetail(account.id),
                                        ),
                                        onEdit: () => _openWalletForm(
                                          context,
                                          existing: account,
                                        ),
                                        onToggleArchive: () =>
                                            _handleToggleArchive(
                                          context,
                                          accountId: account.id,
                                          archived: false,
                                        ),
                                        onDelete: () => _handleDeleteWallet(
                                          context,
                                          account,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ];

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppleTokens.maxContentWidth),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
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
                              flex: 42,
                              child: Column(
                                children: [
                                  heroCard,
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 58,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  filterPills,
                                  const SizedBox(height: 14),
                                  ...walletListItems,
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        heroCard,
                        const SizedBox(height: 14),
                        filterPills,
                        const SizedBox(height: 14),
                        ...walletListItems,
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: const AppleFloatingActionButtonLocation(),
      floatingActionButton: AppleAdaptiveExpandableFab(
        heroTag: 'accounts_add_fab',
        isVisible: _isFabVisible,
        isExpanded: _isFabExpanded,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addWallet),
        onPressed: () => _openWalletForm(context),
        tooltip: l10n.addWallet,
      ),
    );
  }

  Widget _buildHeroNetBalanceCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required Money totalBalance,
    required List<Account> activeAccounts,
    required String locale,
    required bool hideBalance,
    required AppLocalizations l10n,
  }) {
    final isVi = locale.startsWith('vi');

    // Calculate asset allocation across categories for visual telemetry
    int totalCashMinor = 0;
    int totalBankMinor = 0;
    int totalEwalletMinor = 0;
    int totalCardMinor = 0;

    for (final acc in activeAccounts) {
      final bal = acc.balance;
      if (bal > 0) {
        switch (acc.type) {
          case AccountType.cash:
            totalCashMinor += bal;
            break;
          case AccountType.bank:
            totalBankMinor += bal;
            break;
          case AccountType.ewallet:
            totalEwalletMinor += bal;
            break;
          case AccountType.card:
            totalCardMinor += bal;
            break;
        }
      }
    }

    final positiveTotalMinor =
        totalCashMinor + totalBankMinor + totalEwalletMinor + totalCardMinor;

    return AppleGlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      borderColor: isDark
          ? AppleTokens.jadePrimary.withValues(alpha: 0.30)
          : AppleTokens.jadePrimary.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header: Shield Badge + Eyebrow + Count + Eye Toggle
          Row(
            children: [
              const AppleSquircleBadge(
                icon: CupertinoIcons.shield_fill,
                backgroundColor: AppleTokens.jadePrimary,
                size: 28,
                iconSize: 14,
                radius: 8,
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  l10n.totalBalance.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark ? AppleTokens.jadePrimary : const Color(0xFF0F764A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Text(
                  isVi
                      ? '${activeAccounts.length} ví'
                      : '${activeAccounts.length} wallets',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF1B5E20),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                alignment: Alignment.centerRight,
                tooltip: hideBalance ? l10n.showBalance : l10n.hideBalance,
                onPressed: () {
                  unawaited(HapticFeedback.selectionClick());
                  ref
                      .read(settingsControllerProvider.notifier)
                      .toggleHideBalance();
                },
                icon: Icon(
                  hideBalance
                      ? CupertinoIcons.eye_slash
                      : CupertinoIcons.eye,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Primary Big Balance Figure
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              totalBalance.format(locale: locale, masked: hideBalance),
              semanticsLabel: hideBalance ? l10n.balanceHidden : null,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                fontFeatures: AppTheme.tabularFigures,
                color: isDark ? Colors.white : const Color(0xFF072711),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Segmented Asset Distribution Telemetry
          if (positiveTotalMinor > 0 && !hideBalance) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    if (totalCashMinor > 0)
                      Expanded(
                        flex: totalCashMinor,
                        child: Container(color: AppleTokens.jadePrimary),
                      ),
                    if (totalBankMinor > 0)
                      Expanded(
                        flex: totalBankMinor,
                        child: Container(color: AppleTokens.systemBlue),
                      ),
                    if (totalEwalletMinor > 0)
                      Expanded(
                        flex: totalEwalletMinor,
                        child: Container(color: AppleTokens.systemTeal),
                      ),
                    if (totalCardMinor > 0)
                      Expanded(
                        flex: totalCardMinor,
                        child: Container(color: AppleTokens.systemPurple),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                if (totalCashMinor > 0)
                  _buildLegendItem(
                    color: AppleTokens.jadePrimary,
                    label: l10n.walletTypeCash,
                    percent: (totalCashMinor * 100 / positiveTotalMinor).round(),
                    isDark: isDark,
                  ),
                if (totalBankMinor > 0)
                  _buildLegendItem(
                    color: AppleTokens.systemBlue,
                    label: l10n.walletTypeBank,
                    percent: (totalBankMinor * 100 / positiveTotalMinor).round(),
                    isDark: isDark,
                  ),
                if (totalEwalletMinor > 0)
                  _buildLegendItem(
                    color: AppleTokens.systemTeal,
                    label: l10n.walletTypeEwallet,
                    percent: (totalEwalletMinor * 100 / positiveTotalMinor).round(),
                    isDark: isDark,
                  ),
                if (totalCardMinor > 0)
                  _buildLegendItem(
                    color: AppleTokens.systemPurple,
                    label: l10n.walletTypeCard,
                    percent: (totalCardMinor * 100 / positiveTotalMinor).round(),
                    isDark: isDark,
                  ),
              ],
            ),
          ],

          // 4. Quick Action Button: Transfer between wallets
          if (activeAccounts.length >= 2) ...[
            const SizedBox(height: 14),
            ApplePressable(
              onTap: () => _openTransferSheet(context),
              borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppleTokens.systemBlue.withValues(alpha: isDark ? 0.22 : 0.10),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: Border.all(
                    color: AppleTokens.systemBlue.withValues(alpha: 0.32),
                    width: 0.9,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.swap_horiz_rounded,
                      size: 16,
                      color: AppleTokens.systemBlue,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        l10n.transferBetweenWallets,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppleTokens.systemBlue,
                          letterSpacing: -0.1,
                        ),
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

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required int percent,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4.5),
        Text(
          '$label $percent%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : const Color(0xFF48484A),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPills({
    required List<Account> activeAccounts,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    final filters = [
      (
        type: null,
        icon: CupertinoIcons.square_grid_2x2,
        label: '${l10n.localeName.startsWith('vi') ? 'Tất cả' : 'All'} (${activeAccounts.length})'
      ),
      (
        type: AccountType.cash,
        icon: Icons.payments_rounded,
        label:
            '${l10n.walletTypeCash} (${activeAccounts.where((a) => a.type == AccountType.cash).length})'
      ),
      (
        type: AccountType.bank,
        icon: Icons.account_balance_rounded,
        label:
            '${l10n.walletTypeBank} (${activeAccounts.where((a) => a.type == AccountType.bank).length})'
      ),
      (
        type: AccountType.ewallet,
        icon: Icons.qr_code_2_rounded,
        label:
            '${l10n.walletTypeEwallet} (${activeAccounts.where((a) => a.type == AccountType.ewallet).length})'
      ),
      (
        type: AccountType.card,
        icon: Icons.credit_card_rounded,
        label:
            '${l10n.walletTypeCard} (${activeAccounts.where((a) => a.type == AccountType.card).length})'
      ),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _selectedTypeFilter == f.type;
          return ApplePressable(
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              setState(() => _selectedTypeFilter = f.type);
            },
            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF1C1C1E))
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.85)),
                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : AppleTokens.borderLight),
                  width: 0.8,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    f.icon,
                    size: 14,
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    f.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? Colors.white70 : Colors.black87),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
