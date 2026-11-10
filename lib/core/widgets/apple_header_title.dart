import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:so_thu_chi/core/l10n/l10n_ext.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Standard Apple HIG Back Button for sub-screens.
/// Features a Cupertino chevron with 44x44 minimum touch target and smooth haptic feedback.
class AppleBackButton extends StatelessWidget {
  const AppleBackButton({
    super.key,
    this.onPressed,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isLandscape = context.isLandscape;
    return IconButton(
      icon: Icon(
        CupertinoIcons.chevron_left,
        size: isLandscape ? 20 : 22,
      ),
      tooltip: tooltip ?? context.l10n.back,
      onPressed: onPressed ?? () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          try {
            context.pop();
          } catch (_) {
            Navigator.of(context).maybePop();
          }
        }
      },
    );
  }
}

/// Unified Apple HIG Screen Header Title.
/// Combines a consistent typography baseline, responsive font sizing, an optional
/// accent squircle icon, a distinct screen badge pill, and optional subtitle.
class AppleHeaderTitle extends StatelessWidget {
  const AppleHeaderTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    this.icon,
    this.accentColor,
    this.isLandscape = false,
  });

  final String title;
  final String? subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final IconData? icon;
  final Color? accentColor;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveAccent = accentColor ?? theme.colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            width: isLandscape ? 24 : 28,
            height: isLandscape ? 24 : 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: effectiveAccent.withValues(alpha: isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(isLandscape ? 6 : 8),
              border: Border.all(
                color: effectiveAccent.withValues(alpha: isDark ? 0.35 : 0.2),
                width: 0.6,
              ),
            ),
            child: Icon(
              icon,
              size: isLandscape ? 13 : 15,
              color: effectiveAccent,
            ),
          ),
          SizedBox(width: isLandscape ? 6 : 8),
        ],
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: isLandscape ? 16 : 19,
                        letterSpacing: -0.35,
                      ),
                    ),
                  ),
                  if (badgeText != null && badgeText!.isNotEmpty) ...[
                    const SizedBox(width: 7),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLandscape ? 6 : 7,
                        vertical: isLandscape ? 1.5 : 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor ??
                            effectiveAccent.withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(AppleTokens.radiusPill),
                        border: Border.all(
                          color: (badgeColor ?? effectiveAccent)
                              .withValues(alpha: isDark ? 0.4 : 0.25),
                          width: 0.6,
                        ),
                      ),
                      child: Text(
                        badgeText!,
                        style: TextStyle(
                          fontSize: isLandscape ? 10 : 11,
                          fontWeight: FontWeight.w700,
                          color: badgeTextColor ?? effectiveAccent,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (subtitle != null && subtitle!.isNotEmpty && !isLandscape) ...[
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
