# Changelog

All notable changes to AudioPilote.
Format based on [Keep a Changelog](https://keepachangelog.com/),
versioning follows [SemVer](https://semver.org/).

## [0.2.2] - 2026-06-16

### Added

- English and French localization, following the macOS system language

## [0.2.1] - 2026-06-16

### Added

- Application icon (Finder, Launchpad, Spotlight)

## [0.2.0] - 2026-06-15

### Added

- Context-aware volume slider (output volume, input gain)
- Real-time input level meter, triggered per input by a button
- Right-click menu on the menu-bar icon (Quit)
- Help and contact link to hugo-thiphaine.fr in the header
- Restyle inspired by Liquid Glass (translucent materials, default-device highlight)
- "dev" badge when the app is not running from the Applications folder

### Fixed

- Filtered out noise devices (no name, name equal to the UID, system aggregates)
- Smoother level meter (60 fps display, no more half-second lag)
- List scrolls back to the top when switching tabs

## [0.1.0] - 2026-06-15

First release (MVP).

### Added

- Menu-bar app (NSStatusItem + SwiftUI popover), no Dock icon
- Input and Output tabs
- Drag-to-reorder list defining the priority order
- Auto-switch to the highest-priority available device, independently enabled
  for input and output
- Cascading fallback on disconnect, following the priority order
- Manual switch on click (promote to top when auto-switch is on)
- Offline devices remembered and shown greyed out
- Launch at login via SMAppService
- Persistence of order and settings (UserDefaults)
- Build without Xcode (Swift Package Manager + Command Line Tools), ad-hoc signing
