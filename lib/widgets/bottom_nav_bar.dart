import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/tasks_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/about_screen.dart';
import '../widgets/custom_drawer.dart';
import '../providers/navigation_provider.dart';
import '../widgets/admin_route_guard.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  void _handleTap(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    context.read<NavigationProvider>().navigateTo(index);
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    final isAdmin = user?.role == 'admin';
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 65 + bottomPadding,
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: 8.0,
              bottom: 8.0 + bottomPadding,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, NavigationProvider.homeIndex,
                    Icons.home_rounded, 'Home'),
                _buildNavItem(context, NavigationProvider.meetingsIndex,
                    Icons.calendar_today_rounded, 'Meetings'),
                const SizedBox(width: 48), // Space for the Pray button
                _buildNavItem(context, NavigationProvider.readIndex,
                    Icons.menu_book_rounded, 'Read'),
                _buildMoreButton(context, isAdmin),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: -25,
            child: Center(
              child: _buildPrayButton(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, int index, IconData icon, String label) {
    final isSelected =
        context.watch<NavigationProvider>().currentIndex == index;
    final color = isSelected ? AppTheme.primaryColor : const Color(0xFF6B7280);

    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => _handleTap(context, index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
              semanticLabel: label,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayButton(BuildContext context) {
    final isSelected = context.watch<NavigationProvider>().currentIndex ==
        NavigationProvider.prayIndex;
    final color = isSelected ? AppTheme.primaryColor : const Color(0xFF6B7280);

    return Semantics(
      label: 'Pray',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => _handleTap(context, NavigationProvider.prayIndex),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
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
                semanticLabel: 'Pray',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pray',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context, bool isAdmin) {
    final isSelected = context.watch<NavigationProvider>().currentIndex ==
        NavigationProvider.moreIndex;
    final color = isSelected ? AppTheme.primaryColor : const Color(0xFF6B7280);

    return Semantics(
      label: 'More Options',
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => CustomDrawer(
              title: 'More Options',
              items: [
                DrawerItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToScreen(context, const ProfileScreen());
                  },
                ),
                DrawerItem(
                  icon: Icons.task_rounded,
                  label: 'Tasks',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToScreen(
                        context, const TasksScreen(showBackButton: true));
                  },
                ),
                if (isAdmin)
                  DrawerItem(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin Center',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToScreen(
                        context,
                        const AdminRouteGuard(
                          child: AdminScreen(),
                        ),
                      );
                    },
                  ),
                DrawerItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToScreen(context, const SettingsScreen());
                  },
                ),
                DrawerItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToScreen(context, const HelpSupportScreen());
                  },
                ),
                DrawerItem(
                  icon: Icons.info_outline_rounded,
                  label: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToScreen(context, const AboutScreen());
                  },
                ),
              ],
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.more_horiz_rounded,
              color: color,
              size: 24,
              semanticLabel: 'More Options',
            ),
            const SizedBox(height: 4),
            Text(
              'More',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
