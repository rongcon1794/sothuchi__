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

            // 8. Default Wallet Setting (Đặt làm ví mặc định)
            _buildSectionHeader(
              icon: CupertinoIcons.star_fill,
              title: 'Cài đặt ví',
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
                        const Text(
                          'Đặt làm ví mặc định',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tự động chọn ví này khi thêm giao dịch mới',
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
          color: _isDefault
              ? const Color(0xFFFFB800).withValues(alpha: isDark ? 0.65 : 0.55)
              : walletColor.withValues(alpha: isDark ? 0.35 : 0.22),
          width: _isDefault ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDefault
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
                          AppIconCatalog.resolve(_icon),
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
                              nameText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16.5,
                                letterSpacing: -0.2,
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
                                    horizontal: 8,
                                    vertical: 3.5,
                                  ),
                                  alignment: Alignment.center,
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
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _typeIcon(_type),
                                        size: 11,
                                        color: isDark
                                            ? Colors.white70
                                            : walletColor,
                                      ),
                                      const SizedBox(width: 3.5),
                                      Text(
                                        _typeLabel(l10n, _type),
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white70
                                              : walletColor,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Default Wallet Badge
                                if (_isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3.5,
                                    ),
                                    alignment: Alignment.center,
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
                                      crossAxisAlignment: CrossAxisAlignment.center,
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
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Currency Code Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3.5,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(
                                      AppleTokens.radiusPill,
                                    ),
                                  ),
                                  child: Text(
                                    _currency.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                      letterSpacing: 0.2,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 6),

                      // 3-dots action icon matching list tile
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: const Icon(
                          CupertinoIcons.ellipsis_vertical,
                          size: 16,
                          color: AppleTokens.systemGray,
                        ),
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
                      // Label: "SỐ DƯ BAN ĐẦU" with glowing indicator dot
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
                            widget.existing != null ? 'SỐ DƯ HIỆN TẠI' : 'SỐ DƯ BAN ĐẦU',
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: -0.3,
                                  fontFeatures: AppTheme.tabularFigures,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              CupertinoIcons.chevron_right,
                              size: 14,
                              color: AppleTokens.systemGray,
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
