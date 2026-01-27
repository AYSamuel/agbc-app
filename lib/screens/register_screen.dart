import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../widgets/register_form.dart';
import '../config/theme.dart';
import '../widgets/custom_back_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Branch data is already cached from splash screen initialization
  // No need to fetch again

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset:
          true, // Ensure content resizes when keyboard appears
      body: Stack(
        children: [
          // Gorgeous layered gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary(context),
                  AppTheme.secondary(context).withValues(alpha: 0.8),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0, 0.4, 1],
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
                color: AppTheme.secondary(context).withValues(alpha: 0.18),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary(context).withValues(alpha: 0.18),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          // Centered frosted glass card
          SafeArea(
            child: Column(
              children: [
                // Custom Back Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CustomBackButton(
                        onPressed: () => Navigator.of(context)
                            .pushReplacementNamed('/login',
                                arguments: {'clearForm': true}),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: AppTheme.screenPadding(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary(context)
                                      .withValues(alpha: 0.10),
                                  blurRadius: 30,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: AppTheme.dividerColor(context)
                                    .withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                            ),
                            padding: AppTheme.cardPadding(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 12),
                                // Modern user icon
                                Center(
                                  child: CircleAvatar(
                                    radius: 38,
                                    child: Icon(
                                      Remix.user_add_line,
                                      color: AppTheme.primary(context),
                                      size: 48,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Title Text
                                Text(
                                  'Create Account',
                                  style: AppTheme.titleStyle(context).copyWith(
                                    fontSize: 28,
                                    color: AppTheme.primary(context),
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Join our church community',
                                  style:
                                      AppTheme.subtitleStyle(context).copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                RegisterForm(
                                  onRegisterSuccess: () {
                                    Navigator.pushReplacementNamed(
                                        context, '/login',
                                        arguments: {'clearForm': true});
                                  },
                                ),
                                const SizedBox(height: 18),
                                // Login link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Already have an account?',
                                        style:
                                            AppTheme.regularTextStyle(context)),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pushReplacementNamed('/login',
                                                arguments: {'clearForm': true});
                                      },
                                      child: Text('Login',
                                          style: AppTheme.linkStyle(context)),
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
          ),
        ],
      ),
    );
  }
}
