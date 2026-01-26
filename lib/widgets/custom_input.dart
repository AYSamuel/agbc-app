import 'package:flutter/material.dart';
import '../config/theme.dart';

/// A customizable input field widget with support for various features including
/// focus management, and custom styling.
class CustomInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final Function()? onTap;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final FocusNode? focusNode;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? focusBorderColor;
  final Color? labelColor;
  final double borderRadius;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool showLabel;
  final FocusNode? nextFocusNode;
  final bool readOnly;
  final List<String>? autofillHints;

  const CustomInput({
    super.key,
    this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.backgroundColor,
    this.borderColor,
    this.focusBorderColor,
    this.labelColor,
    this.borderRadius = 8.0,
    this.validator,
    this.textInputAction,
    this.autofocus = false,
    this.showLabel = true,
    this.nextFocusNode,
    this.readOnly = false,
    this.autofillHints,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _setupListeners();
  }

  void _setupListeners() {
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _cleanupListeners();
    super.dispose();
  }

  void _cleanupListeners() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _handleSubmitted(String value) {
    widget.onSubmitted?.call(value);

    if (widget.nextFocusNode != null) {
      widget.nextFocusNode!.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel && widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: widget.labelColor ?? AppTheme.textSecondary(context),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
        ],
        _buildInputField(theme),
      ],
    );
  }

  Widget _buildInputField(ThemeData theme) {
    final focusColor = widget.focusBorderColor ?? AppTheme.secondary(context);
    final borderColor =
        widget.borderColor ?? AppTheme.inputBorderColor(context);

    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      onFieldSubmitted: _handleSubmitted,
      onTap: widget.onTap,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      validator: widget.validator,
      textInputAction: widget.nextFocusNode != null
          ? TextInputAction.next
          : TextInputAction.done,
      autofocus: widget.autofocus,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: widget.enabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
        fontWeight: FontWeight.w500,
        fontSize: 16,
        letterSpacing: 0.2,
      ),
      readOnly: widget.readOnly,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w400,
          fontSize: 15,
          letterSpacing: 0.2,
        ),
        errorText: widget.errorText,
        errorStyle: TextStyle(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w500,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
        prefixIcon: widget.prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: IconTheme(
                  data: IconThemeData(
                    color: _isFocused
                        ? focusColor
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  child: widget.prefixIcon!,
                ),
              )
            : null,
        suffixIcon: _buildSuffixIcon(),
        filled: true,
        fillColor: widget.backgroundColor ?? theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: borderColor,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: borderColor,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: focusColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        isDense: true,
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    final theme = Theme.of(context);
    final focusColor = widget.focusBorderColor ?? AppTheme.accentTeal(context);

    if (widget.suffixIcon != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: IconTheme(
          data: IconThemeData(
            color: _isFocused
                ? focusColor
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            size: 20,
          ),
          child: widget.suffixIcon!,
        ),
      );
    }

    // Use ValueListenableBuilder to avoid rebuilding the entire widget
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        if (value.text.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            padding: const EdgeInsets.all(0),
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.clear,
              color: _isFocused
                  ? focusColor
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              size: 20,
            ),
            onPressed: () {
              widget.controller.clear();
              if (widget.onChanged != null) {
                widget.onChanged!('');
              }
            },
          ),
        );
      },
    );
  }
}
