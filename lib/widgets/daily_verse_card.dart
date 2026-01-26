import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyVerseCard extends StatelessWidget {
  final String verse;
  final String reference;

  const DailyVerseCard({
    super.key,
    required this.verse,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Verse',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            verse,
            style: GoogleFonts.roboto(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              height: 1.5,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            reference,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.teal,
            ),
          ),
        ],
      ),
    );
  }
}
