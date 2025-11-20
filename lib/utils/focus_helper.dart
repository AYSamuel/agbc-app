import 'package:flutter/material.dart';

/// Focus management utilities for better UX
class FocusHelper {
  /// Unfocus any active text field
  /// Call this when user taps outside input fields or navigates to date pickers
  static void unfocus(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.focusedChild!.unfocus();
    }
  }

  /// Hide keyboard without unfocusing
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }
}

/// Wrapper widget that dismisses keyboard when tapping outside input fields
/// Usage: Wrap your Scaffold body with this widget
class DismissKeyboard extends StatelessWidget {
  final Widget child;
  final bool dismissOnTap;

  const DismissKeyboard({
    super.key,
    required this.child,
    this.dismissOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!dismissOnTap) return child;

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusHelper.unfocus(context);
      },
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

/// Extension on BuildContext for easy keyboard dismissal
extension KeyboardDismiss on BuildContext {
  /// Dismiss keyboard
  void dismissKeyboard() {
    FocusHelper.unfocus(this);
  }

  /// Hide keyboard
  void hideKeyboard() {
    FocusHelper.hideKeyboard(this);
  }
}
