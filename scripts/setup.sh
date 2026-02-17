#!/bin/bash

# Script de setup inicial do projeto Coletânea Digital

set -e

echo "🚀 Configurando Coletânea Digital..."

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não está instalado. Por favor, instale o Docker primeiro."
    exit 1
fi

# Verificar se Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose não está instalado. Por favor, instale o Docker Compose primeiro."
    exit 1
fi

# Verificar se Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "⚠️  Flutter não está instalado. Você precisará instalá-lo para desenvolver o frontend."
fi

# Copiar .env.example para .env se não existir
if [ ! -f .env ]; then
    echo "📝 Criando arquivo .env a partir de .env.example..."
    cp .env.example .env
    echo "✅ Arquivo .env criado. Por favor, edite-o com suas configurações."
else
    echo "✅ Arquivo .env já existe."
fi

# Subir Docker
echo "🐳 Subindo containers Docker..."
docker-compose up -d

echo "⏳ Aguardando serviços iniciarem..."
sleep 5

# Verificar saúde dos serviços
echo "🔍 Verificando saúde dos serviços..."
if curl -f http://localhost:8001/health > /dev/null 2>&1; then
    echo "✅ Backend está rodando em http://localhost:8001"
else
    echo "⚠️  Backend ainda não está respondendo. Verifique os logs com: docker-compose logs backend"
fi

# Setup do frontend
if [ -d "frontend" ]; then
    echo "📦 Instalando dependências do Flutter..."
    cd frontend
    flutter pub get
    cd ..
    echo "✅ Dependências do Flutter instaladas."
fi

echo ""
echo "✅ Setup concluído!"
echo ""
echo "Próximos passos:"
echo "1. Edite o arquivo .env com suas configurações"
echo "2. Execute 'docker-compose logs -f' para ver os logs"
echo "3. Para rodar o frontend: cd frontend && flutter run"
echo ""
