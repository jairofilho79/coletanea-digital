#!/bin/bash

# Script para iniciar ambiente de produção da Coletânea Digital

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

echo "🚀 Iniciando ambiente de PRODUÇÃO da Coletânea Digital..."

# Verificar se os arquivos .env.prod existem
if [ ! -f ".env.prod" ]; then
    echo "❌ Erro: Arquivo .env.prod não encontrado na raiz!"
    echo "   Crie o arquivo .env.prod baseado em .env.example"
    exit 1
fi

if [ ! -f "backend/.env.prod" ]; then
    echo "❌ Erro: Arquivo backend/.env.prod não encontrado!"
    echo "   Crie o arquivo backend/.env.prod baseado em backend/.env.example"
    exit 1
fi

# Verificar configurações críticas de produção
echo "🔍 Verificando configurações de produção..."

# Verificar se CORS não está usando wildcard
if grep -q "CORS_ORIGINS=\*" backend/.env.prod 2>/dev/null; then
    echo "⚠️  AVISO: CORS_ORIGINS está usando '*' em produção!"
    echo "   Isso é um risco de segurança. Configure domínios específicos."
    read -p "   Continuar mesmo assim? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

# Verificar se URLs de API foram configuradas
if grep -q "seu-dominio.com\|localhost" .env.prod 2>/dev/null; then
    echo "⚠️  AVISO: URLs de API ainda estão com valores padrão!"
    echo "   Configure as URLs reais de produção em .env.prod"
    read -p "   Continuar mesmo assim? (s/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

export COMPOSE_PROFILE=prod

# Iniciar serviços com profile prod
echo "📦 Iniciando serviços Docker Compose (profile: prod)..."
docker-compose --profile prod up -d

echo ""
echo "✅ Ambiente de produção iniciado!"
echo ""
echo "📋 Serviços disponíveis:"
echo "   - Backend API: http://localhost:8001"
echo ""
echo "⚠️  Lembre-se de configurar:"
echo "   - CORS_ORIGINS com domínios específicos"
echo "   - URLs de API em .env.prod"
echo "   - Senhas de banco de dados fortes"
echo ""
echo "Para ver os logs: docker-compose --profile prod logs -f"
echo "Para parar: docker-compose --profile prod down"
