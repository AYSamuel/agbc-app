import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'mixins/location_validation_mixin.dart';

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
  final double borderRadius;
  final double elevation;
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
    this.borderRadius = 12.0,
    this.elevation = 4.0,
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

class _CustomInputState extends State<CustomInput> with SingleTickerProviderStateMixin, LocationValidationMixin {
  late final AnimationController _animationController;
  late final Animation<double> _elevationAnimation;
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _setupAnimations();
    _setupListeners();
    
    if (widget.isLocationField) {
      initializeLocationValidation(
        controller: widget.controller,
        locationService: widget.locationService,
      );
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation * 1.5,
    ).animate(_animationController);
  }

  void _setupListeners() {
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _cleanupListeners();
    _animationController.dispose();
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
      if (_isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _handleSubmitted(String value) {
    widget.onSubmitted?.call(value);
    
    if (widget.nextFocusNode != null) {
      widget.nextFocusNode!.requestFocus();
    } else {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _elevationAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showLabel && widget.label != null) ...[
              Text(
                widget.label!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
            ],
            _buildInputField(theme),
          ],
        );
      },
    );
  }

  Widget _buildInputField(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: _elevationAnimation.value,
            offset: Offset(0, _elevationAnimation.value / 2),
          ),
        ],
      ),
      child: TextFormField(
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
        style: theme.textTheme.bodyLarge,
        readOnly: widget.readOnly,
        autofillHints: widget.autofillHints,
        decoration: InputDecoration(
          hintText: widget.hint,
          errorText: widget.errorText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: _buildSuffixIcon(),
          filled: true,
          fillColor: widget.backgroundColor ?? theme.colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: widget.borderColor ?? theme.colorScheme.outline.withOpacity(0.5),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: widget.borderColor ?? theme.colorScheme.outline.withOpacity(0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: widget.borderColor ?? theme.colorScheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(
              color: theme.colorScheme.error,
            ),
          ),
        ),
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
            ),
          ),
        if (widget.controller.text.isNotEmpty && !widget.obscureText)
          IconButton(
            icon: const Icon(Icons.clear),
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