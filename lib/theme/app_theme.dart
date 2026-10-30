import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors The PAMs - Unified #2294f2
  static const Color primaryBlue = Color(0xFF2294F2); // #2294f2 Campus Brand Blue
  static const Color primaryDark = Color(0xFF1B82D8); // #2294f2 Deeper Tone (for subtle gradients)
  static const Color primaryLight = Color(0xFF4BAAF7); // #2294f2 Lighter Highlight Tone
  static const Color accentGold = Color(0xFFD97706); // Amber Gold
  static const Color accentGoldLight = Color(0xFFFEF3C7); // Soft Amber
  static const Color bgGrey = Color(0xFFF8FAFC); // Clean Canvas
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0F172A); // Dark Slate
  static const Color textMuted = Color(0xFF64748B); // Slate Muted
  static const Color successGreen = Color(0xFF10B981); // Emerald Green
  static const Color dangerRed = Color(0xFFEF4444); // Crimson Red
  static const Color cardBorder = Color(0xFFE2E8F0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: accentGold,
        surface: surfaceWhite,
      ),
      scaffoldBackgroundColor: bgGrey,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0.8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        labelStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
    );
  }
}
