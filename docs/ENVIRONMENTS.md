# Configuração de Ambientes

Este documento explica como configurar e usar os ambientes de desenvolvimento e produção para a Coletânea Digital.

## Estrutura de Ambientes

O projeto suporta dois ambientes principais:

- **dev** (Desenvolvimento): Para desenvolvimento local, com configurações permissivas e debug habilitado
- **prod** (Produção): Para produção, com configurações de segurança mais restritivas

## Arquivos de Configuração

### Backend

- `backend/.env.dev` - Configurações de desenvolvimento do backend
- `backend/.env.prod` - Configurações de produção do backend
- `backend/.env.example` - Template com todas as variáveis disponíveis

### Frontend

- `.env.dev` - Configurações de desenvolvimento (raiz do projeto)
- `.env.prod` - Configurações de produção (raiz do projeto)
- `.env.example` - Template com todas as variáveis disponíveis

## Variáveis de Ambiente

### Backend (.env.dev / .env.prod)

```env
# Database Configuration
POSTGRES_USER=coletanea_user
POSTGRES_PASSWORD=coletanea_password
POSTGRES_DB=coletanea_db
POSTGRES_PORT=5433
DATABASE_URL=postgresql://user:password@localhost:5433/coletanea_db

# API Configuration
API_PORT=8001
ENVIRONMENT=dev  # ou 'prod'

# CORS
# Development: permissivo (localhost e portas de desenvolvimento)
# Production: restritivo (apenas domínios específicos)
CORS_ORIGINS=http://localhost:8080,http://localhost
```

### Frontend (.env.dev / .env.prod)

```env
# Frontend API URLs
COLDIGOM_API_BASE_URL=http://localhost:8000
COLETANEA_API_BASE_URL=http://localhost:8001

# Environment
ENVIRONMENT=dev  # ou 'prod'
```

## Uso com Docker Compose

O projeto usa Docker Compose profiles para gerenciar ambientes.

### Desenvolvimento

```bash
# Iniciar ambiente de desenvolvimento
./scripts/dev.sh

# Ou manualmente:
export COMPOSE_PROFILE=dev
docker-compose --profile dev up -d
```

### Produção

```bash
# Iniciar ambiente de produção
./scripts/prod.sh

# Ou manualmente:
export COMPOSE_PROFILE=prod
docker-compose --profile prod up -d
```

## Uso com Flutter

### Desenvolvimento

```bash
# Executar no Chrome (desenvolvimento)
./scripts/run-frontend.sh dev

# Ou manualmente:
cd frontend
flutter run -d chrome \
  --dart-define=ENVIRONMENT=dev \
  --dart-define=COLDIGOM_API_BASE_URL=http://localhost:8000 \
  --dart-define=COLETANEA_API_BASE_URL=http://localhost:8001
```

### Build para Produção

```bash
# Build para produção
./scripts/build-prod.sh

# Ou manualmente:
cd frontend
flutter build web \
  --dart-define=ENVIRONMENT=prod \
  --dart-define=COLDIGOM_API_BASE_URL=https://api-coldigom.seu-dominio.com \
  --dart-define=COLETANEA_API_BASE_URL=https://api-coletanea.seu-dominio.com \
  --release
```

## Diferenças entre Ambientes

### Desenvolvimento (dev)

- **CORS**: Permissivo, aceita localhost e portas de desenvolvimento
- **Logs**: Detalhados e verbosos
- **Debug**: Habilitado
- **Cache**: Menor (500MB)
- **Timeout**: Maior (30 segundos)
- **URLs**: localhost

### Produção (prod)

- **CORS**: Restritivo, apenas domínios específicos configurados
- **Logs**: Mínimos, apenas erros importantes
- **Debug**: Desabilitado
- **Cache**: Maior (1000MB)
- **Timeout**: Menor (15 segundos)
- **URLs**: Domínios reais de produção

## Configuração Inicial

### 1. Criar arquivos de ambiente

Copie os templates e configure:

```bash
# Backend
cp backend/.env.example backend/.env.dev
cp backend/.env.example backend/.env.prod

# Frontend
cp .env.example .env.dev
cp .env.example .env.prod
```

### 2. Configurar desenvolvimento

Edite `backend/.env.dev` e `.env.dev` com suas configurações locais.

### 3. Configurar produção

**IMPORTANTE**: Antes de usar em produção, configure:

- **CORS_ORIGINS**: Domínios específicos (não use `*`)
- **POSTGRES_PASSWORD**: Senha forte e única
- **COLDIGOM_API_BASE_URL**: URL real da API coldigom
- **COLETANEA_API_BASE_URL**: URL real da API coletanea-digital
- **JWT_SECRET_KEY**: Secret forte e único (quando implementado)

Edite `backend/.env.prod` e `.env.prod` com suas configurações de produção.

## Scripts Disponíveis

### Coldigom

- `scripts/dev.sh` - Inicia ambiente de desenvolvimento
- `scripts/prod.sh` - Inicia ambiente de produção

### Coletânea Digital

- `scripts/dev.sh` - Inicia ambiente de desenvolvimento
- `scripts/prod.sh` - Inicia ambiente de produção
- `scripts/run-frontend.sh [dev|prod]` - Executa Flutter no Chrome
- `scripts/build-dev.sh` - Build Flutter para desenvolvimento
- `scripts/build-prod.sh` - Build Flutter para produção

## Verificação de Segurança

Os scripts de produção (`prod.sh` e `build-prod.sh`) verificam automaticamente:

- CORS não está usando wildcard (`*`)
- URLs não estão com valores padrão (localhost/seu-dominio)
- Senhas não estão com valores padrão

Se algum problema for detectado, você será alertado antes de continuar.

## Troubleshooting

### Erro: "Arquivo .env.dev não encontrado"

Certifique-se de criar os arquivos `.env.dev` e `.env.prod` baseados nos templates `.env.example`.

### Erro: "CORS bloqueado"

Verifique se a porta do Flutter está incluída no `CORS_ORIGINS` do backend. Em desenvolvimento, adicione todas as portas possíveis.

### Ambiente não está sendo detectado

Certifique-se de passar `--dart-define=ENVIRONMENT=dev` ou `--dart-define=ENVIRONMENT=prod` ao executar o Flutter.

## Referências

- [Docker Compose Profiles](https://docs.docker.com/compose/profiles/)
- [Flutter Environment Variables](https://docs.flutter.dev/deployment/environment-variables)
- [FastAPI CORS](https://fastapi.tiangolo.com/tutorial/cors/)
