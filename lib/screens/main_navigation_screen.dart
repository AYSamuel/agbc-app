import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_screen.dart';
import 'meetings_screen.dart';
import 'pray_screen.dart';
import 'read_screen.dart';
import 'profile_screen.dart';
import 'admin_center_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

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
              child: IndexedStack(
                index: navigationProvider.currentIndex,
                children: [
                  const HomeScreen(),
                  const MeetingsScreen(),
                  const PrayScreen(),
                  const ReadScreen(),
                  const ProfileScreen(),
                  const AdminCenterScreen(),
                  const SettingsScreen(),
                  const HelpSupportScreen(),
                  const AboutScreen(),
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
