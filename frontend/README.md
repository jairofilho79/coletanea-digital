# Frontend - Coletânea Digital

Aplicação Flutter mobile-first e offline-first.

## Estrutura

```
lib/
├── core/              # Configurações centrais
│   ├── config/        # Configurações da app
│   ├── network/       # Clientes HTTP (coldigom e backend próprio)
│   ├── storage/       # Hive e cache offline
│   ├── router/        # Roteamento go_router
│   └── theme/         # Tema mobile-first
├── features/          # Features organizadas por domínio
│   └── praises/       # Feature de praises (em desenvolvimento)
└── shared/            # Componentes compartilhados
    └── widgets/       # Widgets reutilizáveis
```

## Comandos

### Desenvolvimento

```bash
# Instalar dependências
flutter pub get

# Executar app no Chrome (web) - RECOMENDADO
cd frontend && flutter pub get && flutter run -d chrome \
  --dart-define=COLDIGOM_API_BASE_URL=http://localhost:8000 \
  --dart-define=COLETANEA_API_BASE_URL=http://localhost:8001

# Executar app (mobile) - opcional para desenvolvimento mobile
# flutter run

# Analisar código
flutter analyze

# Formatar código
dart format .

# Executar testes
flutter test
```

### Build

```bash
# Web
flutter build web

# Android
flutter build apk

# iOS
flutter build ios
```

## Configuração

As URLs das APIs são configuradas via `--dart-define` ou podem ser definidas em `lib/core/config/app_config.dart`.

Variáveis de ambiente:
- `COLDIGOM_API_BASE_URL`: URL da API do coldigom (padrão: http://localhost:8000)
- `COLETANEA_API_BASE_URL`: URL da API própria (padrão: http://localhost:8001)

## Tecnologias

- **Flutter**: Framework multiplataforma
- **Riverpod**: Gerenciamento de estado
- **Hive**: Armazenamento local (cache offline)
- **go_router**: Roteamento declarativo
- **Dio**: Cliente HTTP
- **pdfrx**: Leitor de PDF

## Filosofia

- **Mobile-first**: Design otimizado para dispositivos móveis
- **Offline-first**: Funcionalidade completa sem conexão
- **Tecnologias leves**: Performance em hardwares mais fracos
- **Segurança**: Prioriza segurança sobre retrocompatibilidade
