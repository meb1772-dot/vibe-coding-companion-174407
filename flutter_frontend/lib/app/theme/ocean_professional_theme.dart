import 'package:flutter/material.dart';

/// Ocean Professional theme (modern, clean, subtle shadows, rounded corners).
///
/// Primary: #2563EB
/// Secondary: #F59E0B
class OceanProfessionalTheme {
  OceanProfessionalTheme._();

  static const Color _primary = Color(0xFF2563EB);
  static const Color _secondary = Color(0xFFF59E0B);
  static const Color _error = Color(0xFFEF4444);

  static const Color _background = Color(0xFFF9FAFB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _text = Color(0xFF111827);

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
      primary: _primary,
      secondary: _secondary,
      error: _error,
      surface: _surface,
      onSurface: _text,
    ).copyWith(
      // Keep the overall app background light and neutral.
      surface: _surface,
    );

    final RoundedRectangleBorder cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _background,
      appBarTheme: AppBarTheme(
        backgroundColor: _surface,
        foregroundColor: _text,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _text,
        ),
      ),
      cardTheme: CardTheme(
        color: _surface,
        elevation: 0.5,
        shape: cardShape,
        margin: const EdgeInsets.all(0),
      ),
      listTileTheme: const ListTileThemeData(
        dense: false,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: _text.withAlpha(18),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _text.withAlpha(25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _text.withAlpha(25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: _text.withAlpha(120)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surface,
        indicatorColor: _primary.withAlpha(24),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? _primary : _text.withAlpha(160),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? _primary : _text.withAlpha(160),
          );
        }),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45),
      ).apply(
        bodyColor: _text,
        displayColor: _text,
      ),
    );
  }
}
