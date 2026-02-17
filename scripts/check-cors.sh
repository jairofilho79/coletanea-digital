#!/bin/bash

# Script para verificar configuração de CORS do coldigom

set -e

echo "🔍 Verificando configuração de CORS do coldigom..."

COLDIGOM_URL="${COLDIGOM_API_BASE_URL:-http://localhost:8000}"

# Tenta fazer uma requisição OPTIONS (preflight CORS)
echo "Testando CORS em $COLDIGOM_URL/api/v1/praises..."

response=$(curl -s -o /dev/null -w "%{http_code}" \
  -X OPTIONS \
  -H "Origin: http://localhost:8080" \
  -H "Access-Control-Request-Method: GET" \
  "$COLDIGOM_URL/api/v1/praises" || echo "000")

if [ "$response" = "200" ] || [ "$response" = "204" ]; then
    echo "✅ CORS parece estar configurado corretamente"
else
    echo "⚠️  Possível problema de CORS (status: $response)"
    echo ""
    echo "Para corrigir:"
    echo "1. Adicione a porta do Flutter web ao CORS_ORIGINS do coldigom"
    echo "2. Exemplo: CORS_ORIGINS=http://localhost:3000,http://localhost,http://localhost:8080"
    echo "3. Reinicie o coldigom: docker-compose restart backend"
    echo ""
    echo "Consulte docs/CORS_SETUP.md para mais detalhes"
fi
