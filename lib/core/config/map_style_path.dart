import 'package:flutter/foundation.dart' show kIsWeb;

// Percorso dello stile MapLibre: cambia in base alla piattaforma perchÃ©
// "asset://" Ã¨ un'estensione che solo il plugin nativo (Android/iOS)
// intercetta per leggere dal bundle asset di Flutter. Sul web quel
// prefisso non esiste: maplibre-gl-js si aspetta un URL vero e proprio,
// quindi serviamo lo stesso file come asset web grezzo (cartella web/,
// non assets/) con un percorso RELATIVO â€” funziona indipendentemente
// dal --base-href usato in fase di build, perchÃ© si risolve rispetto
// alla pagina corrente.
const String mapStylePath = kIsWeb
    ? 'map_style/dark_style.json'
    : 'asset://assets/map_style/dark_style.json';
