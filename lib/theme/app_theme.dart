import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Colors ──────────────────────────────────────
  static const Color primary = Color(0xFF00B073);      
  static const Color primaryLight = Color(0xFFE6F7F1);  
  static const Color premium = Color(0xFFF2A33A);       

  // ── Dark Theme Colors ────────────────────────────────
  static const Color background = Color(0xFF0F0F0F);    
  static const Color surface = Color(0xFF1A1A1A);        
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF9E9E9E);

  // ── Light Theme Colors ───────────────────────────────
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF757575);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: primaryLight,
      surface: surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    primaryColor: primary,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: primaryLight,
      surface: lightSurface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: lightTextPrimary,
      iconTheme: IconThemeData(color: lightTextPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );

  // ── Adaptive color helpers ────────────────────────────
  /// Returns the appropriate background color for the current theme.
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? background : lightBackground;

  static Color surf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? surface : lightSurface;

  static Color txtPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textPrimary : lightTextPrimary;

  static Color txtSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textSecondary : lightTextSecondary;

  static Color cardBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.08);

  static Color subtleText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.4)
          : Colors.black.withValues(alpha: 0.5);
}
