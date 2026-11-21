import 'package:flutter/material.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppTokens.primary,
      onPrimary: AppTokens.surface,
      primaryContainer: AppTokens.mint,
      onPrimaryContainer: AppTokens.text,
      secondary: AppTokens.secondary,
      onSecondary: AppTokens.surface,
      secondaryContainer: AppTokens.sky,
      onSecondaryContainer: AppTokens.text,
      tertiary: AppTokens.accent,
      onTertiary: AppTokens.text,
      error: AppTokens.error,
      onError: AppTokens.surface,
      surface: AppTokens.surface,
      onSurface: AppTokens.text,
      surfaceContainerHighest: AppTokens.sky,
      outline: AppTokens.outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppTokens.background,
      fontFamily: 'NunitoSans',
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: AppTokens.text,
          fontSize: 36,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
        headlineLarge: TextStyle(
          color: AppTokens.text,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          color: AppTokens.text,
          fontSize: 21,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          color: AppTokens.text,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        bodyLarge: TextStyle(color: AppTokens.text, fontSize: 15, height: 1.45),
        bodyMedium: TextStyle(
          color: AppTokens.mutedText,
          fontSize: 14,
          height: 1.45,
        ),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.background,
        foregroundColor: AppTokens.text,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppTokens.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          side: const BorderSide(color: AppTokens.outline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minimumTouchTarget,
            AppTokens.buttonHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16,
          vertical: AppTokens.space16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          borderSide: const BorderSide(color: AppTokens.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          borderSide: const BorderSide(color: AppTokens.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          borderSide: const BorderSide(color: AppTokens.primary, width: 2),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
