import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
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
import 'package:so_thu_chi/features/accounts/presentation/widgets/wallet_form_sheet.dart';
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
      builder: (_) => const _TransferBetweenWalletsSheet(),
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

              // Compute breakdown
              int totalCash = 0;
              int totalBank = 0;
              int totalEwallet = 0;
              int totalCard = 0;
              for (final acc in activeAccounts) {
                switch (acc.type) {
                  case AccountType.cash:
                    totalCash += acc.balance;
                    break;
                  case AccountType.bank:
                    totalBank += acc.balance;
                    break;
                  case AccountType.ewallet:
                    totalEwallet += acc.balance;
                    break;
                  case AccountType.card:
                    totalCard += acc.balance;
                    break;
                }
              }

              // 1. Apple Net Balance Hero Card
              final heroCard = _buildHeroNetBalanceCard(
                context: context,
                theme: theme,
                isDark: isDark,
                totalBalance: totalBalance,
                activeAccounts: activeAccounts,
                totalCash: totalCash,
                totalBank: totalBank,
                totalEwallet: totalEwallet,
                totalCard: totalCard,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                    child: _WalletTile(
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
                                    child: _WalletTile(
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
    required int totalCash,
    required int totalBank,
    required int totalEwallet,
    required int totalCard,
    required String locale,
    required bool hideBalance,
    required AppLocalizations l10n,
  }) {
    final currency = totalBalance.currencyCode;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0D281E), Color(0xFF06140E)]
              : const [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
        ),
        borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
        border: Border.all(
          color: AppleTokens.jadePrimary.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppleTokens.jadeDark.withValues(alpha: isDark ? 0.3 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Label & Pulse Status
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppleTokens.jadePrimary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppleTokens.jadePrimary.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.totalBalance.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark ? AppleTokens.jadePrimary : const Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                  IconButton(
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
              const SizedBox(height: 6),
              // Big Balance Figure
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  totalBalance.format(locale: locale, masked: hideBalance),
                  semanticsLabel: hideBalance ? l10n.balanceHidden : null,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    fontFeatures: AppTheme.tabularFigures,
                    color: isDark ? Colors.white : const Color(0xFF0F3816),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Asset Breakdown Mini Strip
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (totalCash > 0)
                    _buildBreakdownChip(
                      icon: Icons.payments_rounded,
                      color: AppleTokens.jadePrimary,
                      label: l10n.walletTypeCash,
                      amount: Money(minorUnits: totalCash, currencyCode: currency)
                          .format(locale: locale, masked: hideBalance),
                      isDark: isDark,
                    ),
                  if (totalBank > 0)
                    _buildBreakdownChip(
                      icon: Icons.account_balance_rounded,
                      color: AppleTokens.systemBlue,
                      label: l10n.walletTypeBank,
                      amount: Money(minorUnits: totalBank, currencyCode: currency)
                          .format(locale: locale, masked: hideBalance),
                      isDark: isDark,
                    ),
                  if (totalEwallet > 0)
                    _buildBreakdownChip(
                      icon: Icons.qr_code_2_rounded,
                      color: AppleTokens.systemPurple,
                      label: l10n.walletTypeEwallet,
                      amount: Money(minorUnits: totalEwallet, currencyCode: currency)
                          .format(locale: locale, masked: hideBalance),
                      isDark: isDark,
                    ),
                  if (totalCard != 0)
                    _buildBreakdownChip(
                      icon: Icons.credit_card_rounded,
                      color: AppleTokens.systemOrange,
                      label: l10n.walletTypeCard,
                      amount: Money(minorUnits: totalCard, currencyCode: currency)
                          .format(locale: locale, masked: hideBalance),
                      isDark: isDark,
                    ),
                ],
              ),
              if (activeAccounts.length >= 2) ...[
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  thickness: AppleTokens.hairline,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.08),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ApplePressable(
                        onTap: () => _openTransferSheet(context),
                        borderRadius:
                            BorderRadius.circular(AppleTokens.radiusPill),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppleTokens.systemBlue
                                .withValues(alpha: isDark ? 0.22 : 0.12),
                            borderRadius:
                                BorderRadius.circular(AppleTokens.radiusPill),
                            border: Border.all(
                              color: AppleTokens.systemBlue
                                  .withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.swap_horiz_rounded,
                                size: 16,
                                color: AppleTokens.systemBlue,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  l10n.transferBetweenWallets,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppleTokens.systemBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ApplePressable(
                        onTap: () => _openWalletForm(context),
                        borderRadius:
                            BorderRadius.circular(AppleTokens.radiusPill),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppleTokens.jadePrimary
                                .withValues(alpha: isDark ? 0.22 : 0.14),
                            borderRadius:
                                BorderRadius.circular(AppleTokens.radiusPill),
                            border: Border.all(
                              color: AppleTokens.jadePrimary
                                  .withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                CupertinoIcons.plus,
                                size: 15,
                                color: AppleTokens.jadePrimary,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  l10n.addWallet,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppleTokens.jadePrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownChip({
    required IconData icon,
    required Color color,
    required String label,
    required String amount,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '$label: ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          Flexible(
            child: Text(
              amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
          ),
        ],
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.black : Colors.white)
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({
    required this.account,
    required this.typeLabel,
    required this.locale,
    required this.hideBalance,
    required this.onTap,
    required this.onEdit,
    required this.onToggleArchive,
    this.isDefault = false,
    this.onSetDefault,
  });

  final Account account;
  final String typeLabel;
  final String locale;
  final bool hideBalance;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleArchive;
  final bool isDefault;
  final VoidCallback? onSetDefault;

  IconData _typeIcon(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return Icons.payments_rounded;
      case AccountType.bank:
        return Icons.account_balance_rounded;
      case AccountType.ewallet:
        return Icons.qr_code_2_rounded;
      case AccountType.card:
        return Icons.credit_card_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final walletColor = AppIconCatalog.contrastSafeColor(
      Color(account.color),
      theme.brightness,
    );
    final balanceText = account.balanceMoney.format(
      locale: locale,
      masked: hideBalance,
    );

    return ApplePressable(
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark
                  ? Color.lerp(walletColor, const Color(0xFF1E1E22), 0.82)!
                  : Color.lerp(walletColor, Colors.white, 0.90)!,
              isDark
                  ? const Color(0xFF141416)
                  : Color.lerp(walletColor, const Color(0xFFF7F8FA), 0.96)!,
            ],
          ),
          border: Border.all(
            color: isDefault
                ? const Color(0xFFFFB800).withValues(alpha: isDark ? 0.65 : 0.55)
                : walletColor.withValues(alpha: isDark ? 0.35 : 0.22),
            width: isDefault ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDefault
                  ? const Color(0xFFFFB800).withValues(alpha: isDark ? 0.16 : 0.08)
                  : walletColor.withValues(alpha: isDark ? 0.18 : 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
          child: Stack(
            children: [
              // Subtle ambient radiant glow at top-right
              Positioned(
                right: -24,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        walletColor.withValues(alpha: isDark ? 0.22 : 0.12),
                        walletColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Tier 1: Identity, Badges, and Overflow Actions ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Squircle Icon Badge with high-gloss gradient & shadow
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                walletColor,
                                Color.lerp(walletColor, Colors.black, isDark ? 0.35 : 0.2)!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: isDark ? 0.3 : 0.45),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: walletColor.withValues(alpha: isDark ? 0.4 : 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            AppIconCatalog.resolve(account.icon),
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Wallet Name & Tags (Type, Currency, Default)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                account.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16.5,
                                  letterSpacing: -0.2,
                                  decoration: account.archived
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 5,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Wallet Type Pill with Icon
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: walletColor.withValues(
                                        alpha: isDark ? 0.20 : 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppleTokens.radiusPill,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _typeIcon(account.type),
                                          size: 11,
                                          color: isDark
                                              ? Colors.white70
                                              : walletColor,
                                        ),
                                        const SizedBox(width: 3.5),
                                        Text(
                                          typeLabel,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                              ? Colors.white70
                                              : walletColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Default Wallet Badge
                                  if (isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFFDF7A),
                                            Color(0xFFD4AF37),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppleTokens.radiusPill,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFD4AF37)
                                                .withValues(alpha: 0.35),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            size: 11,
                                            color: Color(0xFF4A3500),
                                          ),
                                          SizedBox(width: 2.5),
                                          Text(
                                            'Mặc định',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF4A3500),
                                              letterSpacing: 0.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Currency Code Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(
                                        AppleTokens.radiusPill,
                                      ),
                                    ),
                                    child: Text(
                                      account.currency.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),

                                  // Archived Badge
                                  if (account.archived)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppleTokens.rubyExpense
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(
                                          AppleTokens.radiusPill,
                                        ),
                                      ),
                                      child: Text(
                                        l10n.archivedWallets,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppleTokens.rubyExpense,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Apple 3-dots Menu Button
                        ApplePopupMenuButton<String>(
                          tooltip: l10n.moreOptions,
                          onSelected: (value) {
                            if (value == 'edit') onEdit();
                            if (value == 'archive') onToggleArchive();
                            if (value == 'set_default') onSetDefault?.call();
                          },
                          itemBuilder: (ctx) => [
                            if (!isDefault && onSetDefault != null)
                              ApplePopupMenuItem(
                                value: 'set_default',
                                icon: CupertinoIcons.star_fill,
                                title: 'Đặt làm ví mặc định',
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
                              title: account.archived
                                  ? l10n.unarchiveWallet
                                  : l10n.archiveWallet,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Subtle Hairline Divider
                    Divider(
                      height: 1,
                      thickness: AppleTokens.hairline,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),

                    const SizedBox(height: 10),

                    // --- Tier 2: Financial Balance Row ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Label: "SỐ DƯ HIỆN TẠI" with glowing indicator dot
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: walletColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: walletColor.withValues(alpha: 0.6),
                                    blurRadius: 4,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SỐ DƯ HIỆN TẠI',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),

                        // Large Tabular Balance Figure + Forward Chevron
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  balanceText,
                                  semanticsLabel:
                                      hideBalance ? l10n.balanceHidden : null,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: AppTheme.tabularFigures,
                                    letterSpacing: -0.3,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1C1C1E),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 14,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.black.withValues(alpha: 0.3),
                              ),
                            ],
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
    );
  }
}

class _TransferBetweenWalletsSheet extends ConsumerStatefulWidget {
  const _TransferBetweenWalletsSheet();

  @override
  ConsumerState<_TransferBetweenWalletsSheet> createState() =>
      _TransferBetweenWalletsSheetState();
}

class _TransferBetweenWalletsSheetState
    extends ConsumerState<_TransferBetweenWalletsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _fromId;
  String? _toId;

  @override
  void initState() {
    super.initState();
    final active = ref.read(activeAccountsProvider);
    if (active.isNotEmpty) {
      _fromId = active.first.id;
      final sameCurrencyDest = active
          .where((w) => w.id != _fromId && w.currency == active.first.currency)
          .toList(growable: false);
      if (sameCurrencyDest.isNotEmpty) {
        _toId = sameCurrencyDest.first.id;
      } else if (active.length >= 2) {
        _toId = active[1].id;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _swapWallets() {
    if (_fromId == null || _toId == null) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      final temp = _fromId;
      _fromId = _toId;
      _toId = temp;
    });
  }

  String _resolveFromCurrency(List<Account> active) {
    if (_fromId != null) {
      for (final a in active) {
        if (a.id == _fromId) return a.currency;
      }
    }
    return ref.read(settingsControllerProvider).value?.currencyCode ??
        AppCurrencies.defaultCode;
  }

  void _setPresetAmount(int minorUnits, String currency, String locale) {
    unawaited(HapticFeedback.selectionClick());
    final str = Money(minorUnits: minorUnits, currencyCode: currency)
        .toInputString(locale: locale);
    setState(() {
      _amountController.text = str;
      _amountController.selection = TextSelection.collapsed(offset: str.length);
    });
  }

  void _appendTripleZeros(String currency, String locale) {
    final current = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (current.isEmpty || current == '0') return;
    unawaited(HapticFeedback.selectionClick());
    final newRaw = '${current}000';
    final parsed = int.tryParse(newRaw);
    if (parsed == null) return;
    final formatted = Money(minorUnits: parsed, currencyCode: currency)
        .toInputString(locale: locale);
    setState(() {
      _amountController.text = formatted;
      _amountController.selection =
          TextSelection.collapsed(offset: formatted.length);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final active = ref.read(activeAccountsProvider);
    if (_fromId == null || _toId == null) return;
    if (_fromId == _toId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.sameWalletTransferError)),
      );
      return;
    }

    Account? fromAcc;
    Account? toAcc;
    for (final a in active) {
      if (a.id == _fromId) fromAcc = a;
      if (a.id == _toId) toAcc = a;
    }
    if (fromAcc != null && toAcc != null && fromAcc.currency != toAcc.currency) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.differentCurrencyTransferError)),
      );
      return;
    }

    final currency = fromAcc?.currency ?? _resolveFromCurrency(active);
    final parsed = Money.tryParse(
      _amountController.text,
      currencyCode: currency,
    );
    if (parsed == null || parsed.minorUnits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.amountRequiredError)),
      );
      return;
    }

    unawaited(HapticFeedback.mediumImpact());
    final res = await ref
        .read(accountsActionControllerProvider.notifier)
        .transfer(
          fromAccountId: _fromId!,
          toAccountId: _toId!,
          amountMinorUnits: parsed.minorUnits,
          currency: currency,
          note: _noteController.text,
        );

    if (!mounted) return;
    res.fold(
      onSuccess: (_) {
        unawaited(HapticFeedback.lightImpact());
        Navigator.of(context).pop();
      },
      onFailure: (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.localizeError(err))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = ref.watch(activeAccountsProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final currency = _resolveFromCurrency(active);
    final currencyInfo = AppCurrencies.byCode(currency);

    final presets = currency.toUpperCase() == 'VND'
        ? [
            (minorUnits: 100000, label: '100k'),
            (minorUnits: 200000, label: '200k'),
            (minorUnits: 500000, label: '500k'),
            (minorUnits: 1000000, label: '1 triệu'),
            (minorUnits: 2000000, label: '2 triệu'),
            (minorUnits: 5000000, label: '5 triệu'),
          ]
        : [
            (minorUnits: 10 * currencyInfo.minorUnitFactor, label: '${currencyInfo.symbol}10'),
            (minorUnits: 50 * currencyInfo.minorUnitFactor, label: '${currencyInfo.symbol}50'),
            (minorUnits: 100 * currencyInfo.minorUnitFactor, label: '${currencyInfo.symbol}100'),
            (minorUnits: 500 * currencyInfo.minorUnitFactor, label: '${currencyInfo.symbol}500'),
          ];

    return AppleModalSheetLayout(
      title: l10n.transferBetweenWallets,
      bottomAction: AppleButton.primary(
        onPressed: _submit,
        icon: const Icon(Icons.swap_horiz_rounded),
        label: l10n.confirm,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // From Wallet Section
            _buildSectionLabel(
              icon: CupertinoIcons.arrow_up_circle_fill,
              title: l10n.fromWallet,
              color: AppleTokens.rubyExpense,
            ),
            _buildWalletCarousel(
              activeAccounts: active,
              selectedId: _fromId,
              excludeId: _toId,
              locale: locale,
              isDark: isDark,
              onSelected: (id) => setState(() => _fromId = id),
            ),
            const SizedBox(height: 10),

            // Swap button
            Center(
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(36, 36),
                onPressed: _swapWallets,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppleTokens.systemBlue.withValues(alpha: isDark ? 0.25 : 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppleTokens.systemBlue.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    size: 20,
                    color: AppleTokens.systemBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // To Wallet Section
            _buildSectionLabel(
              icon: CupertinoIcons.arrow_down_circle_fill,
              title: l10n.toWallet,
              color: AppleTokens.emeraldIncome,
            ),
            _buildWalletCarousel(
              activeAccounts: active,
              selectedId: _toId,
              excludeId: _fromId,
              locale: locale,
              isDark: isDark,
              onSelected: (id) => setState(() => _toId = id),
            ),
            const SizedBox(height: 18),

            // Amount Input Card with Presets
            _buildSectionLabel(
              icon: CupertinoIcons.money_dollar_circle_fill,
              title: l10n.amount,
              color: AppleTokens.systemBlue,
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppleTokens.bgDarkSecondary
                    : AppleTokens.bgLightSecondary,
                borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                border: Border.all(
                  color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: currencyInfo.decimalDigits > 0,
                          ),
                          inputFormatters: [
                            MoneyInputFormatter(
                              currencyCode: currency,
                              locale: locale,
                            ),
                          ],
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            fontFeatures: AppTheme.tabularFigures,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintText: '0',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppleTokens.systemBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        ),
                        child: Text(
                          currencyInfo.symbol,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppleTokens.systemBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        ...presets.map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ApplePressable(
                              onTap: () => _setPresetAmount(p.minorUnits, currency, locale),
                              borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.white,
                                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                  border: Border.all(
                                    color: isDark ? AppleTokens.separatorDark : AppleTokens.separatorLight,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  p.label,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (currency.toUpperCase() == 'VND')
                          ApplePressable(
                            onTap: () => _appendTripleZeros(currency, locale),
                            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppleTokens.systemBlue.withValues(alpha: isDark ? 0.22 : 0.12),
                                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                                border: Border.all(
                                  color: AppleTokens.systemBlue.withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                '+000',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppleTokens.systemBlue,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Note Field
            _buildSectionLabel(
              icon: CupertinoIcons.doc_text_fill,
              title: l10n.note,
              color: AppleTokens.systemGray,
            ),
            AppleTextField(
              controller: _noteController,
              maxLength: 1000,
              placeholder: l10n.noteHint,
              prefixIcon: const Icon(CupertinoIcons.doc_text, size: 18),
              clearable: true,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCarousel({
    required List<Account> activeAccounts,
    required String? selectedId,
    required String? excludeId,
    required String locale,
    required bool isDark,
    required ValueChanged<String> onSelected,
  }) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: activeAccounts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final acc = activeAccounts[index];
          final isSelected = acc.id == selectedId;
          final isExcluded = acc.id == excludeId;
          final accColor = Color(acc.color);

          return Opacity(
            opacity: isExcluded ? 0.35 : 1.0,
            child: ApplePressable(
              onTap: isExcluded ? null : () => onSelected(acc.id),
              borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accColor.withValues(alpha: isDark ? 0.25 : 0.12)
                      : (isDark
                          ? AppleTokens.bgDarkSecondary
                          : AppleTokens.bgLightSecondary),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                  border: Border.all(
                    color: isSelected
                        ? accColor
                        : (isDark
                            ? AppleTokens.separatorDark
                            : AppleTokens.separatorLight),
                    width: isSelected ? 1.5 : 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                      ),
                      child: Icon(
                        AppIconCatalog.resolve(acc.icon),
                        size: 18,
                        color: accColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          acc.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? (isDark ? Colors.white : accColor)
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        Text(
                          acc.balanceMoney.format(locale: locale),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontFeatures: AppTheme.tabularFigures,
                          ),
                        ),
                      ],
                    ),
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
