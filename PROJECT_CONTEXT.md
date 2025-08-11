# COLETÂNEA DIGITAL - CONTEXTO DO PROJETO

## 📋 VISÃO GERAL
**Nome:** Coletânea Digital  
**Objetivo:** Sistema para organizar materiais de estudo de louvores da Igreja Cristã Maranata  
**Domínio:** Gestão de conteúdo educacional religioso  

## 🏗️ ARQUITETURA TÉCNICA

### Stack Principal
- **Frontend:** Angular 19 (Standalone Components)
- **Backend:** AWS Amplify
- **Storage:** Amazon S3 (arquivos PDF e áudio)
- **Database:** Amazon DynamoDB (metadados)
- **Hosting:** AWS Amplify Hosting
- **Auth:** AWS Cognito (planejado)

### Estrutura do Projeto
```
src/
├── app/
│   ├── components/           # Componentes da aplicação
│   │   ├── biblioteca/       # Listagem e visualização
│   │   ├── upload-material/  # Upload de arquivos
│   │   └── listas/          # Gestão de listas (futuro)
│   ├── services/
│   │   └── amplify.service.ts # Serviço principal AWS
│   ├── models/              # Interfaces e tipos
│   └── shared/              # Componentes compartilhados
```

## 🎯 REGRAS DE NEGÓCIO

### Domínio Principal
- **Igreja Cristã Maranata:** Organização religiosa
- **Materiais de Estudo:** Conteúdo educacional para membros
- **Louvores:** Músicas, hinários, estudos bíblicos relacionados

### Tipos de Material Aceitos
1. **PDF:** Hinários, estudos bíblicos, partituras
2. **Áudio:** MP3, WAV, M4A (louvores, pregações)

### Categorias Padrão
- `louvor` - Músicas de adoração
- `estudo-biblico` - Material de estudo das escrituras  
- `hinario` - Coletâneas de hinos
- `coral` - Arranjos para coro
- `instrumental` - Músicas instrumentais

## 📊 MODELO DE DADOS

### MaterialEstudo (DynamoDB)
```typescript
interface MaterialEstudo {
  id: string;                 // PK: material-{timestamp}
  titulo: string;             // Nome do material
  descricao?: string;         // Descrição opcional
  tipo: 'pdf' | 'audio';      // Tipo do arquivo
  arquivo: string;            // S3 key do arquivo
  categoria: string;          // Categoria do enum acima
  tags: string[];            // Tags para busca
  dataUpload: Date;          // Data de criação
  tamanho: number;           // Tamanho em bytes
  duracao?: number;          // Duração em segundos (áudio)
  paginas?: number;          // Número de páginas (PDF)
  autorUpload?: string;      // ID do usuário (futuro)
}
```

### Lista (DynamoDB) - Futuro
```typescript
interface Lista {
  id: string;                 // PK: lista-{timestamp}
  nome: string;              // Nome da lista
  descricao?: string;        // Descrição opcional
  materiais: string[];       // Array de IDs de materiais
  dataCriacao: Date;         // Data de criação
  dataModificacao: Date;     // Última modificação
  proprietario?: string;     // ID do usuário (futuro)
  publica: boolean;          // Visibilidade da lista
}
```

## 🔧 PADRÕES DE DESENVOLVIMENTO

### Naming Conventions
- **Componentes:** PascalCase (ex: `UploadMaterialComponent`)
- **Serviços:** camelCase com sufixo Service (ex: `amplifyService`)
- **Arquivos S3:** `categoria/timestamp-titulo-sanitizado.ext`
- **IDs DynamoDB:** `{tipo}-{timestamp}` (ex: `material-1234567890`)

### Estrutura de Componentes Angular
- Usar **Standalone Components** (Angular 19)
- Imports: `CommonModule`, `FormsModule` quando necessário
- Template inline para componentes pequenos, arquivo separado para grandes
- Estilos sempre em arquivo separado (.scss)

### Serviços AWS via Amplify
- **Storage (S3):** `Storage.uploadData()`, `Storage.downloadData()`, etc.
- **API (DynamoDB):** Via GraphQL ou REST API gerada pelo Amplify
- **Auth:** AWS Cognito (implementação futura)

## 🎨 PADRÕES DE UI/UX

### Design System
- **Cores Primárias:** Gradiente azul/roxo (`#667eea` → `#764ba2`)
- **Tipografia:** Sistema padrão (sans-serif)
- **Layout:** Flexbox/Grid responsivo
- **Componentes:** Cards para materiais, formulários estruturados

### Navegação
- **Header:** Logo + Navegação principal
- **Rotas:** `/biblioteca`, `/upload`, `/listas` (futuro)
- **Footer:** Informações da organização

### Estados da Aplicação
- **Loading:** Durante uploads e downloads
- **Empty States:** Quando não há materiais
- **Error States:** Tratamento de erros AWS
- **Success States:** Confirmações de ações

## 🚀 FUNCIONALIDADES

### ✅ Implementadas
1. Upload de materiais (PDF/áudio)
2. Visualização de biblioteca
3. Sistema de categorias e tags
4. Busca e filtros
5. Download de arquivos
6. Visualização/reprodução de conteúdo

### 🚧 Em Desenvolvimento
1. Integração completa DynamoDB
2. Sistema de listas personalizadas
3. Melhorias na UI/UX

### 📋 Planejadas
1. Autenticação de usuários (AWS Cognito)
2. Permissões de acesso
3. Compartilhamento de listas
4. Sistema de favoritos
5. Analytics de uso
6. Backup/sync offline

## 🔧 COMANDOS IMPORTANTES

### Desenvolvimento
```bash
npm start                    # Servidor de desenvolvimento
ng build                     # Build de produção
ng test                      # Testes unitários
```

### AWS Amplify
```bash
amplify init                 # Inicializar projeto
amplify add storage          # Adicionar S3
amplify add api              # Adicionar DynamoDB/GraphQL
amplify push                 # Deploy das mudanças
amplify publish              # Build e deploy completo
```

### Git
```bash
git add .
git commit -m "feat: descrição"
git push origin main
```

## 🎯 PRÓXIMOS PASSOS PRIORITÁRIOS

1. **Amplify Init:** Configurar AWS Amplify no projeto
2. **Storage Setup:** Configurar S3 para upload de arquivos
3. **API Setup:** Configurar DynamoDB para metadados
4. **Integration:** Conectar serviços com frontend
5. **Testing:** Testar fluxo completo upload → visualização
6. **Deploy:** Primeira versão em produção

## 📝 NOTAS TÉCNICAS

- **Angular 19:** Usar sempre `standalone: true` em componentes
- **TypeScript:** Tipagem rigorosa, interfaces bem definidas  
- **AWS Amplify:** Seguir padrões da documentação oficial
- **Responsividade:** Mobile-first approach
- **Performance:** Lazy loading de rotas, otimização de imagens
- **SEO:** Meta tags apropriadas (futuro)

---

**Última Atualização:** 11/08/2025  
**Versão:** 1.0.0-alpha  
**Ambiente:** Desenvolvimento
