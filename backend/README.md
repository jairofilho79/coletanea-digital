# Backend - Coletânea Digital

API FastAPI para Coletânea Digital.

## Estrutura

```
backend/
├── app/
│   ├── api/v1/       # Rotas da API
│   ├── models/       # Modelos SQLAlchemy
│   └── schemas/      # Schemas Pydantic
├── alembic/          # Migrações do banco
└── scripts/          # Scripts auxiliares
```

## Configuração

Copie `.env.example` para `.env` e configure:

```env
POSTGRES_USER=coletanea_user
POSTGRES_PASSWORD=coletanea_password
POSTGRES_DB=coletanea_db
POSTGRES_PORT=5433
DATABASE_URL=postgresql://coletanea_user:coletanea_password@localhost:5433/coletanea_db
API_PORT=8001
CORS_ORIGINS=http://localhost:8080,http://localhost
```

## Desenvolvimento com Docker

### Subir serviços

```bash
# Na raiz do projeto
docker-compose up -d
```

### Ver logs

```bash
docker-compose logs -f backend
```

### Executar comandos no container

```bash
# Criar migração
docker-compose exec backend alembic revision --autogenerate -m "descrição"

# Aplicar migrações
docker-compose exec backend alembic upgrade head

# Shell Python
docker-compose exec backend python
```

## Desenvolvimento Local (sem Docker)

### Pré-requisitos

- Python 3.11+
- PostgreSQL 15+

### Setup

```bash
# Criar ambiente virtual
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate  # Windows

# Instalar dependências
pip install -r requirements.txt

# Configurar variáveis de ambiente
cp .env.example .env
# Edite .env com suas configurações

# Aplicar migrações
alembic upgrade head

# Executar servidor
uvicorn app.main:app --reload --port 8001
```

## API

### Endpoints

- `GET /health` - Health check
- `GET /` - Informações da API
- `GET /docs` - Documentação Swagger
- `GET /api/v1/` - API v1 root

### Documentação

Acesse `http://localhost:8001/docs` para ver a documentação interativa da API.

## Migrações

### Criar migração

```bash
alembic revision --autogenerate -m "descrição da migração"
```

### Aplicar migrações

```bash
alembic upgrade head
```

### Reverter migração

```bash
alembic downgrade -1
```

## Tecnologias

- **FastAPI**: Framework web moderno
- **PostgreSQL**: Banco de dados
- **SQLAlchemy**: ORM
- **Alembic**: Migrações
- **Pydantic**: Validação de dados

## Portas

- **API**: 8001 (diferente do coldigom que usa 8000)
- **PostgreSQL**: 5433 (diferente do coldigom que usa 5432)
