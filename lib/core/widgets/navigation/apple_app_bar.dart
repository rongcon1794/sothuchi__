import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/responsive/apple_responsive.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/widgets/apple_header_title.dart';

/// Unified, highly customizable Apple HIG App Bar.
/// Encapsulates:
/// - Responsive height switching (portrait vs landscape).
/// - Default scaffold-matching solid or translucent background (no elevation bleed).
/// - Automatic `AppleBackButton` injection when navigation stack is poppable.
/// - Integrated `AppleHeaderTitle` with icon, badge, and responsive typography.
/// - Flexible slot support for custom leading, actions, and bottom widgets.
class AppleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppleAppBar({
    super.key,
    this.titleText,
    this.titleWidget,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.badgeText,
    this.badgeColor,
    this.leading,
    this.showBackButton,
    this.onBackPressed,
    this.actions,
    this.bottom,
    this.titleSpacing,
    this.centerTitle = false,
    this.backgroundColor,
    this.toolbarHeight,
    this.isLandscape,
  });

  /// Simple string title rendered automatically via [AppleHeaderTitle].
  final String? titleText;

  /// Custom title widget if advanced layout is needed.
  final Widget? titleWidget;

  /// Optional subtitle rendered below title text.
  final String? subtitle;

  /// Optional accent squircle icon next to the title.
  final IconData? icon;

  /// Optional accent color for the title squircle icon.
  final Color? accentColor;

  /// Optional badge text next to the title.
  final String? badgeText;

  /// Optional background color for the badge pill.
  final Color? badgeColor;

  /// Custom leading widget. If null and [showBackButton] is true, defaults to [AppleBackButton].
  final Widget? leading;

  /// Whether to display a back button. Defaults to `Navigator.of(context).canPop()`.
  final bool? showBackButton;

  /// Optional callback invoked when the default back button is tapped.
  final VoidCallback? onBackPressed;

  /// Action buttons aligned on the trailing edge.
  final List<Widget>? actions;

  /// Optional bottom widget attached below the toolbar (e.g. tabs, search, month switcher).
  final PreferredSizeWidget? bottom;

  /// Horizontal padding before the title. Defaults to 0 when leading is present, 16 otherwise.
  final double? titleSpacing;

  /// Whether the title should be centered. Defaults to false (Apple HIG left-aligned).
  final bool centerTitle;

  /// Background color. Defaults to `theme.scaffoldBackgroundColor`.
  final Color? backgroundColor;

  /// Explicit toolbar height override.
  final double? toolbarHeight;

  /// Landscape layout flag. If omitted, automatically derived from [context.isLandscape].
  final bool? isLandscape;

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0.0;
    final baseHeight = toolbarHeight ??
        ((isLandscape == true)
            ? AppleTokens.appBarHeightLandscape
            : AppleTokens.appBarHeightPortrait);
    return Size.fromHeight(baseHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final landscape = isLandscape ?? context.isLandscape;
    final effectiveHeight = toolbarHeight ??
        (landscape
            ? AppleTokens.appBarHeightLandscape
            : AppleTokens.appBarHeightPortrait);

    final canPop = Navigator.of(context).canPop();
    final shouldShowBack = showBackButton ?? canPop;

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && shouldShowBack) {
      effectiveLeading = AppleBackButton(onPressed: onBackPressed);
    }

    Widget? effectiveTitle = titleWidget;
    if (effectiveTitle == null && titleText != null) {
      effectiveTitle = AppleHeaderTitle(
        title: titleText!,
        subtitle: subtitle,
        icon: icon,
        accentColor: accentColor,
        badgeText: badgeText,
        badgeColor: badgeColor,
        isLandscape: landscape,
      );
    }

    final effectiveSpacing =
        titleSpacing ?? (effectiveLeading != null ? 0.0 : 16.0);

    return AppBar(
      toolbarHeight: effectiveHeight,
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      titleSpacing: effectiveSpacing,
      leading: effectiveLeading,
      title: effectiveTitle,
      actions: actions != null
          ? (actions!.isNotEmpty
              ? [...actions!, const SizedBox(width: 8)]
              : const <Widget>[])
          : null,
      bottom: bottom,
    );
  }
}

