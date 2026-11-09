import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/theme/tokens/app_semantic_colors.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

/// Preset amount item for quick selection in [HeroAmountCard].
typedef HeroAmountPreset = ({int minorUnits, String label});

/// Reusable Apple-styled Hero Amount Card for Forms (Wallets, Budgets, Savings, Recurring, Debts).
/// Features:
/// - Large high-contrast tabular currency input (24-28pt)
/// - Integrated [MoneyInputFormatter]
/// - Clear button `[✕]`
/// - Quick preset amount chips (e.g., 500k, 1tr, 2tr, 5tr or custom)
/// - Optional `+000` quick multiplier button
/// - Full theme compliance with [AppSemanticColors] and dark/light/oled modes.
class HeroAmountCard extends StatelessWidget {
  const HeroAmountCard({
    super.key,
    required this.controller,
    required this.currencyCode,
    this.locale = 'vi',
    this.label,
    this.accentColor,
    this.presets,
    this.showPresets = true,
    this.showTripleZeroButton = true,
    this.focusNode,
    this.autofocus = false,
    this.readOnly = false,
    this.onChanged,
    this.onClear,
    this.onPresetSelected,
  });

  final TextEditingController controller;
  final String currencyCode;
  final String locale;
  final String? label;
  final Color? accentColor;
  final List<HeroAmountPreset>? presets;
  final bool showPresets;
  final bool showTripleZeroButton;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final ValueChanged<int>? onPresetSelected;

  void _handlePreset(BuildContext context, int minorUnits) {
    unawaited(HapticFeedback.selectionClick());
    if (onPresetSelected != null) {
      onPresetSelected!(minorUnits);
      return;
    }
    final formatted = Money(
      minorUnits: minorUnits,
      currencyCode: currencyCode,
    ).toInputString(locale: locale);
    controller.text = formatted;
    controller.selection = TextSelection.collapsed(offset: formatted.length);
    if (onChanged != null) {
      onChanged!(formatted);
    }
  }

  void _appendTripleZeros() {
    final current = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (current.isEmpty || current == '0') return;
    unawaited(HapticFeedback.selectionClick());
    final newRaw = '${current}000';
    final parsed = int.tryParse(newRaw);
    if (parsed == null) return;
    final formatted = Money(
      minorUnits: parsed,
      currencyCode: currencyCode,
    ).toInputString(locale: locale);
    controller.text = formatted;
    controller.selection = TextSelection.collapsed(offset: formatted.length);
    if (onChanged != null) {
      onChanged!(formatted);
    }
  }

  void _handleClear() {
    unawaited(HapticFeedback.lightImpact());
    if (onClear != null) {
      onClear!();
      return;
    }
    controller.clear();
    if (onChanged != null) {
      onChanged!('');
    }
  }

  List<HeroAmountPreset> _defaultPresets(CurrencyInfo currencyInfo) {
    if (currencyCode.toUpperCase() == 'VND') {
      return const [
        (minorUnits: 0, label: '0₫'),
        (minorUnits: 500000, label: '500k'),
        (minorUnits: 1000000, label: '1 triệu'),
        (minorUnits: 2000000, label: '2 triệu'),
        (minorUnits: 5000000, label: '5 triệu'),
        (minorUnits: 10000000, label: '10 triệu'),
        (minorUnits: 20000000, label: '20 triệu'),
      ];
    } else {
      final f = currencyInfo.minorUnitFactor;
      final sym = currencyInfo.symbol;
      return [
        (minorUnits: 0, label: '0'),
        (minorUnits: 50 * f, label: '$sym 50'),
        (minorUnits: 100 * f, label: '$sym 100'),
        (minorUnits: 500 * f, label: '$sym 500'),
        (minorUnits: 1000 * f, label: '$sym 1k'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = context.semanticColors;
    final currencyInfo = AppCurrencies.byCode(currencyCode);
    final activeAccent = accentColor ?? theme.colorScheme.primary;
    final effectivePresets = presets ?? _defaultPresets(currencyInfo);
    final isVnd = currencyCode.toUpperCase() == 'VND';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        border: Border.all(
          color: colors.inputBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: activeAccent,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Main amount input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: autofocus,
                  readOnly: readOnly,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: currencyInfo.decimalDigits > 0,
                  ),
                  inputFormatters: [
                    MoneyInputFormatter(
                      currencyCode: currencyCode,
                      locale: locale,
                    ),
                  ],
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    fontFeatures: AppTheme.tabularFigures,
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    filled: false,
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: colors.textTertiary,
                    ),
                  ),
                  onChanged: onChanged,
                ),
              ),

              // Currency badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: activeAccent.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                  border: Border.all(
                    color: activeAccent.withValues(alpha: isDark ? 0.40 : 0.25),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  currencyInfo.symbol,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: activeAccent,
                  ),
                ),
              ),

              // Clear Button
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  if (controller.text.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ApplePressable(
                      scaleDown: 0.88,
                      onTap: _handleClear,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          CupertinoIcons.clear_circled_solid,
                          size: 20,
                          color: colors.textTertiary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          if (showPresets && effectivePresets.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 32,
              child: Row(
                children: [
                  Expanded(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: effectivePresets.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final p = effectivePresets[index];
                        return ApplePressable(
                          scaleDown: 0.92,
                          onTap: () => _handlePreset(context, p.minorUnits),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceSecondary,
                              borderRadius:
                                  BorderRadius.circular(AppleTokens.radiusPill),
                              border: Border.all(
                                color: colors.pillBorder,
                                width: 0.8,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                p.label,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Quick +000 Shortcut (for VND)
                  if (showTripleZeroButton && isVnd) ...[
                    const SizedBox(width: 8),
                    ApplePressable(
                      scaleDown: 0.90,
                      onTap: _appendTripleZeros,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: activeAccent.withValues(
                            alpha: isDark ? 0.20 : 0.12,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppleTokens.radiusPill),
                          border: Border.all(
                            color: activeAccent.withValues(
                              alpha: isDark ? 0.40 : 0.25,
                            ),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '+000',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: activeAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

