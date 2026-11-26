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
      surfaceTint: Colors.transparent,
    );

    final baseTextTheme = TextTheme(
      displayLarge: TextStyle(
        color: AppTokens.text,
        fontSize: 56,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -1.5,
      ),
      displayMedium: TextStyle(
        color: AppTokens.text,
        fontSize: 44,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -1,
      ),
      displaySmall: TextStyle(
        color: AppTokens.text,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      headlineLarge: TextStyle(
        color: AppTokens.text,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.25,
      ),
      headlineMedium: TextStyle(
        color: AppTokens.text,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        color: AppTokens.text,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      titleLarge: TextStyle(
        color: AppTokens.text,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        color: AppTokens.text,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        color: AppTokens.text,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        color: AppTokens.text,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: AppTokens.mutedText,
        fontSize: 14,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        color: AppTokens.mutedText,
        fontSize: 12,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppTokens.background,
      fontFamily: 'NunitoSans',
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppTokens.surface,
        foregroundColor: AppTokens.text,
        centerTitle: false,
        elevation: AppTokens.elevationCard,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: AppTokens.elevationNavBar,
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppTokens.surface,
        elevation: AppTokens.elevationCard,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
          side: const BorderSide(color: AppTokens.outline, width: 1),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(
            AppTokens.minimumTouchTarget,
            AppTokens.buttonHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space24,
            vertical: AppTokens.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          ),
          textStyle: baseTextTheme.labelLarge,
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(
            AppTokens.minimumTouchTarget,
            AppTokens.buttonHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space20,
            vertical: AppTokens.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(fontSize: 14),
          backgroundColor: AppTokens.primary,
          foregroundColor: AppTokens.surface,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(
            AppTokens.minimumTouchTarget,
            AppTokens.buttonHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space20,
            vertical: AppTokens.space12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          ),
          textStyle: baseTextTheme.labelLarge,
          side: const BorderSide(color: AppTokens.outline, width: 1.5),
          foregroundColor: AppTokens.primary,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(
            AppTokens.minimumTouchTarget,
            40,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space12,
            vertical: AppTokens.space8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          ),
          textStyle: baseTextTheme.labelLarge,
          foregroundColor: AppTokens.primary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppTokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppTokens.elevationNavBar,
        shadowColor: AppTokens.text.withValues(alpha: 0.08),
        labelTextStyle: WidgetStatePropertyAll(
          baseTextTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        indicatorColor: AppTokens.primary.withValues(alpha: 0.1),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppTokens.surface,
        elevation: AppTokens.elevationNavBar,
        selectedItemColor: AppTokens.primary,
        unselectedItemColor: AppTokens.mutedText,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: baseTextTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: baseTextTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space14,
          vertical: AppTokens.space12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
          borderSide: const BorderSide(color: AppTokens.error, width: 1.5),
        ),
        labelStyle: baseTextTheme.bodyMedium?.copyWith(
          color: AppTokens.mutedText,
        ),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(
          color: AppTokens.mutedText.withValues(alpha: 0.6),
        ),
        errorStyle: baseTextTheme.bodySmall?.copyWith(
          color: AppTokens.error,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppTokens.surface,
        selectedColor: AppTokens.primary.withValues(alpha: 0.12),
        disabledColor: AppTokens.outline.withValues(alpha: 0.3),
        labelStyle: baseTextTheme.labelMedium?.copyWith(
          color: AppTokens.text,
        ),
        secondaryLabelStyle: baseTextTheme.labelMedium?.copyWith(
          color: AppTokens.primary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space12,
          vertical: AppTokens.space8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusRound),
          side: const BorderSide(color: AppTokens.outline, width: 1),
        ),
        showCheckmark: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppTokens.surface,
        elevation: AppTokens.elevationModal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
        ),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: baseTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: baseTextTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppTokens.surface,
        elevation: AppTokens.elevationModal,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusXLarge),
          ),
        ),
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppTokens.surface,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTokens.text.withValues(alpha: 0.92),
        contentTextStyle: baseTextTheme.bodyMedium?.copyWith(
          color: AppTokens.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
        actionTextColor: AppTokens.accent,
      ),
      dividerTheme: DividerThemeData(
        color: AppTokens.outline,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16,
          vertical: AppTokens.space8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
        titleTextStyle: baseTextTheme.titleMedium,
        subtitleTextStyle: baseTextTheme.bodySmall,
        leadingAndTrailingTextStyle: baseTextTheme.bodyMedium,
        iconColor: AppTokens.mutedText,
        textColor: AppTokens.text,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppTokens.primary,
        foregroundColor: AppTokens.surface,
        elevation: AppTokens.elevationRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppTokens.primary,
        linearTrackColor: AppTokens.outline,
        circularTrackColor: AppTokens.outline,
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        labelColor: AppTokens.primary,
        unselectedLabelColor: AppTokens.mutedText,
        indicatorColor: AppTokens.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppTokens.primary.withValues(alpha: 0.08);
          }
          return Colors.transparent;
        }),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppTokens.text.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
        textStyle: baseTextTheme.bodySmall?.copyWith(
          color: AppTokens.surface,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space12,
          vertical: AppTokens.space8,
        ),
      ),
    );
  }
}
