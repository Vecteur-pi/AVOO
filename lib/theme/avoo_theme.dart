import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AvooColors {
  // Brand
  static const Color green = Color(0xFF146D36); // Brand Primary
  static const Color brandLight = Color(0xFFDEFCE3); // Active states, light backgrounds
  
  // Structure
  static const Color navy = Color(0xFF1C2434); // Structure Navy
  
  // Neutral
  static const Color background = Color(0xFFF5F6F3); // Main app background
  static const Color surface = Colors.white;         // Cards, forms
  static const Color ink = Color(0xFF111827);        // Text primary
  static const Color muted = Color(0xFF4B5563);      // Text secondary
  static const Color line = Color(0xFFE5E7EB);       // Borders, dividers

  // Feedback
  static const Color orange = Color(0xFFCA472C); // Keep for backward compat
  static const Color success = Color(0xFF099C3F);
  static const Color warning = Color(0xFFF55700);
  static const Color error = Color(0xFFEF4444);
  
  // Legacy (Keep for backwards compatibility while migrating)
  static const Color softShadow = Color(0x140C1827);
  static const Color bone = Color(0xFFEAF1D5);
  static const Color fog = Color(0xFFF0F1ED);
}

class AvooTheme {
  static ThemeData get light {
    final base = ThemeData.light();
    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: AvooColors.green,
      onPrimary: Colors.white,
      secondary: AvooColors.brandLight,
      onSecondary: AvooColors.green,
      error: AvooColors.error,
      onError: Colors.white,
      surface: AvooColors.surface,
      onSurface: AvooColors.ink,
      background: AvooColors.background,
      onBackground: AvooColors.ink,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: AvooColors.green,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AvooColors.green,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AvooColors.green,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AvooColors.ink,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AvooColors.ink,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AvooColors.ink,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AvooColors.bone,
    );
  }
}
