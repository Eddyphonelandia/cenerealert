import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Disclaimer sempre visibile, come da vincolo non negoziabile del brief:
// CenereAlert è un servizio informativo collaborativo, non sostituisce
// la Protezione Civile né l'INGV. Testo compatto e a bassa enfasi per non
// rompere il mood "strumento scientifico elegante" con un banner
// allarmistico — ma sempre presente, mai dietro un menu o una modale.
class DisclaimerBar extends StatelessWidget {
  const DisclaimerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: AppColors.darkBackground,
      child: const Text(
        'Servizio informativo collaborativo — non sostituisce Protezione Civile e INGV',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, color: AppColors.darkTextTertiary),
      ),
    );
  }
}
