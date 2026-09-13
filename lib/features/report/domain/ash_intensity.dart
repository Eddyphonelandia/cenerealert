// Rappresenta i tre livelli di intensità di caduta cenere segnalabili
// dall'utente. I nomi restano in inglese per coerenza col resto del
// codice; le etichette mostrate all'utente sono in italiano e vengono
// esposte tramite l'extension sottostante.
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum AshIntensity { light, moderate, intense }

extension AshIntensityX on AshIntensity {
  // Valore numerico salvato lato database (colonna "intensity", smallint 1-3).
  int get dbValue {
    switch (this) {
      case AshIntensity.light:
        return 1;
      case AshIntensity.moderate:
        return 2;
      case AshIntensity.intense:
        return 3;
    }
  }

  // Etichetta mostrata nell'interfaccia utente.
  String get label {
    switch (this) {
      case AshIntensity.light:
        return 'Leggera';
      case AshIntensity.moderate:
        return 'Moderata';
      case AshIntensity.intense:
        return 'Intensa';
    }
  }

  // Colore associato secondo la scala del design system
  // (ambra tenue -> arancio terra -> rosso ossido).
  Color get color {
    switch (this) {
      case AshIntensity.light:
        return AppColors.intensityLight;
      case AshIntensity.moderate:
        return AppColors.intensityModerate;
      case AshIntensity.intense:
        return AppColors.intensityIntense;
    }
  }
}

AshIntensity ashIntensityFromDbValue(int value) {
  switch (value) {
    case 1:
      return AshIntensity.light;
    case 2:
      return AshIntensity.moderate;
    case 3:
      return AshIntensity.intense;
    default:
      throw ArgumentError('Valore di intensità non valido: $value');
  }
}
