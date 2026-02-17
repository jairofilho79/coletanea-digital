# Configuração de CORS para Desenvolvimento

## Problema

Ao executar a Coletânea Digital no Chrome (web), você pode receber erros de CORS ao tentar acessar a API do coldigom. Isso acontece porque o coldigom agora tem políticas de segurança mais restritivas e não permite mais `CORS_ORIGINS="*"` por padrão.

## Solução

É necessário adicionar a origem do Flutter web ao `CORS_ORIGINS` do coldigom.

### 1. Identificar a porta do Flutter Web

Quando você executa `flutter run -d chrome`, o Flutter geralmente usa uma porta como:
- `http://localhost:8080`
- `http://localhost:50000` (porta dinâmica)
- `http://localhost:XXXXX` (varia)

Verifique no terminal qual porta está sendo usada quando você executa o Flutter.

### 2. Configurar CORS no coldigom

No projeto coldigom, você precisa adicionar a porta do Flutter ao `CORS_ORIGINS`.

#### Opção A: Via variável de ambiente (recomendado)

Crie ou edite o arquivo `.env` na raiz do projeto coldigom:

```env
CORS_ORIGINS=http://localhost:3000,http://localhost,http://localhost:8080,http://localhost:50000
```

**Nota**: Adicione todas as portas que você pode usar. O Flutter pode usar portas diferentes em execuções diferentes.

#### Opção B: Via docker-compose.yml

Edite o arquivo `docker-compose.yml` do coldigom:

```yaml
environment:
  - CORS_ORIGINS=${CORS_ORIGINS:-http://localhost:3000,http://localhost,http://localhost:8080,http://localhost:50000}
```

### 3. Reiniciar o coldigom

Após alterar a configuração:

```bash
cd /Volumes/SSD\ 2TB\ SD/dev/coldigom
docker-compose down
docker-compose up -d
```

### 4. Verificar se funcionou

Teste acessar a API diretamente no navegador:

```
http://localhost:8000/api/v1/praises?skip=0&limit=20
```

E verifique se o Flutter consegue fazer requisições sem erro de CORS.

## Portas Comuns

- **Coldigom API**: `http://localhost:8000`
- **Coldigom Frontend**: `http://localhost:3000`
- **Coletânea Digital Backend**: `http://localhost:8001`
- **Flutter Web**: `http://localhost:8080` ou porta dinâmica

## Troubleshooting

### Erro: "Access to XMLHttpRequest has been blocked by CORS policy"

1. Verifique se a porta do Flutter está no `CORS_ORIGINS`
2. Verifique se o coldigom foi reiniciado após alterar a configuração
3. Verifique os logs do coldigom: `docker-compose logs backend`

### Para desenvolvimento local apenas

Se você está apenas desenvolvendo localmente e não se importa com segurança, pode temporariamente usar:

```env
CORS_ORIGINS=*
```

**ATENÇÃO**: Nunca use `*` em produção!

## Referência

- [Documentação FastAPI CORS](https://fastapi.tiangolo.com/tutorial/cors/)
- [Guia de Desenvolvimento Coletânea Digital](GUIA_DESENVOLVIMENTO_PLPCG.md)
