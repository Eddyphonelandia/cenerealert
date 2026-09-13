import 'package:flutter/material.dart';
import 'app_colors.dart';

// Costruisce i due ThemeData (chiaro/scuro) a partire dal design system
// discusso e approvato. Dark mode è il tema di default dell'app.
class AppTheme {
  AppTheme._();

  static const _fontFamily = 'Inter';

  static ThemeData get dark => _buildTheme(
        brightness: Brightness.dark,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        textPrimary: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
      );

  static ThemeData get light => _buildTheme(
        brightness: Brightness.light,
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        textPrimary: AppColors.lightTextPrimary,
        textSecondary: AppColors.lightTextSecondary,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.amberSignal,
      onPrimary: AppColors.darkBackground,
      secondary: AppColors.amberSignal,
      onSecondary: AppColors.darkBackground,
      error: AppColors.intensityIntense,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      background: background,
      onBackground: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: _fontFamily,
      textTheme: TextTheme(
        // Numeri tabulari sempre attivi sui dati (km, orari, conteggi)
        // così le cifre non "ballano" negli aggiornamenti in tempo reale.
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
