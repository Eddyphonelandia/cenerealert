// Le quattro finestre temporali selezionabili per la heatmap, come da
// requisito "filtro 1h/3h/6h/24h".
enum TimeFilter { oneHour, threeHours, sixHours, twentyFourHours }

extension TimeFilterX on TimeFilter {
  Duration get duration {
    switch (this) {
      case TimeFilter.oneHour:
        return const Duration(hours: 1);
      case TimeFilter.threeHours:
        return const Duration(hours: 3);
      case TimeFilter.sixHours:
        return const Duration(hours: 6);
      case TimeFilter.twentyFourHours:
        return const Duration(hours: 24);
    }
  }

  String get label {
    switch (this) {
      case TimeFilter.oneHour:
        return '1h';
      case TimeFilter.threeHours:
        return '3h';
      case TimeFilter.sixHours:
        return '6h';
      case TimeFilter.twentyFourHours:
        return '24h';
    }
  }
}
