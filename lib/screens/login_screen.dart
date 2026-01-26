import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../widgets/login_form.dart';
import '../config/theme.dart';

class LoginScreen extends StatefulWidget {
  final bool isLoggingOut;

  const LoginScreen({
    super.key,
    this.isLoggingOut = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final Map<String, bool>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, bool>?;
    final bool clearForm = args?['clearForm'] ?? false;
    final bool effectivelyIsLoggingOut = widget.isLoggingOut || clearForm;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Gradient background aligned with navy/teal theme
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary(context),
                  AppTheme.primary(context).withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          // Subtle teal glow
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: AppTheme.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.teal.withValues(alpha: 0.1),
                    blurRadius: 100,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.cardShadow(context),
                        border: Border.all(
                          color: AppTheme.dividerColor(context)
                              .withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          CircleAvatar(
                            radius: 40,
                            backgroundColor:
                                AppTheme.teal.withValues(alpha: 0.1),
                            child: const Icon(
                              Remix.lock_password_line,
                              color: AppTheme.teal,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Welcome Back',
                            style: AppTheme.titleStyle(context).copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(context),
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Login to your account',
                            style: AppTheme.subtitleStyle(context).copyWith(
                              color: AppTheme.textMuted(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          LoginForm(
                            key: _formKey,
                            onLoginSuccess: () {
                              Navigator.of(context)
                                  .pushReplacementNamed('/home');
                            },
                            isLoggingOut: effectivelyIsLoggingOut,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Don\'t have an account?',
                                  style: AppTheme.regularTextStyle(context)
                                      .copyWith(
                                    color: AppTheme.textSecondary(context),
                                  )),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushReplacementNamed('/register');
                                },
                                child: Text(
                                  'Sign up',
                                  style: AppTheme.linkStyle(context).copyWith(
                                    color: AppTheme.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
        ],
      ),
    );
  }
}
