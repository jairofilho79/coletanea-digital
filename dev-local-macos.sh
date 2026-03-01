#!/bin/bash
# Flutter run (release) para macOS apontando para os backends locais.
# Uso: ./dev-local-macos.sh
#
# Requer coldigom e coletanea-digital rodando localmente (Docker).
# Portas: coldigom 8000, coletanea 8001 (conforme docker-compose).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_APP_DIR="${SCRIPT_DIR}/frontend"

COLDIGOM_URL="${COLDIGOM_API_BASE_URL:-http://127.0.0.1:8000}"
COLETANEA_URL="${COLETANEA_API_BASE_URL:-http://127.0.0.1:8001}"

if [ ! -d "$FLUTTER_APP_DIR" ] || [ ! -f "$FLUTTER_APP_DIR/pubspec.yaml" ]; then
    echo "❌ Diretório do app Flutter não encontrado: $FLUTTER_APP_DIR"
    exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
    echo "❌ Flutter não encontrado no PATH."
    exit 1
fi

echo "🚀 Flutter (release) macOS → local"
echo "   Coldigom API:  $COLDIGOM_URL"
echo "   Coletânea API: $COLETANEA_URL"
echo ""

cd "$FLUTTER_APP_DIR"
flutter run --release -d macos \
  --dart-define=COLDIGOM_API_BASE_URL="$COLDIGOM_URL" \
  --dart-define=COLETANEA_API_BASE_URL="$COLETANEA_URL"
