import 'package:flutter/material.dart';

class AppTheme {
  static const _darkBg      = Color(0xFF111214);  // true dark gray
  static const _darkSurface = Color(0xFF1C1E21);
  static const _darkCard    = Color(0xFF26282C);

  static ThemeData dark(Color primary, Color secondary) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: _darkSurface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          tertiary: const Color(0xFF4ECDC4),
        ),
        scaffoldBackgroundColor: _darkBg,
        cardColor: _darkCard,
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkBg,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _darkSurface,
        ),
        cardTheme: CardThemeData(
          color: _darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _darkCard,
          selectedColor: primary,
          labelStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF30363D),
          thickness: 1,
        ),
        textTheme: const TextTheme(
          headlineLarge:  TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
          headlineMedium: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
          headlineSmall:  TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          titleLarge:     TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium:    TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          bodyLarge:      TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium:     TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
          bodySmall:      TextStyle(color: Color(0xFF78909C), fontSize: 12),
        ),
      );

  static ThemeData light(Color primary, Color secondary) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: primary,
          secondary: secondary,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFF1A2E28),
          tertiary: const Color(0xFF4ECDC4),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A2E28),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF1A2E28),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFEEF2F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
      );
}
