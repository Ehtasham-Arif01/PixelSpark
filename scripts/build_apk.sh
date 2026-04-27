#!/bin/bash

# PixelSpark Production APK Builder
# Full Audit & Ship Pass

# ── Colors ────────────────────────────────────────────────────────────────────
NAVY='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# ── Header ────────────────────────────────────────────────────────────────────
clear
echo -e "${PURPLE}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}${BOLD}║                PIXELSPARK — PRODUCTION BUILD                 ║${NC}"
echo -e "${PURPLE}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── Environment ───────────────────────────────────────────────────────────────
if [ -d "/opt/android-studio/jbr" ]; then
    export JAVA_HOME="/opt/android-studio/jbr"
    export PATH="$JAVA_HOME/bin:$PATH"
fi

# ── Check Directory ───────────────────────────────────────────────────────────
if [ ! -d "frontend" ]; then
    echo -e "${RED}${BOLD}✖ Error:${NC} Could not find 'frontend' directory."
    exit 1
fi

cd frontend || exit

# ── 1. Icon Generation ────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[1/5]${NC} Generating High-Res Assets..."
dart run tools/generate_icon.dart
flutter pub run flutter_launcher_icons
echo -e "${GREEN}✓ Icons generated successfully.${NC}"

# ── 2. Dependencies ───────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[2/5]${NC} Cleaning & Fetching Dependencies..."
flutter clean > /dev/null

# Python requirements (if pip is available)
if [ -f "../requirements.txt" ] && command -v pip &> /dev/null; then
    echo -e "${YELLOW}ℹ Installing system requirements...${NC}"
    pip install -r ../requirements.txt > /dev/null 2>&1
fi

flutter pub get > /dev/null
echo -e "${GREEN}✓ Workspace cleaned and ready.${NC}"

# ── 3. Code Quality ───────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[3/5]${NC} Performing Code Audit..."
if ! flutter analyze --no-fatal-infos --no-fatal-warnings; then
    echo -e "${RED}✖ Code analysis failed.${NC} Fix issues before building for production."
    exit 1
fi
echo -e "${GREEN}✓ Audit passed.${NC}"

# ── 4. Build ──────────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[4/5]${NC} Compiling Release APK..."
echo -e "${YELLOW}ℹ This may take a few minutes. MIRNet weights are large.${NC}"

if flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols; then
    echo -e "${GREEN}${BOLD}✓ Build successful!${NC}"
else
    echo -e "${RED}${BOLD}✖ Build failed.${NC}"
    exit 1
fi

# ── 5. Deployment ─────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}[5/5]${NC} Deploying Artifacts..."

APK_SRC="build/app/outputs/flutter-apk/app-release.apk"
APK_DEST="$HOME/Desktop/PixelSpark_Production.apk"

if [ -f "$APK_SRC" ]; then
    cp "$APK_SRC" "$APK_DEST"
    echo -e "${PURPLE}${BOLD}✨ SHIPPED!${NC}"
    echo -e "   APK Location: ${YELLOW}$APK_DEST${NC}"
    echo -e "   Size: ${BOLD}$(du -h "$APK_DEST" | cut -f1)${NC}"
else
    echo -e "${RED}✖ Could not find output APK.${NC}"
    exit 1
fi

echo ""
echo -e "${PURPLE}PixelSpark is ready for distribution.${NC}"
