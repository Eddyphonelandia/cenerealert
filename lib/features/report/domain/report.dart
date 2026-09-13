// Modello dati di una segnalazione di caduta cenere.
// Rispecchia la tabella "reports" su Postgres/PostGIS.
import 'ash_intensity.dart';

class Report {
  const Report({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.intensity,
    this.gridCell,
    this.createdAt,
    this.decayWeight,
  });

  final String? id;
  final double latitude;
  final double longitude;
  final AshIntensity intensity;
  final String? gridCell;
  final DateTime? createdAt;

  // Peso 0-1 calcolato lato server da report_decay_weight(): quanto la
  // segnalazione "pesa" ancora nella heatmap in base a quanto tempo è
  // passato. Nullo per le segnalazioni appena inviate dal client stesso,
  // che non passano dalla vista pubblica.
  final double? decayWeight;

  // Payload minimo per l'inserimento: la posizione viene inviata come WKT,
  // convertita da Postgres in geography(Point,4326) grazie al cast implicito.
  Map<String, dynamic> toInsertPayload() {
    return {
      'position': 'SRID=4326;POINT($longitude $latitude)',
      'intensity': intensity.dbValue,
    };
  }

  // Usato per interpretare righe lette dalla vista pubblica "reports_public",
  // che espone latitude/longitude come colonne dedicate (mai lo user_id).
  factory Report.fromPublicJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      intensity: ashIntensityFromDbValue(json['intensity'] as int),
      gridCell: json['grid_cell'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      decayWeight: json['decay_weight'] != null
          ? (json['decay_weight'] as num).toDouble()
          : null,
    );
  }
}
