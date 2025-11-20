import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../utils/theme.dart';

class AppNavBar extends StatefulWidget {
  final VoidCallback? onNotificationTap;
  final int? notificationCount;

  const AppNavBar({
    super.key,
    this.onNotificationTap,
    this.notificationCount,
  });

  @override
  State<AppNavBar> createState() => _AppNavBarState();
}

class _AppNavBarState extends State<AppNavBar> {
  DateTime? _lastTapTime;

  /// OPTIMIZED: Debounced tap handler to prevent rapid taps
  void _handleNotificationTap() {
    final now = DateTime.now();

    // Prevent rapid taps (debounce with 500ms threshold)
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 500)) {
      return; // Ignore rapid taps
    }

    _lastTapTime = now;
    widget.onNotificationTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Notification Bell
          GestureDetector(
            onTap: _handleNotificationTap, // OPTIMIZED: Use debounced handler
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Remix.notification_3_line,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (widget.notificationCount != null && widget.notificationCount! > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        widget.notificationCount! > 99
                            ? '99+'
                            : widget.notificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
