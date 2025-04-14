import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF7C938E); // Deep Teal
  static const Color secondaryColor = Color(0xFF212B26); // Dark Slate

  // Secondary Colors
  static const Color accentColor = Color(0xFF62301F); // Burnt Sienna
  static const Color neutralColor = Color(0xFF698199); // Soft Blue-Gray
  static const Color darkNeutralColor = Color(0xFF222A2A); // Near Black

  // Background & Utility Colors
  static const Color backgroundColor = Color(0xFFF5F7F6); // Warm Off-White
  static const Color cardColor = Color(0xFFE0E6E4); // Soft Gray-Teal
  static const Color dividerColor = Color(0xFFD1D9D7); // Subtle Gray

  // Feedback Colors
  static const Color successColor = Color(0xFF5A8C7A); // Muted Green
  static const Color warningColor = Color(0xFFB38E5E); // Earthy Gold
  static const Color errorColor = Color(0xFFA05D4A); // Soft Red-Brown

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: secondaryColor,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    color: neutralColor,
  );

  static const TextStyle welcomeStyle = TextStyle(
    fontSize: 18,
    color: neutralColor,
  );

  static const TextStyle linkStyle = TextStyle(
    color: primaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
    decorationColor: primaryColor,
    decorationThickness: 1.5,
  );

  static const TextStyle regularTextStyle = TextStyle(
    color: neutralColor,
    fontSize: 14,
  );

  // Layout
  static const EdgeInsets screenPadding = EdgeInsets.all(24.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(24.0);
  static const double defaultSpacing = 16.0;
  static const double largeSpacing = 32.0;
  static const double smallSpacing = 8.0;

  // Icons
  static const double largeIconSize = 80.0;
  static const double smallIconSize = 20.0;

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        background: backgroundColor,
        surface: cardColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: darkNeutralColor,
        onSurface: darkNeutralColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: darkNeutralColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: darkNeutralColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: darkNeutralColor,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: darkNeutralColor,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
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
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),
    );
  }
} 