import 'package:flutter/material.dart';

// Un singolo elemento della checklist "Cosa fare adesso": icona lineare,
// titolo breve, descrizione. Niente colori diversi per elemento — la
// gerarchia visiva viene dallo stato spuntato/non spuntato, non dal
// contenuto, coerente col mood "strumento scientifico" del design system.
class ChecklistItem {
  const ChecklistItem({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}
