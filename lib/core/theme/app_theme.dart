import 'package:flutter/material.dart';

abstract final class AhanChiColors {
  static const graphite = Color(0xFF263331);
  static const graphiteDark = Color(0xFF101817);
  static const copper = Color(0xFFC56A3A);
  static const copperDark = Color(0xFF8D4726);
  static const recycledGreen = Color(0xFF3D705B);
  static const cream = Color(0xFFF6F1E8);
  static const paper = Color(0xFFFFFCF7);
  static const muted = Color(0xFF6F7C79);
}

abstract final class AhanChiTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AhanChiColors.copper,
      brightness: Brightness.light,
      primary: AhanChiColors.graphite,
      secondary: AhanChiColors.copper,
      tertiary: AhanChiColors.recycledGreen,
      surface: AhanChiColors.paper,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AhanChiColors.cream,
      fontFamily: 'sans-serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: AhanChiColors.cream,
        foregroundColor: AhanChiColors.graphite,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AhanChiColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AhanChiColors.paper,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5DDD2))),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AhanChiColors.graphite,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
