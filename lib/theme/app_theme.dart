import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF00595C); // Deep Teal
  static const Color primaryContainer = Color(0xFF0D7377); // Soft Teal
  static const Color secondary = Color(0xFF32666C);
  static const Color secondaryContainer = Color(0xFFB7ECF3);
  static const Color tertiary = Color(0xFF7A401C); // Warm Orange/Brown Accent
  static const Color background = Color(0xFFF7FAFA); // Soft Light Background
  static const Color surface = Color(0xFFF7FAFA);
  
  // Tonal Surfaces (No-Line rule implementation)
  static const Color surfaceLow = Color(0xFFF1F4F4); // Tonal low surface
  static const Color surfaceLowest = Color(0xFFFFFFFF); // Elevated card background
  static const Color surfaceContainerHigh = Color(0xFFE6E9E9);
  static const Color surfaceContainerHighest = Color(0xFFE0E3E3);

  static const Color textMain = Color(0xFF181C1D); // Soft Charcoal
  static const Color textMuted = Color(0xFF5E6E6F);
  
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color success = Color(0xFF0F9D58); // Emerald Green
  static const Color warning = Color(0xFFF4B400); // Amber Yellow
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        tertiary: AppColors.tertiary,
        background: AppColors.background,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.cairoTextTheme().copyWith(
        displayLarge: GoogleFonts.cairo(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.cairo(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
          height: 1.3,
        ),
        titleLarge: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textMain,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textMuted,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: AppColors.textMuted),
        floatingLabelStyle: TextStyle(color: AppColors.primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }
}
