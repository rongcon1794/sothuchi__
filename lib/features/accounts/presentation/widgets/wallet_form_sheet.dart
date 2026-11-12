import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/errors/result.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

class _WalletTemplate {
  const _WalletTemplate({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  final String name;
  final AccountType type;
  final String icon;
  final int color;
  final String subtitle;
}

const _kWalletTemplatesVi = [
  _WalletTemplate(
    name: 'Tiền mặt',
    type: AccountType.cash,
    icon: 'cash',
    color: 0xFF0D7C66,
    subtitle: 'Tiền mặt hàng ngày',
  ),
  _WalletTemplate(
    name: 'Vietcombank',
    type: AccountType.bank,
    icon: 'bank',
    color: 0xFF15803D,
    subtitle: 'Ngân hàng VCB',
  ),
  _WalletTemplate(
    name: 'MB Bank',
    type: AccountType.bank,
    icon: 'bank',
    color: 0xFF1D5BD6,
    subtitle: 'Ngân hàng Quân Đội',
  ),
  _WalletTemplate(
    name: 'Techcombank',
    type: AccountType.bank,
    icon: 'bank',
    color: 0xFFC0352B,
    subtitle: 'Ngân hàng TCB',
  ),
  _WalletTemplate(
    name: 'Ví MoMo',
    type: AccountType.ewallet,
    icon: 'ewallet',
    color: 0xFFDB2777,
    subtitle: 'Ví điện tử MoMo',
  ),
  _WalletTemplate(
    name: 'ZaloPay',
    type: AccountType.ewallet,
    icon: 'ewallet',
    color: 0xFF0891B2,
    subtitle: 'Ví điện tử ZaloPay',
  ),
  _WalletTemplate(
    name: 'ShopeePay',
    type: AccountType.ewallet,
    icon: 'ewallet',
    color: 0xFFD97706,
    subtitle: 'Ví mua sắm Shopee',
  ),
  _WalletTemplate(
    name: 'Thẻ Tín Dụng',
    type: AccountType.card,
    icon: 'card',
    color: 0xFF4F46E5,
    subtitle: 'Visa / MasterCard',
  ),
  _WalletTemplate(
    name: 'Sổ Tiết Kiệm',
    type: AccountType.bank,
    icon: 'savings',
    color: 0xFFB45309,
    subtitle: 'Tích lũy sinh lời',
  ),
];

const _kWalletTemplatesEn = [
  _WalletTemplate(
    name: 'Cash',
    type: AccountType.cash,
    icon: 'cash',
    color: 0xFF0D7C66,
    subtitle: 'Daily cash',
  ),
  _WalletTemplate(
    name: 'Checking Bank',
    type: AccountType.bank,
    icon: 'bank',
    color: 0xFF15803D,
    subtitle: 'Main bank account',
  ),
  _WalletTemplate(
    name: 'Digital Bank',
    type: AccountType.bank,
    icon: 'bank',
    color: 0xFF1D5BD6,
    subtitle: 'Online banking',
  ),
  _WalletTemplate(
    name: 'E-Wallet',
    type: AccountType.ewallet,
    icon: 'ewallet',
    color: 0xFFDB2777,
    subtitle: 'Mobile wallet',
  ),
  _WalletTemplate(
    name: 'PayPal / Apple Pay',
    type: AccountType.ewallet,
    icon: 'ewallet',
    color: 0xFF0891B2,
    subtitle: 'Digital payments',
  ),
  _WalletTemplate(
    name: 'Credit Card',
    type: AccountType.card,
    icon: 'card',
    color: 0xFF4F46E5,
    subtitle: 'Visa / MasterCard',
  ),
  _WalletTemplate(
    name: 'Savings Account',
    type: AccountType.bank,
    icon: 'savings',
    color: 0xFFB45309,
    subtitle: 'Interest savings',
  ),
];

class WalletFormSheet extends ConsumerStatefulWidget {
  const WalletFormSheet({super.key, this.existing});

  final Account? existing;

  static Future<Account?> show(BuildContext context, {Account? existing}) {
    return AppleModalSheetLayout.show<Account?>(
      context: context,
      useSafeArea: true,
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
  late bool _isDefault;

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

    final currentDefault = settings?.defaultWalletId;
    _isDefault = existing != null
        ? currentDefault == existing.id
        : (currentDefault == null || currentDefault.isEmpty);

    _nameController.addListener(_onFieldChanged);
    _balanceController.addListener(_onFieldChanged);
    _lastNameText = _nameController.text;
    _lastBalanceText = _balanceController.text;
  }

  String _lastNameText = '';
  String _lastBalanceText = '';

  void _onFieldChanged() {
    final name = _nameController.text;
    final balance = _balanceController.text;
    if (name == _lastNameText && balance == _lastBalanceText) return;
    _lastNameText = name;
    _lastBalanceText = balance;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _balanceController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  String _typeLabel(AppLocalizations l10n, AccountType type) => switch (type) {
    AccountType.cash => l10n.walletTypeCash,
    AccountType.bank => l10n.walletTypeBank,
    AccountType.ewallet => l10n.walletTypeEwallet,
    AccountType.card => l10n.walletTypeCard,
  };

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final parsedBalance =
        Money.tryParse(_balanceController.text, currencyCode: _currency) ??
        Money.zero(_currency);
    final ctrl = ref.read(accountsActionControllerProvider.notifier);

    unawaited(HapticFeedback.mediumImpact());
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
    await result.fold(
      onSuccess: (acc) async {
        unawaited(HapticFeedback.lightImpact());
        if (_isDefault) {
          await ref
              .read(settingsControllerProvider.notifier)
              .setDefaultWalletId(acc.id);
        } else {
          final currentDefault =
              ref.read(settingsControllerProvider).value?.defaultWalletId;
          if (currentDefault == acc.id) {
            await ref
                .read(settingsControllerProvider.notifier)
                .setDefaultWalletId(null);
          }
        }
        if (mounted) {
          Navigator.of(context).pop(acc);
        }
      },
      onFailure: (err) async {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.localizeError(err))));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(
      settingsControllerProvider.select((s) => s.value?.localeCode ?? 'vi'),
    );
    final currencyInfo = AppCurrencies.byCode(_currency);
    final walletColor = Color(_color);

    return AppleModalSheetLayout(
      title: widget.existing == null ? l10n.addWallet : l10n.editWallet,
      bottomAction: AppleButton.primary(
        color: walletColor,
        onPressed: _submit,
        label: l10n.save,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Interactive Apple Wallet Card Live Preview
            _buildLiveWalletPreviewCard(
              context: context,
              isDark: isDark,
              walletColor: walletColor,
              locale: locale,
              l10n: l10n,
              currencyInfo: currencyInfo,
            ),
            const SizedBox(height: 18),

            // 2. Popular Presets (only in create mode)
            if (widget.existing == null) ...[
              _buildSectionHeader(
                icon: CupertinoIcons.sparkles,
                title: locale == 'vi'
                    ? 'Mẫu tài khoản & ví phổ biến'
                    : 'Popular wallet templates',
                accentColor: walletColor,
              ),
              _buildTemplatesCarousel(isDark: isDark),
              const SizedBox(height: 18),
            ],

            // 3. Tactile Wallet Type Selector
            _buildSectionHeader(
              icon: CupertinoIcons.tag_fill,
              title: l10n.walletType,
              accentColor: walletColor,
            ),
            _buildTypeSelector(
              isDark: isDark,
              accentColor: walletColor,
              l10n: l10n,
            ),
            const SizedBox(height: 18),

            // 4. Wallet Name Input
            _buildSectionHeader(
              icon: CupertinoIcons.pencil,
              title: l10n.walletName,
              accentColor: walletColor,
            ),
            AppleTextField(
              controller: _nameController,
              maxLength: 100,
              textInputAction: TextInputAction.next,
              placeholder: l10n.walletNameHint,
              prefixIcon: Icon(
                AppIconCatalog.resolve(_icon),
                size: 18,
                color: walletColor,
              ),
              clearable: true,
              validator: (v) {
                final trimmed = v?.trim() ?? '';
                if (trimmed.isEmpty || trimmed.length > 100) {
                  return l10n.errorValidation;
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // 5. Initial / Current Balance Hero Input Card
            _buildSectionHeader(
              icon: CupertinoIcons.money_dollar_circle_fill,
              title: widget.existing == null
                  ? l10n.initialBalance
                  : l10n.currentBalance,
              accentColor: walletColor,
            ),
            HeroAmountCard(
              controller: _balanceController,
              currencyCode: _currency,
              locale: locale,
              accentColor: walletColor,
            ),
            const SizedBox(height: 18),

            // 6. Curated Icon Collection
            _buildSectionHeader(
              icon: CupertinoIcons.app_badge_fill,
              title: l10n.selectIcon,
              accentColor: walletColor,
            ),
            _buildIconSelector(
              isDark: isDark,
              accentColor: walletColor,
            ),
            const SizedBox(height: 18),

            // 7. Curated Color Palette
            _buildSectionHeader(
              icon: CupertinoIcons.paintbrush_fill,
              title: l10n.selectColor,
              accentColor: walletColor,
            ),
            _buildColorSelector(isDark: isDark),
            const SizedBox(height: 18),

            // 8. Default Wallet Setting (Đặt làm ví mặc định)
            _buildSectionHeader(
              icon: CupertinoIcons.star_fill,
              title: locale == 'vi' ? 'Cài đặt ví' : 'Wallet settings',
              accentColor: walletColor,
            ),
            AppleGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderColor: _isDefault
                  ? const Color(0xFFFFB800).withValues(alpha: 0.5)
                  : null,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _isDefault
                          ? const Color(0xFFFFB800).withValues(alpha: 0.2)
                          : AppleTokens.systemGray.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isDefault ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: _isDefault ? const Color(0xFFFFB800) : AppleTokens.systemGray,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale == 'vi'
                              ? 'Đặt làm ví mặc định'
                              : 'Set as default wallet',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          locale == 'vi'
                              ? 'Tự động chọn ví này khi thêm giao dịch mới'
                              : 'Auto-select this wallet for new transactions',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isDefault,
                    activeTrackColor: walletColor,
                    onChanged: (val) {
                      unawaited(HapticFeedback.selectionClick());
                      setState(() => _isDefault = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    Color? accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 13,
            color: accentColor ?? AppleTokens.systemGray,
          ),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: accentColor ?? AppleTokens.systemGray,
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(AccountType type) => switch (type) {
        AccountType.cash => Icons.payments_rounded,
        AccountType.bank => Icons.account_balance_rounded,
        AccountType.ewallet => Icons.qr_code_2_rounded,
        AccountType.card => Icons.credit_card_rounded,
      };

  Widget _buildLiveWalletPreviewCard({
    required BuildContext context,
    required bool isDark,
    required Color walletColor,
    required String locale,
    required AppLocalizations l10n,
    required CurrencyInfo currencyInfo,
  }) {
    final theme = Theme.of(context);
    final nameText = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : l10n.walletNameHint;
    final parsedBalance = Money.tryParse(
          _balanceController.text,
          currencyCode: _currency,
        ) ??
        Money.zero(_currency);
    final balanceText = parsedBalance.format(locale: locale);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? Color.lerp(walletColor, const Color(0xFF1E1E22), 0.85)!
                : Color.lerp(walletColor, Colors.white, 0.92)!,
            isDark
                ? const Color(0xFF141416)
                : Color.lerp(walletColor, const Color(0xFFF7F8FA), 0.97)!,
          ],
        ),
        border: Border.all(
          color: _isDefault
              ? const Color(0xFFFFB800).withValues(alpha: isDark ? 0.60 : 0.48)
              : walletColor.withValues(alpha: isDark ? 0.30 : 0.18),
          width: _isDefault ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDefault
                ? const Color(0xFFFFB800).withValues(alpha: isDark ? 0.14 : 0.06)
                : walletColor.withValues(alpha: isDark ? 0.14 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        child: Stack(
          children: [
            // Subtle ambient radiant glow at top-right
            Positioned(
              right: -20,
              top: -24,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      walletColor.withValues(alpha: isDark ? 0.18 : 0.10),
                      walletColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Squircle Icon Badge with subtle gradient & shadow
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          walletColor,
                          Color.lerp(
                            walletColor,
                            Colors.black,
                            isDark ? 0.35 : 0.2,
                          )!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.3 : 0.45,
                        ),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: walletColor.withValues(
                            alpha: isDark ? 0.35 : 0.20,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      AppIconCatalog.resolve(_icon),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Main info: Line 1 (Name + Badges + Menu) & Line 2 (Type/Currency + Balance)
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Line 1: Wallet Name + Badges + Menu Placeholder
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      nameText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15.5,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  if (_isDefault) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
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
                                                .withValues(alpha: 0.3),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 10,
                                            color: Color(0xFF4A3500),
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            locale == 'vi' ? 'Mặc định' : 'Default',
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF4A3500),
                                              letterSpacing: 0.1,
                                              height: 1.1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Menu Placeholder Icon
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              child: Icon(
                                CupertinoIcons.ellipsis_vertical,
                                size: 14,
                                color: isDark ? Colors.white54 : AppleTokens.systemGray,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),

                        // Line 2: Type • Currency & Financial Balance
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _typeIcon(_type),
                                  size: 12,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_typeLabel(l10n, _type)} • ${_currency.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            Flexible(
                              child: Text(
                                balanceText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: AppTheme.tabularFigures,
                                  letterSpacing: -0.3,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1C1C1E),
                                ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesCarousel({required bool isDark}) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    final templates = isVi ? _kWalletTemplatesVi : _kWalletTemplatesEn;
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: templates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final tpl = templates[index];
          final tplColor = Color(tpl.color);
          return ApplePressable(
            onTap: () {
              unawaited(HapticFeedback.mediumImpact());
              setState(() {
                _nameController.text = tpl.name;
                _type = tpl.type;
                _icon = tpl.icon;
                _color = tpl.color;
              });
            },
            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppleTokens.bgDarkSecondary
                    : AppleTokens.bgLightSecondary,
                borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                border: Border.all(
                  color: tplColor.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tplColor.withValues(alpha: 0.16),
                      borderRadius:
                          BorderRadius.circular(AppleTokens.radiusControl),
                    ),
                    child: Icon(
                      AppIconCatalog.resolve(tpl.icon),
                      color: tplColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tpl.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tpl.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypeSelector({
    required bool isDark,
    required Color accentColor,
    required AppLocalizations l10n,
  }) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    final types = [
      (
        type: AccountType.cash,
        label: l10n.walletTypeCash,
        icon: Icons.payments_rounded,
        desc: isVi ? 'Tiền mặt hàng ngày' : 'Daily cash',
      ),
      (
        type: AccountType.bank,
        label: l10n.walletTypeBank,
        icon: Icons.account_balance_rounded,
        desc: isVi ? 'Tài khoản ngân hàng' : 'Bank account',
      ),
      (
        type: AccountType.ewallet,
        label: l10n.walletTypeEwallet,
        icon: Icons.qr_code_2_rounded,
        desc: isVi ? 'MoMo, ZaloPay...' : 'Digital wallets...',
      ),
      (
        type: AccountType.card,
        label: l10n.walletTypeCard,
        icon: Icons.credit_card_rounded,
        desc: isVi ? 'Thẻ tín dụng / visa' : 'Credit / debit card',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: types.map((item) {
            final isSelected = _type == item.type;
            return SizedBox(
              width: cardWidth,
              child: ApplePressable(
                onTap: () {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() {
                    _type = item.type;
                    _icon = item.type.defaultIconKey;
                  });
                },
                borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: isDark ? 0.22 : 0.12)
                        : (isDark
                            ? AppleTokens.bgDarkSecondary
                            : AppleTokens.bgLightSecondary),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : (isDark
                              ? AppleTokens.separatorDark
                              : AppleTokens.separatorLight),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor
                              : (isDark ? Colors.white12 : Colors.black12),
                          borderRadius:
                              BorderRadius.circular(AppleTokens.radiusControl),
                        ),
                        child: Icon(
                          item.icon,
                          size: 18,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: isSelected
                                    ? (isDark ? Colors.white : accentColor)
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.desc,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? Colors.white54 : Colors.black54,
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
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildIconSelector({
    required bool isDark,
    required Color accentColor,
  }) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    const items = AppIconCatalog.walletIconItems;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 420 ? 5 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 8,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = _icon == item.$1;
            return ApplePressable(
              onTap: () {
                unawaited(HapticFeedback.selectionClick());
                setState(() => _icon = item.$1);
              },
              borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor
                          : (isDark
                              ? AppleTokens.bgDarkSecondary
                              : AppleTokens.bgLightSecondary),
                      borderRadius:
                          BorderRadius.circular(AppleTokens.radiusCard),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? AppleTokens.separatorDark
                                : AppleTokens.separatorLight),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      AppIconCatalog.resolve(item.$1),
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                      size: 21,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppIconCatalog.localizedWalletIconLabel(item.$1, isVi: isVi),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : accentColor)
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildColorSelector({required bool isDark}) {
    const palette = AppIconCatalog.palette;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 560 ? 14 : 7;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: palette.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final colorVal = palette[index];
            final isSelected = _color == colorVal;
            final color = Color(colorVal);
            return ApplePressable(
              onTap: () {
                unawaited(HapticFeedback.selectionClick());
                setState(() => _color = colorVal);
              },
              borderRadius: BorderRadius.circular(22),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 36 : 30,
                  height: isSelected ? 36 : 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            color.withValues(alpha: isSelected ? 0.45 : 0.2),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(
                          CupertinoIcons.checkmark,
                          color: Colors.white,
                          size: 17,
                        )
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
