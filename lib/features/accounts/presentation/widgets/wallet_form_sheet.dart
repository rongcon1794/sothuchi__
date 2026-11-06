import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/core/widgets/icon_and_color_picker.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';

class WalletFormSheet extends ConsumerStatefulWidget {
  const WalletFormSheet({super.key, this.existing});

  final Account? existing;

  static Future<void> show(BuildContext context, {Account? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => WalletFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<WalletFormSheet> {
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
            name: _nameController.text.trim(),
            type: _type,
            initialBalance: parsedBalance.minorUnits,
            currency: _currency,
            icon: _icon,
            color: _color,
          )
        : await ctrl.updateWallet(
            existing.copyWith(
              name: _nameController.text.trim(),
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
    final locale =
        ref.watch(settingsControllerProvider).value?.localeCode ?? 'vi';
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
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
              LucianSlidingPillTabs<AccountType>(
                items: [
                  LucianTabItem(
                    value: AccountType.cash,
                    label: l10n.walletTypeCash,
                    icon: Icons.money_rounded,
                  ),
                  LucianTabItem(
                    value: AccountType.bank,
                    label: l10n.walletTypeBank,
                    icon: Icons.account_balance_rounded,
                  ),
                  LucianTabItem(
                    value: AccountType.ewallet,
                    label: l10n.walletTypeEwallet,
                    icon: Icons.phone_android_rounded,
                  ),
                  LucianTabItem(
                    value: AccountType.card,
                    label: l10n.walletTypeCard,
                    icon: Icons.credit_card_rounded,
                  ),
                ],
                selected: _type,
                onChanged: (value) {
                  setState(() {
                    _type = value;
                    _icon = value.defaultIconKey;
                  });
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

