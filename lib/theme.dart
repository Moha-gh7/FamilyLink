import 'package:flutter/material.dart';

class AppThemeConfig {
  final String name;
  final String emoji;
  final Color primary;
  final Color secondary;

  const AppThemeConfig({
    required this.name,
    required this.emoji,
    required this.primary,
    required this.secondary,
  });
}

class AppTheme {
  // Fixed colors — same across all themes
  static const Color background = Color(0xFFF8F7FF);
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color cardBg     = Color(0xFFF0EEF8);
  static const Color textDark   = Color(0xFF2D2640);
  static const Color textMedium = Color(0xFF6B6480);
  static const Color textLight  = Color(0xFF9E99B0);
  static const Color success    = Color(0xFF52B788);
  static const Color warning    = Color(0xFFF4A261);
  static const Color error      = Color(0xFFE76F51);
  static const Color accent     = Color(0xFF8EC5D6);

  // Default fallback (Violet) — used for const contexts
  static const Color primary   = Color(0xFF6B5EA8);
  static const Color secondary = Color(0xFF5B8FA8);

  // ── 5 Themes ──────────────────────────────────────────
  static const List<AppThemeConfig> themes = [
    AppThemeConfig(
      name: 'Violet',
      emoji: '💜',
      primary:   Color(0xFF6B5EA8),
      secondary: Color(0xFF5B8FA8),
    ),
    AppThemeConfig(
      name: 'Ocean',
      emoji: '🌊',
      primary:   Color(0xFF0369A1),
      secondary: Color(0xFF0891B2),
    ),
    AppThemeConfig(
      name: 'Forest',
      emoji: '🌿',
      primary:   Color(0xFF15803D),
      secondary: Color(0xFF0D9488),
    ),
    AppThemeConfig(
      name: 'Sunset',
      emoji: '🌅',
      primary:   Color(0xFFC2410C),
      secondary: Color(0xFFD97706),
    ),
    AppThemeConfig(
      name: 'Rose',
      emoji: '🌸',
      primary:   Color(0xFFBE185D),
      secondary: Color(0xFF9333EA),
    ),
  ];

  static ThemeData buildTheme(AppThemeConfig config) => ThemeData(
    primaryColor: config.primary,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.light(
      primary: config.primary,
      secondary: config.secondary,
    ),
    fontFamily: 'SF Pro Display',
    appBarTheme: AppBarTheme(
      backgroundColor: config.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: config.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: config.primary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? config.primary : null),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? config.primary.withOpacity(0.4)
              : null),
    ),
  );

  // Convenience getter for default theme (Violet)
  static ThemeData get theme => buildTheme(themes[0]);
}
