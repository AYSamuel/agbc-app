import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_input.dart';
import '../widgets/loading_indicator.dart';
import '../utils/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      await authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        if (e is AuthException) {
          if (e.code == 'email_not_verified') {
            // Show verification dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Email Verification Required'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mark_email_unread,
                      size: 64,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'We need to verify your email address before you can log in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _emailController.text.trim(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'We sent a verification link to your email when you registered. Please check your inbox and click the link to verify your email address.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'If you haven\'t received the email or the link has expired, you can request a new one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Close'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Provider.of<AuthService>(context, listen: false)
                          .sendVerificationEmail();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'A new verification email has been sent to your inbox'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text('Resend Email'),
                  ),
                ],
              ),
            );
          } else if (e.code == 'invalid_credentials') {
            // Show invalid credentials dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Invalid Login'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      e.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            // Show other error dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Login Error'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      e.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
          // Show generic error dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'An unexpected error occurred. Please try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
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
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Gorgeous layered gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.secondaryColor,
                  AppTheme.backgroundColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0, 0.5, 1],
              ),
            ),
          ),
          // Decorative blurred circle
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.18),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          // Centered frosted glass card
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: AppTheme.screenPadding,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.10),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: AppTheme.dividerColor.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      padding: AppTheme.cardPadding,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),
                            // Modern lock icon
                            Center(
                              child: CircleAvatar(
                                radius: 38,
                                backgroundColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.08),
                                child: Icon(
                                  Icons.lock_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 48,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Welcome Text
                            Text(
                              'Welcome Back',
                              style: AppTheme.titleStyle.copyWith(
                                fontSize: 28,
                                color: AppTheme.primaryColor,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Login to your account',
                              style: AppTheme.subtitleStyle.copyWith(
                                color: AppTheme.neutralColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            // Email Input
                            CustomInput(
                              label: 'Email',
                              controller: _emailController,
                              hint: 'Enter your email',
                              prefixIcon: Icon(Icons.email,
                                  color: AppTheme.primaryColor),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) =>
                                  FocusScope.of(context).nextFocus(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            // Password Input
                            CustomInput(
                              label: 'Password',
                              controller: _passwordController,
                              hint: 'Enter your password',
                              prefixIcon: Icon(Icons.lock,
                                  color: AppTheme.primaryColor),
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _login(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppTheme.neutralColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            // Remember Me
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppTheme.primaryColor,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                ),
                                Text('Remember me',
                                    style: AppTheme.regularTextStyle),
                                const Spacer(),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Login Button
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 6,
                                  textStyle: AppTheme.titleStyle.copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                child: _isLoading
                                    ? const LoadingIndicator()
                                    : const Text('LOGIN'),
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Signup link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Don\'t have an account?',
                                    style: AppTheme.regularTextStyle),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pushReplacementNamed('/register');
                                  },
                                  child: Text('Sign up',
                                      style: AppTheme.linkStyle),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom clipper for diagonal cut
class DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
