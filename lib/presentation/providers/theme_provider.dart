import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Theme color options ───────────────────────────────────────────────────────

class AppColorScheme {
  final String name;
  final Color primary;
  final Color secondary;
  const AppColorScheme({
    required this.name,
    required this.primary,
    required this.secondary,
  });
}

const List<AppColorScheme> appColorSchemes = [
  AppColorScheme(name: 'Forest',   primary: Color(0xFF1A6B5A), secondary: Color(0xFF2ECC71)),
  AppColorScheme(name: 'Ocean',    primary: Color(0xFF1565C0), secondary: Color(0xFF42A5F5)),
  AppColorScheme(name: 'Sunset',   primary: Color(0xFFBF360C), secondary: Color(0xFFFF7043)),
  AppColorScheme(name: 'Violet',   primary: Color(0xFF6A1B9A), secondary: Color(0xFFAB47BC)),
  AppColorScheme(name: 'Slate',    primary: Color(0xFF37474F), secondary: Color(0xFF78909C)),
  AppColorScheme(name: 'Rose',     primary: Color(0xFFC2185B), secondary: Color(0xFFF06292)),
  AppColorScheme(name: 'Amber',    primary: Color(0xFFE65100), secondary: Color(0xFFFFB300)),
  AppColorScheme(name: 'Teal',     primary: Color(0xFF00695C), secondary: Color(0xFF4DB6AC)),
];

// ── Theme state ───────────────────────────────────────────────────────────────

class ThemeState {
  final ThemeMode mode;
  final int colorIndex;

  const ThemeState({required this.mode, required this.colorIndex});

  AppColorScheme get colorScheme => appColorSchemes[colorIndex];

  ThemeState copyWith({ThemeMode? mode, int? colorIndex}) => ThemeState(
        mode: mode ?? this.mode,
        colorIndex: colorIndex ?? this.colorIndex,
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    _load();
    return const ThemeState(mode: ThemeMode.dark, colorIndex: 1);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? true;
    final colorIndex = prefs.getInt('colorIndex') ?? 1;
    state = ThemeState(
      mode: isDark ? ThemeMode.dark : ThemeMode.light,
      colorIndex: colorIndex.clamp(0, appColorSchemes.length - 1),
    );
  }

  Future<void> toggle() async {
    final newMode =
        state.mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = state.copyWith(mode: newMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', newMode == ThemeMode.dark);
  }

  Future<void> setColorIndex(int index) async {
    state = state.copyWith(colorIndex: index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('colorIndex', index);
  }
}
