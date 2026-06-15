# Changelog

Toutes les versions notables de AudioPilote.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/),
versionnage [SemVer](https://semver.org/lang/fr/).

## [0.1.0] - 2026-06-15

Première version (MVP).

### Ajouté

- App de barre de menus (NSStatusItem + popover SwiftUI), sans icône Dock
- Onglets Entrée et Sortie
- Liste réordonnable par glisser-déposer définissant l'ordre de priorité
- Auto-switch vers le périphérique disponible le plus prioritaire, activable
  indépendamment pour l'entrée et pour la sortie
- Fallback en cascade au débranchement, selon l'ordre de priorité
- Bascule manuelle au clic (promotion en tête quand l'auto-switch est actif)
- Périphériques hors-ligne mémorisés et affichés grisés
- Lancement au démarrage via SMAppService
- Persistance de l'ordre et des réglages (UserDefaults)
- Build sans Xcode (Swift Package Manager + Command Line Tools), signature ad-hoc
