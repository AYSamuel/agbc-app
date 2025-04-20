import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_indicator.dart';
import '../utils/theme.dart';
import 'login_screen.dart';
import 'package:agbc_app/widgets/custom_back_button.dart';
import 'package:agbc_app/screens/main_navigation_screen.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 80,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Verify Your Email',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'We have sent a verification email to your email address. Please check your inbox and click the verification link to continue.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      onPressed: _isLoading ? null : _checkVerification,
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const LoadingIndicator(),
                                const SizedBox(width: 8),
                                Text(
                                  'Checking verification...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Check Verification',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      onPressed: _isResending ? null : _resendVerification,
                      child: _isResending
                          ? const LoadingIndicator()
                          : const Text(
                              'Resend Verification Email',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    CustomBackButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 