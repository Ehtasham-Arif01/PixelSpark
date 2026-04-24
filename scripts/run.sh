#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FRONTEND="$ROOT/frontend"
B='\033[1m'; G='\033[0;32m'; C='\033[0;36m'
Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'

clear
echo -e "${C}"
echo "  ██████╗ ██╗██╗  ██╗███████╗██╗     "
echo "  ██╔══██╗██║╚██╗██╔╝██╔════╝██║     "
echo "  ██████╔╝██║ ╚███╔╝ █████╗  ██║     "
echo "  ██╔═══╝ ██║ ██╔██╗ ██╔══╝  ██║     "
echo "  ██║     ██║██╔╝ ██╗███████╗███████╗"
echo "  ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝"
echo -e "${N}"
echo -e "${B}  PixelSpark — Dev Runner${N}"
echo -e "  ${Y}AI-Powered Offline Image Editor${N}"
echo ""

cd "$FRONTEND"
echo -e "${Y}► Getting dependencies...${N}"
flutter pub get

echo ""
echo -e "${B}Select target:${N}"
echo "  1) Android (USB)"
echo "  2) Chrome  (web)"
echo "  3) Linux   (desktop)"
echo ""
read -rp "  Choice [1-3]: " c

case $c in
1)
  DEVS=$(flutter devices 2>/dev/null | grep -i android || true)
  if [[ -z "$DEVS" ]]; then
    echo -e "${R}No Android device found.${N}"
    echo "  Enable: Settings → Developer Options → USB Debugging"
    exit 1
  fi
  DEV=$(flutter devices 2>/dev/null | grep android | \
    grep -oP '(?<=• )[^ ]+' | head -1)
  echo -e "${G}► Launching on: $DEV${N}"
  flutter run -d "$DEV" --hot
  ;;
2)
  echo -e "${G}► Launching in Chrome...${N}"
  flutter run -d chrome
  ;;
3)
  echo -e "${G}► Launching on Linux...${N}"
  flutter run -d linux
  ;;
*)
  echo -e "${R}Invalid choice${N}"; exit 1 ;;
esac
