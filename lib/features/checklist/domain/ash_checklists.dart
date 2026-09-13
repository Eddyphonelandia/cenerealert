import 'package:flutter/material.dart';

import '../../report/domain/ash_intensity.dart';
import 'checklist_item.dart';

// Contenuto e ordine della checklist cambiano in base all'intensità
// rilevata nella zona dell'utente (requisito esplicito del design
// system). Le liste sono progressive: ogni livello include le
// precauzioni del livello precedente, più le proprie — non liste
// completamente diverse, perché le precauzioni per la cenere leggera
// restano valide anche quando la caduta si intensifica.
List<ChecklistItem> checklistFor(AshIntensity? intensity) {
  if (intensity == null) return const [];

  const base = [
    ChecklistItem(
      title: 'Chiudi le finestre',
      description:
          "Tieni chiuse finestre e prese d'aria per evitare che la cenere entri in casa.",
      icon: Icons.window_outlined,
    ),
    ChecklistItem(
      title: 'Evita le due ruote',
      description:
          "La cenere sull'asfalto riduce l'aderenza: evita moto, scooter e bici finché non è stata rimossa.",
      icon: Icons.two_wheeler_outlined,
    ),
    ChecklistItem(
      title: "Copri l'auto, se puoi",
      description:
          'Un telo protegge la carrozzeria e il parabrezza dai graffi della cenere, che è abrasiva.',
      icon: Icons.directions_car_outlined,
    ),
  ];

  if (intensity == AshIntensity.light) return base;

  const moderateExtra = [
    ChecklistItem(
      title: 'Raccogli la cenere in sacchi trasparenti',
      description:
          'Tienila separata dagli altri rifiuti: molti comuni la ritirano a parte, in sacchi trasparenti.',
      icon: Icons.delete_outline,
    ),
    ChecklistItem(
      title: "Limita l'attività fisica all'aperto",
      description:
          'Respirare cenere fine per periodi prolungati può irritare le vie respiratorie.',
      icon: Icons.directions_run_outlined,
    ),
  ];

  if (intensity == AshIntensity.moderate) return [...base, ...moderateExtra];

  const intenseExtra = [
    ChecklistItem(
      title: 'Esci solo se necessario',
      description:
          'Con cadute intense, la visibilità e la qualità dell\'aria peggiorano sensibilmente.',
      icon: Icons.home_outlined,
    ),
    ChecklistItem(
      title: 'Usa una mascherina se esci',
      description:
          "Una mascherina, anche chirurgica, riduce l'inalazione delle particelle più fini.",
      icon: Icons.masks_outlined,
    ),
    ChecklistItem(
      title: "Non pulire i vetri dell'auto a secco",
      description:
          'La cenere è abrasiva: bagna sempre la superficie prima di rimuoverla, per non graffiare.',
      icon: Icons.cleaning_services_outlined,
    ),
  ];

  return [...base, ...moderateExtra, ...intenseExtra];
}
