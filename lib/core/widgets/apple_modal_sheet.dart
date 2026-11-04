import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Standard Apple HIG Modal Bottom Sheet Scaffold.
/// Provides drag handle, header with title, subtitle, close action,
/// scrollable content with keyboard padding, and optional sticky bottom action bar.
class AppleModalSheetLayout extends StatelessWidget {
  const AppleModalSheetLayout({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.bottomAction,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 20),
    this.showDragHandle = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? bottomAction;
  final EdgeInsetsGeometry padding;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppleTokens.bgDarkPrimary : AppleTokens.bgLightPrimary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppleTokens.radiusHero),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showDragHandle) ...[
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3A3A3C)
                          : const Color(0xFFD1D1D6),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ] else
                const SizedBox(height: 16),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? const Color(0xFF8E8E93)
                                    : const Color(0xFF6C6C70),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(30, 30),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFE5E5EA),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.xmark,
                          size: 14,
                          color: isDark
                              ? const Color(0xFF8E8E93)
                              : const Color(0xFF6C6C70),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Divider(
                height: AppleTokens.hairline,
                color: isDark
                    ? AppleTokens.separatorDark
                    : AppleTokens.separatorLight,
              ),

              // Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: padding,
                  child: child,
                ),
              ),

              // Sticky Bottom Action
              if (bottomAction != null) ...[
                Divider(
                  height: AppleTokens.hairline,
                  color: isDark
                      ? AppleTokens.separatorDark
                      : AppleTokens.separatorLight,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: bottomAction!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
