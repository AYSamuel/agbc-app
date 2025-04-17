import 'package:flutter/material.dart';
import 'package:agbc_app/utils/theme.dart';

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

class _RadialMenuState extends State<RadialMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton(
        heroTag: null,
        onPressed: onTap,
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Task Option
        Positioned(
          right: 80,
          bottom: 80,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildMenuItem(
              icon: Icons.task_alt,
              label: 'Task',
              onTap: () {
                _toggleMenu();
                widget.onTaskPressed();
              },
            ),
          ),
        ),
        // Meeting Option
        if (widget.showMeetingOption)
          Positioned(
            right: 80,
            bottom: 20,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildMenuItem(
                icon: Icons.calendar_today,
                label: 'Meeting',
                onTap: () {
                  _toggleMenu();
                  widget.onMeetingPressed?.call();
                },
              ),
            ),
          ),
        // Branch Option (only visible for admins)
        if (widget.showBranchOption)
          Positioned(
            right: 20,
            bottom: 80,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildMenuItem(
                icon: Icons.church,
                label: 'Branch',
                onTap: () {
                  _toggleMenu();
                  widget.onBranchPressed?.call();
                },
              ),
            ),
          ),
        // Main Button
        Positioned(
          right: 20,
          bottom: 20,
          child: RotationTransition(
            turns: _rotationAnimation,
            child: FloatingActionButton(
              onPressed: _toggleMenu,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(
                _isOpen ? Icons.close : Icons.add,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
} 