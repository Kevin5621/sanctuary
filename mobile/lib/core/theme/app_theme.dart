import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Jarak & radius standar untuk antarmuka cartoon minimalis.
class AppSpacing {
  const AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;

  static const radiusSm = 16.0;
  static const radiusMd = 24.0;
  static const radiusLg = 32.0;
  static const radiusPill = 999.0;

  static const maxContentWidth = 720.0;
  static const tabletBreakpoint = 720.0;
  static const desktopBreakpoint = 1100.0;
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(
        brightness: Brightness.light,
        scheme: const ColorScheme.light(
          primary: AppColors.midnight,
          onPrimary: Colors.white,
          primaryContainer: AppColors.lavenderBg,
          onPrimaryContainer: AppColors.midnight,
          secondary: AppColors.moodHappiness,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.moodHappinessBg,
          onSecondaryContainer: AppColors.midnight,
          tertiary: AppColors.moodFear,
          tertiaryContainer: AppColors.moodFearBg,
          surface: AppColors.creamBg,
          onSurface: AppColors.midnight,
          surfaceContainerHighest: AppColors.creamAlt,
          error: AppColors.ewsIntervention,
        ),
        surface: AppColors.creamBg,
        secondaryText: AppColors.warmTextSecondary,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        scheme: const ColorScheme.dark(
          primary: AppColors.lavender,
          onPrimary: AppColors.darkBackground,
          primaryContainer: AppColors.darkSurfaceAlt,
          onPrimaryContainer: AppColors.darkTextPrimary,
          secondary: AppColors.moodHappiness,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextPrimary,
          surfaceContainerHighest: AppColors.darkSurfaceAlt,
          error: AppColors.ewsIntervention,
        ),
        surface: AppColors.darkBackground,
        secondaryText: AppColors.darkTextSecondary,
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required Color surface,
    required Color secondaryText,
  }) {
    // Quicksand untuk Headings & Titles (Playful Cartoon Feel)
    final quicksandText = GoogleFonts.quicksandTextTheme();
    // DM Sans untuk Body & Button (Clean Readable Sans)
    final dmSansText = GoogleFonts.dmSansTextTheme();

    final textTheme = quicksandText.copyWith(
      displayLarge: quicksandText.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        fontSize: 32,
      ),
      displayMedium: quicksandText.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        fontSize: 28,
      ),
      headlineMedium: quicksandText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        fontSize: 24,
        height: 1.25,
      ),
      titleLarge: quicksandText.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        fontSize: 20,
      ),
      titleMedium: quicksandText.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        fontSize: 16,
      ),
      bodyLarge: dmSansText.bodyLarge?.copyWith(
        color: scheme.onSurface,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: dmSansText.bodyMedium?.copyWith(
        color: scheme.onSurface,
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: dmSansText.bodySmall?.copyWith(
        color: secondaryText,
        fontSize: 12,
        height: 1.4,
      ),
      labelLarge: dmSansText.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        letterSpacing: 0.2,
      ),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: textTheme,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? Colors.white
            : AppColors.darkSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.cartoonBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.cartoonBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.midnight, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: scheme.error, width: 2.0),
        ),
        hintStyle: TextStyle(color: secondaryText),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brightness == Brightness.light
            ? AppColors.midnight
            : AppColors.darkSurface,
        indicatorColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shadowColor: AppColors.cartoonShadow,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.midnight,
            );
          }
          return GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.midnight, size: 24);
          }
          return const IconThemeData(color: Colors.white70, size: 24);
        }),
      ),
      cardTheme: CardThemeData(
        color: brightness == Brightness.light
            ? AppColors.cardBg
            : AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: AppColors.cartoonBorder, width: 1.2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.midnight,
        contentTextStyle: GoogleFonts.dmSans(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
    );
  }
}
