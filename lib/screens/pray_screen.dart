import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../config/theme.dart';
import '../widgets/custom_back_button.dart';

class PrayScreen extends StatelessWidget {
  final bool isMainTab;

  const PrayScreen({
    super.key,
    this.isMainTab = false,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final showBackButton = canPop && !isMainTab;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button (only show if there's a route to pop and not in main tab)
            if (showBackButton)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CustomBackButton(
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Remix.heart_line,
                      size: 64,
                      color: AppTheme.primary(context).withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Prayer Wall Coming Soon',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share your prayer requests and support others',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textMuted(context),
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
