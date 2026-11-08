import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/utils/money.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

/// State-of-the-art Apple Financial Numeric Keypad.
/// Designed for 1-handed rapid expense entry with tactile haptic feedback,
/// '000' shortcut for zero-decimal and large-denomination currencies,
/// inline arithmetic (+, -), and squircle action buttons.
class AppleFinancialKeypad extends StatefulWidget {
  const AppleFinancialKeypad({
    super.key,
    required this.amountController,
    required this.currencyCode,
    required this.locale,
    this.primaryColor,
    this.onDone,
  });

  final TextEditingController amountController;
  final String currencyCode;
  final String locale;
  final Color? primaryColor;
  final VoidCallback? onDone;

  @override
  State<AppleFinancialKeypad> createState() => _AppleFinancialKeypadState();
}

class _AppleFinancialKeypadState extends State<AppleFinancialKeypad> {
  String _expression = '';

  @override
  void initState() {
    super.initState();
    _expression = widget.amountController.text.trim();
  }

  void _tapKey(String value) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      final current = widget.amountController.text;
      if (value == '000') {
        if (current.isNotEmpty && current != '0') {
          widget.amountController.text = '$current' '000';
        }
      } else if (value == '+' || value == '-') {
        if (current.isNotEmpty && !current.endsWith('+') && !current.endsWith('-')) {
          widget.amountController.text = '$current $value ';
        }
      } else {
        if (current == '0') {
          widget.amountController.text = value;
        } else {
          widget.amountController.text = '$current$value';
        }
      }
      _expression = widget.amountController.text;
    });
  }

  void _backspace() {
    unawaited(HapticFeedback.lightImpact());
    setState(() {
      final current = widget.amountController.text;
      if (current.isEmpty) return;

      if (current.endsWith(' ')) {
        // Space + operator + space
        final trimmed = current.trimRight();
        if (trimmed.endsWith('+') || trimmed.endsWith('-')) {
          widget.amountController.text = trimmed.substring(0, trimmed.length - 1).trimRight();
        } else {
          widget.amountController.text = current.substring(0, current.length - 1);
        }
      } else {
        widget.amountController.text = current.substring(0, current.length - 1);
      }
      _expression = widget.amountController.text;
    });
  }

  void _clear() {
    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      widget.amountController.clear();
      _expression = '';
    });
  }

  void _evaluate() {
    unawaited(HapticFeedback.mediumImpact());
    final current = widget.amountController.text;
    if (current.contains('+') || current.contains('-')) {
      final parts = current.split(' ');
      var totalMinor = 0;
      var currentOp = '+';

      for (final part in parts) {
        if (part == '+' || part == '-') {
          currentOp = part;
        } else if (part.isNotEmpty) {
          final parsed = Money.tryParse(part, currencyCode: widget.currencyCode);
          final val = parsed?.minorUnits ?? 0;
          if (currentOp == '+') {
            totalMinor += val;
          } else {
            totalMinor -= val;
          }
        }
      }

      if (totalMinor >= 0) {
        final money = Money(minorUnits: totalMinor, currencyCode: widget.currencyCode);
        setState(() {
          widget.amountController.text = money.toInputString(locale: widget.locale);
          _expression = widget.amountController.text;
        });
      }
    } else {
      widget.onDone?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = widget.primaryColor ?? theme.colorScheme.primary;

    final keyBg = isDark ? AppleTokens.bgDarkSecondary : AppleTokens.bgLightCard;
    final keyBorder = isDark ? Colors.white.withValues(alpha: 0.08) : AppleTokens.borderLight;
    final textStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 20,
      fontFeatures: AppTheme.tabularFigures,
    );

    Widget buildKey({
      required Widget child,
      required VoidCallback onTap,
      Color? background,
      Color? borderColor,
      int flex = 1,
    }) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.all(3.5),
          child: ApplePressable(
            scaleDown: 0.94,
            onTap: onTap,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background ?? keyBg,
                borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
                border: Border.all(
                  color: borderColor ?? keyBorder,
                  width: AppleTokens.hairline,
                ),
                boxShadow: isDark ? null : AppleTokens.cardShadowLight,
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    final hasFormula = _expression.contains('+') || _expression.contains('-');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: 1, 2, 3, +
        Row(
          children: [
            buildKey(
              child: Text('1', style: textStyle),
              onTap: () => _tapKey('1'),
            ),
            buildKey(
              child: Text('2', style: textStyle),
              onTap: () => _tapKey('2'),
            ),
            buildKey(
              child: Text('3', style: textStyle),
              onTap: () => _tapKey('3'),
            ),
            buildKey(
              child: const Icon(CupertinoIcons.plus, size: 20, color: AppleTokens.systemOrange),
              background: isDark ? AppleTokens.bgDarkTertiary : AppleTokens.bgLightSecondary,
              onTap: () => _tapKey('+'),
            ),
          ],
        ),

        // Row 2: 4, 5, 6, -
        Row(
          children: [
            buildKey(
              child: Text('4', style: textStyle),
              onTap: () => _tapKey('4'),
            ),
            buildKey(
              child: Text('5', style: textStyle),
              onTap: () => _tapKey('5'),
            ),
            buildKey(
              child: Text('6', style: textStyle),
              onTap: () => _tapKey('6'),
            ),
            buildKey(
              child: const Icon(CupertinoIcons.minus, size: 20, color: AppleTokens.systemOrange),
              background: isDark ? AppleTokens.bgDarkTertiary : AppleTokens.bgLightSecondary,
              onTap: () => _tapKey('-'),
            ),
          ],
        ),

        // Row 3: 7, 8, 9, Backspace
        Row(
          children: [
            buildKey(
              child: Text('7', style: textStyle),
              onTap: () => _tapKey('7'),
            ),
            buildKey(
              child: Text('8', style: textStyle),
              onTap: () => _tapKey('8'),
            ),
            buildKey(
              child: Text('9', style: textStyle),
              onTap: () => _tapKey('9'),
            ),
            buildKey(
              child: const Icon(CupertinoIcons.delete_left, size: 20, color: AppleTokens.rubyExpense),
              background: isDark ? AppleTokens.bgDarkTertiary : AppleTokens.bgLightSecondary,
              onTap: _backspace,
            ),
          ],
        ),

        // Row 4: C, 0, 000, = / Done
        Row(
          children: [
            buildKey(
              child: Text('C', style: textStyle?.copyWith(color: AppleTokens.rubyExpense)),
              background: isDark ? AppleTokens.bgDarkTertiary : AppleTokens.bgLightSecondary,
              onTap: _clear,
            ),
            buildKey(
              child: Text('0', style: textStyle),
              onTap: () => _tapKey('0'),
            ),
            buildKey(
              child: Text('000', style: textStyle?.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
              background: isDark ? AppleTokens.bgDarkTertiary : AppleTokens.bgLightSecondary,
              onTap: () => _tapKey('000'),
            ),
            buildKey(
              child: Icon(
                hasFormula ? CupertinoIcons.equal : CupertinoIcons.checkmark,
                size: 22,
                color: Colors.white,
              ),
              background: accentColor,
              borderColor: accentColor,
              onTap: hasFormula ? _evaluate : (widget.onDone ?? _evaluate),
            ),
          ],
        ),
      ],
    );
  }
}
