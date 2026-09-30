import 'package:flutter/material.dart';

class AppTheme {
  // Более сдержанная, премиальная палитра
  static const Color background = Color(0xFF0D0D12);
  static const Color surface = Color(0xFF16161D);
  static const Color surfaceElevated = Color(0xFF1D1D26);
  static const Color accent = Color(0xFFE8A87C); // приглушённый тёплый акцент
  static const Color accentMuted = Color(0xFF4A4238);
  static const Color textPrimary = Color(0xFFF2F2F0);
  static const Color textSecondary = Color(0xFF8E8E96);
  static const Color textTertiary = Color(0xFF5C5C64);
  static const Color divider = Color(0xFF232329);
  static const Color danger = Color(0xFFE07A6E);

  static const double radiusS = 12;
  static const double radiusM = 18;
  static const double radiusL = 24;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      splashFactory: NoSplash.splashFactory, // убираем стандартный ripple — своя анимация тапов
      colorScheme: const ColorScheme.dark(
        primary: accent,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16, height: 1.4),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: background,
        elevation: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? background : textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? accent : surfaceElevated;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
  }
}