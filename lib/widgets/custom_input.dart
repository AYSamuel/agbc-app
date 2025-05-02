import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'mixins/location_validation_mixin.dart';
import '../utils/theme.dart';

/// A customizable input field widget with support for various features including
/// location validation, focus management, and custom styling.
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
  final bool isLocationField;
  final LocationService? locationService;
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
    this.isLocationField = false,
    this.locationService,
    this.readOnly = false,
    this.autofillHints,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput>
    with SingleTickerProviderStateMixin, LocationValidationMixin {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _setupListeners();

    if (widget.isLocationField) {
      initializeLocationValidation(
        controller: widget.controller,
        locationService: widget.locationService,
      );
    }
  }

  void _setupListeners() {
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _cleanupListeners();
    if (widget.isLocationField) {
      disposeLocationValidation();
    }
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
      validator: _buildValidator,
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
        errorStyle: TextStyle(
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
        fillColor: widget.enabled
            ? AppTheme.cardColor
            : AppTheme.cardColor.withValues(alpha: 0.5),
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
          borderSide: BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          borderSide: BorderSide(
            color: AppTheme.errorColor,
            width: 1.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        isDense: true,
      ),
    );
  }

  String? _buildValidator(String? value) {
    if (widget.isLocationField && locationError != null) {
      return locationError;
    }
    return widget.validator?.call(value);
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffixIcon != null) return widget.suffixIcon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isLocationField && isValidatingLocation)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neutralColor),
            ),
          ),
        if (widget.controller.text.isNotEmpty && !widget.obscureText)
          IconButton(
            icon: Icon(
              Icons.clear,
              color: AppTheme.neutralColor,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              widget.controller.clear();
              if (widget.onChanged != null) {
                widget.onChanged!('');
              }
            },
          ),
      ],
    );
  }
}
