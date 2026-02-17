#!/bin/bash

# Script para iniciar ambiente de desenvolvimento da Coletânea Digital

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

echo "🚀 Iniciando ambiente de DESENVOLVIMENTO da Coletânea Digital..."

# Verificar se os arquivos .env.dev existem
if [ ! -f ".env.dev" ]; then
    echo "❌ Erro: Arquivo .env.dev não encontrado na raiz!"
    echo "   Crie o arquivo .env.dev baseado em .env.example"
    exit 1
fi

if [ ! -f "backend/.env.dev" ]; then
    echo "❌ Erro: Arquivo backend/.env.dev não encontrado!"
    echo "   Crie o arquivo backend/.env.dev baseado em backend/.env.example"
    exit 1
fi

export COMPOSE_PROFILE=dev

# Iniciar serviços com profile dev
echo "📦 Iniciando serviços Docker Compose (profile: dev)..."
docker-compose --profile dev up -d

echo ""
echo "✅ Ambiente de desenvolvimento iniciado!"
echo ""
echo "📋 Serviços disponíveis:"
echo "   - Backend API: http://localhost:8001"
echo "   - Docs API: http://localhost:8001/docs"
echo ""
echo "Para executar o frontend Flutter:"
echo "   cd frontend && flutter pub get && flutter run -d chrome --dart-define=ENVIRONMENT=dev"
echo ""
echo "Para ver os logs: docker-compose --profile dev logs -f"
echo "Para parar: docker-compose --profile dev down"
