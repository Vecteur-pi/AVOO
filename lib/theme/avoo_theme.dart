import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AvooColors {
  static const Color green = Color(0xFF195D38);
  static const Color navy = Color(0xFF0C1827);
  static const Color orange = Color(0xFFCA472C);
  static const Color bone = Color(0xFFF7F7F6);
  static const Color ink = Color(0xFF101723);
  static const Color fog = Color(0xFFF0F1ED);
  static const Color line = Color(0xFFE2E4DE);
  static const Color softShadow = Color(0x140C1827);
}

class AvooTheme {
  static ThemeData get light {
    final base = ThemeData.light();
    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: AvooColors.green,
      onPrimary: Colors.white,
      secondary: AvooColors.orange,
      onSecondary: Colors.white,
      error: Color(0xFFB42318),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: AvooColors.ink,
      background: AvooColors.bone,
      onBackground: AvooColors.ink,
    );

    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: AvooColors.navy,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AvooColors.navy,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AvooColors.navy,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AvooColors.ink,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AvooColors.ink,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AvooColors.ink,
      ),
      labelLarge: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AvooColors.bone,
      cardTheme: const CardTheme(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AvooColors.navy.withOpacity(0.5),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AvooColors.navy),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AvooColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AvooColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AvooColors.green, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AvooColors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AvooColors.navy,
          side: const BorderSide(color: AvooColors.line),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
