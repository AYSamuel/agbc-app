import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

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
    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final initializationStart = DateTime.now();
    try {
      // Wait for auth service to be ready (it's already initialized in main.dart)
      // Just add a small delay to ensure everything is properly set up
      await Future.delayed(const Duration(milliseconds: 500));

      // Ensure splash screen stays for at least 3 seconds for better UX
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
      // Even on error, ensure minimum splash screen duration
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

  void _navigateToNextScreen() {
    if (!mounted) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/home');
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
                  // App Logo with animation
                  Image.asset(
                    'assets/images/logo.png',
                    width: 200,
                    height: 200,
                    color: colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 24),
                  // App Name
                  Text(
                    'Grace Portal',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Church Management System',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          colorScheme.onPrimary.withAlpha((0.8 * 255).round()),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Loading Indicator
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
