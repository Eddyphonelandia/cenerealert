// Rispecchia la tabella "user_reputation". Sola lettura dal client: gli
// aggiornamenti avvengono esclusivamente lato server, nei trigger
// collegati all'invio di segnalazioni e alla validazione dei cluster.
class UserReputation {
  const UserReputation({
    required this.score,
    required this.totalReports,
    required this.confirmedReports,
  });

  final double score;
  final int totalReports;
  final int confirmedReports;

  factory UserReputation.fromJson(Map<String, dynamic> json) {
    return UserReputation(
      score: (json['score'] as num).toDouble(),
      totalReports: json['total_reports'] as int,
      confirmedReports: json['confirmed_reports'] as int,
    );
  }
}
