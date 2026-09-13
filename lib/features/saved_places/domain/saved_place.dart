// Modello dati di un luogo salvato (casa, lavoro, terreno agricolo, ecc.).
// Rispecchia la tabella "saved_places" (lettura via "saved_places_view").
class SavedPlace {
  const SavedPlace({
    this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.alertRadiusKm,
  });

  final String? id;
  final String label;
  final double latitude;
  final double longitude;
  final double alertRadiusKm;

  // Payload per insert/update sulla tabella base: la posizione viene
  // inviata come WKT, convertita da Postgres in geography(Point,4326).
  Map<String, dynamic> toWritePayload() {
    return {
      'label': label,
      'position': 'SRID=4326;POINT($longitude $latitude)',
      'alert_radius_km': alertRadiusKm,
    };
  }

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: json['id'] as String?,
      label: json['label'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      alertRadiusKm: (json['alert_radius_km'] as num).toDouble(),
    );
  }

  SavedPlace copyWith({
    String? id,
    String? label,
    double? latitude,
    double? longitude,
    double? alertRadiusKm,
  }) {
    return SavedPlace(
      id: id ?? this.id,
      label: label ?? this.label,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      alertRadiusKm: alertRadiusKm ?? this.alertRadiusKm,
    );
  }
}
