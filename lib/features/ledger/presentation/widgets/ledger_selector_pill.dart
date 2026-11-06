import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';
import 'package:so_thu_chi/features/ledger/presentation/controllers/ledgers_controller.dart';
import 'package:so_thu_chi/features/ledger/presentation/widgets/ledger_switcher_sheet.dart';

class LedgerSelectorPill extends ConsumerWidget {
  const LedgerSelectorPill({
    super.key,
    this.compact = false,
  });

  final bool compact;

  IconData _resolveIcon(String iconKey) {
    switch (iconKey) {
      case 'family':
        return CupertinoIcons.person_3_fill;
      case 'briefcase':
        return CupertinoIcons.briefcase_fill;
      case 'wallet':
        return CupertinoIcons.creditcard_fill;
      case 'star':
        return CupertinoIcons.star_fill;
      case 'person':
      default:
        return CupertinoIcons.person_crop_circle_fill;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLandscape = context.isLandscape;
    final activeLedger = ref.watch(activeLedgerProvider);
    final color = Color(activeLedger.color);

    if (compact) {
      return Tooltip(
        message: activeLedger.name,
        child: ApplePressable(
          onTap: () {
            HapticFeedback.lightImpact();
            LedgerSwitcherSheet.show(context);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: isLandscape ? 28 : 36,
            height: isLandscape ? 28 : 36,
            decoration: BoxDecoration(
              color: isDark
                  ? AppleTokens.bgDarkSecondary
                  : AppleTokens.bgLightSecondary,
              borderRadius: BorderRadius.circular(isLandscape ? 8 : 10),
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.35 : 0.22),
                width: AppleTokens.hairline,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  _resolveIcon(activeLedger.icon),
                  size: isLandscape ? 15 : 17,
                  color: color,
                ),
                Positioned(
                  top: isLandscape ? 4 : 5,
                  right: isLandscape ? 4 : 5,
                  child: Container(
                    width: isLandscape ? 5 : 6,
                    height: isLandscape ? 5 : 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppleTokens.bgDarkSecondary
                            : Colors.white,
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ApplePressable(
      onTap: () {
        HapticFeedback.lightImpact();
        LedgerSwitcherSheet.show(context);
      },
      borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 8 : 10,
          vertical: isLandscape ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? AppleTokens.bgDarkSecondary
              : AppleTokens.bgLightSecondary,
          borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.35 : 0.25),
            width: AppleTokens.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isLandscape ? 6 : 8,
              height: isLandscape ? 6 : 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: isLandscape ? 4 : 6),
            Icon(_resolveIcon(activeLedger.icon), size: isLandscape ? 13 : 14, color: color),
            SizedBox(width: isLandscape ? 4 : 6),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isLandscape ? 110 : 130),
              child: Text(
                activeLedger.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isLandscape ? 12 : 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_down,
              size: isLandscape ? 10 : 11,
              color: AppleTokens.systemGray,
            ),
          ],
        ),
      ),
    );
  }
}
