# Coletânea Digital

Aplicação mobile-first e offline-first para consumo de louvores e materiais.

## Estrutura do Projeto

Este é um monorepo contendo:

- **Frontend**: Aplicação Flutter em `frontend/`
- **Backend**: API FastAPI em `backend/`

## Pré-requisitos

- Docker e Docker Compose instalados
- Flutter SDK (para desenvolvimento do frontend)
- Python 3.11+ (opcional, para desenvolvimento local do backend)

## Configuração Inicial

### 1. Variáveis de Ambiente

O projeto suporta dois ambientes: **dev** (desenvolvimento) e **prod** (produção).

#### Desenvolvimento

```bash
# Criar arquivos de ambiente para desenvolvimento
cp .env.example .env.dev
cp backend/.env.example backend/.env.dev

# Editar com suas configurações locais
```

#### Produção

```bash
# Criar arquivos de ambiente para produção
cp .env.example .env.prod
cp backend/.env.example backend/.env.prod

# IMPORTANTE: Configure URLs reais, CORS restritivo e senhas fortes
```

Consulte [docs/ENVIRONMENTS.md](docs/ENVIRONMENTS.md) para mais detalhes sobre configuração de ambientes.

### 2. Subir o Backend (Docker)

#### Desenvolvimento

```bash
./scripts/dev.sh
```

#### Produção

```bash
./scripts/prod.sh
```

Ou manualmente:

```bash
# Desenvolvimento
export COMPOSE_PROFILE=dev
docker-compose --profile dev up -d

# Produção
export COMPOSE_PROFILE=prod
docker-compose --profile prod up -d
```

Isso irá:

- Subir o PostgreSQL na porta 5433
- Subir a API FastAPI na porta 8001
- Executar migrações do banco automaticamente

Verifique se os serviços estão rodando:

```bash
docker-compose ps
```

Teste a API:

```bash
curl http://localhost:8001/health
```

### 3. Configurar CORS no Coldigom

**IMPORTANTE**: Antes de executar o frontend, você precisa configurar o CORS no coldigom para permitir requisições do Flutter web.

O Flutter web geralmente roda em `http://localhost:8080` ou uma porta dinâmica. Adicione essa origem ao `CORS_ORIGINS` do coldigom:

**No arquivo `.env.dev` do coldigom**:

```env
CORS_ORIGINS=http://localhost:3000,http://localhost,http://localhost:8080,http://localhost:50000
```

Depois, reinicie o coldigom:

```bash
cd /Volumes/SSD\ 2TB\ SD/dev/coldigom
./scripts/dev.sh
```

Consulte [docs/CORS_SETUP.md](docs/CORS_SETUP.md) para mais detalhes.

### 4. Configurar o Frontend

Entre na pasta do frontend:

```bash
cd frontend
```

Instale as dependências:

```bash
flutter pub get
```

Execute o app no Chrome (web):

```bash
```bash
# Desenvolvimento (padrão)
./scripts/run-frontend.sh dev

# Caso queira especificar uma porta customizada (default 64753):
./scripts/run-frontend.sh dev 8080

# Ou manualmente:
cd frontend && flutter pub get && flutter run -d chrome \
  --web-port=64753 \
  --dart-define=ENVIRONMENT=dev \
  --dart-define=COLDIGOM_API_BASE_URL=http://localhost:8000 \
  --dart-define=COLETANEA_API_BASE_URL=http://localhost:8001
```

**Nota**: O script do Flutter está configurado para usar a porta **64753** como default (via `--web-port=64753`), caso sinta necessidade mude injetando a porta como segundo argumento, porém não se esqueça de adicionar essa origem no CORS do coldigom.

## Desenvolvimento

### Frontend

Para executar o frontend no Chrome:

```bash
cd frontend && flutter pub get && flutter run -d chrome \
  --web-port=64753 \
  --dart-define=COLDIGOM_API_BASE_URL=http://localhost:8000 \
  --dart-define=COLETANEA_API_BASE_URL=http://localhost:8001
```

Ou use o script auxiliar:

```bash
./scripts/run-frontend.sh
```

### Backend

O backend está em `backend/` e usa FastAPI com PostgreSQL.

**Estrutura**:

```
backend/
├── app/
│   ├── api/v1/     # Rotas da API
│   ├── models/     # Modelos SQLAlchemy
│   └── schemas/    # Schemas Pydantic
├── alembic/        # Migrações do banco
└── scripts/        # Scripts auxiliares
```

**Comandos úteis**:

- Criar nova migração: `docker-compose exec backend alembic revision --autogenerate -m "descrição"`
- Aplicar migrações: `docker-compose exec backend alembic upgrade head`
- Ver logs: `docker-compose logs -f backend`

### Frontend

O frontend está em `frontend/` e usa Flutter com Riverpod.

**Estrutura**:

```
frontend/lib/
├── core/           # Configurações centrais
│   ├── config/     # Configurações da app
│   ├── network/    # Clientes HTTP
│   ├── storage/    # Hive e cache
│   ├── router/     # Roteamento
│   └── theme/      # Tema mobile-first
├── features/       # Features organizadas por domínio
└── shared/         # Componentes compartilhados
```

**Comandos úteis**:

- Executar app no Chrome: `cd frontend && flutter pub get && flutter run -d chrome`
- Analisar código: `cd frontend && flutter analyze`
- Formatar código: `cd frontend && dart format .`
- Executar testes: `cd frontend && flutter test`

## Portas

- **Backend API**: 8001 (diferente do coldigom que usa 8000)
- **PostgreSQL**: 5433 (diferente do coldigom que usa 5432)
- **Frontend Web**: Porta padrão do Flutter (geralmente 8080)

## Arquitetura

### Backend

- **FastAPI**: Framework web moderno e rápido
- **PostgreSQL**: Banco de dados relacional
- **SQLAlchemy**: ORM
- **Alembic**: Migrações do banco

### Frontend

- **Flutter**: Framework multiplataforma
- **Riverpod**: Gerenciamento de estado
- **Hive**: Armazenamento local (cache offline)
- **go_router**: Roteamento declarativo
- **Dio**: Cliente HTTP

## Filosofia de Desenvolvimento

- **Mobile-first**: Design e desenvolvimento priorizam dispositivos móveis
- **Offline-first**: Funcionalidade completa sem conexão, cache em Hive
- **Tecnologias leves**: Bibliotecas escolhidas para funcionar bem em hardwares mais fracos
- **Segurança sobre retrocompatibilidade**: Prioriza segurança sobre suporte a navegadores antigos

## Troubleshooting

### Erro de CORS

Se você receber erros de CORS ao acessar a API do coldigom:

1. Verifique qual porta o Flutter está usando (geralmente aparece no terminal)
2. Adicione essa porta ao `CORS_ORIGINS` do coldigom
3. Reinicie o coldigom: `docker-compose restart backend`

Consulte [docs/CORS_SETUP.md](docs/CORS_SETUP.md) para instruções detalhadas.

Você também pode usar o script de verificação:

```bash
./scripts/check-cors.sh
```

## Ambientes

O projeto suporta dois ambientes: **dev** (desenvolvimento) e **prod** (produção).

### Scripts Disponíveis

- `./scripts/dev.sh` - Inicia ambiente de desenvolvimento (Docker)
- `./scripts/prod.sh` - Inicia ambiente de produção (Docker)
- `./scripts/run-frontend.sh [dev|prod] [porta_opcional]` - Executa Flutter no Chrome
- `./scripts/build-dev.sh` - Build Flutter para desenvolvimento
- `./scripts/build-prod.sh` - Build Flutter para produção

Consulte [docs/ENVIRONMENTS.md](docs/ENVIRONMENTS.md) para documentação completa sobre ambientes.

## Próximos Passos

Consulte o [Guia de Desenvolvimento](docs/GUIA_DESENVOLVIMENTO_PLPCG.md) para mais detalhes sobre:

- Use cases a implementar
- Estrutura de features
- Padrões de código
- Roadmap do projeto

## Licença

[Adicionar licença quando definida]
