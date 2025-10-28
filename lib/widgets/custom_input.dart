import 'package:flutter/material.dart';
import '../utils/theme.dart';

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
    this.labelColor,
    this.borderRadius = 12.0,
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
    widget.controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _cleanupListeners();
    super.dispose();
  }

  void _cleanupListeners() {
    _focusNode.removeListener(_handleFocusChange);
    widget.controller.removeListener(_handleTextChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
  }

  void _handleTextChange() {
    setState(() {});
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
              color: widget.labelColor ?? AppTheme.neutralColor,
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
            ? AppTheme.darkNeutralColor
            : AppTheme.neutralColor.withValues(alpha: 0.5),
        fontWeight: FontWeight.w500,
        fontSize: 16,
        letterSpacing: 0.2,
      ),
      readOnly: widget.readOnly,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(
          color: AppTheme.neutralColor.withValues(alpha: 0.6),
          fontWeight: FontWeight.w400,
          fontSize: 15,
          letterSpacing: 0.2,
        ),
        errorText: widget.errorText,
        errorStyle: const TextStyle(
          color: AppTheme.errorColor,
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
                        ? AppTheme.primaryColor
                        : AppTheme.neutralColor.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  child: widget.prefixIcon!,
                ),
              )
            : null,
        suffixIcon: _buildSuffixIcon(),
        filled: true,
        fillColor: widget.backgroundColor ?? Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: AppTheme.neutralColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: AppTheme.neutralColor.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: const BorderSide(
            color: AppTheme.errorColor,
            width: 1.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffixIcon != null) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: IconTheme(
          data: IconThemeData(
            color: _isFocused
                ? AppTheme.primaryColor
                : AppTheme.neutralColor.withValues(alpha: 0.6),
            size: 20,
          ),
          child: widget.suffixIcon!,
        ),
      );
    }

    // Show clear button whenever there's text
    if (widget.controller.text.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: IconButton(
          padding: const EdgeInsets.all(0),
          constraints: const BoxConstraints(),
          icon: Icon(
            Icons.clear,
            color: _isFocused
                ? AppTheme.primaryColor
                : AppTheme.neutralColor.withValues(alpha: 0.6),
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
    }

    return null;
  }
}
