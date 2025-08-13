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
          
          <div class="panel-placeholder">
            <p>🎵 Conteúdo da seleção/criação de Louvor será implementado na próxima etapa</p>
            
            <!-- Botão temporário para testar navegação -->
            <div class="temp-actions">
              <button class="btn-primary" (click)="tempSelecionarLouvor()">
                Selecionar Louvor Teste (temporário)
              </button>
            </div>
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
