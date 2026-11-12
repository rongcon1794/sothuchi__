import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/constants/icon_catalog.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/domain/entities/account.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';

class TransferBetweenWalletsSheet extends ConsumerStatefulWidget {
  const TransferBetweenWalletsSheet({super.key});

  @override
  ConsumerState<TransferBetweenWalletsSheet> createState() =>
      _TransferBetweenWalletsSheetState();
}

class _TransferBetweenWalletsSheetState
    extends ConsumerState<TransferBetweenWalletsSheet> {
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
    final locale = ref.watch(
      settingsControllerProvider.select((s) => s.value?.localeCode ?? 'vi'),
    );
    final currency = _resolveFromCurrency(active);
    final currencyInfo = AppCurrencies.byCode(currency);

    final isVi = locale.startsWith('vi');
    final presets = currency.toUpperCase() == 'VND'
        ? [
            const (minorUnits: 100000, label: '100k'),
            const (minorUnits: 200000, label: '200k'),
            const (minorUnits: 500000, label: '500k'),
            (minorUnits: 1000000, label: isVi ? '1 triệu' : '1M'),
            (minorUnits: 2000000, label: isVi ? '2 triệu' : '2M'),
            (minorUnits: 5000000, label: isVi ? '5 triệu' : '5M'),
          ]
        : [
            (
              minorUnits: 10 * currencyInfo.minorUnitFactor,
              label: '${currencyInfo.symbol}10',
            ),
            (
              minorUnits: 50 * currencyInfo.minorUnitFactor,
              label: '${currencyInfo.symbol}50',
            ),
            (
              minorUnits: 100 * currencyInfo.minorUnitFactor,
              label: '${currencyInfo.symbol}100',
            ),
            (
              minorUnits: 500 * currencyInfo.minorUnitFactor,
              label: '${currencyInfo.symbol}500',
            ),
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
                    color: AppleTokens.systemBlue.withValues(
                      alpha: isDark ? 0.25 : 0.12,
                    ),
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
                  color: isDark
                      ? AppleTokens.separatorDark
                      : AppleTokens.separatorLight,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppleTokens.systemBlue.withValues(
                            alpha: isDark ? 0.2 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppleTokens.radiusPill,
                          ),
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
                              onTap: () => _setPresetAmount(
                                p.minorUnits,
                                currency,
                                locale,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppleTokens.radiusPill,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    AppleTokens.radiusPill,
                                  ),
                                  border: Border.all(
                                    color: isDark
                                        ? AppleTokens.separatorDark
                                        : AppleTokens.separatorLight,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  p.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (currency.toUpperCase() == 'VND')
                          ApplePressable(
                            onTap: () => _appendTripleZeros(currency, locale),
                            borderRadius: BorderRadius.circular(
                              AppleTokens.radiusPill,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppleTokens.systemBlue.withValues(
                                  alpha: isDark ? 0.22 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppleTokens.radiusPill,
                                ),
                                border: Border.all(
                                  color: AppleTokens.systemBlue.withValues(
                                    alpha: 0.35,
                                  ),
                                  width: 0.8,
                                ),
                              ),
                              child: const Text(
                                '+000',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppleTokens.systemBlue,
                                  height: 1.2,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
                        borderRadius: BorderRadius.circular(
                          AppleTokens.radiusControl,
                        ),
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
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
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

