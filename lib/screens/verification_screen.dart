import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_indicator.dart';
import '../utils/theme.dart';
import 'login_screen.dart';
import 'package:agbc_app/widgets/custom_back_button.dart';
import 'package:agbc_app/screens/main_navigation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isLoading = false;
  bool _isResending = false;
  int _retryCount = 0;
  static const int maxRetries = 5;
  static const Duration retryDelay = Duration(seconds: 2);

  Future<void> _checkVerification() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _retryCount = 0;
    });

    await _checkVerificationWithRetry();
  }

  Future<void> _checkVerificationWithRetry() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final isVerified = await authService.isEmailVerified();
      
      if (isVerified && mounted) {
        // Navigate to main app screen since user is already logged in
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          (route) => false,
        );
      } else if (_retryCount < maxRetries && mounted) {
        // If not verified and haven't exceeded max retries, try again after delay
        _retryCount++;
        await Future.delayed(retryDelay);
        if (mounted) {
          await _checkVerificationWithRetry();
        }
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email not verified yet. Please check your inbox.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMessage = 'An error occurred while checking verification status.';
        if (e is PostgrestException) {
          errorMessage = 'Database error: ${e.message}';
        } else if (e is AuthException) {
          errorMessage = 'Authentication error: ${e.message}';
        } else {
          errorMessage = 'An unexpected error occurred. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  Future<void> _resendVerification() async {
    setState(() => _isResending = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendVerificationEmail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent. Please check your inbox.')),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to resend verification email.';
        if (e is PostgrestException) {
          errorMessage = 'Database error: ${e.message}';
        } else if (e is AuthException) {
          errorMessage = 'Authentication error: ${e.message}';
        } else {
          errorMessage = 'An unexpected error occurred. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Verify Your Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We have sent a verification email to your inbox. Please check your email and click the verification link to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                onPressed: _checkVerification,
                isLoading: _isLoading,
                child: const Text('Check Verification Status'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isResending ? null : _resendVerification,
                child: _isResending
                    ? const LoadingIndicator()
                    : const Text('Resend Verification Email'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 