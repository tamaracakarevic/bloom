import 'package:flutter/material.dart';

class BloomColors {
  static const primary = Color(0xFFB8436B);
  static const primaryContainer = Color(0xFFFFD9E3);
  static const onPrimaryContainer = Color(0xFF3E0420);
  static const secondary = Color(0xFF8B6BB1);
  static const background = Color(0xFFFFF7F9);
  static const onSurface = Color(0xFF2B1A20);
  static const onSurfaceVariant = Color(0xFF6B5560);
  static const container = Color(0xFFFCEAF0);
  static const containerHigh = Color(0xFFF8E3EA);
  static const outline = Color(0xFFCDAAB7);
  static const outlineVariant = Color(0xFFEBD3DB);
  static const mint = Color(0xFF3E9C7A);
  static const mintSoft = Color(0xFFDDF3EA);
  static const coral = Color(0xFFD9785F);
  static const blush = Color(0xFFF8B5C8);
  static const lilac = Color(0xFFD9C2F0);
}

const headerGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [BloomColors.blush, BloomColors.lilac],
);

ThemeData bloomTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: BloomColors.primary,
    onPrimary: Colors.white,
    primaryContainer: BloomColors.primaryContainer,
    onPrimaryContainer: BloomColors.onPrimaryContainer,
    secondary: BloomColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFEFE2FF),
    onSecondaryContainer: Color(0xFF2E1650),
    tertiary: BloomColors.coral,
    onTertiary: Colors.white,
    error: Color(0xFFBA1A1A),
    onError: Colors.white,
    surface: BloomColors.background,
    onSurface: BloomColors.onSurface,
    onSurfaceVariant: BloomColors.onSurfaceVariant,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFFFF0F4),
    surfaceContainer: BloomColors.container,
    surfaceContainerHigh: BloomColors.containerHigh,
    surfaceContainerHighest: Color(0xFFF3DCE4),
    outline: BloomColors.outline,
    outlineVariant: BloomColors.outlineVariant,
  );

  const heading = TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.5, color: BloomColors.onSurface);

  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Poppins');
  return base.copyWith(
    scaffoldBackgroundColor: BloomColors.background,
    textTheme: base.textTheme.copyWith(
      displaySmall: heading.copyWith(fontSize: 34),
      headlineLarge: heading.copyWith(fontSize: 30),
      headlineMedium: heading.copyWith(fontSize: 26),
      headlineSmall: heading.copyWith(fontSize: 22),
      titleLarge: heading.copyWith(fontSize: 19, letterSpacing: -0.2),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
      titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 15),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 13.5),
      bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 12, color: BloomColors.onSurfaceVariant),
      labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: BloomColors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: BloomColors.primary, width: 2),
      ),
      helperMaxLines: 2,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: BloomColors.outline),
        textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: BloomColors.primaryContainer,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? BloomColors.primary : BloomColors.onSurfaceVariant,
          )),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? BloomColors.primary : BloomColors.onSurfaceVariant,
          )),
    ),
    dialogTheme: const DialogTheme(backgroundColor: Colors.white),
  );
}

/// Za velike brojeve.
const numberStyle = TextStyle(
  fontFamily: 'Poppins',
  fontWeight: FontWeight.w600,
  color: BloomColors.onSurface,
  letterSpacing: -0.5,
);
