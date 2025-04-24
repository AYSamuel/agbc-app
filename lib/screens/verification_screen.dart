import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_indicator.dart';
import '../utils/theme.dart';
import 'dart:async';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isLoading = false;
  bool _isVerified = false;
  int _countdownSeconds = 60;
  bool _canResend = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _checkVerificationStatus();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _canResend = false;
      _countdownSeconds = 60;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _checkVerificationStatus() async {
    try {
      setState(() => _isLoading = true);

      final authService = Provider.of<AuthService>(context, listen: false);
      final isVerified = await authService.isEmailVerified();

      if (isVerified) {
        setState(() {
          _isVerified = true;
          _isLoading = false;
        });

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    try {
      setState(() => _isLoading = true);

      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendVerificationEmail();

      _startCountdown();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mark_email_unread,
                  size: 100,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'We\'ve sent a verification email to your inbox. Please check your email and click the verification link to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const LoadingIndicator()
                else if (_isVerified)
                  Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Email Verified!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/home');
                        },
                        child: const Text('Continue to App'),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      CustomButton(
                        onPressed: _checkVerificationStatus,
                        child: const Text('Check Verification Status'),
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        onPressed: _canResend ? _resendVerificationEmail : null,
                        child: Text(
                          _canResend
                              ? 'Resend Verification Email'
                              : 'Resend in $_countdownSeconds seconds',
                        ),
                      ),
                    ],
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 