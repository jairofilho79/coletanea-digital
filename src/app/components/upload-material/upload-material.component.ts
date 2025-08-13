import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AmplifyService } from '../../services/amplify.service';
import { TipoPartitura, CreateMaterialForm, TipoPartituraLabels } from '../../models/coletanea.models';

@Component({
  selector: 'app-upload-material',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="upload-container">
      <h2>Adicionar Material</h2>
      
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
          <label for="usuarioUpload">Usuário</label>
          <input 
            type="text" 
            id="usuarioUpload" 
            [(ngModel)]="material.usuarioUpload" 
            name="usuarioUpload"
            placeholder="Nome do usuário">
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
          <label for="arranjoId">ID do Arranjo *</label>
          <input 
            type="text" 
            id="arranjoId" 
            [(ngModel)]="material.arranjoId" 
            name="arranjoId" 
            required
            placeholder="ID do arranjo ao qual este material pertence">
          <small class="help-text">
            Temporário: Digite o ID do arranjo. No futuro, será possível selecionar de uma lista.
          </small>
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

      <div *ngIf="message" class="message" [class.error]="messageType === 'error'" [class.success]="messageType === 'success'">
        {{ message }}
      </div>
    </div>
  `,
  styles: [`
    .upload-container {
      max-width: 600px;
      margin: 20px auto;
      padding: 20px;
    }

    .upload-form {
      background: white;
      padding: 30px;
      border-radius: 8px;
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
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
    }

    .form-group textarea {
      resize: vertical;
      min-height: 60px;
    }

    .help-text {
      display: block;
      margin-top: 5px;
      font-size: 12px;
      color: #666;
    }

    .form-actions {
      display: flex;
      gap: 15px;
      margin-top: 30px;
    }

    .btn-primary, .btn-secondary {
      padding: 12px 24px;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-size: 14px;
      font-weight: bold;
      transition: background-color 0.2s;
    }

    .btn-primary {
      background: #3498db;
      color: white;
      flex: 1;
    }

    .btn-primary:hover:not(:disabled) {
      background: #2980b9;
    }

    .btn-primary:disabled {
      background: #bdc3c7;
      cursor: not-allowed;
    }

    .btn-secondary {
      background: #95a5a6;
      color: white;
    }

    .btn-secondary:hover:not(:disabled) {
      background: #7f8c8d;
    }

    .btn-secondary:disabled {
      background: #ecf0f1;
      cursor: not-allowed;
    }

    .message {
      margin-top: 20px;
      padding: 15px;
      border-radius: 4px;
      font-weight: bold;
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

    @media (max-width: 768px) {
      .upload-container {
        margin: 10px;
        padding: 10px;
      }
      
      .upload-form {
        padding: 20px;
      }
      
      .form-actions {
        flex-direction: column;
      }
    }
  `]
})
export class UploadMaterialComponent implements OnInit {
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
    // Inicialização se necessário
  }

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
    this.material = {
      titulo: '',
      usuarioUpload: '',
      tipoPartitura: TipoPartitura.CORO,
      arquivoKey: '',
      descricao: '',
      observacoes: '',
      arranjoId: ''
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
