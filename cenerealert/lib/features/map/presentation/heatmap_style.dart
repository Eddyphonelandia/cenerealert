import 'package:maplibre_gl/maplibre_gl.dart';

// Definisce l'aspetto del layer heatmap in stile MapLibre (style spec v8),
// riusando la stessa scala di colori del design system (ambra tenue ->
// arancio terra -> rosso ossido) così la mappa parla lo stesso linguaggio
// visivo del resto dell'app. Le espressioni sono scritte come liste grezze
// secondo la style spec, per non dipendere da eventuali helper di più alto
// livello che potrebbero differire tra versioni del pacchetto.
class HeatmapStyle {
  HeatmapStyle._();

  static const sourceId = 'reports-source';
  static const layerId = 'reports-heatmap-layer';

  static const layerProperties = HeatmapLayerProperties(
    heatmapWeight: [
      'interpolate',
      ['linear'],
      ['get', 'weight'],
      0, 0,
      1, 1,
    ],
    heatmapIntensity: [
      'interpolate',
      ['linear'],
      ['zoom'],
      8, 1,
      14, 3,
    ],
    heatmapColor: [
      'interpolate',
      ['linear'],
      ['heatmap-density'],
      0, 'rgba(11,13,15,0)',
      0.2, '#E8C77A',
      0.5, '#D9822B',
      1, '#B8452F',
    ],
    heatmapRadius: [
      'interpolate',
      ['linear'],
      ['zoom'],
      8, 14,
      14, 34,
    ],
    heatmapOpacity: 0.85,
  );
}
