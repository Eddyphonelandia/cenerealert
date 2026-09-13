// Rappresenta l'ultimo comunicato VONA/INGV in cache, alimentato dalla
// Edge Function di scraping "fetch-vona-feed".
class VonaFeedEntry {
  const VonaFeedEntry({
    required this.volcano,
    required this.simplifiedText,
    required this.pdfUrl,
    required this.receivedAt,
    required this.eventStatus,
    required this.parsingSucceeded,
  });

  final String volcano;
  final String simplifiedText;
  final String? pdfUrl;
  final DateTime receivedAt;
  final String eventStatus; // started | ongoing | ended | unknown
  final bool parsingSucceeded;

  factory VonaFeedEntry.fromJson(Map<String, dynamic> json) {
    return VonaFeedEntry(
      volcano: json['volcano'] as String? ?? 'ETNA',
      simplifiedText:
          json['simplified_text'] as String? ?? "Nuovo comunicato dell'INGV.",
      pdfUrl: json['pdf_url'] as String?,
      receivedAt: DateTime.parse(json['received_at'] as String),
      eventStatus: json['event_status'] as String? ?? 'unknown',
      parsingSucceeded: json['parsing_succeeded'] as bool? ?? true,
    );
  }
}
