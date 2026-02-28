#!/bin/bash

# Script para executar o frontend Flutter no Chrome

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FRONTEND_DIR="$PROJECT_DIR/frontend"

# Determinar ambiente (padrão: dev)
ENV=${1:-dev}
PORT=${2:-64753}

if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
    echo "❌ Erro: Ambiente inválido. Use 'dev' ou 'prod'"
    echo "   Uso: ./scripts/run-frontend.sh [dev|prod] [port]"
    exit 1
fi

cd "$FRONTEND_DIR"

echo "🚀 Executando Coletânea Digital no Chrome (ambiente: $ENV)..."

# Verificar se Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter não está instalado. Por favor, instale o Flutter primeiro."
    exit 1
fi

# Obter o IP da máquina na rede local ANTES de carregar o .env
echo "🔍 Detectando IP da máquina na rede local..."
LOCAL_IP=""

# Tentar diferentes métodos para obter o IP
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | grep -v "169.254" | awk '{print $2}' | head -1)
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    LOCAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || ip route get 1.1.1.1 | awk '{print $7; exit}' 2>/dev/null)
fi

# Se ainda não encontrou, tentar método alternativo
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "")
fi

# Mostrar informações de rede
echo ""
echo "📡 Informações de rede:"
if [ -n "$LOCAL_IP" ]; then
    echo "   ✅ IP local detectado: $LOCAL_IP"
else
    echo "   ⚠️  Não foi possível detectar IP local automaticamente"
    LOCAL_IP="0.0.0.0"
fi
echo ""

# Carregar variáveis de ambiente
ENV_FILE="$PROJECT_DIR/.env.$ENV"
if [ -f "$ENV_FILE" ]; then
    echo "📋 Carregando variáveis de .env.$ENV..."
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

# Substituir localhost pelo IP real nas URLs da API quando em modo host
COLDIGOM_API_BASE_URL_ORIGINAL=${COLDIGOM_API_BASE_URL:-http://localhost:8000}
COLETANEA_API_BASE_URL_ORIGINAL=${COLETANEA_API_BASE_URL:-http://localhost:8001}

# Substituir localhost pelo IP detectado
if [ -n "$LOCAL_IP" ] && [ "$LOCAL_IP" != "0.0.0.0" ]; then
    COLDIGOM_API_BASE_URL=$(echo "$COLDIGOM_API_BASE_URL_ORIGINAL" | sed "s|localhost|$LOCAL_IP|g")
    COLETANEA_API_BASE_URL=$(echo "$COLETANEA_API_BASE_URL_ORIGINAL" | sed "s|localhost|$LOCAL_IP|g")
    
    echo "🔧 URLs da API ajustadas para modo host:"
    echo "   COLDIGOM_API_BASE_URL:   $COLDIGOM_API_BASE_URL_ORIGINAL → $COLDIGOM_API_BASE_URL"
    echo "   COLETANEA_API_BASE_URL:  $COLETANEA_API_BASE_URL_ORIGINAL → $COLETANEA_API_BASE_URL"
else
    COLDIGOM_API_BASE_URL=$COLDIGOM_API_BASE_URL_ORIGINAL
    COLETANEA_API_BASE_URL=$COLETANEA_API_BASE_URL_ORIGINAL
    echo "⚠️  Usando URLs originais (localhost) - IP não detectado"
fi
echo ""

# Instalar dependências
echo "📦 Instalando dependências..."
flutter pub get

# Executar no Chrome com porta configurada e modo host para permitir acesso de outros dispositivos
echo ""
echo "🌐 Iniciando aplicação no Chrome na porta $PORT (modo host)..."
echo ""
echo "✅ Aplicação será acessível em:"
echo "   📱 Máquina local:    http://localhost:$PORT"
if [ -n "$LOCAL_IP" ] && [ "$LOCAL_IP" != "0.0.0.0" ]; then
    echo "   🌍 Rede local:       http://$LOCAL_IP:$PORT"
    echo ""
    echo "💡 Para acessar de outros dispositivos na rede, use:"
    echo "   http://$LOCAL_IP:$PORT"
    echo ""
    echo "📡 APIs configuradas para:"
    echo "   Coldigom:  $COLDIGOM_API_BASE_URL"
    echo "   Coletânea: $COLETANEA_API_BASE_URL"
    echo ""
    echo "⚠️  IMPORTANTE: Certifique-se de que o backend coldigom está rodando"
    echo "   e que o CORS_ORIGINS no .env.dev inclui:"
    echo "   - http://$LOCAL_IP:$PORT (IP da rede local)"
    echo "   - http://0.0.0.0:$PORT (fallback)"
    echo ""
    echo "💡 Se tiver problemas de CORS, adicione manualmente ao .env.dev do coldigom:"
    echo "   CORS_ORIGINS=...,http://$LOCAL_IP:$PORT,http://0.0.0.0:$PORT"
else
    echo "   🌍 Rede local:       http://[SEU-IP-LOCAL]:$PORT"
    echo ""
    echo "💡 Para descobrir seu IP local, execute:"
    echo "   ifconfig | grep 'inet ' | grep -v 127.0.0.1"
fi
echo ""
# Executar Flutter em modo host
# IMPORTANTE: Usar o IP real ao invés de 0.0.0.0 para evitar problemas de CORS
# O Flutter precisa do IP real para que o navegador use a origem correta nas requisições
if [ -n "$LOCAL_IP" ] && [ "$LOCAL_IP" != "0.0.0.0" ]; then
    echo "🌐 Usando IP real ($LOCAL_IP) para evitar problemas de CORS..."
    flutter run -d chrome \
      --web-port=$PORT \
      --web-hostname=$LOCAL_IP \
      --dart-define=ENVIRONMENT=$ENV \
      --dart-define=COLDIGOM_API_BASE_URL=$COLDIGOM_API_BASE_URL \
      --dart-define=COLETANEA_API_BASE_URL=$COLETANEA_API_BASE_URL
else
    echo "⚠️  IP não detectado, usando 0.0.0.0 (pode ter problemas de CORS)..."
    flutter run -d chrome \
      --web-port=$PORT \
      --web-hostname=0.0.0.0 \
      --dart-define=ENVIRONMENT=$ENV \
      --dart-define=COLDIGOM_API_BASE_URL=$COLDIGOM_API_BASE_URL \
      --dart-define=COLETANEA_API_BASE_URL=$COLETANEA_API_BASE_URL
fi
