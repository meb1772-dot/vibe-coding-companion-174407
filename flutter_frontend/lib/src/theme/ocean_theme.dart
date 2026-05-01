import 'package:flutter/material.dart';

class OceanTheme {
  OceanTheme._();

  static const Color _primary = Color(0xFF2563EB); // blue
  static const Color _secondary = Color(0xFFF59E0B); // amber
  static const Color _error = Color(0xFFEF4444);
  static const Color _text = Color(0xFF111827);
  static const Color _bg = Color(0xFFF9FAFB);
  static const Color _surface = Color(0xFFFFFFFF);

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
      primary: _primary,
      secondary: _secondary,
      error: _error,
      surface: _surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _bg,
      textTheme: Typography.blackMountainView.apply(
        bodyColor: _text,
        displayColor: _text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: _text,
        elevation: 0,
        surfaceTintColor: scheme.surface,
      ),
      cardTheme: CardTheme(
        color: scheme.surface,
        elevation: 0.5,
        shadowColor: Colors.black.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: _text.withAlpha(18),
        space: 1,
      ),
    );
  }

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.dark,
      primary: _primary,
      secondary: _secondary,
      error: _error,
      surface: const Color(0xFF0B1220),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF050A14),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        elevation: 0,
        surfaceTintColor: scheme.surface,
      ),
      cardTheme: CardTheme(
        color: scheme.surface,
        elevation: 0.5,
        shadowColor: Colors.black.withAlpha(40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withAlpha(18),
        space: 1,
      ),
    );
  }
}
