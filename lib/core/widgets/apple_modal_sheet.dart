import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Tactile edge-swipe detector that brings native iOS and Android edge-swipe
/// dismiss gestures to bottom sheets and overlay modals.
///
/// Listens for horizontal drag gestures starting near either the left edge
/// (swipe right to back) or right edge (swipe left on Android gesture nav)
/// without interfering with vertical list scrolling or nested form inputs.
class AppleEdgeSwipeToDismiss extends StatefulWidget {
  const AppleEdgeSwipeToDismiss({
    super.key,
    required this.child,
    this.edgeWidth = 64.0,
    this.threshold = 40.0,
    this.onDismiss,
  });

  final Widget child;
  final double edgeWidth;
  final double threshold;
  final VoidCallback? onDismiss;

  @override
  State<AppleEdgeSwipeToDismiss> createState() => _AppleEdgeSwipeToDismissState();
}

class _AppleEdgeSwipeToDismissState extends State<AppleEdgeSwipeToDismiss> {
  double? _startX;
  double? _startY;
  bool _isLeftEdge = false;
  bool _isRightEdge = false;
  bool _hasTriggered = false;

  void _triggerDismiss() {
    if (_hasTriggered || !mounted) return;
    _hasTriggered = true;
    _isLeftEdge = false;
    _isRightEdge = false;
    _startX = null;
    _startY = null;
    unawaited(HapticFeedback.lightImpact());
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    } else if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
    }
  }

  void _reset() {
    _isLeftEdge = false;
    _isRightEdge = false;
    _startX = null;
    _startY = null;
    _hasTriggered = false;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _hasTriggered = false;
        final x = event.position.dx;
        if (x <= widget.edgeWidth) {
          _isLeftEdge = true;
          _isRightEdge = false;
          _startX = x;
          _startY = event.position.dy;
        } else if (x >= screenWidth - widget.edgeWidth) {
          _isLeftEdge = false;
          _isRightEdge = true;
          _startX = x;
          _startY = event.position.dy;
        } else {
          _reset();
        }
      },
      onPointerMove: (event) {
        if (_hasTriggered || (!_isLeftEdge && !_isRightEdge)) return;
        if (_startX == null || _startY == null) return;

        final dx = event.position.dx - _startX!;
        final dy = (event.position.dy - _startY!).abs();

        // If vertical scrolling is overwhelmingly dominating (e.g. fast vertical scroll)
        if (dy > 90 && dy > dx.abs() * 2.0) {
          _reset();
          return;
        }

        // Left edge swipe: drag to the right
        if (_isLeftEdge && dx >= widget.threshold && dx.abs() > dy * 0.7) {
          _triggerDismiss();
        }

        // Right edge swipe: drag to the left (Android gesture navigation)
        if (_isRightEdge && -dx >= widget.threshold && dx.abs() > dy * 0.7) {
          _triggerDismiss();
        }
      },
      onPointerUp: (_) => _reset(),
      onPointerCancel: (_) => _reset(),
      child: widget.child,
    );
  }
}

/// Standard Apple HIG Modal Bottom Sheet Scaffold.
/// Provides drag handle, header with title, subtitle, close action,
/// notch / status bar protection (`SafeArea`), native edge-swipe to go back,
/// scrollable content with keyboard padding, and optional sticky bottom action bar.
class AppleModalSheetLayout extends StatelessWidget {
  const AppleModalSheetLayout({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.bottomAction,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 20),
    this.showDragHandle = true,
    this.enableEdgeSwipeBack = true,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? bottomAction;
  final EdgeInsetsGeometry padding;
  final bool showDragHandle;
  final bool enableEdgeSwipeBack;
  final VoidCallback? onBack;

  /// Helper to display a modal bottom sheet formatted with [AppleModalSheetLayout].
  ///
  /// Guarantees `useSafeArea: true` so the modal sheet never renders underneath
  /// the status bar, notch ("tai thỏ"), or Dynamic Island.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
    bool useSafeArea = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: useSafeArea,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final paddingTop = MediaQuery.paddingOf(context).top;
    final viewPaddingTop = MediaQuery.viewPaddingOf(context).top;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    // Physical hardware notch / camera cutout / status bar insets protection
    final topHardwareInset = math.max(paddingTop, viewPaddingTop);
    // Guarantees generous clearance below any notch / Dynamic Island / camera cutout (min 68dp)
    final effectiveTopMargin = math.max(topHardwareInset + 16.0, 68.0);

    final sheetContent = Container(
      margin: EdgeInsets.only(top: effectiveTopMargin),
      constraints: BoxConstraints(
        maxHeight: screenHeight - effectiveTopMargin,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? (context.isOled
                ? AppleTokens.bgOledCard
                : AppleTokens.bgDarkPrimary)
            : AppleTokens.bgLightPrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppleTokens.radiusHero),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showDragHandle) ...[
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3A3A3C)
                          : const Color(0xFFD1D1D6),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ] else
                const SizedBox(height: 16),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFF6C6C70),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 44),
                      onPressed: onBack ?? () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFE5E5EA),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.xmark,
                          size: 14,
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6C6C70),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Divider(
                height: AppleTokens.hairline,
                color: isDark
                    ? AppleTokens.separatorDark
                    : AppleTokens.separatorLight,
              ),

              // Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: padding,
                  child: RepaintBoundary(child: child),
                ),
              ),

              // Sticky Bottom Action
              if (bottomAction != null) ...[
                Divider(
                  height: AppleTokens.hairline,
                  color: isDark
                      ? AppleTokens.separatorDark
                      : AppleTokens.separatorLight,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: RepaintBoundary(child: bottomAction!),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (enableEdgeSwipeBack) {
      return AppleEdgeSwipeToDismiss(
        onDismiss: onBack,
        child: sheetContent,
      );
    }

    return sheetContent;
  }
}
