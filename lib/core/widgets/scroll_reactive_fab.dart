import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

export 'package:flutter/rendering.dart' show ScrollDirection;
export 'package:flutter/widgets.dart' show UserScrollNotification;

/// Animated wrapper for Floating Action Buttons that automatically slides
/// down and scales away when the user scrolls down, preventing content
/// from being obscured, and springs back into view when scrolling up or at top.
class ScrollReactiveFab extends StatelessWidget {
  const ScrollReactiveFab({
    super.key,
    required this.visible,
    required this.child,
    this.duration = const Duration(milliseconds: 260),
  });

  final bool visible;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1.6),
      duration: duration,
      curve: visible ? Curves.easeOutBack : Curves.easeInOutCubic,
      child: AnimatedScale(
        scale: visible ? 1.0 : 0.75,
        duration: duration,
        curve: visible ? Curves.easeOutBack : Curves.easeInOutCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          child: IgnorePointer(
            ignoring: !visible,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Helper mixin or callback handler for managing FAB visibility based on UserScrollNotification.
class ScrollFabVisibilityHandler {
  ScrollFabVisibilityHandler({required this.onVisibilityChanged});

  final ValueChanged<bool> onVisibilityChanged;
  bool _isVisible = true;

  bool get isVisible => _isVisible;

  bool handleScrollNotification(UserScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    // Always restore visibility when near top of the scrollable
    if (notification.metrics.pixels <= 20) {
      if (!_isVisible) {
        _isVisible = true;
        onVisibilityChanged(true);
      }
      return false;
    }

    if (notification.direction == ScrollDirection.reverse && _isVisible) {
      // User is scrolling down -> Hide FAB to reveal content
      _isVisible = false;
      onVisibilityChanged(false);
    } else if (notification.direction == ScrollDirection.forward && !_isVisible) {
      // User is scrolling up -> Show FAB
      _isVisible = true;
      onVisibilityChanged(true);
    }

    return false;
  }
}
