import 'package:flutter/material.dart';
import 'package:agbc_app/screens/home_screen.dart';
import 'package:agbc_app/screens/profile_screen.dart';
import 'package:agbc_app/screens/admin_screen.dart';
import 'package:agbc_app/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:agbc_app/services/auth_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();

  // Public method to navigate to a specific tab
  static void navigateToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainNavigationScreenState>();
    if (state != null) {
      state._onItemTapped(index);
    }
  }
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  List<Widget> _screens = [];
  List<BottomNavigationBarItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    // Initialize with default screens
    _screens = const [
      HomeScreen(),
      ProfileScreen(),
    ];

    // Initialize with default navigation items
    _navItems = [
      _buildNavItem(Icons.home, 'Home', 0, 0),
      _buildNavItem(Icons.person, 'Profile', 1, 0),
    ];
  }

  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, int index, int currentIndex) {
    return BottomNavigationBarItem(
      icon: Container(
        decoration: currentIndex == index
            ? BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Icon(
          icon,
          color: currentIndex == index
              ? AppTheme.primaryColor
              : AppTheme.neutralColor,
        ),
      ),
      label: label,
    );
  }

  void _onItemTapped(int index) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (index == 2 && !(user?.isAdmin ?? false)) {
      return; // Don't allow non-admins to access admin page
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateAdminAccess(bool hasAdminAccess) {
    setState(() {
      if (hasAdminAccess && _screens.length == 2) {
        _screens = [..._screens, const AdminScreen()];
        _navItems = [
          ..._navItems,
          _buildNavItem(Icons.admin_panel_settings, 'Admin', 2, _selectedIndex)
        ];
      } else if (!hasAdminAccess && _screens.length > 2) {
        _screens = _screens.sublist(0, 2);
        _navItems = _navItems.sublist(0, 2);
        if (_selectedIndex >= _screens.length) {
          _selectedIndex = 0;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final hasAdminAccess = user?.isAdmin ?? false;

    // Update admin access if needed
    if ((hasAdminAccess && _screens.length == 2) ||
        (!hasAdminAccess && _screens.length > 2)) {
      _updateAdminAccess(hasAdminAccess);
    }

    // Rebuild nav items with current selected index
    _navItems = [
      _buildNavItem(Icons.home, 'Home', 0, _selectedIndex),
      _buildNavItem(Icons.person, 'Profile', 1, _selectedIndex),
    ];
    if (hasAdminAccess) {
      _navItems.add(_buildNavItem(
          Icons.admin_panel_settings, 'Admin', 2, _selectedIndex));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: AppTheme.cardColor.withValues(alpha: 0.75),
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.neutralColor,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        type: BottomNavigationBarType.fixed,
        items: _navItems,
      ),
    );
  }
}
