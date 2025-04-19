import 'package:flutter/material.dart';

/// A simple loading indicator widget that displays a circular progress indicator.
/// 
/// This widget provides a consistent loading indicator design across the app with:
/// - Fixed size (20x20)
/// - Thin stroke width (2)
/// - White color
/// - Can be used in buttons or other UI elements
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
} 