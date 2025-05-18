import 'package:flutter/material.dart';
import '../services/app_initialization_service.dart';

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
      duration: const Duration(milliseconds: 5000),
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
      await AppInitializationService.initializeApp();

      // Ensure splash screen stays for at least 5 seconds
      final initializationDuration =
          DateTime.now().difference(initializationStart);
      if (initializationDuration < const Duration(seconds: 5)) {
        await Future.delayed(
            const Duration(seconds: 5) - initializationDuration);
      }

      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      debugPrint('Error during app initialization: $e');
      // Even on error, ensure minimum splash screen duration
      final initializationDuration =
          DateTime.now().difference(initializationStart);
      if (initializationDuration < const Duration(seconds: 5)) {
        await Future.delayed(
            const Duration(seconds: 5) - initializationDuration);
      }
      if (mounted) {
        _navigateToNextScreen();
      }
    }
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
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
