import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/l10n/app_localizations.dart';

/// Lightweight scope that only notifies dependents when keyboard visibility
/// toggles (`false <-> true`), avoiding 60-120fps per-frame rebuilds during
/// keyboard slide animations.
class KeyboardVisibilityScope extends InheritedWidget {
  const KeyboardVisibilityScope({
    required this.isKeyboardOpen,
    required this.heightListenable,
    required super.child,
    super.key,
  });

  final bool isKeyboardOpen;
  final ValueNotifier<double> heightListenable;

  static bool isOpenOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<KeyboardVisibilityScope>();
    if (scope != null) return scope.isKeyboardOpen;
    return MediaQuery.viewInsetsOf(context).bottom > 0;
  }

  static ValueNotifier<double>? heightListenableOf(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<KeyboardVisibilityScope>();
    return (element?.widget as KeyboardVisibilityScope?)?.heightListenable;
  }

  @override
  bool updateShouldNotify(KeyboardVisibilityScope oldWidget) {
    return isKeyboardOpen != oldWidget.isKeyboardOpen;
  }
}

/// Translucent Apple HIG Keyboard Accessory Toolbar.
///
/// Automatically docks directly on top of the software keyboard whenever
/// any text input is focused. Features a prominent, tactile "Ẩn bàn phím"
/// (Hide keyboard) button with smooth haptics and keyboard dismissal.
class KeyboardDismissBarOverlay extends StatefulWidget {
  const KeyboardDismissBarOverlay({
    required this.child,
    this.barHeightPortrait = 38.0,
    this.barHeightLandscape = 32.0,
    super.key,
  });

  final Widget child;
  final double barHeightPortrait;
  final double barHeightLandscape;

  @override
  State<KeyboardDismissBarOverlay> createState() =>
      _KeyboardDismissBarOverlayState();
}

class _KeyboardDismissBarOverlayState extends State<KeyboardDismissBarOverlay> {
  final ValueNotifier<double> _keyboardHeightNotifier = ValueNotifier<double>(0);

  @override
  void dispose() {
    _keyboardHeightNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final rawKeyboardHeight = mediaQuery.viewInsets.bottom;
    final isLandscape = mediaQuery.size.width > mediaQuery.size.height;
    final barHeight =
        isLandscape ? widget.barHeightLandscape : widget.barHeightPortrait;
    final isKeyboardVisible = rawKeyboardHeight > 0;

    final effectiveBarInset = isKeyboardVisible
        ? math.min(rawKeyboardHeight, barHeight)
        : 0.0;
    _keyboardHeightNotifier.value =
        isKeyboardVisible ? rawKeyboardHeight + effectiveBarInset : 0.0;

    // Stabilize both `padding` (to `viewPadding`) and `viewInsets` (to `zero`)
    // for the entire Navigator subtree! Because `data` remains 100% identical
    // on every frame of the keyboard animation, `MediaQuery.updateShouldNotify`
    // returns `false`, completely preventing all Scaffolds, AppBars, SafeAreas,
    // and ModalBottomSheets in the app from rebuilding/relayouting at 120fps.
    final stabilizedChild = MediaQuery(
      data: mediaQuery.copyWith(
        padding: mediaQuery.viewPadding,
        viewInsets: EdgeInsets.zero,
      ),
      child: KeyboardVisibilityScope(
        isKeyboardOpen: isKeyboardVisible,
        heightListenable: _keyboardHeightNotifier,
        child: RepaintBoundary(child: widget.child),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        final currentFocus = FocusManager.instance.primaryFocus;
        if (currentFocus != null && currentFocus.hasFocus) {
          currentFocus.unfocus();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          stabilizedChild,
          Positioned.fill(
            child: Offstage(
              offstage: !isKeyboardVisible,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset: Offset(0, -rawKeyboardHeight),
                  child: RepaintBoundary(
                    child: SizedBox(
                      width: double.infinity,
                      height: barHeight,
                      child: _AppleKeyboardAccessoryBar(
                        barHeight: barHeight,
                        isLandscape: isLandscape,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppleKeyboardAccessoryBar extends StatelessWidget {
  const _AppleKeyboardAccessoryBar({
    required this.barHeight,
    required this.isLandscape,
  });

  final double barHeight;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final keyboardLabel = l10n.keyboard;
    final hideKeyboardLabel = l10n.hideKeyboard;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1E1E)
              : const Color(0xFFF7F7F7),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              width: AppleTokens.hairline,
            ),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 12 : 16,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Subtle keyboard indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.keyboard,
                  size: isLandscape ? 15 : 17,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
                const SizedBox(width: 6),
                Text(
                  keyboardLabel,
                  style: TextStyle(
                    fontSize: isLandscape ? 11.5 : 12.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),

            // Prominent Dismiss Keyboard Button
            CupertinoButton(
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 10 : 12,
                vertical: isLandscape ? 2 : 4,
              ),
              minimumSize: Size(0, barHeight - 8),
              borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
              color: primary.withValues(alpha: isDark ? 0.22 : 0.12),
              onPressed: () {
                HapticFeedback.lightImpact();
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.keyboard_chevron_compact_down,
                    size: isLandscape ? 16 : 18,
                    color: primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hideKeyboardLabel,
                    style: TextStyle(
                      fontSize: isLandscape ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: primary,
                      letterSpacing: -0.2,
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
}
