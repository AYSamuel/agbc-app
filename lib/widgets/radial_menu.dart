import 'package:flutter/material.dart';
import 'package:agbc_app/utils/theme.dart';

class RadialMenu extends StatefulWidget {
  final VoidCallback onTaskPressed;
  final VoidCallback onMeetingPressed;

  const RadialMenu({
    super.key,
    required this.onTaskPressed,
    required this.onMeetingPressed,
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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
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
                widget.onMeetingPressed();
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

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.darkNeutralColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 