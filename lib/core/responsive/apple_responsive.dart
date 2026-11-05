import 'package:flutter/widgets.dart';

/// Window size classifications inspired by Material 3 and Apple HIG iPadOS adaptations.
enum AppleWindowSizeClass {
  /// Phones in portrait (< 600 dp width).
  compact,

  /// Phones in landscape, foldable devices, or small tablets (600 dp - 839 dp width).
  medium,

  /// Tablets, large foldable, or medium desktop windows (840 dp - 1199 dp width).
  expanded,

  /// Large tablet displays, full desktop monitors (>= 1200 dp width).
  large;

  bool get isCompact => this == AppleWindowSizeClass.compact;
  bool get isMedium => this == AppleWindowSizeClass.medium;
  bool get isExpanded => this == AppleWindowSizeClass.expanded;
  bool get isLarge => this == AppleWindowSizeClass.large;

  /// True if medium or larger (suitable for multi-column grids or side navigation).
  bool get isWide => this != AppleWindowSizeClass.compact;
}

/// Responsive extensions on [BuildContext] to simplify adaptive rendering.
extension AppleResponsiveContext on BuildContext {
  /// App window size.
  Size get windowSize => MediaQuery.sizeOf(this);

  /// True if the current window is wider than it is tall.
  bool get isLandscape => windowSize.width > windowSize.height;

  /// Width of the window.
  double get windowWidth => windowSize.width;

  /// Height of the window.
  double get windowHeight => windowSize.height;

  /// Categorizes window width into [AppleWindowSizeClass].
  AppleWindowSizeClass get windowSizeClass {
    final width = windowWidth;
    if (width < 600) {
      return AppleWindowSizeClass.compact;
    } else if (width < 840) {
      return AppleWindowSizeClass.medium;
    } else if (width < 1200) {
      return AppleWindowSizeClass.expanded;
    } else {
      return AppleWindowSizeClass.large;
    }
  }

  /// Whether the screen is considered wide (tablet, desktop, or landscape phone).
  bool get isWideScreen => isLandscape || windowSizeClass.isWide;

  /// Selects a responsive value based on current [windowSizeClass].
  T responsiveValue<T>({
    required T compact,
    T? medium,
    T? expanded,
    T? large,
  }) {
    switch (windowSizeClass) {
      case AppleWindowSizeClass.compact:
        return compact;
      case AppleWindowSizeClass.medium:
        return medium ?? compact;
      case AppleWindowSizeClass.expanded:
        return expanded ?? medium ?? compact;
      case AppleWindowSizeClass.large:
        return large ?? expanded ?? medium ?? compact;
    }
  }
}

/// A builder that evaluates local [BoxConstraints] to compute [AppleWindowSizeClass].
class AppleResponsiveBuilder extends StatelessWidget {
  const AppleResponsiveBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(
    BuildContext context,
    BoxConstraints constraints,
    AppleWindowSizeClass sizeClass,
  ) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final AppleWindowSizeClass sizeClass;
        if (width < 600) {
          sizeClass = AppleWindowSizeClass.compact;
        } else if (width < 840) {
          sizeClass = AppleWindowSizeClass.medium;
        } else if (width < 1200) {
          sizeClass = AppleWindowSizeClass.expanded;
        } else {
          sizeClass = AppleWindowSizeClass.large;
        }

        return builder(context, constraints, sizeClass);
      },
    );
  }
}

