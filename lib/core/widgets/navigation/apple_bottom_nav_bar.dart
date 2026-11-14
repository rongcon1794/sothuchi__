import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Value object representing a single navigation destination tab in [AppleBottomNavBar].
class AppleNavDestination {
  const AppleNavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;
}

/// Standalone Apple HIG Bottom Navigation Bar.
/// Features:
/// - iOS blur backdrop filter (or solid OLED pure black for battery saving).
/// - Responsive height switching (portrait vs landscape).
/// - Safe area clearance for gesture indicators and home pills.
/// - Tactile animated items with active icon morphing and spring curves.
class AppleBottomNavBar extends StatelessWidget {
  const AppleBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.destinations,
    required this.onTap,
    this.isLandscape,
    this.isOled,
    this.maxWidth = AppleTokens.maxContentWidth,
  });

  final int currentIndex;
  final List<AppleNavDestination> destinations;
  final ValueChanged<int> onTap;
  final bool? isLandscape;
  final bool? isOled;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final landscape = isLandscape ?? context.isLandscape;
    final oled = isOled ?? context.isOled;

    final navBarHeight = landscape
        ? AppleTokens.navBarHeightLandscape
        : AppleTokens.navBarHeightPortrait;

    final navBarContent = Container(
      decoration: BoxDecoration(
        color: isDark
            ? (oled
                ? AppleTokens.bgOledPrimary
                : AppleTokens.bgDarkCard.withValues(alpha: 0.88))
            : Colors.white.withValues(alpha: 0.90),
        border: Border(
          top: BorderSide(
            color: isDark
                ? (oled
                    ? AppleTokens.bgOledBorder
                    : Colors.white.withValues(alpha: 0.12))
                : Colors.black.withValues(alpha: 0.08),
            width: AppleTokens.hairline,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        left: true,
        right: true,
        bottom: true,
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: landscape ? 1.05 : 1.15,
          child: SizedBox(
            height: navBarHeight,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (int i = 0; i < destinations.length; i++)
                      AppleNavBarItem(
                        destination: destinations[i],
                        isSelected: i == currentIndex,
                        isLandscape: landscape,
                        onTap: () => onTap(i),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return RepaintBoundary(
      child: ClipRect(
        child: oled || theme.platform == TargetPlatform.android
            ? navBarContent
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: navBarContent,
              ),
      ),
    );
  }
}

/// Tactile, animated navigation tab item with icon scale bounce.
class AppleNavBarItem extends StatelessWidget {
  const AppleNavBarItem({
    super.key,
    required this.destination,
    required this.isSelected,
    required this.isLandscape,
    required this.onTap,
  });

  final AppleNavDestination destination;
  final bool isSelected;
  final bool isLandscape;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    const inactiveColor = Color(0xFF8E8E93);

    final itemContent = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: LucianTokens.ease,
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 10 : 14,
                vertical: isLandscape ? 1 : 4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: isDark ? 0.22 : 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
              ),
              child: Icon(
                isSelected ? destination.activeIcon : destination.icon,
                size: isLandscape ? 17 : 22,
                color: isSelected ? primaryColor : inactiveColor,
              ),
            ),
            if (destination.badgeCount != null && destination.badgeCount! > 0)
              Positioned(
                top: -2,
                right: isLandscape ? 4 : 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppleTokens.systemRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    destination.badgeCount! > 99 ? '99+' : '${destination.badgeCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: isLandscape ? 1 : 2),
        Text(
          destination.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isLandscape ? 9.5 : 10.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? primaryColor : inactiveColor,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedScale(
          scale: isSelected ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Center(child: itemContent),
        ),
      ),
    );
  }
}
