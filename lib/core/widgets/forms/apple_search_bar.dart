import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';
import 'package:so_thu_chi/core/theme/tokens/app_semantic_colors.dart';
import 'package:so_thu_chi/core/widgets/apple_kit.dart';

/// Standard Apple HIG Search Bar Component.
/// Provides:
/// - Vertically centered text input with optical baseline alignment
/// - Clean search magnifying glass icon
/// - Subtle clear button [✕] when text is non-empty
/// - Smooth focus transition with brand primary border
/// - Synchronized elevation, background, and pill borders for visual consistency
class AppleSearchBar extends StatefulWidget {
  const AppleSearchBar({
    super.key,
    this.controller,
    required this.hintText,
    this.focusNode,
    this.onChanged,
    this.onClear,
    this.height,
    this.borderRadius,
    this.isLandscape = false,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hintText;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final double? height;
  final double? borderRadius;
  final bool isLandscape;
  final bool autofocus;

  @override
  State<AppleSearchBar> createState() => _AppleSearchBarState();
}

class _AppleSearchBarState extends State<AppleSearchBar> {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;
  bool _isInternalController = false;
  bool _isInternalFocusNode = false;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController();
      _isInternalController = true;
    } else {
      _controller = widget.controller!;
    }

    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    } else {
      _focusNode = widget.focusNode!;
    }

    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleTextChange);
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _handleFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    _focusNode.removeListener(_handleFocusChange);
    if (_isInternalController) {
      _controller.dispose();
    }
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _clearText() {
    unawaited(HapticFeedback.lightImpact());
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = context.semanticColors;
    final primary = theme.colorScheme.primary;

    final barHeight = widget.height ?? (widget.isLandscape ? 34.0 : 40.0);
    final iconSize = widget.isLandscape ? 15.0 : 17.0;
    final fontSize = widget.isLandscape ? 12.5 : 13.5;
    final effectiveRadius = BorderRadius.circular(
      widget.borderRadius ?? AppleTokens.radiusPill,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: barHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.inputBackground,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: _isFocused ? primary : colors.inputBorder,
          width: _isFocused ? 1.3 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            filled: false,
            fillColor: Colors.transparent,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            prefixIcon: Padding(
              padding: EdgeInsetsDirectional.only(
                start: widget.isLandscape ? 10 : 12,
                end: 8,
              ),
              child: Icon(
                CupertinoIcons.search,
                size: iconSize,
                color: _isFocused ? primary : colors.textTertiary,
              ),
            ),
            prefixIconConstraints: BoxConstraints(
              minWidth: widget.isLandscape ? 32 : 38,
              minHeight: barHeight,
            ),
            suffixIcon: _hasText
                ? Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: widget.isLandscape ? 6 : 8,
                    ),
                    child: ApplePressable(
                      scaleDown: 0.88,
                      onTap: _clearText,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          CupertinoIcons.clear_circled_solid,
                          size: iconSize,
                          color: colors.textTertiary,
                        ),
                      ),
                    ),
                  )
                : null,
            suffixIconConstraints: BoxConstraints(
              minWidth: widget.isLandscape ? 28 : 34,
              minHeight: barHeight,
            ),
            hintText: widget.hintText,
            hintStyle: TextStyle(
              fontSize: fontSize,
              color: colors.textTertiary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
