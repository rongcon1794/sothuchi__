import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Lucian Labs Element #003: "Hold to Delete" Action Button.
///
/// Features:
/// - Liquid ruby/danger fill that animates linearly as the user holds.
/// - Tactile haptic ticks along progress thresholds (25%, 50%, 75%).
/// - Smooth spring-back recoil (`LucianTokens.spring`) if released early.
/// - Completion triggers heavy/medium haptic and fires [onConfirmed].
/// - Quick tap hint notifying the user to press & hold, eliminating accidental deletions.
class LucianHoldToDeleteButton extends StatefulWidget {
  const LucianHoldToDeleteButton({
    super.key,
    required this.onConfirmed,
    this.onTap,
    this.label,
    this.holdingLabel,
    this.confirmedLabel,
    this.duration = const Duration(milliseconds: 1200),
    this.height = 46.0,
    this.borderRadius,
    this.icon = CupertinoIcons.trash,
    this.color,
  });

  final FutureOr<void> Function() onConfirmed;
  final VoidCallback? onTap;
  final String? label;
  final String? holdingLabel;
  final String? confirmedLabel;
  final Duration duration;
  final double height;
  final BorderRadius? borderRadius;
  final IconData icon;
  final Color? color;

  @override
  State<LucianHoldToDeleteButton> createState() => _LucianHoldToDeleteButtonState();
}

class _LucianHoldToDeleteButtonState extends State<LucianHoldToDeleteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isHolding = false;
  bool _isCompleted = false;
  int _lastHapticQuarter = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(_handleAnimationProgress)
     ..addStatusListener(_handleStatusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAnimationProgress() {
    if (!_isHolding || _isCompleted) return;

    final progress = _controller.value;
    final quarter = (progress * 4).floor();
    if (quarter > _lastHapticQuarter && quarter > 0 && quarter < 4) {
      _lastHapticQuarter = quarter;
      unawaited(HapticFeedback.selectionClick());
    }
  }

  void _handleStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_isCompleted) {
      _isCompleted = true;
      unawaited(HapticFeedback.mediumImpact());
      widget.onConfirmed();
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (_isCompleted) return;
    setState(() {
      _isHolding = true;
      _lastHapticQuarter = 0;
    });
    unawaited(HapticFeedback.lightImpact());
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (_isCompleted) return;
    final progress = _controller.value;
    _cancelHold();
    if (progress < 0.25 && widget.onTap != null) {
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (_isCompleted) return;
    _cancelHold();
  }

  void _cancelHold() {
    if (!_isHolding) return;
    setState(() => _isHolding = false);
    // Smooth recoil back to start
    _controller.animateBack(
      0.0,
      duration: const Duration(milliseconds: 280),
      curve: LucianTokens.spring,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dangerColor = widget.color ?? LucianTokens.resolveDanger(isDark);
    final radius = widget.borderRadius ?? BorderRadius.circular(AppleTokens.radiusPill);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final scale = _isHolding ? 0.97 : 1.0;

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: radius,
                color: isDark
                    ? dangerColor.withValues(alpha: 0.12)
                    : dangerColor.withValues(alpha: 0.08),
                border: Border.all(
                  color: dangerColor.withValues(alpha: isDark ? 0.35 : 0.25),
                  width: AppleTokens.hairline,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Liquid rising / filling progress bar
                  Positioned.fill(
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: dangerColor,
                          gradient: LinearGradient(
                            colors: [
                              dangerColor.withValues(alpha: 0.85),
                              dangerColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Button content: icon + text + hold percentage indicator
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.icon,
                            size: 18,
                            color: progress > 0.4
                                ? Colors.white
                                : dangerColor,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Builder(
                              builder: (context) {
                                final isVi = Localizations.localeOf(context)
                                    .languageCode
                                    .toLowerCase()
                                    .startsWith('vi');
                                final defaultLabel =
                                    widget.label ?? (isVi ? 'Giữ để xóa' : 'Hold to delete');
                                final defaultHolding = widget.holdingLabel ??
                                    (isVi ? 'Đang giữ để xóa...' : 'Keep holding...');
                                final defaultConfirmed =
                                    widget.confirmedLabel ?? (isVi ? 'Đã xóa!' : 'Deleted!');
                                return Text(
                                  _isCompleted
                                      ? defaultConfirmed
                                      : _isHolding
                                          ? '$defaultHolding ${(progress * 100).toInt()}%'
                                          : defaultLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: progress > 0.4
                                        ? Colors.white
                                        : dangerColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}