#!/bin/bash

# Script para build do Flutter em modo produção

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FRONTEND_DIR="$PROJECT_DIR/frontend"

cd "$FRONTEND_DIR"

echo "🔨 Building Flutter app para PRODUÇÃO..."

# Carregar variáveis de ambiente do .env.prod
if [ ! -f "$PROJECT_DIR/.env.prod" ]; then
    echo "❌ Erro: Arquivo .env.prod não encontrado!"
    echo "   Crie o arquivo .env.prod com as configurações de produção"
    exit 1
fi

echo "📋 Carregando variáveis de .env.prod..."
export $(grep -v '^#' "$PROJECT_DIR/.env.prod" | xargs)

# Verificar se URLs foram configuradas
if [[ "$COLDIGOM_API_BASE_URL" == *"localhost"* ]] || [[ "$COLDIGOM_API_BASE_URL" == *"seu-dominio"* ]]; then
    echo "⚠️  AVISO: COLDIGOM_API_BASE_URL ainda está com valor padrão!"
    echo "   Configure a URL real de produção em .env.prod"
    read -p "   Continuar mesmo assim? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

if [[ "$COLETANEA_API_BASE_URL" == *"localhost"* ]] || [[ "$COLETANEA_API_BASE_URL" == *"seu-dominio"* ]]; then
    echo "⚠️  AVISO: COLETANEA_API_BASE_URL ainda está com valor padrão!"
    echo "   Configure a URL real de produção em .env.prod"
    read -p "   Continuar mesmo assim? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

# Definir ambiente
export ENVIRONMENT=prod

# Build para web (produção) com otimizações
echo "🌐 Building para web (produção otimizada)..."
flutter build web \
  --dart-define=ENVIRONMENT=prod \
  --dart-define=COLDIGOM_API_BASE_URL=${COLDIGOM_API_BASE_URL} \
  --dart-define=COLETANEA_API_BASE_URL=${COLETANEA_API_BASE_URL} \
  --release \
  --web-renderer canvaskit

echo ""
echo "✅ Build de produção concluído!"
echo "📦 Arquivos gerados em: frontend/build/web"
echo ""
echo "⚠️  Próximos passos:"
echo "   1. Revise os arquivos em frontend/build/web"
echo "   2. Faça deploy para seu servidor web"
echo "   3. Configure CORS no backend para permitir seu domínio"
