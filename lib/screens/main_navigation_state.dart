import 'package:flutter/material.dart';
import 'package:agbc_app/screens/home_screen.dart';
import 'package:agbc_app/screens/profile_screen.dart';
import 'package:agbc_app/screens/admin_screen.dart';
import 'package:agbc_app/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:agbc_app/services/auth_service.dart';
import 'main_navigation_screen.dart';

class MainNavigationState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _hasAdminAccess = false;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
    _initializeScreens();
  }

  void _checkAdminAccess() {
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() {
      _hasAdminAccess = authService.currentUser?.isAdmin ?? false;
    });
  }

  void _initializeScreens() {
    _screens = [
      const HomeScreen(),
      if (_hasAdminAccess) const AdminScreen(),
      const ProfileScreen(),
    ];
  }

  List<BottomNavigationBarItem> _buildNavigationItems() {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      if (_hasAdminAccess)
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
    return items;
  }

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _buildNavigationItems(),
        currentIndex: _selectedIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: onItemTapped,
      ),
    );
  }
}
