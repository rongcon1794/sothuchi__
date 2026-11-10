import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:so_thu_chi/features/accounts/presentation/widgets/wallet_form_sheet.dart';
import 'package:so_thu_chi/features/settings/presentation/controllers/settings_controller.dart';
import 'package:so_thu_chi/features/transactions/presentation/widgets/transaction_wallet_picker_sheet.dart';

class DashboardQuickActionBar extends ConsumerWidget {
  const DashboardQuickActionBar({super.key});

  Future<void> _handleWalletTap(
      BuildContext context, WidgetRef ref, String locale) async {
    final activeWallets = ref.read(activeAccountsProvider);
    if (activeWallets.isEmpty) {
      final created = await WalletFormSheet.show(context);
      if (created != null && context.mounted) {
        await context.push(AppRoutes.accountDetail(created.id));
      }
      return;
    }
    if (activeWallets.length == 1) {
      await context.push(AppRoutes.accountDetail(activeWallets.first.id));
      return;
    }

    final pickedWalletId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionWalletPickerSheet(
        wallets: activeWallets,
        selectedId: null,
        defaultWalletId:
            ref.read(settingsControllerProvider).value?.defaultWalletId,
        locale: locale,
        title: locale.startsWith('vi')
            ? 'Chi tiết ví & tài khoản'
            : 'Wallet details',
        onCreateNew: () async {
          final created = await WalletFormSheet.show(context);
          if (created != null && context.mounted) {
            await context.push(AppRoutes.accountDetail(created.id));
          }
        },
      ),
    );

    if (pickedWalletId != null && context.mounted) {
      await context.push(AppRoutes.accountDetail(pickedWalletId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final locale =
        ref.watch(settingsControllerProvider).value?.localeCode ?? 'vi';

    final actions = [
      _ActionItemData(
        icon: CupertinoIcons.plus,
        label: l10n.homeActionTransaction,
        gradient: [
          Color.lerp(primary, Colors.white, 0.28)!,
          primary,
        ],
        accentColor: primary,
        route: AppRoutes.transactionNew,
      ),
      _ActionItemData(
        icon: CupertinoIcons.creditcard,
        label: l10n.homeActionWallet,
        gradient: const [Color(0xFF38BDF8), Color(0xFF0284C7)],
        accentColor: const Color(0xFF0284C7),
        onTap: () => _handleWalletTap(context, ref, locale),
      ),
      _ActionItemData(
        icon: CupertinoIcons.sparkles,
        label: l10n.homeActionSavings,
        gradient: const [Color(0xFFFBBF24), Color(0xFFD97706)],
        accentColor: const Color(0xFFF59E0B),
        route: AppRoutes.savings,
      ),
      _ActionItemData(
        icon: CupertinoIcons.repeat,
        label: l10n.homeActionRecurring,
        gradient: const [Color(0xFFC084FC), Color(0xFF7E22CE)],
        accentColor: const Color(0xFF9333EA),
        route: AppRoutes.recurring,
      ),
      _ActionItemData(
        icon: CupertinoIcons.person_2,
        label: l10n.homeActionDebts,
        gradient: const [Color(0xFFFB7185), Color(0xFFE11D48)],
        accentColor: const Color(0xFFE11D48),
        route: AppRoutes.debts,
      ),
      _ActionItemData(
        icon: CupertinoIcons.square_grid_2x2,
        label: l10n.homeActionCategories,
        gradient: const [Color(0xFF2DD4BF), Color(0xFF0F766E)],
        accentColor: const Color(0xFF0D9488),
        route: AppRoutes.categories,
      ),
    ];

    final isLandscape = context.isLandscape;
    final isDark = theme.brightness == Brightness.dark;

    if (isLandscape) {
      final landscapeActions = actions.take(4).toList();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? (context.isOled
                  ? AppleTokens.bgOledCard
                  : AppleTokens.bgDarkCard)
              : AppleTokens.bgLightCard,
          borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
          border: Border.all(
            color: isDark ? AppleTokens.separatorDark : AppleTokens.borderLight,
            width: AppleTokens.hairline,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < landscapeActions.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: _LandscapeQuickActionItem(
                  icon: landscapeActions[i].icon,
                  label: landscapeActions[i].label,
                  gradient: landscapeActions[i].gradient,
                  accentColor: landscapeActions[i].accentColor,
                  onTap: landscapeActions[i].onTap ??
                      () => context.push(landscapeActions[i].route!),
                ),
              ),
            ],
          ],
        ),
      );
    }

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final barHeight = math.max(88.0, 60.0 + (28.0 * textScale));

    return SizedBox(
      height: barHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _QuickActionItem(
            icon: action.icon,
            label: action.label,
            gradient: action.gradient,
            accentColor: action.accentColor,
            onTap: action.onTap ?? () => context.push(action.route!),
          );
        },
      ),
    );
  }
}

class _LandscapeQuickActionItem extends StatelessWidget {
  const _LandscapeQuickActionItem({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ApplePressable(
      scaleDown: 0.94,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(AppleTokens.radiusControl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.32 : 0.45),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 15,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.35),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    icon,
                    size: 16,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionItemData {
  const _ActionItemData({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.accentColor,
    this.route,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final Color accentColor;
  final String? route;
  final VoidCallback? onTap;
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 76,
      child: ApplePressable(
        scaleDown: 0.92,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.32 : 0.45),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: isDark ? 0.38 : 0.28),
                    blurRadius: 12,
                    spreadRadius: -1,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Specular gloss reflection overlay
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 24,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.35),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    icon,
                    size: 24,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

