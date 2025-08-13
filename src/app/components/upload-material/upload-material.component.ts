import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AmplifyService } from '../../services/amplify.service';
import { TipoPartitura, CreateMaterialForm, TipoPartituraLabels, Louvor, Arranjo, Material, CreateLouvorForm, CreateArranjoForm } from '../../models/coletanea.models';

enum TabStep {
  LOUVOR = 'louvor',
  ARRANJO = 'arranjo',
  MATERIAL = 'material'
}

@Component({
  selector: 'app-upload-material',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="upload-container">
      <h2>Adicionar Material</h2>
      
      <!-- Tab Navigation -->
      <div class="tab-navigation">
        <button 
          class="tab-button"
          [class.active]="currentTab === TabStep.LOUVOR" 
          [class.completed]="louvorSelecionado"
          (click)="goToTab(TabStep.LOUVOR)">
          <span class="tab-number">1</span>
          <span class="tab-title">Louvor</span>
          <span class="tab-subtitle" *ngIf="louvorSelecionado">{{ louvorSelecionado.titulo }}</span>
        </button>
        
        <button 
          class="tab-button"
          [class.active]="currentTab === TabStep.ARRANJO" 
          [class.completed]="arranjoSelecionado"
          [disabled]="!louvorSelecionado"
          (click)="goToTab(TabStep.ARRANJO)">
          <span class="tab-number">2</span>
          <span class="tab-title">Arranjo</span>
          <span class="tab-subtitle" *ngIf="arranjoSelecionado">{{ arranjoSelecionado.nome }}</span>
        </button>
        
        <button 
          class="tab-button"
          [class.active]="currentTab === TabStep.MATERIAL" 
          [disabled]="!arranjoSelecionado"
          (click)="goToTab(TabStep.MATERIAL)">
          <span class="tab-number">3</span>
          <span class="tab-title">Material</span>
        </button>
      </div>

      <!-- Tab Content -->
      <div class="tab-content">
        
        <!-- Tab Louvor -->
        <div *ngIf="currentTab === TabStep.LOUVOR" class="tab-panel">
          <h3>Selecionar ou Criar Louvor</h3>
          
          <!-- Toggle entre Selecionar e Criar -->
          <div class="mode-toggle">
            <button 
              class="toggle-btn"
              [class.active]="!criandoNovoLouvor"
              (click)="toggleCriarLouvor(false)">
              📋 Selecionar Existente
            </button>
            <button 
              class="toggle-btn"
              [class.active]="criandoNovoLouvor"
              (click)="toggleCriarLouvor(true)">
              ➕ Criar Novo
            </button>
          </div>

          <!-- Modo: Selecionar Louvor Existente -->
          <div *ngIf="!criandoNovoLouvor" class="selecionar-mode">
            <!-- Campo de Pesquisa -->
            <div class="search-container">
              <div class="search-input-group">
                <input 
                  type="text" 
                  placeholder="Pesquisar louvores..." 
                  [(ngModel)]="termoPesquisaLouvor"
                  (keyup.enter)="pesquisarLouvores()"
                  class="search-input">
                <button 
                  class="search-btn" 
                  (click)="pesquisarLouvores()"
                  [disabled]="carregandoLouvores">
                  🔍 Pesquisar
                </button>
              </div>
            </div>

            <!-- Lista de Louvores -->
            <div class="lista-louvores" *ngIf="louvores.length > 0">
              <div class="louvor-item" 
                   *ngFor="let louvor of louvores" 
                   [class.selected]="louvorSelecionado?.id === louvor.id"
                   (click)="selecionarLouvor(louvor)">
                <div class="louvor-info">
                  <h4>{{ louvor.titulo }}</h4>
                  <p *ngIf="louvor.autor">🎵 {{ louvor.autor }}</p>
                </div>
                <div class="louvor-actions">
                  <button 
                    class="btn-select"
                    [class.selected]="louvorSelecionado?.id === louvor.id">
                    {{ louvorSelecionado?.id === louvor.id ? '✓ Selecionado' : 'Selecionar' }}
                  </button>
                </div>
              </div>
            </div>

            <!-- Estado de carregamento/vazio -->
            <div class="empty-state" *ngIf="!carregandoLouvores && louvores.length === 0 && !termoPesquisaLouvor">
              <p>🎵 Digite um termo para pesquisar louvores ou clique em "Criar Novo"</p>
            </div>
            
            <div class="loading-state" *ngIf="carregandoLouvores">
              <p>🔄 Carregando louvores...</p>
            </div>

            <div class="empty-state" *ngIf="!carregandoLouvores && louvores.length === 0 && termoPesquisaLouvor">
              <p>❌ Nenhum louvor encontrado para "{{ termoPesquisaLouvor }}"</p>
              <button class="btn-secondary" (click)="toggleCriarLouvor(true)">
                Criar novo louvor
              </button>
            </div>
          </div>

          <!-- Modo: Criar Novo Louvor -->
          <div *ngIf="criandoNovoLouvor" class="criar-mode">
            <div class="form-info">
              <p><strong>📝 Campos marcados com * são obrigatórios</strong></p>
            </div>
            
            <form class="louvor-form" #novoLouvorForm="ngForm">
              <div class="form-group">
                <label for="louvorTitulo">Título do Louvor *</label>
                <input 
                  type="text" 
                  id="louvorTitulo"
                  [(ngModel)]="novoLouvorFormData.titulo" 
                  name="louvorTitulo"
                  required
                  placeholder="Ex: Grande é o Senhor">
              </div>

              <div class="form-group">
                <label for="louvorAutor">Autor *</label>
                <input 
                  type="text" 
                  id="louvorAutor"
                  [(ngModel)]="novoLouvorFormData.autor" 
                  name="louvorAutor"
                  required
                  placeholder="Nome do autor/compositor">
              </div>

              <div class="form-group">
                <label for="louvorObservacoes">Observações</label>
                <textarea 
                  id="louvorObservacoes"
                  [(ngModel)]="novoLouvorFormData.observacoes" 
                  name="louvorObservacoes"
                  rows="3"
                  placeholder="Observações adicionais sobre o louvor...">
                </textarea>
              </div>

              <div class="form-actions">
                <button 
                  type="button" 
                  class="btn-primary"
                  (click)="criarNovoLouvor()"
                  [disabled]="!novoLouvorForm.valid || salvandoLouvor">
                  {{ salvandoLouvor ? 'Criando...' : 'Criar e Selecionar' }}
                </button>
                <button 
                  type="button" 
                  class="btn-secondary"
                  (click)="limparFormularioLouvor()">
                  Limpar
                </button>
              </div>
            </form>
          </div>

          <!-- Ações da Tab -->
          <div class="tab-actions" *ngIf="louvorSelecionado">
            <div class="selected-info">
              <strong>✓ Selecionado:</strong> {{ louvorSelecionado.titulo }}
            </div>
            <button 
              class="btn-next" 
              (click)="goToTab(TabStep.ARRANJO)">
              Próximo: Selecionar Arranjo →
            </button>
          </div>
        </div>

        <!-- Tab Arranjo -->
        <div *ngIf="currentTab === TabStep.ARRANJO" class="tab-panel">
          <h3>Selecionar ou Criar Arranjo</h3>
          <p class="context-info">📋 Contexto: Louvor "<strong>{{ louvorSelecionado?.titulo }}</strong>"</p>
          
          <div class="panel-placeholder">
            <p>🎼 Conteúdo da seleção/criação de Arranjo será implementado na próxima etapa</p>
            
            <!-- Botão temporário para testar navegação -->
            <div class="temp-actions">
              <button class="btn-primary" (click)="tempSelecionarArranjo()">
                Selecionar Arranjo Teste (temporário)
              </button>
            </div>
          </div>
        </div>

        <!-- Tab Material -->
        <div *ngIf="currentTab === TabStep.MATERIAL" class="tab-panel">
          <h3>Upload de Material</h3>
          <p class="context-info">
            📋 Contexto: <strong>{{ louvorSelecionado?.titulo }}</strong> › <strong>{{ arranjoSelecionado?.nome }}</strong>
          </p>

          <form class="upload-form" (ngSubmit)="onSubmit()" #uploadForm="ngForm">
            <div class="form-group">
              <label for="titulo">Título *</label>
              <input 
                type="text" 
                id="titulo" 
                [(ngModel)]="material.titulo" 
                name="titulo" 
                required
                placeholder="Digite o título do material">
            </div>

            <div class="form-group">
              <label for="tipoPartitura">Tipo de Partitura *</label>
              <select id="tipoPartitura" [(ngModel)]="material.tipoPartitura" name="tipoPartitura" required>
                <option value="">Selecione o tipo</option>
                <option *ngFor="let tipo of tiposPartitura" [value]="tipo.value">
                  {{ tipo.label }}
                </option>
              </select>
            </div>

            <div class="form-group">
              <label for="descricao">Descrição</label>
              <textarea 
                id="descricao" 
                [(ngModel)]="material.descricao" 
                name="descricao"
                rows="3"
                placeholder="Descrição opcional do material">
              </textarea>
            </div>

            <div class="form-group">
              <label for="observacoes">Observações</label>
              <textarea 
                id="observacoes" 
                [(ngModel)]="material.observacoes" 
                name="observacoes"
                rows="2"
                placeholder="Observações adicionais">
              </textarea>
            </div>

            <div class="form-group">
              <label for="arquivo">Arquivo *</label>
              <input 
                type="file" 
                id="arquivo" 
                (change)="onFileSelected($event)" 
                accept=".pdf,.jpg,.jpeg,.png"
                required>
              <small class="help-text">
                Formatos aceitos: PDF, JPG, PNG
              </small>
            </div>

            <div class="form-actions">
              <button 
                type="submit" 
                class="btn-primary" 
                [disabled]="!uploadForm.valid || !selectedFile || isUploading">
                {{ isUploading ? 'Enviando...' : 'Adicionar Material' }}
              </button>
              <button 
                type="button" 
                class="btn-secondary" 
                (click)="limparFormulario()"
                [disabled]="isUploading">
                Limpar
              </button>
            </div>
          </form>
        </div>
      </div>

      <!-- Messages -->
      <div *ngIf="message" class="message" [class.error]="messageType === 'error'" [class.success]="messageType === 'success'">
        {{ message }}
      </div>
    </div>
  `,
  styles: [`
    .upload-container {
      max-width: 800px;
      margin: 20px auto;
      padding: 20px;
    }

    /* ==================== TAB NAVIGATION ==================== */
    .tab-navigation {
      display: flex;
      background: #f8f9fa;
      border-radius: 8px 8px 0 0;
      padding: 0;
      margin-bottom: 0;
      border: 1px solid #dee2e6;
      border-bottom: none;
    }

    .tab-button {
      flex: 1;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 16px 12px;
      background: transparent;
      border: none;
      cursor: pointer;
      transition: all 0.3s ease;
      position: relative;
      min-height: 80px;
      border-right: 1px solid #dee2e6;
    }

    .tab-button:last-child {
      border-right: none;
    }

    .tab-button:hover:not(:disabled) {
      background: rgba(0, 123, 255, 0.1);
    }

    .tab-button:disabled {
      opacity: 0.5;
      cursor: not-allowed;
      background: #f8f9fa;
    }

    .tab-button.active {
      background: white;
      border-bottom: 3px solid #007bff;
      font-weight: bold;
    }

    .tab-button.completed:not(.active) {
      background: #d4edda;
      border-bottom: 3px solid #28a745;
    }

    .tab-number {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 24px;
      height: 24px;
      border-radius: 50%;
      background: #6c757d;
      color: white;
      font-size: 12px;
      font-weight: bold;
      margin-bottom: 4px;
    }

    .tab-button.active .tab-number {
      background: #007bff;
    }

    .tab-button.completed .tab-number {
      background: #28a745;
    }

    .tab-title {
      font-size: 14px;
      font-weight: 600;
      margin-bottom: 2px;
    }

    .tab-subtitle {
      font-size: 12px;
      color: #6c757d;
      text-align: center;
      max-width: 120px;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }

    /* ==================== TAB CONTENT ==================== */
    .tab-content {
      background: white;
      border: 1px solid #dee2e6;
      border-top: none;
      border-radius: 0 0 8px 8px;
      min-height: 400px;
    }

    .tab-panel {
      padding: 30px;
    }

    .tab-panel h3 {
      margin: 0 0 20px 0;
      color: #333;
      font-size: 20px;
    }

    .context-info {
      background: #e3f2fd;
      border: 1px solid #bbdefb;
      border-radius: 4px;
      padding: 12px;
      margin-bottom: 20px;
      font-size: 14px;
      color: #1976d2;
    }

    .panel-placeholder {
      text-align: center;
      padding: 40px 20px;
      color: #6c757d;
      background: #f8f9fa;
      border-radius: 8px;
      margin: 20px 0;
    }

    .panel-placeholder p {
      font-size: 16px;
      margin-bottom: 20px;
    }

    .temp-actions {
      margin-top: 20px;
    }

    /* ==================== FORM STYLES ==================== */
    .upload-form {
      background: white;
      padding: 0;
    }

    .form-group {
      margin-bottom: 20px;
    }

    .form-group label {
      display: block;
      margin-bottom: 5px;
      font-weight: bold;
      color: #333;
    }

    .form-group input,
    .form-group select,
    .form-group textarea {
      width: 100%;
      padding: 10px;
      border: 1px solid #ddd;
      border-radius: 4px;
      font-size: 14px;
      transition: border-color 0.3s ease;
    }

    .form-group input:focus,
    .form-group select:focus,
    .form-group textarea:focus {
      outline: none;
      border-color: #007bff;
      box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
    }

    .help-text {
      display: block;
      margin-top: 5px;
      font-size: 12px;
      color: #666;
    }

    .form-actions {
      display: flex;
      gap: 10px;
      justify-content: flex-end;
      margin-top: 30px;
      padding-top: 20px;
      border-top: 1px solid #dee2e6;
    }

    /* ==================== BUTTONS ==================== */
    .btn-primary {
      background: #007bff;
      color: white;
      border: none;
      padding: 12px 24px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 14px;
      font-weight: 600;
      transition: background-color 0.3s ease;
    }

    .btn-primary:hover:not(:disabled) {
      background: #0056b3;
    }

    .btn-primary:disabled {
      background: #6c757d;
      cursor: not-allowed;
    }

    .btn-secondary {
      background: #6c757d;
      color: white;
      border: none;
      padding: 12px 24px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 14px;
      font-weight: 600;
      transition: background-color 0.3s ease;
    }

    .btn-secondary:hover:not(:disabled) {
      background: #545b62;
    }

    /* ==================== MESSAGES ==================== */
    .message {
      margin-top: 20px;
      padding: 12px;
      border-radius: 4px;
      font-size: 14px;
    }

    .message.success {
      background: #d4edda;
      color: #155724;
      border: 1px solid #c3e6cb;
    }

    .message.error {
      background: #f8d7da;
      color: #721c24;
      border: 1px solid #f5c6cb;
    }

    /* ==================== TAB LOUVOR STYLES ==================== */
    .mode-toggle {
      display: flex;
      gap: 0;
      margin-bottom: 20px;
      border-radius: 6px;
      overflow: hidden;
      border: 1px solid #dee2e6;
    }

    .toggle-btn {
      flex: 1;
      padding: 12px 20px;
      background: #f8f9fa;
      border: none;
      cursor: pointer;
      font-size: 14px;
      font-weight: 500;
      transition: all 0.3s ease;
      border-right: 1px solid #dee2e6;
    }

    .toggle-btn:last-child {
      border-right: none;
    }

    .toggle-btn:hover {
      background: #e9ecef;
    }

    .toggle-btn.active {
      background: #007bff;
      color: white;
    }

    .search-container {
      margin-bottom: 20px;
    }

    .search-input-group {
      display: flex;
      gap: 8px;
    }

    .search-input {
      flex: 1;
      padding: 12px;
      border: 1px solid #dee2e6;
      border-radius: 4px;
      font-size: 14px;
    }

    .search-btn {
      padding: 12px 20px;
      background: #28a745;
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-size: 14px;
      font-weight: 500;
      transition: background-color 0.3s ease;
      white-space: nowrap;
    }

    .search-btn:hover:not(:disabled) {
      background: #218838;
    }

    .search-btn:disabled {
      background: #6c757d;
      cursor: not-allowed;
    }

    .lista-louvores {
      max-height: 300px;
      overflow-y: auto;
      border: 1px solid #dee2e6;
      border-radius: 4px;
      background: white;
    }

    .louvor-item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 15px;
      border-bottom: 1px solid #dee2e6;
      cursor: pointer;
      transition: all 0.3s ease;
    }

    .louvor-item:last-child {
      border-bottom: none;
    }

    .louvor-item:hover {
      background: #f8f9fa;
    }

    .louvor-item.selected {
      background: #e3f2fd;
      border-color: #2196f3;
    }

    .louvor-info h4 {
      margin: 0 0 5px 0;
      color: #333;
      font-size: 16px;
    }

    .louvor-info p {
      margin: 2px 0;
      color: #666;
      font-size: 13px;
    }

    .louvor-actions {
      margin-left: 15px;
    }

    .btn-select {
      padding: 8px 16px;
      border: 1px solid #007bff;
      background: white;
      color: #007bff;
      border-radius: 4px;
      cursor: pointer;
      font-size: 13px;
      font-weight: 500;
      transition: all 0.3s ease;
      white-space: nowrap;
    }

    .btn-select:hover {
      background: #007bff;
      color: white;
    }

    .btn-select.selected {
      background: #28a745;
      border-color: #28a745;
      color: white;
    }

    .empty-state, .loading-state {
      text-align: center;
      padding: 40px 20px;
      color: #6c757d;
      background: #f8f9fa;
      border-radius: 4px;
      border: 1px dashed #dee2e6;
    }

    .loading-state {
      background: #fff3cd;
      color: #856404;
      border-color: #ffeaa7;
    }

    .criar-mode {
      background: #f8f9fa;
      padding: 20px;
      border-radius: 4px;
      border: 1px solid #dee2e6;
    }

    .form-info {
      background: #e7f3ff;
      border: 1px solid #b3d9ff;
      border-radius: 4px;
      padding: 12px;
      margin-bottom: 20px;
      font-size: 14px;
      color: #0c5aa6;
    }

    .form-info p {
      margin: 0;
    }

    .louvor-form .form-group {
      margin-bottom: 15px;
    }

    .tab-actions {
      margin-top: 30px;
      padding-top: 20px;
      border-top: 2px solid #28a745;
      display: flex;
      justify-content: space-between;
      align-items: center;
      background: #f8fff9;
      padding: 20px;
      border-radius: 4px;
    }

    .selected-info {
      color: #28a745;
      font-weight: 500;
    }

    .btn-next {
      background: #28a745;
      color: white;
      border: none;
      padding: 12px 24px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 14px;
      font-weight: 600;
      transition: background-color 0.3s ease;
    }

    .btn-next:hover {
      background: #218838;
    }

    /* ==================== RESPONSIVE ==================== */
    @media (max-width: 768px) {
      .upload-container {
        margin: 10px;
        padding: 10px;
      }

      .tab-button {
        padding: 12px 8px;
        min-height: 70px;
      }

      .tab-title {
        font-size: 12px;
      }

      .tab-subtitle {
        font-size: 10px;
        max-width: 80px;
      }

      .tab-panel {
        padding: 20px;
      }

      .form-actions {
        flex-direction: column;
      }
    }
  `]
})
export class UploadMaterialComponent implements OnInit {
  // Enum reference for template
  TabStep = TabStep;
  
  // Workflow state
  currentTab: TabStep = TabStep.LOUVOR;
  louvorSelecionado?: Louvor;
  arranjoSelecionado?: Arranjo;
  
  // Tab Louvor
  louvores: Louvor[] = [];
  termoPesquisaLouvor: string = '';
  criandoNovoLouvor: boolean = false;
  carregandoLouvores: boolean = false;
  salvandoLouvor: boolean = false;
  novoLouvorFormData: CreateLouvorForm = {
    titulo: '',
    autor: '',
    observacoes: '',
    listaId: '' // Temporário - futuramente será selecionado/criado
  };
  
  // Material form (mantém estrutura atual)
  material: CreateMaterialForm = {
    titulo: '',
    usuarioUpload: '',
    tipoPartitura: TipoPartitura.CORO,
    arquivoKey: '',
    descricao: '',
    observacoes: '',
    arranjoId: ''
  };

  selectedFile: File | null = null;
  isUploading: boolean = false;
  message: string = '';
  messageType: 'success' | 'error' = 'success';

  tiposPartitura = Object.entries(TipoPartituraLabels).map(([value, label]) => ({
    value: value as TipoPartitura,
    label
  }));

  constructor(private amplifyService: AmplifyService) {}

  ngOnInit(): void {
    // TODO: Quando implementar autenticação, pegar do AuthService
    this.material.usuarioUpload = 'sistema-temp'; // Temporário até ter autenticação
  }

  // ==================== TAB NAVIGATION ====================
  
  goToTab(tab: TabStep): void {
    // Validar se pode navegar para a tab
    if (!this.canNavigateToTab(tab)) {
      return;
    }
    
    this.currentTab = tab;
    this.message = ''; // Clear messages when changing tabs
  }

  private canNavigateToTab(tab: TabStep): boolean {
    switch (tab) {
      case TabStep.LOUVOR:
        return true; // Sempre pode voltar para o primeiro tab
      case TabStep.ARRANJO:
        return !!this.louvorSelecionado; // Precisa ter louvor selecionado
      case TabStep.MATERIAL:
        return !!(this.louvorSelecionado && this.arranjoSelecionado); // Precisa ter ambos
      default:
        return false;
    }
  }

  // ==================== TAB LOUVOR METHODS ====================

  toggleCriarLouvor(criar: boolean): void {
    this.criandoNovoLouvor = criar;
    this.message = '';
    
    if (criar) {
      // Limpar formulário ao entrar no modo criar
      this.limparFormularioLouvor();
    } else {
      // Carregar louvores ao voltar para o modo selecionar
      if (this.louvores.length === 0 && !this.termoPesquisaLouvor) {
        // Não carregar automaticamente - usuário deve pesquisar
      }
    }
  }

  async pesquisarLouvores(): Promise<void> {
    if (!this.termoPesquisaLouvor.trim()) {
      this.showMessage('Digite um termo para pesquisar.', 'error');
      return;
    }

    this.carregandoLouvores = true;
    try {
      const response = await this.amplifyService.buscarPorTitulo(this.termoPesquisaLouvor, 'Louvor');
      
      if (response.success && response.data) {
        // Filtrar apenas louvores da resposta
        this.louvores = response.data.filter(item => 'letra' in item) as Louvor[];
        
        if (this.louvores.length === 0) {
          this.showMessage(`Nenhum louvor encontrado para "${this.termoPesquisaLouvor}".`, 'error');
        } else {
          this.showMessage(`Encontrados ${this.louvores.length} louvor(es).`, 'success');
        }
      } else {
        this.showMessage('Erro ao buscar louvores: ' + (response.error || response.message), 'error');
        this.louvores = [];
      }
    } catch (error) {
      console.error('Erro ao buscar louvores:', error);
      this.showMessage('Erro ao buscar louvores.', 'error');
      this.louvores = [];
    } finally {
      this.carregandoLouvores = false;
    }
  }

  selecionarLouvor(louvor: Louvor): void {
    this.louvorSelecionado = louvor;
    this.showMessage(`Louvor "${louvor.titulo}" selecionado!`, 'success');
  }

  async criarNovoLouvor(): Promise<void> {
    if (!this.novoLouvorFormData.titulo?.trim()) {
      this.showMessage('O título é obrigatório.', 'error');
      return;
    }

    if (!this.novoLouvorFormData.autor?.trim()) {
      this.showMessage('O autor é obrigatório.', 'error');
      return;
    }

    this.salvandoLouvor = true;
    try {
      const response = await this.amplifyService.criarLouvor(this.novoLouvorFormData);
      
      if (response.success && response.data) {
        this.louvorSelecionado = response.data;
        this.showMessage(`Louvor "${response.data.titulo}" criado e selecionado!`, 'success');
        
        // Voltar para modo seleção e limpar
        this.criandoNovoLouvor = false;
        this.limparFormularioLouvor();
        
        // Adicionar à lista local
        this.louvores.unshift(response.data);
      } else {
        this.showMessage('Erro ao criar louvor: ' + (response.error || response.message), 'error');
      }
    } catch (error) {
      console.error('Erro ao criar louvor:', error);
      this.showMessage('Erro ao criar louvor.', 'error');
    } finally {
      this.salvandoLouvor = false;
    }
  }

  limparFormularioLouvor(): void {
    this.novoLouvorFormData = {
      titulo: '',
      autor: '',
      observacoes: '',
      listaId: ''
    };
  }

  // ==================== TEMPORARY TEST METHODS ====================
  
  tempSelecionarLouvor(): void {
    // Método temporário para testar navegação
    this.louvorSelecionado = {
      id: 'temp-louvor-1',
      titulo: 'Louvor de Teste',
      autor: 'Autor Teste',
      letra: 'Letra do louvor...',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    this.showMessage('Louvor selecionado! Agora você pode ir para o próximo passo.', 'success');
  }

  tempSelecionarArranjo(): void {
    // Método temporário para testar navegação
    if (!this.louvorSelecionado) return;
    
    this.arranjoSelecionado = {
      id: 'temp-arranjo-1',
      nome: 'Arranjo de Teste',
      autor: 'Arranjador Teste',
      louvorId: this.louvorSelecionado.id,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    // Atualizar o arranjoId no material form
    this.material.arranjoId = this.arranjoSelecionado.id;
    
    this.showMessage('Arranjo selecionado! Agora você pode fazer o upload do material.', 'success');
  }

  // ==================== MATERIAL UPLOAD (métodos existentes) ====================

  onFileSelected(event: any): void {
    const file = event.target.files[0];
    if (file) {
      this.selectedFile = file;
      
      // Validar tipo de arquivo
      const allowedTypes = ['application/pdf', 'image/jpeg', 'image/jpg', 'image/png'];
      if (!allowedTypes.includes(file.type)) {
        this.showMessage('Tipo de arquivo não suportado. Use PDF, JPG ou PNG.', 'error');
        this.selectedFile = null;
        event.target.value = '';
        return;
      }

      // Validar tamanho (máximo 10MB)
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (file.size > maxSize) {
        this.showMessage('Arquivo muito grande. Tamanho máximo: 10MB.', 'error');
        this.selectedFile = null;
        event.target.value = '';
        return;
      }

      this.showMessage('Arquivo selecionado com sucesso.', 'success');
    }
  }

  async onSubmit(): Promise<void> {
    if (!this.selectedFile || !this.material.titulo || !this.material.tipoPartitura || !this.material.arranjoId) {
      this.showMessage('Preencha todos os campos obrigatórios.', 'error');
      return;
    }

    this.isUploading = true;
    this.showMessage('Enviando arquivo...', 'success');

    try {
      // Gerar chave S3
      const timestamp = Date.now();
      const fileExtension = this.selectedFile.name.split('.').pop();
      const s3Key = `materiais/${this.material.arranjoId}/${timestamp}-${this.material.titulo.replace(/[^a-zA-Z0-9]/g, '-')}.${fileExtension}`;

      // Upload do arquivo para S3
      await this.amplifyService.uploadFile(this.selectedFile, s3Key);
      
      // Criar material no DynamoDB
      const materialForm: CreateMaterialForm = {
        ...this.material,
        arquivoKey: s3Key
      };

      const response = await this.amplifyService.criarMaterial(materialForm);
      
      if (response.success) {
        this.showMessage('Material adicionado com sucesso!', 'success');
        this.limparFormulario();
      } else {
        this.showMessage(`Erro ao salvar material: ${response.error || response.message}`, 'error');
      }
    } catch (error) {
      console.error('Erro no upload:', error);
      this.showMessage('Erro no upload. Tente novamente.', 'error');
    } finally {
      this.isUploading = false;
    }
  }

  limparFormulario(): void {
    const currentUsuario = this.material.usuarioUpload; // Preservar o usuário
    
    this.material = {
      titulo: '',
      usuarioUpload: currentUsuario, // Manter usuário preenchido automaticamente
      tipoPartitura: TipoPartitura.CORO,
      arquivoKey: '',
      descricao: '',
      observacoes: '',
      arranjoId: this.arranjoSelecionado?.id || '' // Manter arranjo se já selecionado
    };
    
    this.selectedFile = null;
    this.message = '';
    
    // Limpar input de arquivo
    const fileInput = document.getElementById('arquivo') as HTMLInputElement;
    if (fileInput) {
      fileInput.value = '';
    }
  }

  private showMessage(message: string, type: 'success' | 'error'): void {
    this.message = message;
    this.messageType = type;
    
    // Limpar mensagem após alguns segundos
    setTimeout(() => {
      this.message = '';
    }, 5000);
  }
}
