import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Translucent, frosted-glass Apple bottom navigation shell.
/// Features iOS 18 blur materials, subtle spring micro-interactions, and haptic feedback.
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
                  ? const Color(0xFF1C1C1E).withValues(alpha: 0.88)
                  : Colors.white.withValues(alpha: 0.88),
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
              child: SizedBox(
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (int i = 0; i < destinations.length; i++)
                      _AppleNavBarItem(
                        data: destinations[i],
                        isSelected: i == currentIndex,
                        onTap: () => _onDestinationSelected(i),
                      ),
                  ],
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
    required this.onTap,
  });

  final _NavDestinationData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = AppleTokens.jadePrimary;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedScale(
          scale: isSelected ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: isDark ? 0.22 : 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                ),
                child: Icon(
                  isSelected ? data.activeIcon : data.icon,
                  size: 22,
                  color: isSelected
                      ? primaryColor
                      : (isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF8E8E93)),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? primaryColor
                      : (isDark
                          ? const Color(0xFF8E8E93)
                          : const Color(0xFF8E8E93)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
