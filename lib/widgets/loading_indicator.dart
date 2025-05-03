import 'package:flutter/material.dart';

/// A simple loading indicator widget that displays a circular progress indicator.
///
/// This widget provides a consistent loading indicator design across the app with:
/// - Fixed size (20x20)
/// - Thin stroke width (2)
/// - Customizable color (defaults to white)
/// - Can be used in buttons or other UI elements
class LoadingIndicator extends StatelessWidget {
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.white),
      ),
    );
  }
}
