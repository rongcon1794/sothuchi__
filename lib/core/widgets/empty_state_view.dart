// Lucian UX/UI Prompt #088 / #092 · MIT License (c) 2026 Seokwoooo · https://lucianlabs.dev/uxui-prompt/#088
// Adapted for Flutter with tactile squircle icon badge, subtle breathing shadow, and responsive layout.

import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

/// Clean, accessible empty state view used across lists and charts.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lucian Squircle floating badge with gentle glow
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: primary.withValues(alpha: isDark ? 0.35 : 0.22),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: isDark ? 0.25 : 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, size: 34, color: primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: isDark ? LucianTokens.inkDark : LucianTokens.inkLight,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? LucianTokens.ink2Dark : LucianTokens.ink2Light,
                  height: 1.4,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              AppleButton(
                onPressed: onAction,
                label: actionLabel!,
                icon: Icons.add_rounded,
                isFullWidth: false,
                variant: AppleButtonVariant.primary,
              ),
            ],
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) {
          return content;
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        );
      },
    );
  }
}
