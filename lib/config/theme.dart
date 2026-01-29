import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Static color constants (matching web tokens)
  static const Color navy = Color(0xFF1E3A5F);
  static const Color navyDark = Color(0xFF0F172A);
  static const Color navyLight = Color(0xFF2D4A6F);

  static const Color teal = Color(0xFF2A9D8F);
  static const Color tealLight = Color(0xFF3DB9A9);
  static const Color tealDark = Color(0xFF1F7A6D);

  static const Color seafoam = Color(0xFFA7D7C5);
  static const Color sky = Color(0xFF7EC8E3);
  static const Color slate = Color(0xFF475569);

  // Neutrals
  static const Color pearl = Color(0xFFF8FAFC);
  static const Color mist = Color(0xFFE2E8F0);
  static const Color charcoal = Color(0xFF1E293B);
  static const Color cloud = Color(0xFFF1F5F9);

  // Status
  static const Color successColor = Color(0xFF059669);
  static const Color errorColor = Color(0xFFDC2626);
  static const Color warningColor = Color(0xFFD97706);
  static const Color infoColor = Color(0xFF0284C7);

  // Deprecated constants - DO NOT USE in widget build methods
  // Use theme helpers below instead to ensure dark mode support
  static const Color primaryColor = navy;
  static const Color secondaryColor = teal;
  static const Color accentColor = teal;
  static const Color neutralColor = slate;
  static const Color darkNeutralColor = Color(0xFF2C2C2C);

  // Context-aware color helpers (Prefer these over static constants)
  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color secondary(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
  static Color accent(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;
  static Color error(BuildContext context) =>
      Theme.of(context).colorScheme.error;
  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  // Semantic Helpers
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);
  }

  static Color success(BuildContext context) => successColor;

  static Color warning(BuildContext context) => warningColor;

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : const Color(0xFF334155);
  }

  static Color textMuted(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : const Color(0xFF64748B);
  }

  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return [
      BoxShadow(
        color: teal.withValues(alpha: 0.08),
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: navy.withValues(alpha: 0.06),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static Color inputBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF334155) // Darker slate for dark mode
        : const Color(0xFFCBD5E1); // Slate
  }

  static Color accentTeal(BuildContext context) => secondary(context);

  static Color backgroundColor(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  static Color cardColor(BuildContext context) {
    return Theme.of(context).cardTheme.color ??
        Theme.of(context).colorScheme.surface;
  }

  static Color dividerColor(BuildContext context) {
    return Theme.of(context).dividerColor;
  }

  static TextStyle titleStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium ??
        GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold);
  }

  static TextStyle subtitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium ??
        GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500);
  }

  static TextStyle regularTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium ??
        GoogleFonts.roboto(fontSize: 14);
  }

  static TextStyle linkStyle(BuildContext context) {
    return GoogleFonts.roboto(
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
      primary: navy,
      secondary: Color.fromARGB(255, 81, 30, 95),
      error: errorColor,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF0F172A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: pearl,
      shadowColor: navy.withValues(alpha: 0.1),
      dividerColor: mist,
      appBarTheme: AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: teal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.roboto(color: const Color(0xFF334155)),
        hintStyle: GoogleFonts.roboto(color: const Color(0xFF64748B)),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.roboto(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        displayMedium: GoogleFonts.roboto(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        displaySmall: GoogleFonts.roboto(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        headlineMedium: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.roboto(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
        labelLarge: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const ColorScheme colorScheme = ColorScheme.dark(
      primary: Color(0xFF7A9FD9),
      secondary: Color.fromARGB(255, 110, 94, 210),
      error: Color(0xFFEF5350),
      surface: Color(0xFF1E293B), // Charcoal
      onPrimary: Color(0xFF0F172A),
      onSecondary: Color(0xFF0F172A),
      onSurface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Navy Dark
      shadowColor: Colors.black.withValues(alpha: 0.4),
      dividerColor: const Color(0xFF334155),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: tealLight, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.roboto(color: Colors.white70),
        hintStyle: GoogleFonts.roboto(color: Colors.white54),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.roboto(
            fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: GoogleFonts.roboto(
            fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        displaySmall: GoogleFonts.roboto(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: GoogleFonts.roboto(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        bodyLarge: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
        bodyMedium: GoogleFonts.roboto(fontSize: 14, color: Colors.white70),
        labelLarge: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary),
      ),
    );
  }
}
