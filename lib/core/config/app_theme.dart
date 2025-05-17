import 'package:flutter/material.dart';
import 'app_config.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: const Color(AppConfig.primaryColorHex),
      scaffoldBackgroundColor: const Color(AppConfig.backgroundColorHex),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(AppConfig.primaryColorHex),
        primary: const Color(AppConfig.primaryColorHex),
        secondary: const Color(AppConfig.secondaryColorHex),
        surface: const Color(AppConfig.surfaceColorHex),
        background: const Color(AppConfig.backgroundColorHex),
        error: Colors.redAccent,
      ),
      cardTheme: const CardTheme(
        color: Color(AppConfig.cardColorHex),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: Color(AppConfig.textColorHex),
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: Color(AppConfig.textColorHex),
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: Color(AppConfig.textColorHex),
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: Color(AppConfig.textColorHex),
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: Color(AppConfig.textColorHex),
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: Color(AppConfig.textColorHex)),
        bodyMedium: TextStyle(color: Color(AppConfig.textColorHex)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(AppConfig.primaryColorHex),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(AppConfig.primaryColorHex),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(AppConfig.primaryColorHex)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        hintStyle: const TextStyle(color: Color(AppConfig.mutedTextColorHex)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(AppConfig.primaryColorHex),
        unselectedItemColor: Color(AppConfig.mutedTextColorHex),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        elevation: 8,
      ),
      useMaterial3: true,
    );
  }
} 