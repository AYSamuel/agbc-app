import 'package:flutter/material.dart';
import 'package:agbc_app/widgets/loading_indicator.dart';

/// A customizable button widget with loading state, animations, and disabled state styling.
/// 
/// This widget provides a consistent button design across the app with:
/// - Loading state with spinner
/// - Disabled state styling
/// - Scale animation on press
/// - Customizable colors and dimensions
/// - Flexible child content
class CustomButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final bool isLoading;
  final Duration animationDuration;

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
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
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
        ? (widget.backgroundColor ?? Colors.white).withOpacity(0.5)
        : widget.backgroundColor ?? Colors.white;
    final foregroundColor = isDisabled
        ? (widget.foregroundColor ?? Colors.black).withOpacity(0.5)
        : widget.foregroundColor ?? Colors.black;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: ElevatedButton(
          onPressed: _handleTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            elevation: isDisabled ? 0 : 2,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: widget.isLoading
              ? const LoadingIndicator()
              : widget.child,
        ),
      ),
    );
  }
} 