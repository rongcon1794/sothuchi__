import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Apple-styled User Avatar widget.
///
/// Automatically displays the Google profile picture from [photoUrl] if available,
/// with graceful fallback to a jade gradient squircle badge bearing the user's initial.
class AppleUserAvatar extends StatelessWidget {
  const AppleUserAvatar({
    super.key,
    this.photoUrl,
    this.displayName,
    this.email,
    this.size = 48.0,
    this.borderRadius,
    this.showBorder = true,
    this.borderColor,
    this.onTap,
  });

  /// The network image URL (e.g. from Google Account).
  final String? photoUrl;

  /// User display name, used to extract initial for fallback avatar.
  final String? displayName;

  /// User email, secondary fallback for initial.
  final String? email;

  /// Diameter/size of the square avatar.
  final double size;

  /// Corner radius for the squircle. If omitted, defaults to `size * 0.28`.
  final double? borderRadius;

  /// Whether to render a subtle border & shadow.
  final bool showBorder;

  /// Optional custom border color.
  final Color? borderColor;

  /// Optional tap callback.
  final VoidCallback? onTap;

  String _extractInitial() {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    final mail = email?.trim();
    if (mail != null && mail.isNotEmpty) {
      return mail[0].toUpperCase();
    }
    return 'S';
  }

  Widget _buildFallback(BuildContext context, double radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B074), Color(0xFF0D7C66)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        _extractInitial(),
        style: TextStyle(
          color: Colors.white,
          fontSize: (size * 0.44).clamp(10.0, 32.0),
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? (size * 0.28);
    final hasValidUrl = photoUrl != null && photoUrl!.trim().isNotEmpty;

    Widget avatarCore;

    if (!hasValidUrl) {
      avatarCore = _buildFallback(context, effectiveRadius);
    } else {
      avatarCore = ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: Image.network(
          photoUrl!.trim(),
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildFallback(context, effectiveRadius);
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildFallback(context, effectiveRadius);
          },
        ),
      );
    }

    final decorated = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: showBorder
            ? Border.all(
                color: borderColor ??
                    (isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.black.withValues(alpha: 0.08)),
                width: 0.8,
              )
            : null,
        boxShadow: showBorder
            ? [
                BoxShadow(
                  color: AppleTokens.jadePrimary.withValues(alpha: isDark ? 0.18 : 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: avatarCore,
    );

    if (onTap != null) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onTap,
        child: decorated,
      );
    }

    return decorated;
  }
}
