import 'package:flutter/material.dart';

class AppAnimations {
  // Spring transition constants (matching web tokens)
  static const Duration springDuration = Duration(milliseconds: 300);
  static const Curve springCurve = Curves.easeOutBack;
  static const Curve smoothCurve = Curves.easeInOut;

  /// A widget that applies a staggered fadeInUp animation to its child.
  static Widget staggeredFadeIn({
    required Widget child,
    required int index,
    Duration duration = const Duration(milliseconds: 500),
    double offset = 20.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offset * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Subtle lift effect for cards (matching web design)
  static Matrix4 hoverLift(bool isHovered) {
    return Matrix4.identity()
      ..setTranslationRaw(0.0, isHovered ? -4.0 : 0.0, 0.0);
  }

  /// Subtle scale effect for buttons (matching web design)
  static double scaleTap(bool isPressed) {
    return isPressed ? 0.98 : 1.0;
  }
}
