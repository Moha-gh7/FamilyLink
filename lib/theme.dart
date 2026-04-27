import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primary = Color(0xFF6B5EA8);      // Lavender purple
  static const Color secondary = Color(0xFF5B8FA8);    // Steel blue
  static const Color accent = Color(0xFF8EC5D6);       // Light blue
  
  // Background Colors  
  static const Color background = Color(0xFFF8F7FF);   // Near white
  static const Color surface = Color(0xFFFFFFFF);      // Pure white
  static const Color cardBg = Color(0xFFF0EEF8);       // Light lavender card

  // Text Colors
  static const Color textDark = Color(0xFF2D2640);     // Dark purple-black
  static const Color textMedium = Color(0xFF6B6480);   // Medium grey-purple
  static const Color textLight = Color(0xFF9E99B0);    // Light grey

  // Status Colors
  static const Color success = Color(0xFF52B788);      // Green
  static const Color warning = Color(0xFFF4A261);      // Orange
  static const Color error = Color(0xFFE76F51);        // Red

  static ThemeData get theme => ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
    ),
    fontFamily: 'SF Pro Display',
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
  );
}