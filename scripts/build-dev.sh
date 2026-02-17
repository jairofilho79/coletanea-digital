#!/bin/bash

# Script para build do Flutter em modo desenvolvimento

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FRONTEND_DIR="$PROJECT_DIR/frontend"

cd "$FRONTEND_DIR"

echo "🔨 Building Flutter app para DESENVOLVIMENTO..."

# Carregar variáveis de ambiente do .env.dev
if [ -f "$PROJECT_DIR/.env.dev" ]; then
    echo "📋 Carregando variáveis de .env.dev..."
    export $(grep -v '^#' "$PROJECT_DIR/.env.dev" | xargs)
fi

# Definir ambiente
export ENVIRONMENT=dev

# Build para web (desenvolvimento)
echo "🌐 Building para web (Chrome)..."
flutter build web \
  --dart-define=ENVIRONMENT=dev \
  --dart-define=COLDIGOM_API_BASE_URL=${COLDIGOM_API_BASE_URL:-http://localhost:8000} \
  --dart-define=COLETANEA_API_BASE_URL=${COLETANEA_API_BASE_URL:-http://localhost:8001} \
  --release

echo ""
echo "✅ Build de desenvolvimento concluído!"
echo "📦 Arquivos gerados em: frontend/build/web"
echo ""
echo "Para executar localmente:"
echo "   cd frontend && flutter run -d chrome --dart-define=ENVIRONMENT=dev"
