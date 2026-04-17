import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF00B073);      
  static const Color primaryLight = Color(0xFFE6F7F1);  
  static const Color premium = Color(0xFFF2A33A);       
  static const Color background = Color(0xFF0F0F0F);    
  static const Color surface = Color(0xFF1A1A1A);        
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF9E9E9E);

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
}
