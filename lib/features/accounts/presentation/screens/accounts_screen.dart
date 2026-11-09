import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

  String _typeLabel(AppLocalizations l10n, AccountType type) => switch (type) {
    AccountType.cash => l10n.walletTypeCash,
    AccountType.bank => l10n.walletTypeBank,
    AccountType.ewallet => l10n.walletTypeEwallet,
    AccountType.card => l10n.walletTypeCard,
  };

  void _openWalletForm(BuildContext context, {Account? existing}) {
    WalletFormSheet.show(context, existing: existing);
  }

  void _openTransferSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
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
      onSuccess: (_) {},
      onFailure: (err) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.localizeError(err))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
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

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: appBarHeight,
        title: Text(l10n.walletsTitle),
        actions: [
          if (activeAccounts.length >= 2) ...[
            IconButton(
              tooltip: l10n.transferBetweenWallets,
              onPressed: () => _openTransferSheet(context),
              icon: const Icon(Icons.swap_horiz_rounded),
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
              setState(() {
                _isFabVisible = true;
              });
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

            final isDark = theme.brightness == Brightness.dark;
            final balanceCard = AppleGlassCard(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
              borderColor: isDark
                  ? LucianTokens.accentDark.withValues(alpha: 0.25)
                  : LucianTokens.accentLight.withValues(alpha: 0.20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: LucianTokens.resolveMint(isDark),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: LucianTokens.resolveMint(isDark).withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.totalBalance,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: hideBalance
                            ? l10n.showBalance
                            : l10n.hideBalance,
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(settingsControllerProvider.notifier)
                              .toggleHideBalance();
                        },
                        icon: Icon(
                          hideBalance
                              ? CupertinoIcons.eye_slash
                              : CupertinoIcons.eye,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      totalBalance.format(locale: locale, masked: hideBalance),
                      semanticsLabel: hideBalance ? l10n.balanceHidden : null,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                  ),
                  if (activeAccounts.length >= 2) ...[
                    const SizedBox(height: 16),
                    ApplePressable(
                      scaleDown: 0.96,
                      onTap: () => _openTransferSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.25),
                            width: AppleTokens.hairline,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.arrow_right_arrow_left,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.transferBetweenWallets,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
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

            final walletListItems = <Widget>[
              Text(l10n.activeWallets, style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              ...activeAccounts.map(
                (account) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _WalletTile(
                    account: account,
                    typeLabel: _typeLabel(l10n, account.type),
                    locale: locale,
                    hideBalance: hideBalance,
                    onTap: () => context.push(AppRoutes.accountDetail(account.id)),
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
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    '${l10n.archivedWallets} (${archivedAccounts.length})',
                    style: theme.textTheme.titleSmall,
                  ),
                  children: archivedAccounts
                      .map(
                        (account) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _WalletTile(
                            account: account,
                            typeLabel: _typeLabel(l10n, account.type),
                            locale: locale,
                            hideBalance: hideBalance,
                            onTap: () => context.push(AppRoutes.accountDetail(account.id)),
                            onEdit: () =>
                                _openWalletForm(context, existing: account),
                            onToggleArchive: () => _handleToggleArchive(
                              context,
                              accountId: account.id,
                              archived: false,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ];

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1024),
                child: ListView(
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
                            child: balanceCard,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 58,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: walletListItems,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      balanceCard,
                      const SizedBox(height: 20),
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
  });

  final Account account;
  final String typeLabel;
  final String locale;
  final bool hideBalance;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final walletColor = AppIconCatalog.contrastSafeColor(
      Color(account.color),
      theme.brightness,
    );
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final stackBalance = textScale >= 1.4;
    final balanceText = account.balanceMoney.format(
      locale: locale,
      masked: hideBalance,
    );

    final balanceWidget = Text(
      balanceText,
      semanticsLabel: hideBalance ? l10n.balanceHidden : null,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontFeatures: AppTheme.tabularFigures,
      ),
    );

    return ApplePressable(
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      onTap: onTap,
      child: AppleGlassCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      walletColor.withValues(alpha: theme.brightness == Brightness.dark ? 0.28 : 0.20),
                      walletColor.withValues(alpha: theme.brightness == Brightness.dark ? 0.12 : 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: walletColor.withValues(alpha: theme.brightness == Brightness.dark ? 0.35 : 0.25),
                    width: AppleTokens.hairline,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: walletColor.withValues(alpha: theme.brightness == Brightness.dark ? 0.16 : 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  AppIconCatalog.resolve(account.icon),
                  color: walletColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: account.archived
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      typeLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (stackBalance) ...[
                      const SizedBox(height: 4),
                      balanceWidget,
                    ],
                  ],
                ),
              ),
              if (!stackBalance) ...[
                const SizedBox(width: 8),
                Flexible(flex: 0, child: balanceWidget),
              ],
              ApplePopupMenuButton<String>(
                tooltip: l10n.moreOptions,
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'archive') onToggleArchive();
                },
                itemBuilder: (ctx) => [
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

  String _resolveFromCurrency(List<Account> active) {
    if (_fromId != null) {
      for (final a in active) {
        if (a.id == _fromId) return a.currency;
      }
    }
    return ref.read(settingsControllerProvider).value?.currencyCode ??
        AppCurrencies.defaultCode;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.amountRequiredError)));
      return;
    }

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
      onSuccess: (_) => Navigator.of(context).pop(),
      onFailure: (err) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.localizeError(err))));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final active = ref.watch(activeAccountsProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final currency = _resolveFromCurrency(active);
    final currencyInfo = AppCurrencies.byCode(currency);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.transferBetweenWallets,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: active.any((a) => a.id == _fromId)
                    ? _fromId
                    : null,
                decoration: InputDecoration(labelText: l10n.fromWallet),
                items: active
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(
                          '${a.name} (${a.balanceMoney.format(locale: locale)})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _fromId = v),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: active.any((a) => a.id == _toId) ? _toId : null,
                decoration: InputDecoration(labelText: l10n.toWallet),
                items: active
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(
                          '${a.name} (${a.balanceMoney.format(locale: locale)})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _toId = v),
              ),
              const SizedBox(height: 14),
              AppleTextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: currencyInfo.decimalDigits > 0,
                ),
                inputFormatters: [
                  MoneyInputFormatter(currencyCode: currency, locale: locale),
                ],
                label: l10n.amount,
                suffix: Text(
                  currencyInfo.symbol,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                validator: (v) {
                  final parsed = Money.tryParse(v ?? '', currencyCode: currency);
                  if (parsed == null || parsed.minorUnits <= 0) {
                    return l10n.amountRequiredError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AppleTextField(
                controller: _noteController,
                maxLength: 1000,
                label: l10n.note,
                placeholder: l10n.noteHint,
              ),
              const SizedBox(height: 24),
              AppleButton.primary(
                onPressed: _submit,
                icon: Icons.swap_horiz_rounded,
                label: l10n.confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
