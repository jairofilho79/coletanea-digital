# Guia de Desenvolvimento - Coletânea Digital

Documentação de referência para o projeto Coletânea Digital (frontend Flutter).

---

## 1. Visão geral do projeto

- **Nome**: Coletânea Digital
- **Objetivo**: substituir o plpcjf como frontend de consumo de louvores/materiais; consumir dados do coldigom (apenas leitura) e oferecer listas/salas via backend próprio.
- **Build inicial**: web. Uso de libs compatíveis com todas as plataformas (iOS, Android, Windows, macOS, Linux) para evoluir depois.
- **Filosofia de desenvolvimento**: **mobile-first** e **offline-first**. A aplicação é projetada prioritariamente para dispositivos móveis e funciona completamente offline, utilizando tecnologias leves que funcionam bem em hardwares mais fracos. Compatibilidade com versões antigas de navegadores é considerada apenas se não comprometer a segurança — **prioriza-se segurança sobre retrocompatibilidade**.

---

## 2. Contexto e arquitetura

- **Coletânea Digital** é projeto **independente**, em **repositório próprio**.
- **coldigom** (VPS): apenas **APIs públicas (GET)**. Coldigom é o gerenciador de objetos (materiais, praises, tags, material kinds). Nenhum auth, POST/PUT/DELETE no coldigom pela Coletânea Digital.
- **Backend da Coletânea Digital** (próprio): listas de praises e salas (no MVP podem ser locais, Hive; depois sincronização online). Backend em **Docker próprio e separado** (FastAPI + PostgreSQL) — **não reutiliza o Docker do coldigom**. A stack Cloudflare (Workers) não atende ao volume de requisições das salas online. Autenticação e preferências são **features futuras**, não prioritárias no MVP.
- **UX/UI**: tela principal **fortemente inspirada no plpcjf** (header Como Usar | Biblioteca | Coletânea Digital | Offline | Listas, pesquisa, filtros, cards, leitor PDF, listas, offline). Design **mobile-first** com foco em dispositivos móveis.
- **Objetivos**: tecnologia escalável, vários material kinds e agrupamento praises × material kinds, **offline-first 100%** com cache em Hive (metadados e **materiais** — PDF, áudio, lyrics — para consumo offline), manter beleza e usabilidade do plpcjf. Utilizar tecnologias leves que funcionem bem em hardwares mais fracos. Compatibilidade com navegadores antigos apenas se não comprometer a segurança — **prioriza-se segurança sobre retrocompatibilidade**.

---

## 3. Stack e tecnologias

| Área | Tecnologia | Observação |
|------|------------|------------|
| Framework | Flutter | Build inicial web; libs multi-plataforma. **Mobile-first** e **offline-first**. Tecnologias leves para hardwares mais fracos. |
| Estado | Riverpod | Providers, async notifiers. Leve e eficiente. |
| Persistência | Hive | Cache de **metadados** e cache dos **materiais** (PDF, áudio, lyrics) para consumo offline; listas/salas locais (MVP); depois token/preferências; **sem SharedPreferences**. Armazenamento local eficiente e leve. |
| PDF | pdfrx | Visualização e carregamento progressivo. Otimizado para performance em dispositivos móveis. |
| Roteamento | go_router | Declarativo, deep links. Leve e eficiente. |
| Rede | dio (ou http) | Coldigom: cliente → API direto. Backend da Coletânea Digital: cliente → API (FastAPI em Docker próprio e separado); banco PostgreSQL. Cliente HTTP leve. |
| i18n | flutter_localizations + ARB | Idioma persistido em Hive. |
| Lints | flutter_lints | CI com `flutter analyze` e `dart format` |
| Compatibilidade | Navegadores modernos | Suporte a versões antigas de navegadores apenas se não comprometer a segurança. **Prioriza-se segurança sobre retrocompatibilidade**. |

- **Rede**: (1) **coldigom** — apenas GET, sem auth; cliente → coldigom direto. (2) **Backend da Coletânea Digital** — no MVP listas/salas locais (Hive); futuramente API em Docker próprio e separado (FastAPI + PostgreSQL) para auth, listas online, salas online (token e 401 no cliente da Coletânea Digital).

---

## 4. Configuração de APIs (dois backends)

- **Coldigom** (apenas GET públicos): URL base configurável, ex. `--dart-define=COLDIGOM_API_BASE_URL=https://api.coldigom.example.com`. Cliente → coldigom direto.
- **Backend da Coletânea Digital** (auth, listas, salas): URL base configurável, ex. `--dart-define=COLETANEA_API_BASE_URL=https://api.coletanea.example.com`. Backend em **Docker próprio e separado**: **FastAPI** (Python) + **PostgreSQL** — **não reutiliza o Docker do coldigom**. Chamadas do cliente para essa API.

---

## 5. Hosting e backend

- **Stack Cloudflare** (Workers + D1) **não atende** ao backend da Coletânea Digital: as **salas online** (participantes, chat, SSE/WebSocket) gerariam muitas requisições e estourariam o limite de Workers. Por isso o backend da Coletânea Digital será em **Docker próprio e separado**.
- **Backend da Coletânea Digital**: **Docker próprio e separado** com **Python (FastAPI)** e **PostgreSQL** — **não reutiliza o Docker do coldigom**. O cliente (Flutter) chama a URL da API (ex.: `COLETANEA_API_BASE_URL`). Escalável para salas online, auth, listas online.
- **Coldigom**: o app chama **diretamente** a API do coldigom (cliente → coldigom). O Docker do coldigom é **separado e independente** do Docker da Coletânea Digital.
- **Frontend (Flutter web)**: pode ser hospedado onde preferir (ex.: Cloudflare Pages apenas para build estático, ou outro host). O importante é que a **API da Coletânea Digital** rode em Docker próprio e separado (FastAPI + PostgreSQL).

---

## 5.1. Ambiente de desenvolvimento

Para desenvolver a Coletânea Digital com os dois backends (coldigom + backend da Coletânea Digital), siga estes passos:

### Pré-requisitos

- Docker e Docker Compose instalados.
- Flutter SDK (para o app da Coletânea Digital).
- Coldigom e backend da Coletânea Digital cada um com seu **próprio Docker separado** (ou docker-compose). **Não reutilizar o Docker do coldigom**.

### Portas: não coincidir com o coldigom

O **coldigom** já utiliza, por exemplo, **8000** (API FastAPI) e **3000** (frontend, se aplicável). As portas dos serviços do **backend da Coletânea Digital** **não devem coincidir** com as do coldigom para evitar conflito quando os dois estiverem rodando na mesma máquina.

- **Coldigom** (referência): API em 8000, PostgreSQL em 5432, frontend em 3000 (conforme configuração do projeto coldigom).
- **Backend da Coletânea Digital**: usar portas **diferentes**, por exemplo:
  - API FastAPI: **8001** (evitar 8000).
  - PostgreSQL: **5433** (evitar 5432 se o coldigom estiver usando na mesma máquina).
  - Não usar **3000** nem **8000** para a Coletânea Digital, pois já são usados pelo coldigom.

### Ordem de subida

1. **Subir o Docker do coldigom** (API + PostgreSQL do coldigom), se for consumir dados reais do coldigom em desenvolvimento.
2. **Subir o Docker próprio e separado do backend da Coletânea Digital** (FastAPI + PostgreSQL) — **não reutilizar o Docker do coldigom**.
3. **Garantir que os dois estejam em execução** antes de rodar o app Flutter (ex.: `flutter run -d chrome`).

### URLs sincronizadas com o Flutter

As URLs que o app Flutter usa devem apontar para onde os serviços estão rodando:

- **COLDIGOM_API_BASE_URL**: URL base da API do coldigom (apenas GET). Ex.: `http://localhost:8000` se o coldigom estiver na porta 8000. Deve bater com a porta exposta pelo Docker do coldigom.
- **COLETANEA_API_BASE_URL**: URL base da API do backend da Coletânea Digital. Ex.: `http://localhost:8001` se a Coletânea Digital estiver na porta 8001. Deve bater com a porta exposta pelo Docker próprio e separado da Coletânea Digital.

Configurar no Flutter, por exemplo via `--dart-define` ao rodar ou em um arquivo de config de ambiente:

```bash
flutter run -d chrome \
  --dart-define=COLDIGOM_API_BASE_URL=http://localhost:8000 \
  --dart-define=COLETANEA_API_BASE_URL=http://localhost:8001
```

Ou definir as mesmas variáveis em um `.env` / script de run usado no projeto, garantindo que **portas e hosts** estejam alinhados com o que os Dockers expõem.

### Checklist rápido

- [ ] Docker do coldigom rodando (API acessível, ex.: `http://localhost:8000/health`).
- [ ] Docker próprio e separado do backend da Coletânea Digital rodando (API na porta escolhida, ex.: 8001) — **não reutilizar o Docker do coldigom**.
- [ ] Portas da Coletânea Digital diferentes das do coldigom (não usar 3000, 8000 para a Coletânea Digital).
- [ ] `COLDIGOM_API_BASE_URL` e `COLETANEA_API_BASE_URL` no Flutter apontando para as URLs corretas (host e porta).

---

## 6. Use cases a desenvolver (priorizados)

### Coldigom (apenas GET)

A Coletânea Digital usa apenas APIs públicas (GET) do coldigom. Nenhum registro/login nem criar/editar/deletar no coldigom.

### MVP – Foco do primeiro entregável

O **auth não é prioridade** no MVP. O foco é leitura do coldigom, listas/salas locais e leitores de conteúdo.

- **Ler praises do coldigom**: listar praises (UC-005), detalhes (UC-006), listar tags (UC-030, UC-031, UC-035), material kinds (UC-036, UC-037), material types (UC-041, UC-042), listar materiais de um praise (UC-018), detalhes de material (UC-019), traduções/i18n (UC-046 a UC-062, UC-112, UC-113). URL de download temporária (UC-027) e download de arquivo (UC-026) quando o coldigom expor GET públicos.
- **Mostrar e consumir material kinds**: exibir e usar os vários material kinds (agrupamento, ícones por tipo, múltiplos tipos desde o início).
- **Listas e salas**: criar listas de praises e **salas**. A sala é evolução da playlist: contém **lista de praises** (ordenável, única para todos) e **lista de materiais** (ordenável, por participante, offline) — ver seção “Sala e lista de materiais”. No MVP podem ser locais (Hive).
- **Leitores**:
  - **Leitor de PDF** (pdfrx).
  - **Leitor de áudio** (reprodução de materiais de áudio).
  - **Leitor de lyrics** (exibir letra / material tipo texto).
- **App**: navegação (dashboard/menu), tela principal inspirada no plpcjf (pesquisa, filtros, cards).
- **Offline**: além do cache de **metadados** em Hive, cachear os **materiais** (PDF, áudio, lyrics) para consumo offline — os leitores devem poder abrir conteúdo a partir do cache quando não houver rede. Keep offline, status offline, remover do cache (UC-123 a UC-126).

### Fase 2 – Offline e materiais

- Download em lote (UC-127, UC-128) se coldigom tiver endpoint GET público para batch.
- Gestão de cache, versionamento, snapshot (conforme GETs disponíveis no coldigom).
- Metadados estendidos (UC-152 a UC-161) via GET do coldigom.

### Features futuras (após o MVP)

O **auth** e as funcionalidades online do backend da Coletânea Digital entram em fases posteriores, quando for necessário:

- **Autenticação**: registro, login, sessão, logout (usuários próprios da Coletânea Digital).
- **Sincronização das listas online**: persistir e sincronizar listas no backend (FastAPI + PostgreSQL em Docker próprio e separado).
- **Salas online**: conceito “clássico” de sala com participantes, chat, entrada por código/senha/aprovação, sincronização em tempo real (SSE/WebSocket). Rodar no backend Docker (FastAPI + PostgreSQL); o volume de requisições inviabiliza Workers. A sala na Coletânea Digital (lista de praises + lista de materiais por participante) pode depois ganhar essa camada online.
- **Preferências do usuário**: ordem de material kind, idioma da interface, etc., armazenadas no backend após login.
- Outras funcionalidades que dependam de usuário identificado (ex.: seguir listas, copiar listas, compartilhar salas).

---

## 7. Requisitos funcionais e não funcionais por use case

Para cada UC (ou grupo):

- **Funcionais**: entrada, saída, regras (ex.: listar praises com paginação, busca por nome e filtro por tag).
- **Não funcionais**:
  - **Mobile-first**: design e desenvolvimento priorizam dispositivos móveis; interface otimizada para telas pequenas e toque.
  - **Offline-first**: leitura de metadados e de materiais (PDF, áudio, lyrics) a partir do cache quando offline; fila de ações opcional em fases posteriores. Funcionalidade completa sem conexão.
  - **Leveza**: evitar dependências pesadas; lazy load de PDF e listas. Tecnologias leves que funcionem bem em hardwares mais fracos.
  - **Performance**: tempo de resposta percebido (ex.: lista &lt; 500 ms quando em cache); cache Hive antes de rede. Otimizado para dispositivos móveis com recursos limitados.
  - **Hardware limitado**: evitar animações pesadas; listas virtualizadas; PDF com carregamento progressivo (pdfrx). Compatibilidade com dispositivos de baixo desempenho.
  - **Segurança sobre retrocompatibilidade**: compatibilidade com versões antigas de navegadores apenas se não comprometer a segurança. Prioriza-se segurança sobre retrocompatibilidade — não usar tecnologias vulneráveis apenas para suportar navegadores antigos.
- **Tecnologias**: ex. Riverpod para estado, Hive para cache (metadados + materiais), pdfrx para PDF; leitores consumindo de cache quando offline. Todas escolhidas por serem leves e eficientes em dispositivos móveis.

---

## 8. Layout e identidade visual (fortemente inspirado no plpcjf)

- **Tela principal**: fortemente inspirada no plpcjf — mesma sensação de uso e beleza. Design **mobile-first** com foco em dispositivos móveis.
- **Header fixo**: Como Usar | Biblioteca | **Coletânea Digital** (título central) | Offline | Listas. Otimizado para telas pequenas e interação por toque.
- **Cores e tipografia**: fundo (background), destaque (ex.: gold), texto (placeholder-color); fonte serif (ex.: Garamond) para títulos. Escolhas leves que não impactem performance em hardwares mais fracos.
- **Detalhe “light-beam”** nos botões ativos (manter estética do plpcjf).
- **Responsivo**: menu colapsável em telas pequenas; conteúdo com largura máxima. Prioriza experiência mobile.
- **Páginas principais**: Home (pesquisa + filtros + lista de louvores), Biblioteca, Leitor (PDF / áudio / lyrics), Listas, Salas, Offline (gestão de cache). Todas otimizadas para mobile e funcionamento offline.

---

## 9. Material kinds e agrupamento

- Exibir materiais **agrupados por material kind** e ordenação por tipo (PDF, áudio, texto, YouTube, etc.), com ícones por tipo.
- Suporte a **múltiplos material kinds** desde o MVP (diferente do plpcjf que tinha apenas 3 tipos e só PDF).
- Traduções de material kinds via API (UC-051 a UC-054) e idioma da interface (UC-112, UC-113).

---

## 9.1. Sala e lista de materiais (evolução da playlist)

A **sala** na Coletânea Digital é a evolução da playlist do plpcjf. No plpcjf, quando só havia “materiais”, a playlist definia apenas a **ordem em que os PDFs seriam abertos**. Agora, com **praises**, é preciso definir **quais praises** serão usados e, para cada um, **quais materiais** cada pessoa abre — pois cada participante usa **material kinds diferentes** (ex.: um usa Cifra, outro Partitura).

- **Lista de praises (ordenável)**: define **quais** praises entram na sala e em **qual ordem**. Essa ordem é **única para todos** (compartilhada quando a sala for online; no MVP pode ser local).
- **Lista de materiais (ordenável)**: define, **por participante**, quais materiais (PDF, áudio, lyrics, etc.) serão usados e em que ordem abri-los. É escolhida por cada participante e fica **offline** (local). A **lista de materiais é a exata representação da playlist do plpcjf** — a “minha” sequência de materiais a abrir.

Resumo: sala = lista de praises (uma para todos, ordenável) + lista de materiais (uma por participante, ordenável, offline = playlist ao estilo plpcjf). O conceito de **sala online** (participantes, chat, entrada por código, SSE) é um conceito mais antigo que entra como camada futura quando houver backend próprio e separado e auth.

---

## 10. Offline e cache (Hive)

- **Hive** como única persistência local. **Não usar SharedPreferences.**
- **Cache de metadados**: entidades (praises, tags, material kinds, etc.), metadados dos materiais, status “keep offline”, listas e salas locais (MVP). Futuramente token e preferências após auth.
- **Cache dos materiais**: além dos metadados, a aplicação deve **cachear os próprios materiais** (arquivos/conteúdo) — PDF, áudio, lyrics (texto) — para que possam ser **consumidos offline** nos leitores. Ao abrir um material, se estiver em cache, usar o arquivo local; caso contrário, baixar e cachear quando online.
- Versionamento e invalidação de cache (metadados e, quando aplicável, materiais) conforme endpoints de snapshots/metadados do coldigom.
- Indicador de status (online / offline / desatualizado) e tela de gestão de materiais offline (UC-123 a UC-126), incluindo espaço usado pelo cache de materiais.

---

## 11. Padrões de projeto Flutter / frontend

- **Estrutura de pastas**: feature-first (ex.: `lib/features/praises`, `lib/features/listas`, `lib/features/salas`, `lib/features/reader`, `lib/features/offline`, `lib/core/network`, `lib/core/storage`, `lib/shared/widgets`; `lib/features/auth` quando houver features futuras).
- **Camadas**: UI → Riverpod → repositórios/serviços → API client e Hive.
- **Separação**: modelos de domínio vs DTOs de API; adapters API → domínio e para Hive.
- **Testabilidade**: injeção de ApiClient e repositórios via Riverpod.
- **Mobile-first**: design e desenvolvimento priorizam dispositivos móveis; componentes e layouts otimizados para telas pequenas e interação por toque.
- **Acessibilidade**: semântica, contraste, tamanhos mínimos de toque (especialmente importante em mobile).
- **Performance**: `ListView.builder`/lazy loading; carregamento progressivo de PDF (pdfrx); `const` e `select` no Riverpod para evitar rebuilds. Otimizações para hardwares mais fracos.
- **Tecnologias leves**: escolher bibliotecas e padrões que sejam leves e eficientes, evitando dependências pesadas que impactem dispositivos com recursos limitados.

---

## 12. Lints e qualidade

- `flutter_lints` (recomended ou stricter).
- Evitar `print` em produção; preferir `debugPrint` ou logger; tipos explícitos em APIs públicas.
- CI: `flutter analyze` e `dart format --set-exit-if-changed`.

---

## 13. Checklist de implementação por feature

**MVP**: para cada feature (praises, material kinds, listas, salas, leitor PDF, leitor áudio, leitor lyrics, offline):

- Lista de arquivos a criar (páginas, providers, repositórios, modelos).
- Endpoints coldigom (GET) usados.
- Persistência local (Hive): metadados e **cache dos materiais** (PDF, áudio, lyrics) para consumo offline; listas, salas.
- Leitores: consumir material do cache quando disponível; caso contrário baixar e cachear.
- Testes mínimos (unit/widget).

**Futuro** (auth, listas online, salas online, preferências): idem, incluindo endpoints do backend da Coletânea Digital (FastAPI em Docker próprio e separado, PostgreSQL) e token.

---

## 14. Diagrama de arquitetura

```
[UI: Pages / Widgets]
        ↓
[Riverpod Providers]
        ↓
[Repositories / Services]
        ↓
[Coldigom API - GET only]     [Backend Coletânea Digital: FastAPI + PostgreSQL (Docker próprio e separado)]     [Hive]
(cliente → coldigom direto)   (cliente → API Coletânea Digital → PostgreSQL)
```

---

## 15. Observações importantes

- **Coldigom**: apenas APIs públicas (GET). Sem auth; sem criar/editar/deletar praises ou materiais. Coldigom é só gerenciador de objetos.
- **Backend da Coletânea Digital**: listas e salas (MVP local/Hive; depois online). Backend em **Docker próprio e separado (FastAPI + PostgreSQL)** — **não reutiliza o Docker do coldigom**. A stack Cloudflare não atende ao volume das salas online. Auth e preferências em **features futuras**. Projeto separado do coldigom.
- **Hosting**: coldigom chamado direto pelo cliente. API da Coletânea Digital em Docker próprio e separado (FastAPI + PostgreSQL) — **não reutiliza o Docker do coldigom**. Frontend Flutter web pode usar Cloudflare Pages só para estático, ou outro host.
- **Plpcjf**: Coletânea Digital consome dados de leitura do coldigom (GET) e cache em Hive; a tela principal é fortemente inspirada no plpcjf (beleza e usabilidade).
- **Mobile-first e Offline-first**: a aplicação é projetada prioritariamente para dispositivos móveis e funciona completamente offline. Tecnologias leves são escolhidas para funcionar bem em hardwares mais fracos.
- **Segurança sobre retrocompatibilidade**: compatibilidade com versões antigas de navegadores é considerada apenas se não comprometer a segurança. **Prioriza-se segurança sobre retrocompatibilidade** — não usar tecnologias vulneráveis apenas para suportar navegadores antigos.
