import 'package:flutter/material.dart';
import 'package:agbc_app/utils/theme.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/tasks_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    final isAdmin = user?.role == 'admin';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.calendar_today_rounded, 'Meetings'),
              _buildPrayButton(),
              _buildMoreButton(context, isAdmin),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.primaryColor : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppTheme.primaryColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayButton() {
    return GestureDetector(
      onTap: () => onTap(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pray',
            style: TextStyle(
              fontSize: 12,
              color: currentIndex == 2 ? AppTheme.primaryColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context, bool isAdmin) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  blurRadius: 30,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _buildMoreItem(
                  context,
                  Icons.person_outline_rounded,
                  'Profile',
                  () {
                    Navigator.pop(context);
                    onTap(4); // Profile
                  },
                ),
                _buildMoreItem(
                  context,
                  Icons.task_rounded,
                  'Tasks',
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TasksScreen(showBackButton: true),
                      ),
                    );
                  },
                ),
                if (isAdmin)
                  _buildMoreItem(
                    context,
                    Icons.admin_panel_settings_rounded,
                    'Admin Center',
                    () {
                      Navigator.pop(context);
                      onTap(5); // Admin Center
                    },
                  ),
                _buildMoreItem(
                  context,
                  Icons.settings_outlined,
                  'Settings',
                  () {
                    Navigator.pop(context);
                    onTap(6); // Settings
                  },
                ),
                _buildMoreItem(
                  context,
                  Icons.help_outline_rounded,
                  'Help & Support',
                  () {
                    Navigator.pop(context);
                    onTap(7); // Help
                  },
                ),
                _buildMoreItem(
                  context,
                  Icons.info_outline_rounded,
                  'About',
                  () {
                    Navigator.pop(context);
                    onTap(8); // About
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_rounded,
            color: currentIndex >= 4 ? AppTheme.primaryColor : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            'More',
            style: TextStyle(
              fontSize: 12,
              color: currentIndex >= 4 ? AppTheme.primaryColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1A237E),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
