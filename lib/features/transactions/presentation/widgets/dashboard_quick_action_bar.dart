import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/router/app_routes.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

/// Modern flat-elevated quick action grid on the dashboard for:
/// Giao dịch (+), Ví tiền, Tiết kiệm, Định kỳ, Sổ ghi nợ, Danh mục.
class DashboardQuickActionBar extends StatelessWidget {
  const DashboardQuickActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final actions = [
      _ActionItemData(
        icon: CupertinoIcons.plus_circle_fill,
        label: l10n.homeActionTransaction,
        accentColor: primary,
        route: AppRoutes.transactionNew,
      ),
      _ActionItemData(
        icon: CupertinoIcons.creditcard_fill,
        label: l10n.homeActionWallet,
        accentColor: const Color(0xFF0284C7),
        route: AppRoutes.accounts,
      ),
      _ActionItemData(
        icon: CupertinoIcons.sparkles,
        label: l10n.homeActionSavings,
        accentColor: const Color(0xFFF59E0B),
        route: AppRoutes.savings,
      ),
      _ActionItemData(
        icon: CupertinoIcons.arrow_2_circlepath_circle_fill,
        label: l10n.homeActionRecurring,
        accentColor: const Color(0xFF9333EA),
        route: AppRoutes.recurring,
      ),
      _ActionItemData(
        icon: CupertinoIcons.person_2_fill,
        label: l10n.homeActionDebts,
        accentColor: const Color(0xFFE11D48),
        route: AppRoutes.debts,
      ),
      _ActionItemData(
        icon: CupertinoIcons.square_grid_2x2_fill,
        label: l10n.homeActionCategories,
        accentColor: const Color(0xFF0D9488),
        route: AppRoutes.categories,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = context.isLandscape || constraints.maxWidth >= 540;

        if (isWide) {
          // Landscape / Tablet: All 6 actions in a single clean elevated row
          return Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionCardTile(action: actions[i]),
                ),
              ],
            ],
          );
        }

        // Mobile Portrait: 2 rows x 3 columns modern flat elevated grid
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: _QuickActionCardTile(action: actions[0])),
                const SizedBox(width: 10),
                Expanded(child: _QuickActionCardTile(action: actions[1])),
                const SizedBox(width: 10),
                Expanded(child: _QuickActionCardTile(action: actions[2])),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _QuickActionCardTile(action: actions[3])),
                const SizedBox(width: 10),
                Expanded(child: _QuickActionCardTile(action: actions[4])),
                const SizedBox(width: 10),
                Expanded(child: _QuickActionCardTile(action: actions[5])),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ActionItemData {
  const _ActionItemData({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.route,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final String route;
}

class _QuickActionCardTile extends StatelessWidget {
  const _QuickActionCardTile({
    required this.action,
  });

  final _ActionItemData action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ApplePressable(
      scaleDown: 0.94,
      onTap: () {
        HapticFeedback.selectionClick();
        context.push(action.route);
      },
      borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark
              ? (context.isOled
                  ? AppleTokens.bgOledCard
                  : AppleTokens.bgDarkCard)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            width: AppleTokens.hairline,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : action.accentColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: action.accentColor.withValues(alpha: isDark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Icon(
                action.icon,
                size: 22,
                color: action.accentColor,
              ),
            ),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  action.label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.92)
                        : Colors.black87,
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
