import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/empty_state_view.dart';
import 'package:so_thu_chi/core/widgets/icon_and_color_picker.dart';
import 'package:so_thu_chi/core/widgets/skeleton_box.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _WalletFormSheet(existing: existing),
    );
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
    final scheme = theme.colorScheme;
    final accountsAsync = ref.watch(accountsStreamProvider);
    final activeAccounts = ref.watch(activeAccountsProvider);
    final archivedAccounts = ref.watch(archivedAccountsProvider);
    final totalBalance = ref.watch(totalNetBalanceProvider);
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = settings?.localeCode ?? 'vi';
    final hideBalance = settings?.hideBalance ?? false;

    return Scaffold(
      appBar: AppBar(
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
      body: NotificationListener<UserScrollNotification>(
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

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                AppleTokens.scrollBottomPaddingWithFab,
              ),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.totalBalance,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: hideBalance
                              ? l10n.showBalance
                              : l10n.hideBalance,
                          onPressed: () => ref
                              .read(settingsControllerProvider.notifier)
                              .toggleHideBalance(),
                          icon: Icon(
                            hideBalance
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      totalBalance.format(locale: locale, masked: hideBalance),
                      semanticsLabel: hideBalance ? l10n.balanceHidden : null,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontFeatures: AppTheme.tabularFigures,
                      ),
                    ),
                    if (activeAccounts.length >= 2) ...[
                      const SizedBox(height: 14),
                      FilledButton.tonalIcon(
                        onPressed: () => _openTransferSheet(context),
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: Text(l10n.transferBetweenWallets),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
            ],
          );
        },
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
    required this.onEdit,
    required this.onToggleArchive,
  });

  final Account account;
  final String typeLabel;
  final String locale;
  final bool hideBalance;
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
      onTap: onEdit,
      child: AppleGlassCard(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: walletColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
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
              PopupMenuButton<String>(
                tooltip: l10n.moreOptions,
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'archive') onToggleArchive();
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(
                      account.archived
                          ? l10n.unarchiveWallet
                          : l10n.archiveWallet,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }
}

class _WalletFormSheet extends ConsumerStatefulWidget {
  const _WalletFormSheet({this.existing});

  final Account? existing;

  @override
  ConsumerState<_WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<_WalletFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late AccountType _type;
  late String _icon;
  late int _color;
  late String _currency;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final settings = ref.read(settingsControllerProvider).value;
    _currency =
        existing?.currency ??
        settings?.currencyCode ??
        AppCurrencies.defaultCode;
    final locale = settings?.localeCode ?? 'vi';

    _nameController = TextEditingController(text: existing?.name ?? '');
    _balanceController = TextEditingController(
      text: existing == null
          ? ''
          : Money(
              minorUnits: existing.balance,
              currencyCode: _currency,
            ).toInputString(locale: locale),
    );
    _type = existing?.type ?? AccountType.cash;
    _icon = existing?.icon ?? _type.defaultIconKey;
    _color = existing?.color ?? AppIconCatalog.palette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final parsedBalance =
        Money.tryParse(_balanceController.text, currencyCode: _currency) ??
        Money.zero(_currency);
    final ctrl = ref.read(accountsActionControllerProvider.notifier);

    final existing = widget.existing;
    final Result<Account> result = existing == null
        ? await ctrl.createWallet(
            name: _nameController.text,
            type: _type,
            initialBalance: parsedBalance.minorUnits,
            currency: _currency,
            icon: _icon,
            color: _color,
          )
        : await ctrl.updateWallet(
            existing.copyWith(
              name: _nameController.text,
              type: _type,
              balance: parsedBalance.minorUnits,
              currency: _currency,
              icon: _icon,
              color: _color,
            ),
          );

    if (!mounted) return;
    result.fold(
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
    final locale = ref.watch(settingsControllerProvider).value?.localeCode ?? 'vi';
    final currencyInfo = AppCurrencies.byCode(_currency);

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
                widget.existing == null ? l10n.addWallet : l10n.editWallet,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              AppleTextField(
                controller: _nameController,
                maxLength: 100,
                textInputAction: TextInputAction.next,
                label: l10n.walletName,
                placeholder: l10n.walletNameHint,
                validator: (v) {
                  final trimmed = v?.trim() ?? '';
                  if (trimmed.isEmpty || trimmed.length > 100) {
                    return l10n.errorValidation;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<AccountType>(
                isExpanded: true,
                initialValue: _type,
                decoration: InputDecoration(labelText: l10n.walletType),
                items: [
                  DropdownMenuItem(
                    value: AccountType.cash,
                    child: Text(l10n.walletTypeCash),
                  ),
                  DropdownMenuItem(
                    value: AccountType.bank,
                    child: Text(l10n.walletTypeBank),
                  ),
                  DropdownMenuItem(
                    value: AccountType.ewallet,
                    child: Text(l10n.walletTypeEwallet),
                  ),
                  DropdownMenuItem(
                    value: AccountType.card,
                    child: Text(l10n.walletTypeCard),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _type = value;
                      _icon = value.defaultIconKey;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              AppleTextField(
                controller: _balanceController,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: currencyInfo.decimalDigits > 0,
                ),
                inputFormatters: [
                  MoneyInputFormatter(currencyCode: _currency, locale: locale),
                ],
                label: widget.existing == null
                    ? l10n.initialBalance
                    : l10n.currentBalance,
                suffix: Text(
                  currencyInfo.symbol,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 18),
              IconAndColorPicker(
                selectedIcon: _icon,
                selectedColor: _color,
                onIconChanged: (v) => setState(() => _icon = v),
                onColorChanged: (v) => setState(() => _color = v),
                iconSectionLabel: l10n.selectIcon,
                colorSectionLabel: l10n.selectColor,
              ),
              const SizedBox(height: 24),
              AppleButton.primary(
                onPressed: _submit,
                label: l10n.save,
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
