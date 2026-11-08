import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/constants/currency_constants.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/transactions/domain/entities/transaction_entity.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_type_segmented_pill.dart';

class TransactionHeroAmountCard extends StatefulWidget {
  const TransactionHeroAmountCard({
    super.key,
    required this.type,
    required this.amountController,
    required this.focusNode,
    required this.currencyInfo,
    required this.currencyCode,
    required this.locale,
    required this.isEditing,
    required this.onTypeChanged,
    required this.onSetAmount,
    required this.onClear,
    this.availableWalletBalance,
    this.isKeypadOpen = false,
    this.onToggleKeypad,
  });

  final TransactionType type;
  final TextEditingController amountController;
  final FocusNode focusNode;
  final CurrencyInfo currencyInfo;
  final String currencyCode;
  final String locale;
  final bool isEditing;
  final ValueChanged<TransactionType> onTypeChanged;
  final ValueChanged<int> onSetAmount;
  final VoidCallback onClear;
  final Money? availableWalletBalance;
  final bool isKeypadOpen;
  final VoidCallback? onToggleKeypad;

  @override
  State<TransactionHeroAmountCard> createState() => _TransactionHeroAmountCardState();
}

class _TransactionHeroAmountCardState extends State<TransactionHeroAmountCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  bool _wasOverBalance = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    widget.amountController.addListener(_onAmountChange);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 2.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 2.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: LucianTokens.ease));

    _checkBalance(notify: false);
  }

  @override
  void didUpdateWidget(covariant TransactionHeroAmountCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
    if (oldWidget.availableWalletBalance != widget.availableWalletBalance ||
        oldWidget.type != widget.type) {
      _checkBalance(notify: true);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.amountController.removeListener(_onAmountChange);
    _shakeController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  void _onAmountChange() {
    _checkBalance(notify: true);
  }

  void _checkBalance({bool notify = true}) {
    if (widget.type == TransactionType.income ||
        widget.availableWalletBalance == null) {
      if (_wasOverBalance) {
        if (notify && mounted) setState(() => _wasOverBalance = false);
      }
      return;
    }

    final rawMoney = Money.tryParse(widget.amountController.text,
        currencyCode: widget.currencyCode);
    final currentMinor = rawMoney?.minorUnits ?? 0;
    final isOver = currentMinor > widget.availableWalletBalance!.minorUnits;

    if (isOver && !_wasOverBalance) {
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        _shakeController.forward(from: 0.0);
        unawaited(HapticFeedback.mediumImpact());
      }
      if (notify && mounted) setState(() => _wasOverBalance = true);
    } else if (!isOver && _wasOverBalance) {
      if (notify && mounted) setState(() => _wasOverBalance = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFocused = widget.focusNode.hasFocus;

    final baseTypeColor = switch (widget.type) {
      TransactionType.expense => AppleTokens.rubyExpense,
      TransactionType.income => AppleTokens.jadePrimary,
      TransactionType.transfer => AppleTokens.cobaltTransfer,
    };

    final typeColor = _wasOverBalance
        ? LucianTokens.resolveDanger(isDark)
        : baseTypeColor;

    final typeSign = switch (widget.type) {
      TransactionType.expense => '-',
      TransactionType.income => '+',
      TransactionType.transfer => '⇄',
    };

    final isLandscape = context.isLandscape;

    return AppleGlassCard(
      padding: EdgeInsets.fromLTRB(
          16, isLandscape ? 10 : 16, 16, isLandscape ? 12 : 18),
      borderRadius: BorderRadius.circular(AppleTokens.radiusHero),
      borderColor: isFocused
          ? typeColor.withValues(alpha: isDark ? 0.6 : 0.45)
          : typeColor.withValues(alpha: isDark ? 0.35 : 0.25),
      child: Column(
        children: [
          // 1. Sliding Segmented Type Pill
          TransactionTypeSegmentedPill(
            selected: widget.type,
            onChanged: widget.onTypeChanged,
          ),
          const SizedBox(height: 18),

          // 2. Large Amount Input Display with Lucian Shake Animation
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              );
            },
            child: GestureDetector(
              onTap: () {
                if (!widget.focusNode.hasFocus) {
                  widget.focusNode.requestFocus();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isFocused
                      ? typeColor.withValues(alpha: isDark ? 0.12 : 0.07)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.02)),
                  borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
                  border: Border.all(
                    color: isFocused
                        ? typeColor
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08)),
                    width: isFocused ? 2.0 : 1.0,
                  ),
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: typeColor.withValues(
                                alpha: isDark ? 0.35 : 0.22),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      typeSign,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: typeColor,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: IntrinsicWidth(
                        child: TextFormField(
                          controller: widget.amountController,
                          focusNode: widget.focusNode,
                          autofocus: !widget.isEditing && !widget.isKeypadOpen,
                          readOnly: widget.isKeypadOpen,
                          textAlign: TextAlign.center,
                          showCursor: true,
                          cursorColor: typeColor,
                          cursorWidth: 3.0,
                          cursorRadius: const Radius.circular(2),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: widget.currencyInfo.decimalDigits > 0,
                          ),
                          inputFormatters: [
                            MoneyInputFormatter(
                              currencyCode: widget.currencyCode,
                              locale: widget.locale,
                            ),
                          ],
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: typeColor,
                            letterSpacing: -0.8,
                            fontFeatures: AppTheme.tabularFigures,
                            height: 1.1,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            filled: false,
                            fillColor: Colors.transparent,
                            isDense: true,
                            hintText: '0',
                            hintStyle: TextStyle(
                              color: typeColor.withValues(alpha: 0.25),
                              fontWeight: FontWeight.w800,
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (val) {
                            final m = Money.tryParse(val ?? '',
                                currencyCode: widget.currencyCode);
                            if (m == null || m.minorUnits <= 0) {
                              return context.l10n.amountRequiredError;
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.currencyInfo.symbol,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: typeColor.withValues(alpha: 0.85),
                        height: 1.0,
                      ),
                    ),
                    // Clear button inside when amount is non-empty
                    ListenableBuilder(
                      listenable: widget.amountController,
                      builder: (context, _) {
                        if (widget.amountController.text.trim().isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ApplePressable(
                            scaleDown: 0.88,
                            onTap: widget.onClear,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                CupertinoIcons.clear_circled_solid,
                                size: 20,
                                color: typeColor.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (widget.onToggleKeypad != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ApplePressable(
                          scaleDown: 0.88,
                          onTap: widget.onToggleKeypad!,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: widget.isKeypadOpen
                                  ? typeColor.withValues(alpha: 0.18)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                            ),
                            child: Icon(
                              widget.isKeypadOpen
                                  ? CupertinoIcons.keyboard
                                  : CupertinoIcons.number_square,
                              size: 20,
                              color: widget.isKeypadOpen
                                  ? typeColor
                                  : typeColor.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Lucian Balance Shield Warning Badge
          if (_wasOverBalance && widget.availableWalletBalance != null) ...[
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: LucianTokens.ease,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: LucianTokens.dangerLight
                    .withValues(alpha: isDark ? 0.20 : 0.10),
                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                border: Border.all(
                  color: LucianTokens.dangerLight
                      .withValues(alpha: isDark ? 0.40 : 0.28),
                  width: AppleTokens.hairline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    size: 13,
                    color: isDark
                        ? LucianTokens.dangerDark
                        : LucianTokens.dangerLight,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Vượt số dư ví (${widget.availableWalletBalance!.format(locale: widget.locale)} khả dụng)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? LucianTokens.dangerDark
                            : LucianTokens.dangerLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 3. Smart Zero & Quick Amount Suggestions Bar (Reactive to amountController)
          ListenableBuilder(
            listenable: widget.amountController,
            builder: (context, _) {
              final l10n = context.l10n;
              final rawMoney = Money.tryParse(widget.amountController.text,
                  currencyCode: widget.currencyCode);
              final currentMinor = rawMoney?.minorUnits ?? 0;

              // Quick starter chips when amount is empty (Lucian #035 quick-chips)
              if (currentMinor <= 0) {
                final isVnd = widget.currencyCode.toUpperCase() == 'VND';
                if (!isVnd) return const SizedBox.shrink();
                final starterChips = [
                  (label: '+50k', value: 50000),
                  (label: '+100k', value: 100000),
                  (label: '+200k', value: 200000),
                  (label: '+500k', value: 500000),
                  (label: '+1tr', value: 1000000),
                  (label: '+2tr', value: 2000000),
                ];
                return Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final chip in starterChips)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ApplePressable(
                              scaleDown: 0.94,
                              onTap: () => widget.onSetAmount(chip.value),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppleTokens.bgDarkSecondary
                                      : AppleTokens.bgLightSecondary,
                                  borderRadius: BorderRadius.circular(
                                      AppleTokens.radiusPill),
                                  border: Border.all(
                                    color: isDark
                                        ? typeColor.withValues(alpha: 0.3)
                                        : typeColor.withValues(alpha: 0.25),
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  chip.label,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: typeColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }

              // Calculate suggestions for appending zeros (x10, x100, x1.000, x10.000, x100.000, x1.000.000, x10.000.000)
              final List<({String label, int value})> zeroSuggestions = [];

              final List<int> multipliers = [
                10,
                100,
                1000,
                10000,
                100000,
                1000000,
                10000000
              ];

              for (final m in multipliers) {
                final target = currentMinor * m;
                if (target > 0 && target <= 100000000000) {
                  final formatted = Money(
                    minorUnits: target,
                    currencyCode: widget.currencyCode,
                  ).toInputString(locale: widget.locale);
                  zeroSuggestions.add((
                    label: '$formatted ${widget.currencyInfo.symbol}',
                    value: target,
                  ));
                }
              }

              if (zeroSuggestions.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.sparkles,
                          size: 13,
                          color: typeColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          l10n.zeroSuggestions,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: isDark
                                ? const Color(0xFF98989F)
                                : const Color(0xFF6E6E73),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final s in zeroSuggestions)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ApplePressable(
                                scaleDown: 0.94,
                                onTap: () => widget.onSetAmount(s.value),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppleTokens.bgDarkSecondary
                                        : AppleTokens.bgLightSecondary,
                                    borderRadius: BorderRadius.circular(
                                        AppleTokens.radiusPill),
                                    border: Border.all(
                                      color: isDark
                                          ? typeColor.withValues(alpha: 0.3)
                                          : typeColor.withValues(alpha: 0.25),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.arrow_right,
                                        size: 11,
                                        color: typeColor.withValues(alpha: 0.8),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        s.label,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: typeColor,
                                          fontFeatures: AppTheme.tabularFigures,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
