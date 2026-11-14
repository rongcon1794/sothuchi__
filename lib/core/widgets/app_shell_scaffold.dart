import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/widgets/apple_dynamic_ambient_background.dart';
import 'package:so_thu_chi/core/widgets/navigation/apple_bottom_nav_bar.dart';

/// Translucent, frosted-glass Apple navigation shell.
/// Uses the dedicated [AppleBottomNavBar] component to provide tactile navigation.
class AppShellScaffold extends ConsumerWidget {
  const AppShellScaffold({
    required this.navigationShell,
    this.topBanner,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final Widget? topBanner;

  void _onDestinationSelected(WidgetRef ref, int index) {
    if (index != navigationShell.currentIndex) {
      HapticFeedback.selectionClick();
      ref.read(ambientBackgroundIndexProvider.notifier).setIndex(index);
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentIndex = navigationShell.currentIndex;

    // Keep global ambient background index synced when navigating (only when out of sync)
    if (ref.read(ambientBackgroundIndexProvider) != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(ambientBackgroundIndexProvider) != currentIndex) {
          ref.read(ambientBackgroundIndexProvider.notifier).setIndex(currentIndex);
        }
      });
    }

    final destinations = [
      AppleNavDestination(
        icon: CupertinoIcons.square_grid_2x2,
        activeIcon: CupertinoIcons.square_grid_2x2_fill,
        label: l10n.navOverview,
      ),
      AppleNavDestination(
        icon: CupertinoIcons.doc_text,
        activeIcon: CupertinoIcons.doc_text_fill,
        label: l10n.navTransactions,
      ),
      AppleNavDestination(
        icon: CupertinoIcons.chart_pie,
        activeIcon: CupertinoIcons.chart_pie_fill,
        label: l10n.navBudgets,
      ),
      AppleNavDestination(
        icon: CupertinoIcons.chart_bar,
        activeIcon: CupertinoIcons.chart_bar_fill,
        label: l10n.navReports,
      ),
      AppleNavDestination(
        icon: CupertinoIcons.gear_alt,
        activeIcon: CupertinoIcons.gear_alt_fill,
        label: l10n.navSettings,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          ?topBanner,
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: AppleBottomNavBar(
        currentIndex: currentIndex,
        destinations: destinations,
        onTap: (index) => _onDestinationSelected(ref, index),
      ),
    );
  }
}
