import 'package:flutter/material.dart';
import 'package:agbc_app/screens/register_screen.dart';
import 'package:agbc_app/screens/home_screen.dart';
import 'package:agbc_app/widgets/login_form.dart';
import 'package:agbc_app/utils/theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppTheme.screenPadding,
              child: Card(
                color: AppTheme.cardColor,
                child: Padding(
                  padding: AppTheme.cardPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo and Title
                      const Icon(
                        Icons.church,
                        size: AppTheme.largeIconSize,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: AppTheme.defaultSpacing),
                      const Text(
                        'Amazing Grace Bible Church',
                        style: AppTheme.titleStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.smallSpacing),
                      const Text(
                        'Welcome Back!',
                        style: AppTheme.welcomeStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.largeSpacing),

                      // Login Form
                      LoginForm(
                        onLoginSuccess: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const HomeScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: AppTheme.defaultSpacing),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: AppTheme.regularTextStyle,
                          ),
                          const SizedBox(width: AppTheme.smallSpacing),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Register',
                              style: AppTheme.linkStyle,
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
    );
  }
}
