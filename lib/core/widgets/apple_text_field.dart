import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:so_thu_chi/core/theme/apple_theme_tokens.dart';

/// Standard Apple HIG Text Input Component with unified padding,
/// squircle container, focused accent border, and optional clear button.
class AppleTextField extends StatefulWidget {
  const AppleTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.label,
    this.placeholder,
    this.prefixIcon,
    this.prefixText,
    this.suffix,
    this.suffixIcon,
    this.clearable = false,
    this.obscureText = false,
    this.readOnly = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.borderRadius,
    this.backgroundColor,
    this.contentPadding,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final String? label;
  final String? placeholder;
  final Widget? prefixIcon;
  final String? prefixText;
  final Widget? suffix;
  final Widget? suffixIcon;
  final bool clearable;
  final bool obscureText;
  final bool readOnly;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<AppleTextField> createState() => _AppleTextFieldState();
}

class _AppleTextFieldState extends State<AppleTextField> {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;
  bool _isInternalController = false;
  bool _isInternalFocusNode = false;
  bool _isFocused = false;
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController(text: widget.initialValue);
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

    _showClear = widget.clearable && _controller.text.isNotEmpty;
    _controller.addListener(_handleControllerChange);
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleControllerChange() {
    final hasText = _controller.text.isNotEmpty;
    if (_showClear != (widget.clearable && hasText)) {
      setState(() => _showClear = widget.clearable && hasText);
    }
  }

  void _handleFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    _focusNode.removeListener(_handleFocusChange);
    if (_isInternalController) _controller.dispose();
    if (_isInternalFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final radius = widget.borderRadius ?? BorderRadius.circular(AppleTokens.radiusControl);

    final bg = widget.backgroundColor ??
        (isDark
            ? (context.isOled
                ? AppleTokens.bgOledSecondary
                : const Color(0xFF2C2C2E))
            : Colors.white);

    final borderColor = _isFocused
        ? primary.withValues(alpha: 0.85)
        : (isDark
            ? const Color(0xFF38383A)
            : const Color(0xFFD1D1D6));

    Widget? suffixWidget = widget.suffix ?? widget.suffixIcon;
    if (widget.clearable && _showClear && !widget.readOnly) {
      suffixWidget = CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(28, 28),
        onPressed: () {
          _controller.clear();
          widget.onChanged?.call('');
        },
        child: Icon(
          CupertinoIcons.clear_circled_solid,
          size: 18,
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFFC7C7CC),
        ),
      );
    }

    final isSpecialInput = widget.obscureText ||
        widget.keyboardType?.index == TextInputType.phone.index ||
        widget.keyboardType?.index == TextInputType.number.index ||
        widget.keyboardType?.index == TextInputType.emailAddress.index ||
        widget.keyboardType?.index == TextInputType.url.index ||
        widget.keyboardType?.index == TextInputType.visiblePassword.index;

    final effectiveTextCapitalization = isSpecialInput
        ? TextCapitalization.none
        : widget.textCapitalization;

    final shouldCapitalizeFirstLetter =
        !isSpecialInput && effectiveTextCapitalization != TextCapitalization.none;

    final effectiveFormatters = <TextInputFormatter>[
      if (widget.inputFormatters != null) ...widget.inputFormatters!,
      if (shouldCapitalizeFirstLetter &&
          (widget.inputFormatters == null ||
              !widget.inputFormatters!
                  .any((f) => f is FirstLetterCapitalizationFormatter)))
        const FirstLetterCapitalizationFormatter(),
    ];

    final field = TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: effectiveTextCapitalization,
      inputFormatters: effectiveFormatters,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 340),
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.placeholder,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 15,
          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF9E9E9E),
        ),
        prefixIcon: widget.prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: widget.prefixIcon,
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        prefixText: widget.prefixText,
        prefixStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        suffixIcon: suffixWidget != null
            ? Padding(
                padding: const EdgeInsets.only(right: 10),
                child: suffixWidget,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        filled: true,
        fillColor: bg,
        isDense: true,
        contentPadding: widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: borderColor, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: borderColor, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppleTokens.systemRed, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppleTokens.systemRed, width: 1.5),
        ),
      ),
    );

    return field;
  }
}

/// A [TextInputFormatter] that automatically capitalizes the first non-whitespace
/// letter of the input, while respecting active IME composing buffers (e.g. Vietnamese Telex).
class FirstLetterCapitalizationFormatter extends TextInputFormatter {
  const FirstLetterCapitalizationFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Do not alter text while the IME is actively composing (e.g. Vietnamese Telex composing buffer).
    if (newValue.composing.isValid &&
        newValue.composing.start >= 0 &&
        newValue.composing.end > newValue.composing.start) {
      return newValue;
    }

    final match = RegExp(r'\S').firstMatch(newValue.text);
    if (match == null) {
      return newValue;
    }

    final index = match.start;
    final firstChar = newValue.text[index];
    final upperChar = firstChar.toUpperCase();

    if (firstChar == upperChar) {
      return newValue;
    }

    final lengthDiff = upperChar.length - firstChar.length;
    final newText = newValue.text.replaceRange(index, index + 1, upperChar);
    TextSelection newSelection = newValue.selection;

    if (lengthDiff != 0 && newValue.selection.end >= index + 1) {
      newSelection = newValue.selection.copyWith(
        baseOffset: newValue.selection.baseOffset + lengthDiff,
        extentOffset: newValue.selection.extentOffset + lengthDiff,
      );
    }

    return newValue.copyWith(
      text: newText,
      selection: newSelection,
    );
  }
}
