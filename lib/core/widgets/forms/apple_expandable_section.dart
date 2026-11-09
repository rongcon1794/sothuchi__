import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/theme/tokens/app_semantic_colors.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

/// Reusable Apple-styled Accordion Expandable Section for Filters and Form Sheets.
/// Features:
/// - Collapsed header with squircle icon, title, active selection subtitle, and rotated chevron
/// - Optional clear button `[✕]`
/// - Smooth animated size expansion
/// - Visual active badge/border
class AppleExpandableSection extends StatefulWidget {
  const AppleExpandableSection({
    super.key,
    required this.title,
    required this.expandedChild,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.initiallyExpanded = false,
    this.onToggle,
    this.onClear,
    this.hasActiveValue = false,
  });

  final String title;
  final Widget expandedChild;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onClear;
  final bool hasActiveValue;

  @override
  State<AppleExpandableSection> createState() => _AppleExpandableSectionState();
}

class _AppleExpandableSectionState extends State<AppleExpandableSection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late final AnimationController _animController;
  late final Animation<double> _chevronTurns;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: _isExpanded ? 1.0 : 0.0,
    );
    _chevronTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant AppleExpandableSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded &&
        widget.initiallyExpanded != _isExpanded) {
      _toggle(notify: false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle({bool notify = true}) {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
    if (notify && widget.onToggle != null) {
      widget.onToggle!(_isExpanded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = widget.iconColor ?? theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
        border: Border.all(
          color: widget.hasActiveValue
              ? accent.withValues(alpha: isDark ? 0.60 : 0.45)
              : colors.inputBorder,
          width: widget.hasActiveValue ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          ApplePressable(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(AppleTokens.radiusCard),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
                        borderRadius:
                            BorderRadius.circular(AppleTokens.radiusControl),
                      ),
                      child: Center(
                        child: Icon(
                          widget.icon,
                          size: 18,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: widget.hasActiveValue
                                ? accent
                                : colors.textPrimary,
                          ),
                        ),
                        if (widget.subtitle != null &&
                            widget.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: widget.hasActiveValue
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: widget.hasActiveValue
                                  ? accent
                                  : colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.hasActiveValue && widget.onClear != null) ...[
                    ApplePressable(
                      scaleDown: 0.88,
                      onTap: widget.onClear,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          CupertinoIcons.clear_circled_solid,
                          size: 18,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  RotationTransition(
                    turns: _chevronTurns,
                    child: Icon(
                      CupertinoIcons.chevron_down,
                      size: 16,
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Animated expandable body
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Divider(
                  height: 1,
                  thickness: 0.8,
                  color: colors.divider,
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: widget.expandedChild,
                ),
              ],
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            firstCurve: Curves.easeInOutCubic,
            secondCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }
}
