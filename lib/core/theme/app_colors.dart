import 'package:flutter/material.dart';

// Palette definita dal design system di CenereAlert.
// Mood: "strumento scientifico elegante" — nessun rosso da allarme
// antincendio, nessun colore usato come unico veicolo di informazione
// (vedi IntensityGlyph per la codifica ridondante forma+colore).
class AppColors {
  AppColors._();

  // --- Dark mode (tema di default) ---
  static const darkBackground = Color(0xFF0B0D0F);
  static const darkSurface = Color(0xFF15181C);
  static const darkSurfaceElevated = Color(0xFF1E2227);
  static const darkBorder = Color(0xFF2A2F35);
  static const darkTextPrimary = Color(0xFFF2EEE9);
  static const darkTextSecondary = Color(0xFF9A9690);
  static const darkTextTertiary = Color(0xFF5C5954);

  // --- Light mode ---
  static const lightBackground = Color(0xFFF7F5F2);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightTextPrimary = Color(0xFF15181C);
  static const lightTextSecondary = Color(0xFF5C5954);

  // --- Accento neutro di brand ---
  static const amberSignal = Color(0xFFD9A441);

  // --- Scala intensità (identica in dark e light mode) ---
  static const intensityLight = Color(0xFFE8C77A);
  static const intensityModerate = Color(0xFFD9822B);
  static const intensityIntense = Color(0xFFB8452F);
}
