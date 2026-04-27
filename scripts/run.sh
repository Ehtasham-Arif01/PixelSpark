#!/bin/bash

# PixelSpark Development Runner
# Premium CLI Experience

# ── Colors ────────────────────────────────────────────────────────────────────
CYAN='\033[0;36m'
NAVY='\033[0;34m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Header ────────────────────────────────────────────────────────────────────
clear
echo -e "${NAVY}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${NAVY}${BOLD}║                PIXELSPARK — DEVELOPMENT RUNER                ║${NC}"
echo -e "${NAVY}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── Environment ───────────────────────────────────────────────────────────────
if [ -d "/opt/android-studio/jbr" ]; then
    export JAVA_HOME="/opt/android-studio/jbr"
    export PATH="$JAVA_HOME/bin:$PATH"
fi

# ── Check Directory ───────────────────────────────────────────────────────────
if [ ! -d "frontend" ]; then
    echo -e "${RED}${BOLD}✖ Error:${NC} Could not find 'frontend' directory."
    echo -e "  Please run this script from the project root."
    exit 1
fi

cd frontend || exit

# ── Icon Generation ───────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}⚡ Checking Assets...${NC}"
if [ ! -f "assets/icon/app_icon.png" ]; then
    echo -e "${YELLOW}ℹ App icon missing. Generating programmatically...${NC}"
    dart run tools/generate_icon.dart
    flutter pub run flutter_launcher_icons
fi

# ── Dependencies ──────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}📦 Checking Dependencies...${NC}"

# Python requirements (if pip is available)
if [ -f "../requirements.txt" ] && command -v pip &> /dev/null; then
    echo -e "${YELLOW}ℹ Installing system requirements...${NC}"
    pip install -r ../requirements.txt > /dev/null 2>&1
fi

flutter pub get > /dev/null
echo -e "${GREEN}✓ Dependencies up to date.${NC}"

# ── Analyze ───────────────────────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}🔍 Analyzing Code...${NC}"
if ! flutter analyze --no-fatal-infos --no-fatal-warnings; then
    echo -e "${RED}⚠ Analysis found issues. Continuing anyway...${NC}"
else
    echo -e "${GREEN}✓ Code analysis passed.${NC}"
fi

# ── Device Selection ──────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Select Target Device:${NC}"
devices=$(flutter devices | grep "•" | grep -v "flutter-tester")

if [ -z "$devices" ]; then
    echo -e "${RED}✖ No devices found.${NC} Please connect a device or start an emulator."
    exit 1
fi

i=1
while read -r line; do
    echo -e "  ${PURPLE}[$i]${NC} $line"
    ((i++))
done <<< "$devices"

echo ""
echo -n -e "${BOLD}Choice [1]: ${NC}"
read choice
choice=${choice:-1}

device_id=$(echo "$devices" | sed -n "${choice}p" | awk -F ' • ' '{print $2}')

if [ -z "$device_id" ]; then
    echo -e "${RED}✖ Invalid selection.${NC}"
    exit 1
fi

# ── Run ───────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}🚀 Launching PixelSpark on ${device_id}...${NC}"
echo -e "${CYAN}------------------------------------------------------------${NC}"
flutter run -d "$device_id"
