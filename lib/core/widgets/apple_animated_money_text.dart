import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/app_theme.dart';
import 'package:so_thu_chi/core/utils/money.dart';

/// Tactile, smooth animated number counter for currency values.
/// Smoothly interpolates integer minor units from previous to new amount
/// using [Curves.easeOutCubic] and Apple tabular numerals.
class AppleAnimatedMoneyText extends StatefulWidget {
  const AppleAnimatedMoneyText({
    super.key,
    required this.money,
    this.locale = 'vi',
    this.masked = false,
    this.showPlusSign = false,
    this.showMinusSign = false,
    this.style,
    this.semanticsLabel,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
  });

  final Money money;
  final String locale;
  final bool masked;
  final bool showPlusSign;
  final bool showMinusSign;
  final TextStyle? style;
  final String? semanticsLabel;
  final Duration duration;
  final Curve curve;

  @override
  State<AppleAnimatedMoneyText> createState() => _AppleAnimatedMoneyTextState();
}

class _AppleAnimatedMoneyTextState extends State<AppleAnimatedMoneyText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _oldUnits = 0;
  int _targetUnits = 0;

  @override
  void initState() {
    super.initState();
    _oldUnits = widget.money.minorUnits;
    _targetUnits = widget.money.minorUnits;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
  }

  @override
  void didUpdateWidget(covariant AppleAnimatedMoneyText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.money.minorUnits != widget.money.minorUnits && !widget.masked) {
      _oldUnits = oldWidget.money.minorUnits;
      _targetUnits = widget.money.minorUnits;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (widget.style ?? const TextStyle()).copyWith(
      fontFeatures: AppTheme.tabularFigures,
    );

    if (widget.masked) {
      return Text(
        widget.money.format(
          locale: widget.locale,
          showPlusSign: widget.showPlusSign,
          showMinusSign: widget.showMinusSign,
          masked: true,
        ),
        semanticsLabel: widget.semanticsLabel,
        style: effectiveStyle,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentUnits = _controller.isAnimating
            ? (_oldUnits + ((_targetUnits - _oldUnits) * _animation.value)).round()
            : widget.money.minorUnits;

        final currentMoney = Money(
          minorUnits: currentUnits,
          currencyCode: widget.money.currencyCode,
        );

        return Text(
          currentMoney.format(
            locale: widget.locale,
            showPlusSign: widget.showPlusSign,
            showMinusSign: widget.showMinusSign,
            masked: false,
          ),
          semanticsLabel: widget.semanticsLabel,
          style: effectiveStyle,
        );
      },
    );
  }
}

