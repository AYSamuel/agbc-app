import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_indicator.dart';
import '../utils/theme.dart';
import 'home_screen.dart';
import 'verification_screen.dart';
import 'dart:async';
import 'package:agbc_app/widgets/register_form.dart';
import 'package:agbc_app/widgets/custom_back_button.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

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
          child: Column(
            children: [
              // Back Button
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16),
                  child: CustomBackButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Expanded(
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
                            // Title
                            Text(
                              'Create Account',
                              style: AppTheme.titleStyle,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: AppTheme.smallSpacing),
                            Text(
                              'Join our community today',
                              style: AppTheme.subtitleStyle,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: AppTheme.largeSpacing),

                            // Register Form
                            RegisterForm(
                              onRegisterSuccess: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const VerificationScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
