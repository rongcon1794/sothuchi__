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
    final res = await ref
        .read(accountsActionControllerProvider.notifier)
        .toggleArchive(accountId: accountId, archived: archived);
    if (!context.mounted) return;
    res.fold(
      onSuccess: (_) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              archived ? 'Đã lưu trữ ví' : 'Đã khôi phục ví hoạt động',
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
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('${l10n.delete} ${account.name}'),
        message: const Text('Bạn có chắc chắn muốn xóa ví này? Giao dịch liên quan sẽ không bị mất.'),
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
              SnackBar(content: Text('Đã xóa ví "${account.name}"')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã chọn "${account.name}" làm ví mặc định chi tiêu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        title: Text(
          l10n.walletsTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (activeAccounts.length >= 2) ...[
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onPressed: () => _openTransferSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppleTokens.systemBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  border: Border.all(
                    color: AppleTokens.systemBlue.withValues(alpha: 0.3),
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
            const SizedBox(width: 4),
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

              // 1. Apple Net Balance Hero Card
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
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.activeWallets.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppleTokens.systemGray,
                          letterSpacing: 0.6,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppleTokens.bgDarkSecondary
                              : AppleTokens.bgLightSecondary,
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        ),
                        child: Text(
                          '${filteredAccounts.length} ví',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppleTokens.systemGray,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                ...filteredAccounts.map(
                  (account) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
                  const SizedBox(height: 16),
                  AppleGlassCard(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    child: ExpansionTile(
                      shape: const Border(),
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
                              fontWeight: FontWeight.w600,
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
                ],
              ];

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1024),
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
                              flex: 44,
                              child: Column(
                                children: [
                                  heroCard,
                                  const SizedBox(height: 14),
                                  filterPills,
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 56,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: walletListItems,
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0D281E), Color(0xFF06140E)]
              : const [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
        ),
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        border: Border.all(
          color: AppleTokens.jadePrimary.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppleTokens.jadeDark.withValues(alpha: isDark ? 0.25 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Label & Pulse Status Row
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppleTokens.jadePrimary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppleTokens.jadePrimary.withValues(alpha: 0.6),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      l10n.totalBalance.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark ? AppleTokens.jadePrimary : const Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                    ),
                    child: Text(
                      '${activeAccounts.length} ví',
                      style: TextStyle(
                        fontSize: 10,
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
                      size: 19,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Big Balance Figure
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  totalBalance.format(locale: locale, masked: hideBalance),
                  semanticsLabel: hideBalance ? l10n.balanceHidden : null,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    fontFeatures: AppTheme.tabularFigures,
                    color: isDark ? Colors.white : const Color(0xFF0F3816),
                  ),
                ),
              ),
              if (activeAccounts.length >= 2) ...[
                const SizedBox(height: 10),
                ApplePressable(
                  onTap: () => _openTransferSheet(context),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppleTokens.systemBlue.withValues(alpha: isDark ? 0.20 : 0.10),
                      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                      border: Border.all(
                        color: AppleTokens.systemBlue.withValues(alpha: 0.28),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.swap_horiz_rounded,
                          size: 15,
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
        ),
      ),
    );
  }

  Widget _buildFilterPills({
    required List<Account> activeAccounts,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    final filters = [
      (type: null, label: 'Tất cả (${activeAccounts.length})'),
      (
        type: AccountType.cash,
        label:
            '${l10n.walletTypeCash} (${activeAccounts.where((a) => a.type == AccountType.cash).length})'
      ),
      (
        type: AccountType.bank,
        label:
            '${l10n.walletTypeBank} (${activeAccounts.where((a) => a.type == AccountType.bank).length})'
      ),
      (
        type: AccountType.ewallet,
        label:
            '${l10n.walletTypeEwallet} (${activeAccounts.where((a) => a.type == AccountType.ewallet).length})'
      ),
      (
        type: AccountType.card,
        label:
            '${l10n.walletTypeCard} (${activeAccounts.where((a) => a.type == AccountType.card).length})'
      ),
    ];

    return SizedBox(
      height: 36,
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
                    ? (isDark ? Colors.white : Colors.black87)
                    : (isDark
                        ? AppleTokens.bgDarkSecondary
                        : AppleTokens.bgLightSecondary),
                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                          ? AppleTokens.separatorDark
                          : AppleTokens.separatorLight),
                  width: 0.8,
                ),
              ),
              child: Text(
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
            ),
          );
        },
      ),
    );
  }
}
