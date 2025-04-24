import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';

class VerificationBanner extends StatelessWidget {
  const VerificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.currentUser?.emailVerified ?? true) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          color: Colors.blue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SafeArea(
            child: Row(
              children: [
                const Icon(
                  Icons.mark_email_unread,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please verify your email (${authService.currentUser?.email})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    authService.sendVerificationEmail();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Verification email resent'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Resend'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 