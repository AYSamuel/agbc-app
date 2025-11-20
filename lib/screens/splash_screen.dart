import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../providers/branches_provider.dart';
import '../providers/supabase_provider.dart';
import '../main.dart' as main_app;

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
    try {
      if (!mounted) return;

      // Get all providers
      final notificationService =
          Provider.of<NotificationService>(context, listen: false);
      final supabaseProvider =
          Provider.of<SupabaseProvider>(context, listen: false);
      final branchesProvider =
          Provider.of<BranchesProvider>(context, listen: false);

      // Clear any previous errors
      if (supabaseProvider.error != null) {
        supabaseProvider.clearError();
      }
      if (branchesProvider.error != null) {
        branchesProvider.clearError();
      }

      // Initialize services in parallel with timeout protection
      debugPrint('Starting parallel service initialization...');

      await Future.wait([
        // Initialize notification service (already initialized in main.dart, but ensure it's ready)
        Future(() async {
          try {
            await notificationService.initialize();
            debugPrint('✓ Notification service ready');
          } catch (e) {
            debugPrint('⚠ Notification service failed (non-critical): $e');
          }
        }),

        // Fetch branches with caching
        Future(() async {
          try {
            await branchesProvider.fetchBranches();
            debugPrint('✓ Branches loaded');
          } catch (e) {
            debugPrint('⚠ Failed to load branches: $e');
          }
        }),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠ Service initialization timeout - proceeding anyway');
          return [];
        },
      );

      debugPrint('Service initialization completed');

      // Minimum 1.5 second delay for UX (show splash briefly)
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      debugPrint('Error during app initialization: $e');

      if (mounted) {
        // Show error to user
        _showInitializationError(e.toString());
      }
    }
  }

  void _showInitializationError(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Initialization Error'),
        content: Text(
          'The app encountered an error during startup:\n\n$error\n\nWould you like to continue anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToNextScreen();
            },
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeApp(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _navigateToNextScreen() async {
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.isAuthenticated) {
      if (authService.currentUser?.emailConfirmedAt == null) {
        // Email not confirmed, go to login
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        // Check if user should stay logged in using AuthService method
        final shouldStayLoggedIn = await authService.shouldStayLoggedIn();

        if (!mounted) return;
        if (shouldStayLoggedIn) {
          // User chose to stay logged in
          debugPrint('User staying logged in - navigating to home');
          Navigator.of(context).pushReplacementNamed('/home');

          // Check for pending notifications after navigation
          main_app.handlePendingNotification();
        } else {
          // User didn't choose "Remember Me", so sign them out and go to login
          debugPrint('Remember me not enabled - signing out user');
          await authService.signOut();
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } else {
      // Not authenticated, go to login
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
