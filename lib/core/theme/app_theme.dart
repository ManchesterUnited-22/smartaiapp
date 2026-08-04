// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _indigo = Color(0xFF3E52D9);
  static const _indigoDark = Color(0xFF8B97F5);
  static const _coral = Color(0xFFFF6F59);
  static const _teal = Color(0xFF22A699);

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData(brightness: Brightness.dark).textTheme
        : ThemeData(brightness: Brightness.light).textTheme;
    final body = GoogleFonts.manropeTextTheme(base);

    return body.copyWith(
      displaySmall: GoogleFonts.fraunces(
        fontSize: 30, fontWeight: FontWeight.w600, height: 1.2,
        color: body.displaySmall?.color,
      ),
      headlineSmall: GoogleFonts.fraunces(
        fontSize: 21, fontWeight: FontWeight.w600,
        color: body.headlineSmall?.color,
      ),
      titleLarge: GoogleFonts.fraunces(
        fontSize: 19, fontWeight: FontWeight.w600,
        color: body.titleLarge?.color,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.3,
        color: body.labelSmall?.color,
      ),
    );
  }

  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: _indigo,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE3E6FB),
      onPrimaryContainer: Color(0xFF1B2361),
      secondary: _coral,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFE2DB),
      onSecondaryContainer: Color(0xFF5C2116),
      tertiary: _teal,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFD8F3EE),
      onTertiaryContainer: Color(0xFF0B3B35),
      error: Color(0xFFD64545),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF1E2230),
      surfaceContainerHighest: Color(0xFFEDEEF5),
      onSurfaceVariant: Color(0xFF62667A),
      outline: Color(0xFFDBDDE6),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      textTheme: _textTheme(Brightness.light),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1E2230),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEDEEF5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }

  static ThemeData get dark {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _indigoDark,
      onPrimary: Color(0xFF0B1030),
      primaryContainer: Color(0xFF2A3378),
      onPrimaryContainer: Color(0xFFDDE1FF),
      secondary: Color(0xFFFF8770),
      onSecondary: Color(0xFF3A140C),
      secondaryContainer: Color(0xFF5C2116),
      onSecondaryContainer: Color(0xFFFFDCD3),
      tertiary: Color(0xFF3FD1B4),
      onTertiary: Color(0xFF00332B),
      tertiaryContainer: Color(0xFF0B3B35),
      onTertiaryContainer: Color(0xFFB6F3E7),
      error: Color(0xFFFF6B6B),
      onError: Color(0xFF3A0A0A),
      surface: Color(0xFF1A1D27),
      onSurface: Color(0xFFE7E8ED),
      surfaceContainerHighest: Color(0xFF242835),
      onSurfaceVariant: Color(0xFFA4A8B8),
      outline: Color(0xFF3A3F52),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0F1117),
      textTheme: _textTheme(Brightness.dark),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFE7E8ED),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1D27),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF242835),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}