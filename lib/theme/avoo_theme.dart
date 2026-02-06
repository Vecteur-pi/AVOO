import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AvooColors {
  static const Color green = Color(0xFF5D8F42);
  static const Color navy = Color(0xFF0C1827);
  static const Color orange = Color(0xFFCA472C);
  static const Color bone = Color(0xFFEAF1D5);
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

    final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.nunito(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: AvooColors.green,
      ),
      displayMedium: GoogleFonts.nunito(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AvooColors.green,
      ),
      titleLarge: GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AvooColors.green,
      ),
      titleMedium: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AvooColors.ink,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AvooColors.ink,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AvooColors.ink,
      ),
      labelLarge: GoogleFonts.nunito(
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
