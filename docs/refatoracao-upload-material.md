# 📋 ETAPA 1: Análise e Preparação - Refatoração Upload Material

## 🎯 **OBJETIVO DA REFATORAÇÃO**
Transformar o componente `upload-material` de um simples uploader em um fluxo completo hierárquico:
**Louvor (escolher/criar)** → **Arranjo (escolher/criar)** → **Material (upload)**

---

## 🔍 **ANÁLISE DO COMPONENTE ATUAL**

### **Estrutura Atual**
- **Arquivo**: `src/app/components/upload-material/upload-material.component.ts`
- **Linha de código**: 370 linhas
- **Dependências**: AmplifyService, FormsModule, CommonModule
- **Rota**: `/upload`

### **Funcionalidades Atuais**
1. ✅ **Formulário de Material**: título, usuarioUpload, tipo, descrição, observações
2. ✅ **Campo arranjoId**: Input manual (temporário conforme comentário)
3. ✅ **Upload de arquivo**: Validação tipo/tamanho + S3
4. ✅ **Integração AmplifyService**: `criarMaterial()` + `uploadFile()`
5. ✅ **Validações**: Campos obrigatórios, tipos arquivo, tamanho máximo
6. ✅ **UX**: Loading states, mensagens feedback, limpeza formulário

### **Problemas Identificados**
1. ❌ **Campo arranjoId manual**: Usuário precisa saber ID do arranjo
2. ❌ **Sem contexto hierárquico**: Não há seleção de Louvor/Arranjo
3. ❌ **Fluxo isolado**: Não permite criação de novos Louvores/Arranjos
4. ❌ **Sem persistência de rascunho**: Perda de dados se usuário sair
5. ❌ **Sem gestão pós-upload**: Não mostra materiais do arranjo

---

## 🏗️ **ESTRUTURA PROJETADA**

### **Interface de Tabs**
```typescript
enum TabStep {
  LOUVOR = 'louvor',
  ARRANJO = 'arranjo', 
  MATERIAL = 'material'
}

interface WorkflowState {
  currentTab: TabStep;
  louvorSelecionado?: Louvor;
  arranjoSelecionado?: Arranjo;
  materiaisDoArranjo?: Material[];
}
```

### **LocalStorage Schema**
```typescript
interface UploadDraft {
  timestamp: number;
  louvor?: {
    id?: string;
    titulo?: string;
    autor?: string;
    // ... outros campos para criação
  };
  arranjo?: {
    id?: string;
    nome?: string;
    autor?: string;
    // ... outros campos para criação
  };
  material?: CreateMaterialForm;
}
```

---

## 🔧 **INTEGRAÇÕES NECESSÁRIAS**

### **AmplifyService Methods**
- ✅ `listarLouvores()` - Para tab de seleção de Louvor
- ✅ `criarLouvor()` - Para criação de novo Louvor
- ✅ `listarArranjos(louvorId)` - Para tab de seleção contextual de Arranjo
- ✅ `criarArranjo()` - Para criação de novo Arranjo
- ✅ `criarMaterial()` - Já existe e funcionando
- ✅ `uploadFile()` - Já existe e funcionando
- ❓ `buscarPorTitulo()` - Para pesquisa (método existe mas pode precisar ajustes)

### **Novos Métodos Necessários**
```typescript
// Para pesquisa específica de Louvores
buscarLouvoresPorTitulo(titulo: string): Promise<ApiResponse<Louvor[]>>

// Para pesquisa específica de Arranjos por Louvor
buscarArranjosPorTitulo(titulo: string, louvorId: string): Promise<ApiResponse<Arranjo[]>>

// Para listar materiais de um arranjo específico
listarMateriaisPorArranjo(arranjoId: string): Promise<ApiResponse<Material[]>>
```

---

## 📱 **NOVA ESTRUTURA DE COMPONENTE**

### **Estados e Propriedades**
```typescript
export class UploadMaterialComponent implements OnInit {
  // Workflow state
  currentTab: TabStep = TabStep.LOUVOR;
  workflowState: WorkflowState = { currentTab: TabStep.LOUVOR };
  
  // Tab Louvor
  louvores: Louvor[] = [];
  louvorSelecionado?: Louvor;
  novoLouvorForm: CreateLouvorForm = {};
  termoPesquisaLouvor: string = '';
  criandoNovoLouvor: boolean = false;
  
  // Tab Arranjo  
  arranjos: Arranjo[] = [];
  arranjoSelecionado?: Arranjo;
  novoArranjoForm: CreateArranjoForm = {};
  termoPesquisaArranjo: string = '';
  criandoNovoArranjo: boolean = false;
  
  // Tab Material (mantém estrutura atual)
  material: CreateMaterialForm = {};
  selectedFile: File | null = null;
  
  // Pós-upload
  materiaisDoArranjo: Material[] = [];
  mostrandoMateriais: boolean = false;
  
  // Estados gerais
  loading: boolean = false;
  message: string = '';
  messageType: 'success' | 'error' = 'success';
}
```

### **Métodos Principais**
```typescript
// Navegação entre tabs
goToTab(tab: TabStep): void
canNavigateToTab(tab: TabStep): boolean
resetWorkflow(): void

// Tab Louvor
carregarLouvores(): Promise<void>
pesquisarLouvores(): Promise<void>
selecionarLouvor(louvor: Louvor): void
toggleCriarLouvor(): void
salvarNovoLouvor(): Promise<void>

// Tab Arranjo
carregarArranjos(): Promise<void>
pesquisarArranjos(): Promise<void>
selecionarArranjo(arranjo: Arranjo): void
toggleCriarArranjo(): void
salvarNovoArranjo(): Promise<void>

// Tab Material (adaptar métodos existentes)
onSubmitMaterial(): Promise<void>
onUploadSuccess(): void
carregarMateriaisDoArranjo(): Promise<void>
adicionarMaisMaterial(): void

// LocalStorage
salvarRascunho(): void
carregarRascunho(): void
limparRascunho(): void
```

---

## 🎨 **ESTRUTURA DE TEMPLATE**

### **Layout de Tabs**
```html
<div class="upload-container">
  <h2>Adicionar Material</h2>
  
  <!-- Tab Navigation -->
  <div class="tab-navigation">
    <button [class.active]="currentTab === 'louvor'" 
            [disabled]="!canNavigateToTab('louvor')"
            (click)="goToTab('louvor')">
      1. Louvor
    </button>
    <button [class.active]="currentTab === 'arranjo'" 
            [disabled]="!canNavigateToTab('arranjo')"
            (click)="goToTab('arranjo')">
      2. Arranjo  
    </button>
    <button [class.active]="currentTab === 'material'" 
            [disabled]="!canNavigateToTab('material')"
            (click)="goToTab('material')">
      3. Material
    </button>
  </div>

  <!-- Tab Content -->
  <div class="tab-content">
    <!-- Tab Louvor -->
    <div *ngIf="currentTab === 'louvor'" class="tab-panel">
      <!-- Pesquisa + Lista + Criar Novo -->
    </div>
    
    <!-- Tab Arranjo -->
    <div *ngIf="currentTab === 'arranjo'" class="tab-panel">
      <!-- Pesquisa + Lista + Criar Novo -->
    </div>
    
    <!-- Tab Material -->
    <div *ngIf="currentTab === 'material'" class="tab-panel">
      <!-- Formulário atual adaptado -->
    </div>
  </div>

  <!-- Pós-upload: Lista de materiais -->
  <div *ngIf="mostrandoMateriais" class="materiais-do-arranjo">
    <!-- Lista + Botão "Adicionar Mais" -->
  </div>
</div>
```

---

## 📦 **DEPENDÊNCIAS ADICIONAIS**

### **Imports Necessários**
- Manter: `CommonModule`, `FormsModule`, `AmplifyService`
- Adicionar: Possivelmente `ReactiveFormsModule` para formulários mais complexos

### **Modelos TypeScript**
- ✅ `Louvor`, `CreateLouvorForm` - Já existem
- ✅ `Arranjo`, `CreateArranjoForm` - Já existem  
- ✅ `Material`, `CreateMaterialForm` - Já existem

---

## 🚧 **PRÓXIMAS ETAPAS**

### **ETAPA 2: Interface de Tabs**
- Implementar sistema de navegação entre tabs
- Criar validações de progresso
- Estruturar layout responsivo

### **ETAPA 3-6: Implementação das Funcionalidades**
- Tab Louvor com pesquisa e CRUD
- Tab Arranjo contextual com pesquisa e CRUD  
- Tab Material integrado ao fluxo
- Sistema pós-upload

---

## ✅ **VALIDAÇÃO DA ANÁLISE**

Esta análise fornece base sólida para refatoração:
- ✅ **Estrutura atual mapeada** completamente
- ✅ **Integrações identificadas** com AmplifyService
- ✅ **Arquitetura projetada** para nova funcionalidade
- ✅ **Estados e fluxos definidos** claramente
- ✅ **Dependências mapeadas** sem quebras

**Status**: Pronto para ETAPA 2 - Implementação da Interface de Tabs
