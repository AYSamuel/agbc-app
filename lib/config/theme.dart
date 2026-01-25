import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Static color constants for use in const contexts
  static const Color primaryColor = Color(0xFF5B7EBF);
  static const Color secondaryColor = Color(0xFFF9C784);
  static const Color accentColor = Color(0xFF2E5A3C);
  static const Color successColor = Color(0xFF7A9D7A);
  static const Color warningColor = Color(0xFFFFB74D);
  static const Color errorColor = Color(0xFFC62828);
  static const Color neutralColor = Color(0xFF8E8E8E);
  static const Color darkNeutralColor = Color(0xFF2C2C2C);

  // Helper getters for commonly used properties
  static Color dividerColor(BuildContext context) {
    return Theme.of(context).dividerColor;
  }

  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color cardColor(BuildContext context) {
    return Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
  }

  static TextStyle titleStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium ?? const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  }

  static TextStyle subtitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
  }

  static TextStyle regularTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
  }

  static TextStyle linkStyle(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w500,
    );
  }

  static EdgeInsets screenPadding(BuildContext context) {
    return const EdgeInsets.all(16.0);
  }

  static EdgeInsets cardPadding(BuildContext context) {
    return const EdgeInsets.all(16.0);
  }

  static ThemeData get lightTheme {
    const ColorScheme colorScheme = ColorScheme.light(
      primary: Color(0xFF5B7EBF), // Primary Blue
      secondary: Color(0xFFF9C784), // Warm Orange
      tertiary: Color(0xFF7A9D7A), // Success/Completed - Sage Green
      tertiaryContainer: Color(0xFFFFB74D), // Warning/In-Progress - Amber
      error: Color(0xFFC62828), // Soft Red
      surface: Color(0xFFFFFFFF), // White
      background: Color(0xFFF8F9FA), // Light Gray Background
      onPrimary: Colors.white,
      onSecondary: Color(0xFF2C2C2C), // Deep Charcoal
      onSurface: Color(0xFF2C2C2C), // Deep Charcoal
      onBackground: Color(0xFF2C2C2C),
      onTertiary: Colors.white,
      onTertiaryContainer: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      dividerColor: const Color(0xFFE5E7EB),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          color: colorScheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  static ThemeData get darkTheme {
    const ColorScheme colorScheme = ColorScheme.dark(
      primary: Color(0xFF7A9FD9), // Lighter Blue for dark mode
      secondary: Color(0xFFFDB863), // Lighter Orange for dark mode
      tertiary: Color(0xFF8FBA8F), // Success/Completed - Lighter Sage Green
      tertiaryContainer: Color(0xFFFFCC80), // Warning/In-Progress - Lighter Amber
      error: Color(0xFFEF5350), // Lighter Red for dark mode
      surface: Color(0xFF1E1E1E), // Dark Surface for cards
      background: Color(0xFF121212), // Very dark background
      onPrimary: Color(0xFF121212),
      onSecondary: Color(0xFF121212),
      onSurface: Color(0xFFE0E0E0), // Light gray text
      onBackground: Color(0xFFE0E0E0),
      onTertiary: Color(0xFF121212),
      onTertiaryContainer: Color(0xFF121212),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      dividerColor: const Color(0xFF2A2A2A),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          color: colorScheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: colorScheme.onBackground,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: colorScheme.onBackground,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colorScheme.onBackground,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onBackground,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: colorScheme.onBackground,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colorScheme.onBackground,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: colorScheme.onBackground,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: colorScheme.onBackground,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colorScheme.secondary,
          letterSpacing: 0.1,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: colorScheme.secondary,
          letterSpacing: 0.1,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colorScheme.secondary,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
