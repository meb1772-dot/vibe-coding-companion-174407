import 'package:flutter/material.dart';

/// Ocean Professional theme configuration
/// Blue primary with amber accents, modern rounded corners and subtle shadows.
class OceanTheme {
  // PUBLIC_INTERFACE
  /// Provides the ThemeData for the app following the Ocean Professional style.
  static ThemeData get theme {
    const primary = Color(0xFF2563EB); // Blue 600
    const secondary = Color(0xFFF59E0B); // Amber 500
    const error = Color(0xFFEF4444); // Red 500
    const background = Color(0xFFF9FAFB); // Gray-50
    const surface = Color(0xFFFFFFFF); // White
    const text = Color(0xFF111827); // Gray-900

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.black,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: const Color(0xFFE5E7EB), // subtle containers
      surfaceBright: surface,
      surfaceDim: const Color(0xFFF3F4F6),
      outline: const Color(0xFFE5E7EB),
      outlineVariant: const Color(0xFFD1D5DB),
      tertiary: const Color(0xFF0EA5E9),
      onTertiary: Colors.white,
      inverseSurface: text,
      inversePrimary: primary,
      // Non-deprecated background isn't in ColorScheme; use surface for surfaces.
    );

    final baseTextTheme = Typography.blackCupertino.apply(
      bodyColor: text,
      displayColor: text,
    );

    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      textTheme: baseTextTheme.copyWith(
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(height: 1.4),
        titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 1,
        shadowColor: Colors.black.withAlpha(10),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 1,
        shadowColor: Colors.black.withAlpha(12),
        margin: const EdgeInsets.all(8),
        shape: rounded,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        shape: rounded,
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black.withAlpha(20),
          shape: rounded,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          shape: rounded,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: rounded,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF3F4F6),
        labelStyle: baseTextTheme.bodyMedium?.copyWith(color: text),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: text,
        contentTextStyle: baseTextTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: rounded,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withAlpha(20),
        elevation: 1,
        labelTextStyle: WidgetStateProperty.all(
          baseTextTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      bottomAppBarTheme: const BottomAppBarTheme(
        color: surface,
        elevation: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: Colors.black,
      ),
      shadowColor: Colors.black.withAlpha(16),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
