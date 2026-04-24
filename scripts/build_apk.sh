#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FRONTEND="$ROOT/frontend"
DESKTOP="$HOME/Desktop"
G='\033[0;32m'; C='\033[0;36m'
Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'

clear
echo -e "${C}╔══════════════════════════════════════╗${N}"
echo -e "${C}║   PixelSpark — APK Builder           ║${N}"
echo -e "${C}╚══════════════════════════════════════╝${N}"
echo ""

# Check flutter
command -v flutter &>/dev/null || {
  echo -e "${R}Flutter not found in PATH${N}"; exit 1; }

cd "$FRONTEND"

echo -e "${Y}[1/5] Cleaning...${N}"
flutter clean

echo -e "${Y}[2/5] Repairing pub cache...${N}"
flutter pub cache repair 2>/dev/null || true

echo -e "${Y}[3/5] Getting dependencies...${N}"
flutter pub get

echo -e "${Y}[4/5] Generating launcher icons...${N}"
dart run tools/generate_icon.dart 2>/dev/null || \
  echo -e "${Y}      Icon script failed, skipping...${N}"
flutter pub run flutter_launcher_icons 2>/dev/null || \
  echo -e "${Y}      Icon generation skipped${N}"

echo -e "${Y}[5/5] Building release APK...${N}"
flutter build apk --release \
  --target-platform android-arm64,android-arm

APK="$FRONTEND/build/app/outputs/flutter-apk/app-release.apk"

if [[ ! -f "$APK" ]]; then
  echo -e "${R}Build failed — APK not found${N}"
  exit 1
fi

# Copy to Desktop
DEST="$DESKTOP/PixelSpark.apk"
cp "$APK" "$DEST"
SIZE=$(du -sh "$DEST" | cut -f1)

echo ""
echo -e "${G}╔══════════════════════════════════════╗${N}"
echo -e "${G}║        BUILD SUCCESSFUL ✓            ║${N}"
echo -e "${G}╚══════════════════════════════════════╝${N}"
echo ""
echo -e "  APK saved to: ${G}$DEST${N}"
echo -e "  Size: ${C}$SIZE${N}"
echo ""
echo -e "${Y}Install on device:${N}"
echo "  adb install $DEST"
echo ""
