import 'package:flutter/material.dart';
import '../utils/theme.dart';

class PrayScreen extends StatelessWidget {
  const PrayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 64,
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Prayer Wall Coming Soon',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share your prayer requests and support others',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
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
