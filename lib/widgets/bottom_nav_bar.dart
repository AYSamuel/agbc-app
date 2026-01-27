import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
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
    final authService = Provider.of<AuthService>(context, listen: false);
    final isAdmin = authService.isAdmin;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 65 + bottomPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: AppTheme.dividerColor(context).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
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
                    Remix.home_3_line, 'Home'),
                _buildNavItem(context, NavigationProvider.sermonIndex,
                    Remix.play_circle_line, 'Sermon'),
                const SizedBox(width: 48), // Space for the Pray button
                _buildNavItem(context, NavigationProvider.readIndex,
                    Remix.book_read_line, 'Read'),
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
    final color = isSelected ? AppTheme.accent(context) : AppTheme.textMuted(context);

    return Semantics(
      label: label,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => _handleTap(context, index),
        child: Container(
          color: Colors.transparent, // Expand tap area
          padding: const EdgeInsets.symmetric(horizontal: 4),
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
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayButton(BuildContext context) {
    final isSelected = context.watch<NavigationProvider>().currentIndex ==
        NavigationProvider.prayIndex;

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
                color: AppTheme.secondary(context),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary(context).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 4,
                ),
              ),
              child: const Icon(
                Remix.heart_3_line,
                color: Colors.white,
                size: 24,
                semanticLabel: 'Pray',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pray',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: isSelected
                    ? AppTheme.secondary(context)
                    : AppTheme.textMuted(context),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
    final color = isSelected ? AppTheme.teal : AppTheme.textMuted(context);

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
                  icon: Remix.user_3_line,
                  label: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToScreen(context, const ProfileScreen());
                  },
                ),
                DrawerItem(
                  icon: Remix.task_line,
                  label: 'Tasks',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToScreen(
                        context, const TasksScreen(showBackButton: true));
                  },
                ),
                if (isAdmin)
                  DrawerItem(
                    icon: Remix.admin_line,
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
                  icon: Remix.settings_3_line,
                  label: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToScreen(context, const SettingsScreen());
                  },
                ),
                DrawerItem(
                  icon: Remix.question_line,
                  label: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToScreen(context, const HelpSupportScreen());
                  },
                ),
                DrawerItem(
                  icon: Remix.information_line,
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
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Remix.more_2_line,
                color: color,
                size: 24,
                semanticLabel: 'More Options',
              ),
              const SizedBox(height: 4),
              Text(
                'More',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
