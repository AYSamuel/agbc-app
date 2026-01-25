import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grace_portal/config/theme.dart';

class RadialMenu extends StatefulWidget {
  final VoidCallback onTaskPressed;
  final VoidCallback? onMeetingPressed;
  final VoidCallback? onBranchPressed;
  final bool showBranchOption;
  final bool showMeetingOption;

  const RadialMenu({
    super.key,
    required this.onTaskPressed,
    this.onMeetingPressed,
    this.onBranchPressed,
    required this.showBranchOption,
    required this.showMeetingOption,
  });

  @override
  State<RadialMenu> createState() => _RadialMenuState();
}

class _RadialMenuState extends State<RadialMenu>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scaleAnimation;
  Animation<double>? _rotationAnimation;
  Animation<double>? _opacityAnimation;
  Animation<Offset>? _taskOffsetAnimation;
  Animation<Offset>? _meetingOffsetAnimation;
  Animation<Offset>? _branchOffsetAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final curvedAnimation = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeInOut,
    );

    _scaleAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
    _rotationAnimation =
        Tween<double>(begin: 0.0, end: 0.5).animate(curvedAnimation);
    _opacityAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
    _taskOffsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-0.5, -0.5),
    ).animate(curvedAnimation);
    _meetingOffsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-0.5, 0),
    ).animate(curvedAnimation);
    _branchOffsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.5),
    ).animate(curvedAnimation);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_controller == null) return;

    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller!.forward();
      } else {
        _controller!.reverse();
      }
    });
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required String semanticLabel,
    required Animation<Offset>? offsetAnimation,
  }) {
    if (offsetAnimation == null ||
        _scaleAnimation == null ||
        _opacityAnimation == null) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: offsetAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation!,
        child: FadeTransition(
          opacity: _opacityAnimation!,
          child: FloatingActionButton(
            heroTag: null,
            onPressed: () async {
              await HapticFeedback.lightImpact();
              onTap();
            },
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 4,
            tooltip: label,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                  semanticLabel: semanticLabel,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _rotationAnimation == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Task Option
        Positioned(
          right: 50,
          bottom: 50,
          child: _buildMenuItem(
            icon: Icons.task_alt,
            label: 'Task',
            semanticLabel: 'Create new task',
            onTap: () {
              _toggleMenu();
              widget.onTaskPressed();
            },
            offsetAnimation: _taskOffsetAnimation,
          ),
        ),
        // Meeting Option
        if (widget.showMeetingOption)
          Positioned(
            right: 50,
            bottom: 10,
            child: _buildMenuItem(
              icon: Icons.calendar_today,
              label: 'Meeting',
              semanticLabel: 'Schedule new meeting',
              onTap: () {
                _toggleMenu();
                widget.onMeetingPressed?.call();
              },
              offsetAnimation: _meetingOffsetAnimation,
            ),
          ),
        // Branch Option (only visible for admins)
        if (widget.showBranchOption)
          Positioned(
            right: 10,
            bottom: 50,
            child: _buildMenuItem(
              icon: Icons.church,
              label: 'Branch',
              semanticLabel: 'Create new branch',
              onTap: () {
                _toggleMenu();
                widget.onBranchPressed?.call();
              },
              offsetAnimation: _branchOffsetAnimation,
            ),
          ),
        // Main Button
        Positioned(
          right: 10,
          bottom: 10,
          child: RotationTransition(
            turns: _rotationAnimation!,
            child: FloatingActionButton(
              onPressed: _toggleMenu,
              backgroundColor: AppTheme.primaryColor,
              elevation: 4,
              tooltip: _isOpen ? 'Close menu' : 'Open menu',
              child: Icon(
                _isOpen ? Icons.close : Icons.add,
                color: Colors.white,
                semanticLabel: _isOpen ? 'Close menu' : 'Open menu',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
