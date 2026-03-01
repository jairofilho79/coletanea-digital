#!/bin/bash
# Flutter run (release) para macOS apontando para as APIs na VPS (produção).
# Uso: ./dev-vps-macos.sh
#
# Portas conforme Docker na VPS:
#   - coldigom backend: docker-compose.prod.yml → "${API_PORT:-8000}:8000"
#   - coletanea backend: docker-compose.prod.yml → "${API_PORT:-8001}:8001"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_APP_DIR="${SCRIPT_DIR}/frontend"
VPS_IP="${VPS_IP:-129.121.44.196}"
COLDIGOM_PORT="${COLDIGOM_API_PORT:-8000}"
COLETANEA_PORT="${COLETANEA_API_PORT:-8001}"

COLDIGOM_URL="http://${VPS_IP}:${COLDIGOM_PORT}"
COLETANEA_URL="http://${VPS_IP}:${COLETANEA_PORT}"

if [ ! -d "$FLUTTER_APP_DIR" ] || [ ! -f "$FLUTTER_APP_DIR/pubspec.yaml" ]; then
    echo "❌ Diretório do app Flutter não encontrado: $FLUTTER_APP_DIR"
    exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
    echo "❌ Flutter não encontrado no PATH."
    exit 1
fi

echo "🚀 Flutter (release) macOS → VPS (prod)"
echo "   Coldigom API:  $COLDIGOM_URL"
echo "   Coletânea API: $COLETANEA_URL"
echo ""

cd "$FLUTTER_APP_DIR"
flutter run --release -d macos \
  --dart-define=COLDIGOM_API_BASE_URL="$COLDIGOM_URL" \
  --dart-define=COLETANEA_API_BASE_URL="$COLETANEA_URL"
