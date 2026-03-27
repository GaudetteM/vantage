import 'package:flutter/material.dart';

/// Centralised colour + text-style tokens for Vantage.
class VantageTheme {
  VantageTheme._();

  // Palette
  static const Color background = Color(0xFF0D0D1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color accent = Color(0xFF00E5FF);
  static const Color accentDim = Color(0xFF006070);
  static const Color playerColor = Color(0xFF00E5FF);
  static const Color goalColor = Color(0xFFFFD54F);
  static const Color wallColor = Color(0xFF4A4A7A);         // clearly brighter than floor
  static const Color wallBorderColor = Color(0xFF6A6A9A);    // top-left edge highlight
  static const Color floorColor = Color(0xFF1E1E36);
  static const Color emptyColor = Color(0xFF07070F);         // true void — darker than bg
  static const Color perspectiveHiddenColor = Color(0xFF12122A);
  static const Color perspectiveLockedArrow = Color(0xFF3A3A6A);  // dim arrow
  static const Color perspectiveActiveColor = Color(0xFF7C4DFF);
  static const Color perspectiveActiveArrow = Color(0xFFB39DFF);  // bright arrow
  static const Color perspectiveNorthColor = Color(0xFF81C784); // green
  static const Color perspectiveEastColor = Color(0xFFFFC857); // amber
  static const Color perspectiveSouthColor = Color(0xFFE57373); // red
  static const Color perspectiveWestColor = Color(0xFF7C4DFF); // purple

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: goalColor,
          surface: surface,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: accent,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
          titleMedium: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            letterSpacing: 2,
          ),
          bodyMedium: TextStyle(color: Colors.white60, fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentDim,
            foregroundColor: accent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      );
}
