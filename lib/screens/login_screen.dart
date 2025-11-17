import 'dart:ui';

import 'package:flutter/material.dart';
import '../widgets/login_form.dart';
import '../utils/theme.dart';

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

  // Branch data is already cached from splash screen initialization
  // No need to fetch again

  @override
  Widget build(BuildContext context) {
    final Map<String, bool>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, bool>?;
    final bool clearForm = args?['clearForm'] ?? false;
    final bool effectivelyIsLoggingOut = widget.isLoggingOut || clearForm;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      resizeToAvoidBottomInset: true, // Ensure content resizes when keyboard appears
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),
                          // Modern lock icon
                          Center(
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.08),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                color: AppTheme.primaryColor,
                                size: 48,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Title Text
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
                          LoginForm(
                            key: _formKey,
                            onLoginSuccess: () {
                              Navigator.of(context)
                                  .pushReplacementNamed('/home');
                            },
                            isLoggingOut: effectivelyIsLoggingOut,
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
                                child:
                                    Text('Sign up', style: AppTheme.linkStyle),
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
