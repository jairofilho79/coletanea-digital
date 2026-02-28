# Docker - Coletanea Digital

Este projeto possui configurações Docker separadas para ambientes de desenvolvimento e produção.

## Setup Inicial

### 1. Criar Redes Docker Compartilhadas

Execute o script para criar as redes necessárias:

```bash
./setup-docker-networks.sh
```

Ou manualmente:

```bash
docker network create coldigom-coletanea-dev-network
docker network create coldigom-coletanea-prod-network
```

## Desenvolvimento

### Subir Ambiente Dev

**Importante:** Suba primeiro o coletanea-digital dev, depois o coldigom dev.

```bash
cd /Users/jairofilho79/DEV/coletanea-digital
docker-compose -f docker-compose.dev.yml up -d
```

### Características do Ambiente Dev

- Hot-reload habilitado no backend (`--reload`)
- Volumes montados para código fonte (alterações refletem imediatamente)
- Rede compartilhada: `coldigom-coletanea-dev-network`
- Container name: `coletanea_api_dev` (para comunicação com coldigom-dev)

### Containers Dev

- `coletanea_db_dev` - PostgreSQL
- `coletanea_api_dev` - Backend API

## Produção

### Subir Ambiente Prod

**Importante:** Suba primeiro o coletanea-digital prod, depois o coldigom prod.

```bash
cd /Users/jairofilho79/DEV/coletanea-digital
docker-compose -f docker-compose.prod.yml up -d
```

### Características do Ambiente Prod

- Sem hot-reload (otimizado para produção)
- Código copiado na imagem (sem volumes de código)
- Rede compartilhada: `coldigom-coletanea-prod-network`
- Container name: `coletanea_api_prod` (para comunicação com coldigom-prod)
- Health checks configurados
- Restart policies adequadas

### Containers Prod

- `coletanea_db_prod` - PostgreSQL
- `coletanea_api_prod` - Backend API

## Variáveis de Ambiente

### Dev

Use `backend/.env.dev` com valores de desenvolvimento.

### Prod

Use `backend/.env.prod` com valores de produção.

## Isolamento de Ambientes

- **Dev** e **Prod** são completamente isolados
- Cada ambiente usa sua própria rede Docker
- Dev não se comunica com Prod e vice-versa
- Cada ambiente tem seus próprios volumes de banco de dados

## Comunicação entre Serviços

O coldigom se conecta ao coletanea-digital através do nome do container:

- **Dev**: `coletanea_api_dev:8001`
- **Prod**: `coletanea_api_prod:8001`

## Comandos Úteis

```bash
# Ver logs
docker-compose -f docker-compose.dev.yml logs -f
docker-compose -f docker-compose.prod.yml logs -f

# Parar containers
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.prod.yml down

# Rebuild
docker-compose -f docker-compose.dev.yml build --no-cache
docker-compose -f docker-compose.prod.yml build --no-cache
```
