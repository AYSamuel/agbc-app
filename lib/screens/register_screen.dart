import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/register_form.dart';
import '../utils/theme.dart';
import '../widgets/custom_back_button.dart';
import 'package:provider/provider.dart';
import '../providers/branches_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize branches when screen is opened
    Future.microtask(() {
      if (mounted) {
        Provider.of<BranchesProvider>(context, listen: false).fetchBranches();
      }
    });
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
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.10),
                                  blurRadius: 30,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: AppTheme.dividerColor
                                    .withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                            ),
                            padding: AppTheme.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 12),
                                // Modern user icon
                                Center(
                                  child: CircleAvatar(
                                    radius: 38,
                                    backgroundColor: AppTheme.primaryColor
                                        .withValues(alpha: 0.08),
                                    child: Icon(
                                      Icons.person_add_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 48,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Title Text
                                Text(
                                  'Create Account',
                                  style: AppTheme.titleStyle.copyWith(
                                    fontSize: 28,
                                    color: AppTheme.primaryColor,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Join our church community',
                                  style: AppTheme.subtitleStyle.copyWith(
                                    color: AppTheme.neutralColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                RegisterForm(
                                  onRegisterSuccess: () {
                                    Navigator.pushReplacementNamed(
                                        context, '/login', arguments: {'clearForm': true});
                                  },
                                ),
                                const SizedBox(height: 18),
                                // Login link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Already have an account?',
                                        style: AppTheme.regularTextStyle),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pushReplacementNamed('/login', arguments: {'clearForm': true});
                                      },
                                      child: Text('Login',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
