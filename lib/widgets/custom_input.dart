import 'package:flutter/material.dart';
import 'dart:async';
import '../services/location_service.dart';

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

  const CustomInput({
    Key? key,
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
  }) : super(key: key);

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _elevationAnimation;
  bool _isFocused = false;
  late FocusNode _focusNode;
  bool _isValidatingLocation = false;
  String? _locationError;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation * 1.5,
    ).animate(_animationController);
    widget.controller.addListener(_handleTextChange);
    
    // Add listener to handle focus changes
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _handleTextChange() {
    if (widget.isLocationField && widget.locationService != null) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 1500), () {
        if (widget.controller.text.isNotEmpty) {
          _validateLocation(widget.controller.text.trim());
        } else {
          setState(() => _locationError = null);
        }
      });
    }
    setState(() {}); // Trigger rebuild when text changes
  }

  Future<void> _validateLocation(String location) async {
    if (!mounted) return;
    setState(() => _isValidatingLocation = true);
    try {
      final result = await widget.locationService!.validateAndNormalizeLocation(location);
      
      if (!mounted) return;
      
      if (result.isValid && result.normalizedLocation != null) {
        // Only update if the normalized location is different from current input
        // and the user hasn't typed anything new
        if (result.normalizedLocation != widget.controller.text && 
            location == widget.controller.text.trim()) {
          widget.controller.text = result.normalizedLocation!;
          // Move cursor to end
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length),
          );
        }
        setState(() => _locationError = null);
      } else {
        setState(() => _locationError = result.error ?? 'Invalid location');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationError = 'Error validating location');
    } finally {
      if (mounted) {
        setState(() => _isValidatingLocation = false);
      }
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
    if (widget.onSubmitted != null) {
      widget.onSubmitted!(value);
    }
    
    // Move to next field if available
    if (widget.nextFocusNode != null) {
      widget.nextFocusNode!.requestFocus();
    } else {
      // If no next field, unfocus to hide keyboard
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor = theme.colorScheme.surface;
    final defaultBorderColor = theme.colorScheme.outline.withOpacity(0.5);
    final focusBorderColor = theme.colorScheme.primary;

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
            Container(
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
                validator: (value) {
                  if (widget.isLocationField && _locationError != null) {
                    return _locationError;
                  }
                  return widget.validator?.call(value);
                },
                textInputAction: widget.nextFocusNode != null 
                    ? TextInputAction.next 
                    : TextInputAction.done,
                autofocus: widget.autofocus,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  errorText: widget.errorText,
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isLocationField && _isValidatingLocation)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      if (widget.controller.text.isNotEmpty && !widget.obscureText)
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          onPressed: () {
                            widget.controller.clear();
                          },
                        ),
                      if (widget.suffixIcon != null) widget.suffixIcon!,
                    ],
                  ),
                  filled: true,
                  fillColor: widget.backgroundColor ?? defaultBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    borderSide: BorderSide(
                      color: widget.borderColor ?? defaultBorderColor,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    borderSide: BorderSide(
                      color: widget.borderColor ?? defaultBorderColor,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    borderSide: BorderSide(
                      color: focusBorderColor,
                      width: 2.0,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    borderSide: BorderSide(
                      color: theme.colorScheme.error,
                      width: 1.5,
                    ),
                  ),
                ),
                onTapOutside: (_) => _focusNode.unfocus(),
                readOnly: widget.readOnly,
              ),
            ),
          ],
        );
      },
    );
  }
} 