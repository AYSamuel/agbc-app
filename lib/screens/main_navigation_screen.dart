import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/admin_route_guard.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'meetings_screen.dart';
import 'pray_screen.dart';
import 'profile_screen.dart';
import 'admin_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/bottom_nav_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const MeetingsScreen(),
    const PrayScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.checkAuthState();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: true);
    final supabase = Supabase.instance.client;

    // Check both the auth service state and Supabase session
    final isAuthenticated =
        authService.isAuthenticated && supabase.auth.currentSession != null;

    // If not authenticated, show login screen
    if (!isAuthenticated) {
      return const LoginScreen(isLoggingOut: false);
    }

    return Scaffold(
      body: Navigator(
        initialRoute: '/',
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleNavigation,
      ),
    );
  }

  void _handleNavigation(int index) {
    // For bottom nav items (0-3), just update the index
    if (index < 4) {
      setState(() {
        _currentIndex = index;
      });
      return;
    }

    // For modal screens (4+), handle navigation
    switch (index) {
      case 4: // Profile
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
      case 5: // Admin Center
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminRouteGuard(
              child: AdminScreen(),
            ),
          ),
        );
        break;
      case 6: // Settings
        // TODO: Navigate to settings screen
        break;
      case 7: // Help & Support
        // TODO: Navigate to help screen
        break;
      case 8: // About
        // TODO: Navigate to about screen
        break;
    }
  }
}
