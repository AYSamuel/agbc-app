import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../config/theme.dart';
import '../widgets/custom_back_button.dart';

class ReadScreen extends StatelessWidget {
  const ReadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button (only show if there's a route to pop)
            if (canPop)
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
                      Remix.book_open_line,
                      size: 64,
                      color: AppTheme.primary(context).withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bible Reading Coming Soon',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stay tuned for daily readings and study materials',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary(context),
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
