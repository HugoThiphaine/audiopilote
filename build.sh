#!/bin/bash
# Compile AudioPilote en release, assemble le bundle .app et le signe en ad-hoc.
# Usage : ./build.sh [chemin/sortie/AudioPilote.app]
# Par défaut, produit ./AudioPilote.app à côté du script.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP="${1:-$DIR/AudioPilote.app}"
NAME="AudioPilote"
BUNDLE_ID="fr.thiphaine.audiopilote"
VERSION="0.3.0"
BUILD="6"

echo "==> swift build -c release"
swift build --package-path "$DIR" -c release

BIN="$DIR/.build/release/$NAME"
if [[ ! -f "$BIN" ]]; then
  echo "Binaire introuvable : $BIN" >&2
  exit 1
fi

echo "==> Assemblage de $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$NAME"

# Icône d'app : génère AppIcon.icns depuis AppIcon.png (1024 px) si présent.
if [[ -f "$DIR/AppIcon.png" ]]; then
  ICONSET="$DIR/.build/AppIcon.iconset"
  rm -rf "$ICONSET"; mkdir -p "$ICONSET"
  for sz in 16 32 128 256 512; do
    sips -z "$sz" "$sz" "$DIR/AppIcon.png" --out "$ICONSET/icon_${sz}x${sz}.png" >/dev/null
    sips -z "$((sz * 2))" "$((sz * 2))" "$DIR/AppIcon.png" --out "$ICONSET/icon_${sz}x${sz}@2x.png" >/dev/null
  done
  iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
  echo "==> Icône AppIcon.icns générée"
fi

# Localisations : copie des .lproj (anglais par défaut + français) dans le bundle.
if [[ -d "$DIR/Resources" ]]; then
  cp -R "$DIR/Resources/"*.lproj "$APP/Contents/Resources/" 2>/dev/null || true
  echo "==> Localisations copiées"
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>$NAME</string>
    <key>CFBundleDisplayName</key>     <string>$NAME</string>
    <key>CFBundleIdentifier</key>      <string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key>      <string>$NAME</string>
    <key>CFBundleIconFile</key>        <string>AppIcon</string>
    <key>CFBundleDevelopmentRegion</key> <string>en</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleVersion</key>         <string>$BUILD</string>
    <key>CFBundleShortVersionString</key> <string>$VERSION</string>
    <key>CFBundleInfoDictionaryVersion</key> <string>6.0</string>
    <key>LSMinimumSystemVersion</key>  <string>13.0</string>
    <key>LSUIElement</key>             <true/>
    <key>NSMicrophoneUsageDescription</key> <string>AudioPilote affiche le niveau d'entrée en temps réel.</string>
    <key>NSPrincipalClass</key>        <string>NSApplication</string>
    <key>NSHighResolutionCapable</key> <true/>
</dict>
</plist>
PLIST

echo "==> plutil -lint"
plutil -lint "$APP/Contents/Info.plist"

echo "==> codesign ad-hoc"
codesign --force --sign - "$APP"
codesign --verify --verbose "$APP"

echo "==> OK : $APP"
