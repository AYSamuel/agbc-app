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
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static List<Widget> _screens(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    return [
      const HomeScreen(),
      const ProfileScreen(),
      if (user?.isAdmin ?? false) const AdminScreen(),
    ];
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

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final screens = _screens(context);
    
    // Ensure selected index is valid
    if (_selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }
    
    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: AppTheme.cardColor,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.neutralColor,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Container(
              decoration: _selectedIndex == 0
                  ? BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    )
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Icon(
                Icons.home,
                color: _selectedIndex == 0 ? AppTheme.primaryColor : AppTheme.neutralColor,
              ),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Container(
              decoration: _selectedIndex == 1
                  ? BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    )
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Icon(
                Icons.person,
                color: _selectedIndex == 1 ? AppTheme.primaryColor : AppTheme.neutralColor,
              ),
            ),
            label: 'Profile',
          ),
          if (user?.isAdmin ?? false)
            BottomNavigationBarItem(
              icon: Container(
                decoration: _selectedIndex == 2
                    ? BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      )
                    : null,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: _selectedIndex == 2 ? AppTheme.primaryColor : AppTheme.neutralColor,
                ),
              ),
              label: 'Admin',
            ),
        ],
      ),
    );
  }
} 