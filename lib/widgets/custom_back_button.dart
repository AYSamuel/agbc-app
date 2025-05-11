import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';

/// A customizable back button widget with animation and haptic feedback.
///
/// This widget provides a consistent back button design across the app with:
/// - Smooth animation on press
/// - Haptic feedback
/// - Customizable color and style
/// - Optional shadow and background
class CustomBackButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color? color;
  final bool showBackground;
  final bool showShadow;
  final double size;

  const CustomBackButton({
    super.key,
    required this.onPressed,
    this.color,
    this.showBackground = true,
    this.showShadow = true,
    this.size = 20,
  });

  @override
  State<CustomBackButton> createState() => _CustomBackButtonState();
}

class _CustomBackButtonState extends State<CustomBackButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    // Provide haptic feedback
    await HapticFeedback.lightImpact();

    // Animate the button
    await _controller.forward();
    await _controller.reverse();

    // Call the onPressed callback
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final button = ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _handleTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: widget.color ?? AppTheme.primaryColor,
              size: widget.size,
            ),
          ),
        ),
      ),
    );

    if (!widget.showBackground) {
      return button;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: widget.showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: button,
    );
  }
}
