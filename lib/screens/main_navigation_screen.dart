import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/notification_panel.dart';
import 'home_screen.dart';
import 'sermon_screen.dart';
import 'pray_screen.dart';
import 'read_screen.dart';
import 'profile_screen.dart';
import 'admin_center_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _showNotificationPanel() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100, // Position below the nav bar
        left: 16,
        child: NotificationPanel(
          onClose: _removeOverlay,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return ChangeNotifierProvider(
      create: (_) => NavigationProvider(),
      child: Consumer<NavigationProvider>(
        builder: (context, navigationProvider, _) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  // Persistent Navigation Bar with Notification Bell
                  Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      return AppNavBar(
                        onNotificationTap: _showNotificationPanel,
                        notificationCount: notificationProvider.unreadCount,
                      );
                    },
                  ),
                  // Main Content Area
                  Expanded(
                    child: IndexedStack(
                      index: navigationProvider.currentIndex,
                      children: const [
                        HomeScreen(),
                        SermonScreen(),
                        PrayScreen(),
                        ReadScreen(),
                        ProfileScreen(),
                        AdminCenterScreen(),
                        SettingsScreen(),
                        HelpSupportScreen(),
                        AboutScreen(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: const BottomNavBar(),
          );
        },
      ),
    );
  }
}
