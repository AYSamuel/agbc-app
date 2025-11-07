import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../providers/branches_provider.dart';
import '../providers/supabase_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final initializationStart = DateTime.now();

    try {
      if (!mounted) return;
      final authService = Provider.of<AuthService>(context, listen: false);
      while (authService.isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      }

      if (!mounted) return;
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      try {
        await notificationService.initialize();
      } catch (e) {
        debugPrint('Notification service initialization warning: $e');
      }

      if (!mounted) return;
      final supabaseProvider =
          Provider.of<SupabaseProvider>(context, listen: false);
      while (supabaseProvider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      }

      if (supabaseProvider.error != null) {
        supabaseProvider.clearError();
      }

      if (!mounted) return;
      final branchesProvider =
          Provider.of<BranchesProvider>(context, listen: false);
      await branchesProvider.fetchBranches();

      while (branchesProvider.isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
      }

      final initializationDuration =
          DateTime.now().difference(initializationStart);
      if (initializationDuration < const Duration(seconds: 3)) {
        await Future.delayed(
            const Duration(seconds: 3) - initializationDuration);
      }

      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      debugPrint('Error during app initialization: $e');

      final initializationDuration =
          DateTime.now().difference(initializationStart);
      if (initializationDuration < const Duration(seconds: 3)) {
        await Future.delayed(
            const Duration(seconds: 3) - initializationDuration);
      }

      if (mounted) {
        _navigateToNextScreen();
      }
    }
  }

  void _navigateToNextScreen() async {
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.isAuthenticated) {
      if (authService.currentUser?.emailConfirmedAt == null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        // Check if user had "Remember Me" enabled
        final prefs = await SharedPreferences.getInstance();
        final rememberMe = prefs.getBool('remember_me') ?? false;

        if (!mounted) return;
        if (rememberMe) {
          // User chose to stay logged in
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          // User didn't choose "Remember Me", so sign them out and go to login
          await authService.signOut();
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary,
              colorScheme.primaryContainer,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 200,
                    height: 200,
                    color: colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Grace Portal',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 40),
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
