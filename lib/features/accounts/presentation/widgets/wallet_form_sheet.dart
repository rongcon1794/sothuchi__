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

const _kWalletTemplates = [
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

const _kWalletIcons = [
  ('cash', 'Tiền mặt'),
  ('bank', 'Ngân hàng'),
  ('ewallet', 'Ví điện tử'),
  ('card', 'Thẻ'),
  ('savings', 'Tiết kiệm'),
  ('wallet', 'Ví chính'),
  ('salary', 'Lương'),
  ('investment', 'Đầu tư'),
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

    _nameController.addListener(_onFieldChanged);
    _balanceController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
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
    result.fold(
      onSuccess: (acc) {
        unawaited(HapticFeedback.lightImpact());
        Navigator.of(context).pop(acc);
      },
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
                title: 'Mẫu tài khoản & ví phổ biến',
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

  Widget _buildLiveWalletPreviewCard({
    required BuildContext context,
    required bool isDark,
    required Color walletColor,
    required String locale,
    required AppLocalizations l10n,
    required CurrencyInfo currencyInfo,
  }) {
    final nameText = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : l10n.walletNameHint;
    final parsedBalance = Money.tryParse(
          _balanceController.text,
          currencyCode: _currency,
        ) ??
        Money.zero(_currency);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            walletColor,
            Color.lerp(walletColor, Colors.black, isDark ? 0.45 : 0.3)!,
          ],
        ),
        borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
        boxShadow: [
          BoxShadow(
            color: walletColor.withValues(alpha: isDark ? 0.45 : 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
        child: Stack(
          children: [
            // Decorative card gloss/shimmer circle
            Positioned(
              right: -20,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Metallic Smart Chip Graphic
                      Container(
                        width: 38,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFDF7A),
                              Color(0xFFD4AF37),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 1, color: Colors.black26),
                            const SizedBox(width: 8),
                            Container(width: 1, color: Colors.black26),
                          ],
                        ),
                      ),
                      // Icon Badge & NFC Symbol
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.radiowaves_right,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                            ),
                            child: Icon(
                              AppIconCatalog.resolve(_icon),
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // Wallet Name
                  Text(
                    nameText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Balance with tabular figures
                  Text(
                    parsedBalance.format(locale: locale),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Bottom row: Type pill & currency tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius:
                              BorderRadius.circular(AppleTokens.radiusPill),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          _typeLabel(l10n, _type).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Text(
                        _currency,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildTemplatesCarousel({required bool isDark}) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _kWalletTemplates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final tpl = _kWalletTemplates[index];
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
    final types = [
      (
        type: AccountType.cash,
        label: l10n.walletTypeCash,
        icon: Icons.payments_rounded,
        desc: 'Tiền mặt hàng ngày',
      ),
      (
        type: AccountType.bank,
        label: l10n.walletTypeBank,
        icon: Icons.account_balance_rounded,
        desc: 'Tài khoản ngân hàng',
      ),
      (
        type: AccountType.ewallet,
        label: l10n.walletTypeEwallet,
        icon: Icons.qr_code_2_rounded,
        desc: 'MoMo, ZaloPay...',
      ),
      (
        type: AccountType.card,
        label: l10n.walletTypeCard,
        icon: Icons.credit_card_rounded,
        desc: 'Thẻ tín dụng / visa',
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
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _kWalletIcons.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = _kWalletIcons[index];
          final isSelected = _icon == item.$1;
          return ApplePressable(
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              setState(() => _icon = item.$1);
            },
            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor
                        : (isDark
                            ? AppleTokens.bgDarkSecondary
                            : AppleTokens.bgLightSecondary),
                    borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
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
                    size: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.$2,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : accentColor)
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorSelector({required bool isDark}) {
    const palette = AppIconCatalog.palette;

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: palette.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final colorVal = palette[index];
          final isSelected = _color == colorVal;
          final color = Color(colorVal);
          return ApplePressable(
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              setState(() => _color = colorVal);
            },
            borderRadius: BorderRadius.circular(23),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isSelected ? 0.45 : 0.2),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSelected
                  ? const Icon(CupertinoIcons.checkmark,
                      color: Colors.white, size: 20)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
