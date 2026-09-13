import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../report/domain/ash_intensity.dart';
import '../../report/domain/report.dart';
import '../application/reports_feed_providers.dart';
import 'heatmap_style.dart';
import 'map_skeleton_loader.dart';

// Etna, cratere sommitale: punto di partenza della camera.
const _etnaCenter = LatLng(37.7510, 14.9934);

// Mostra la heatmap live delle segnalazioni su base MapLibre. Lo stile di
// base (raster scuro) è statico e caricato da asset; il layer heatmap
// viene aggiunto a runtime e i suoi dati aggiornati quando arriva un nuovo
// fetch dal feed o quando l'utente cambia il filtro temporale.
//
// Nota: "myLocationEnabled" resta disattivato di proposito — guardare la
// mappa non deve richiedere il permesso di geolocalizzazione, che viene
// chiesto solo al momento di una segnalazione (consenso granulare, GDPR).
class LiveMap extends ConsumerStatefulWidget {
  const LiveMap({super.key});

  @override
  ConsumerState<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends ConsumerState<LiveMap> {
  MaplibreMapController? _controller;
  bool _styleReady = false;
  bool _layerAdded = false;

  Future<void> _onStyleLoaded() async {
    _styleReady = true;
    await _pushCurrentData();
  }

  // Aggiorna i dati della heatmap rimuovendo e ricreando layer e sorgente.
  // Non esiste (in questa versione del pacchetto) un metodo dedicato per
  // aggiornare solo i dati di una sorgente GeoJSON già esistente, quindi
  // usiamo solo le operazioni base (remove/add), certamente disponibili.
  // Costo: un breve lampeggio della heatmap ad ogni aggiornamento — un
  // compromesso accettabile rispetto al rischio di un nome di metodo
  // sbagliato non verificabile in questo ambiente.
  Future<void> _pushCurrentData() async {
    final controller = _controller;
    if (controller == null || !_styleReady) return;

    final reports = ref.read(filteredReportsProvider);
    final geojson = _toFeatureCollection(reports);

    if (_layerAdded) {
      await controller.removeLayer(HeatmapStyle.layerId);
      await controller.removeSource(HeatmapStyle.sourceId);
    }

    await controller.addSource(
      HeatmapStyle.sourceId,
      GeojsonSourceProperties(data: geojson),
    );
    await controller.addLayer(
      HeatmapStyle.sourceId,
      HeatmapStyle.layerId,
      HeatmapStyle.layerProperties,
    );
    _layerAdded = true;
  }

  Map<String, dynamic> _toFeatureCollection(List<Report> reports) {
    return {
      'type': 'FeatureCollection',
      'features': [
        for (final report in reports)
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [report.longitude, report.latitude],
            },
            'properties': {
              'weight': report.decayWeight ?? 1.0,
              'intensity': report.intensity.dbValue,
            },
          },
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    // Ogni volta che la lista filtrata cambia (nuovo fetch periodico o
    // nuovo filtro temporale scelto dall'utente) aggiorniamo la sorgente
    // GeoJSON del layer heatmap, con una breve dissolvenza del loader a
    // fare da transizione percepita (vedi MapSkeletonLoader).
    ref.listen(filteredReportsProvider, (previous, next) => _pushCurrentData());

    final feedState = ref.watch(reportsFeedProvider);
    final isFirstLoad = feedState.isLoading && feedState.valueOrNull == null;

    return Stack(
      fit: StackFit.expand,
      children: [
        MaplibreMap(
          styleString: 'asset://assets/map_style/dark_style.json',
          initialCameraPosition: const CameraPosition(
            target: _etnaCenter,
            zoom: 10,
          ),
          onMapCreated: (controller) => _controller = controller,
          onStyleLoadedCallback: _onStyleLoaded,
          myLocationEnabled: false,
          compassEnabled: false,
        ),
        AnimatedOpacity(
          opacity: isFirstLoad ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: const MapSkeletonLoader(),
        ),
      ],
    );
  }
}
