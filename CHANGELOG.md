# Changelog

Toutes les versions notables de AudioPilote.
Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/),
versionnage [SemVer](https://semver.org/lang/fr/).

## [0.2.0] - 2026-06-15

### Ajouté

- Slider de volume contextuel (volume de sortie, gain d'entrée)
- VU-mètre d'entrée en temps réel, déclenché par un bouton sur chaque entrée
- Menu au clic droit sur l'icône de barre de menus (Quitter)
- Lien d'aide et contact vers hugo-thiphaine.fr dans l'en-tête
- Restyle inspiré de Liquid Glass (matériaux translucides, surbrillance du défaut)
- Badge « dev » quand l'app ne tourne pas depuis le dossier Applications

### Corrigé

- Périphériques parasites filtrés (sans nom, nom égal à l'UID, agrégats système)
- VU-mètre fluidifié (affichage 60 images/s, fini la latence d'une demi-seconde)
- Liste qui repart du haut au changement d'onglet

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
