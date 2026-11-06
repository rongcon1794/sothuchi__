// Lucian UX/UI Prompt #013 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#013
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Stretchy switch inspired by Lucian UX/UI #013.
/// While travelling, the knob stretches horizontally like rubber with [LucianTokens.ease]
/// and snaps into place with [LucianTokens.spring], providing tactile haptic feedback.
class LucianStretchySwitch extends StatefulWidget {
  const LucianStretchySwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final String? semanticLabel;

  @override
  State<LucianStretchySwitch> createState() => _LucianStretchySwitchState();
}

class _LucianStretchySwitchState extends State<LucianStretchySwitch> {
  bool _isStretching = false;

  void _handleTap() {
    if (widget.onChanged == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isStretching = true);
    widget.onChanged!(!widget.value);

    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) {
        setState(() => _isStretching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor = widget.activeColor ??
        (isDark ? LucianTokens.resolveMint(true) : AppleTokens.systemGreen);
    final inactiveColor = widget.inactiveColor ??
        (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA));

    // Track dimensions: 52 wide x 30 high
    const trackWidth = 52.0;
    const trackHeight = 30.0;
    const knobHeight = 24.0;
    final knobWidth = _isStretching ? 32.0 : 24.0;
    final maxLeft = trackWidth - knobWidth - 3.0;
    final leftPos = widget.value ? maxLeft : 3.0;

    return Semantics(
      toggled: widget.value,
      value: widget.value ? 'on' : 'off',
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: SizedBox(
          width: 58,
          height: 48, // Touch target >= 48x48
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: LucianTokens.ease,
              width: trackWidth,
              height: trackHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                color: widget.value ? activeColor : inactiveColor,
                boxShadow: widget.value
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.38),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: LucianTokens.spring,
                    left: leftPos,
                    top: 3,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: LucianTokens.ease,
                      width: knobWidth,
                      height: knobHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x28000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: widget.value
                              ? Icon(
                                  Icons.check_rounded,
                                  key: const ValueKey('on'),
                                  size: 14,
                                  color: activeColor,
                                )
                              : const SizedBox.shrink(key: ValueKey('off')),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
