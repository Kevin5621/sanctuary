import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Jarak & radius standar. Dipakai seluruh widget agar ritme visual konsisten.
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

  /// Lebar konten maksimum pada layar lebar (tablet/desktop) supaya baris teks
  /// tidak terlalu panjang untuk dibaca.
  static const maxContentWidth = 720.0;
  static const tabletBreakpoint = 720.0;
  static const desktopBreakpoint = 1100.0;
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(
        brightness: Brightness.light,
        scheme: const ColorScheme.light(
          primary: AppColors.sage,
          onPrimary: Colors.white,
          primaryContainer: AppColors.sageLight,
          onPrimaryContainer: AppColors.sageDark,
          secondary: AppColors.lavender,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.lavenderLight,
          onSecondaryContainer: AppColors.lavenderDark,
          tertiary: AppColors.calmingBlue,
          tertiaryContainer: AppColors.calmingBlueLight,
          surface: AppColors.cream,
          onSurface: AppColors.warmGreyDark,
          surfaceContainerHighest: AppColors.creamAlt,
          error: AppColors.ewsIntervention,
        ),
        surface: AppColors.cream,
        secondaryText: AppColors.warmGrey,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        scheme: const ColorScheme.dark(
          primary: AppColors.sage,
          onPrimary: Color(0xFF14200F),
          primaryContainer: AppColors.sageDark,
          onPrimaryContainer: AppColors.sageLight,
          secondary: AppColors.lavender,
          onSecondary: Color(0xFF1A1424),
          secondaryContainer: AppColors.lavenderDark,
          onSecondaryContainer: AppColors.lavenderLight,
          tertiary: AppColors.calmingBlue,
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
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      fontFamily: 'Nunito', // fallback ke font sistem bila belum ditambahkan
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      textTheme: base.textTheme
          .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
          .copyWith(
            headlineMedium: base.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
            titleMedium: base.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.5),
            bodySmall: base.textTheme.bodySmall?.copyWith(
              color: secondaryText,
              height: 1.45,
            ),
          ),
      // Bidang input mengikuti bahasa clay: tanpa garis tegas, latar lembut.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? AppColors.creamAlt
            : AppColors.darkSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        hintStyle: TextStyle(color: secondaryText),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brightness == Brightness.light
            ? AppColors.cream
            : AppColors.darkSurface,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: brightness == Brightness.light
            ? AppColors.cream
            : AppColors.darkSurface,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface,
        contentTextStyle: TextStyle(color: scheme.surface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.onSurface.withValues(alpha: 0.08),
        thickness: 1,
      ),
    );
  }
}
