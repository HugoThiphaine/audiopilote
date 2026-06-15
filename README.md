# AudioPilote

Petit utilitaire macOS de barre de menus qui gère l'ordre de priorité de tes
périphériques audio (entrée et sortie) et bascule automatiquement vers le
périphérique disponible le plus prioritaire.

Tu classes tes périphériques par glisser-déposer. AudioPilote force le premier
disponible de la liste comme périphérique par défaut, et redescend tout seul au
suivant quand l'actif se déconnecte.

## Fonctionnalités

- Onglets Entrée et Sortie
- Liste réordonnable par glisser-déposer : c'est ton ordre de priorité
- Bascule automatique vers le périphérique disponible le plus prioritaire
- Auto-switch activable indépendamment pour l'entrée et pour la sortie
- Fallback en cascade : quand l'actif se déconnecte, le suivant dispo prend le relais
- Bascule manuelle au clic (avec l'auto-switch actif, le clic promeut le périphérique en tête)
- Périphériques hors-ligne mémorisés et affichés grisés à leur rang
- Lancement au démarrage (optionnel)
- 100 % local : aucune télémétrie, aucun compte, gratuit

## Installation

**[Télécharger la dernière version (AudioPilote.zip)](https://github.com/HugoThiphaine/audiopilote/releases/latest/download/AudioPilote.zip)**

Attention : n'utilise pas le bouton vert « Code › Download ZIP » en haut de la
page. Celui-là télécharge le code source (Package.swift, build.sh...), pas
l'application. Pour l'app prête à l'emploi, passe par le lien ci-dessus ou par
l'onglet [Releases](../../releases).

Ensuite :

1. Décompresse `AudioPilote.zip` (double-clic).
2. Glisse `AudioPilote.app` dans ton dossier `Applications`.
3. **Premier lancement** : clic droit sur `AudioPilote.app` puis `Ouvrir`, et
   confirme (l'app n'est pas notarisée par Apple, c'est normal). macOS ne le
   redemandera plus.

L'icône apparaît dans la barre de menus (en haut à droite). Pas d'icône dans le
Dock, c'est voulu.

## Compiler depuis la source

Besoin uniquement des Command Line Tools d'Apple (`xcode-select --install`),
pas de Xcode complet.

```sh
git clone https://github.com/HugoThiphaine/audiopilote.git
cd audiopilote
./build.sh
open ./AudioPilote.app
```

`build.sh` compile en release, assemble le `.app` et le signe en ad-hoc pour un
usage local.

## Comment ça marche

AudioPilote lit et écrit le périphérique par défaut via CoreAudio (HAL) et
écoute les branchements/débranchements. L'ordre de priorité est mémorisé par
UID (clé stable), donc il survit aux rebranchements. Avec l'auto-switch actif
pour un mode, AudioPilote impose en continu le périphérique disponible le plus
haut de la liste de ce mode.

Cible : macOS 13 ou plus récent.

## Crédits

Inspiré par [SoundAnchor](https://apps.kopiro.me/soundanchor) de Flavio De
Stefano. AudioPilote en est une réécriture indépendante, à partir des seules API
publiques d'Apple (CoreAudio, SwiftUI, ServiceManagement). Aucun code ni asset
de SoundAnchor n'a été repris.

## Auteur

Hugo Thiphaine, web designer et consultant SEO. Aide et contact :
[hugo-thiphaine.fr](https://hugo-thiphaine.fr).

## Licence

[MIT](LICENSE)
