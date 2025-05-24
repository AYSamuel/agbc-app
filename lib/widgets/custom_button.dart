import 'package:flutter/material.dart';
import 'package:agbc_app/widgets/loading_indicator.dart';
import 'package:agbc_app/utils/theme.dart';

/// Different button variants
enum ButtonVariant {
  /// A filled button with background color
  filled,
  
  /// An outlined button with border
  outlined,
  
  /// A text button with no background or border
  text,
}

/// A customizable button widget with multiple variants, loading state, and animations.
///
/// This widget provides a consistent button design across the app with:
/// - Multiple variants: filled, outlined, and text
/// - Loading state with spinner
/// - Disabled state styling
/// - Scale animation on press
/// - Customizable colors and dimensions
/// - Flexible child content
class CustomButton extends StatefulWidget {
  /// Callback when button is pressed
  final VoidCallback? onPressed;
  
  /// The button's child widget
  final Widget child;
  
  /// Button width (null for auto)
  final double? width;
  
  /// Button height
  final double height;
  
  /// Background color (ignored for text variant)
  final Color? backgroundColor;
  
  /// Text/icon color
  final Color? foregroundColor;
  
  /// Border radius
  final double borderRadius;
  
  /// Show loading indicator if true
  final bool isLoading;
  
  /// Animation duration
  final Duration animationDuration;
  
  /// Button style variant
  final ButtonVariant variant;
  
  /// Border color (only used for outlined variant)
  final Color? borderColor;
  
  /// Elevation (only used for filled variant)
  final double? elevation;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height = 50,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 12,
    this.isLoading = false,
    this.animationDuration = const Duration(milliseconds: 150),
    this.variant = ButtonVariant.filled,
    this.borderColor,
    this.elevation,
  });

  /// Creates a text button with default styling
  const CustomButton.text({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height = 40,
    this.foregroundColor,
    this.isLoading = false,
    this.animationDuration = const Duration(milliseconds: 150),
  })  : variant = ButtonVariant.text,
        backgroundColor = Colors.transparent,
        borderRadius = 0,
        borderColor = null,
        elevation = null;

  /// Creates an outlined button with default styling
  const CustomButton.outlined({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height = 50,
    this.backgroundColor = Colors.transparent,
    this.foregroundColor,
    this.borderRadius = 12,
    this.borderColor,
    this.isLoading = false,
    this.animationDuration = const Duration(milliseconds: 150),
  })  : variant = ButtonVariant.outlined,
        elevation = 0;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (widget.onPressed == null || widget.isLoading) return;

    await _controller.forward();
    await _controller.reverse();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final backgroundColor = isDisabled
        ? (widget.backgroundColor ?? AppTheme.primaryColor)
            .withValues(alpha: 0.5)
        : widget.backgroundColor ?? AppTheme.primaryColor;
    final foregroundColor = isDisabled
        ? (widget.foregroundColor ?? Colors.white).withValues(alpha: 0.5)
        : widget.foregroundColor ?? Colors.white;

    final buttonChild = widget.isLoading ? const LoadingIndicator() : widget.child;
    
    Widget button;
    
    switch (widget.variant) {
      case ButtonVariant.text:
        button = TextButton(
          onPressed: isDisabled ? null : _handleTap,
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: buttonChild,
        );
        break;
        
      case ButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isDisabled ? null : _handleTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: widget.backgroundColor,
            foregroundColor: foregroundColor,
            side: BorderSide(
              color: isDisabled 
                  ? (widget.borderColor ?? foregroundColor).withOpacity(0.5)
                  : widget.borderColor ?? AppTheme.primaryColor,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: buttonChild,
        );
        break;
        
      case ButtonVariant.filled:
        button = ElevatedButton(
          onPressed: isDisabled ? null : _handleTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            elevation: isDisabled ? 0 : (widget.elevation ?? 2),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: buttonChild,
        );
    }
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: button,
      ),
    );
  }
}
