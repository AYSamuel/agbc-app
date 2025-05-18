import 'package:flutter/material.dart';
import 'package:agbc_app/utils/theme.dart';
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Verse',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            verse,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reference,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
