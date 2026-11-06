import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Translucent, frosted-glass Apple navigation shell.
/// Adapts seamlessly between:
/// - iOS Bottom Navigation Bar on portrait phones (52dp, stacked Icon + Label).
/// - Ultra-compact, non-obscured Landscape BottomBar on landscape phones/tablets
///   (50dp, stacked Icon + Label with full width per tab, fully protected by left/right/bottom SafeArea
///   against camera notches, 3-button navigation bars, and gesture pills with zero text truncation).
class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({
    required this.navigationShell,
    this.topBanner,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final Widget? topBanner;

  void _onDestinationSelected(int index) {
    if (index != navigationShell.currentIndex) {
      HapticFeedback.selectionClick();
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = navigationShell.currentIndex;

    final destinations = [
      _NavDestinationData(
        icon: CupertinoIcons.square_grid_2x2,
        activeIcon: CupertinoIcons.square_grid_2x2_fill,
        label: l10n.navOverview,
      ),
      _NavDestinationData(
        icon: CupertinoIcons.doc_text,
        activeIcon: CupertinoIcons.doc_text_fill,
        label: l10n.navTransactions,
      ),
      _NavDestinationData(
        icon: CupertinoIcons.chart_pie,
        activeIcon: CupertinoIcons.chart_pie_fill,
        label: l10n.navBudgets,
      ),
      _NavDestinationData(
        icon: CupertinoIcons.chart_bar,
        activeIcon: CupertinoIcons.chart_bar_fill,
        label: l10n.navReports,
      ),
      _NavDestinationData(
        icon: CupertinoIcons.gear_alt,
        activeIcon: CupertinoIcons.gear_alt_fill,
        label: l10n.navSettings,
      ),
    ];

    final isLandscape = context.isLandscape;
    final navBarHeight = isLandscape
        ? AppleTokens.navBarHeightLandscape
        : AppleTokens.navBarHeightPortrait;

    return Scaffold(
      body: Column(
        children: [
          ?topBanner,
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1C1C1E).withValues(alpha: 0.90)
                  : Colors.white.withValues(alpha: 0.90),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
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
                maxScaleFactor: isLandscape ? 1.05 : 1.15,
                child: SizedBox(
                  height: navBarHeight,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          for (int i = 0; i < destinations.length; i++)
                            _AppleNavBarItem(
                              data: destinations[i],
                              isSelected: i == currentIndex,
                              isLandscape: isLandscape,
                              onTap: () => _onDestinationSelected(i),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDestinationData {
  const _NavDestinationData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _AppleNavBarItem extends StatelessWidget {
  const _AppleNavBarItem({
    required this.data,
    required this.isSelected,
    required this.isLandscape,
    required this.onTap,
  });

  final _NavDestinationData data;
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
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 12 : 14,
            vertical: isLandscape ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: isDark ? 0.22 : 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
          ),
          child: Icon(
            isSelected ? data.activeIcon : data.icon,
            size: isLandscape ? 20 : 22,
            color: isSelected ? primaryColor : inactiveColor,
          ),
        ),
        SizedBox(height: isLandscape ? 1 : 2),
        Text(
          data.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isLandscape ? 10.0 : 10.5,
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
