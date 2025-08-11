import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AmplifyService, MaterialEstudo } from '../../services/amplify.service';

@Component({
  selector: 'app-upload-material',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="upload-container">
      <h2>Upload de Material</h2>
      
      <form (ngSubmit)="uploadMaterial()" #uploadForm="ngForm">
        <div class="form-group">
          <label for="titulo">Título:</label>
          <input type="text" id="titulo" [(ngModel)]="material.titulo" name="titulo" required>
        </div>

        <div class="form-group">
          <label for="descricao">Descrição:</label>
          <textarea id="descricao" [(ngModel)]="material.descricao" name="descricao"></textarea>
        </div>

        <div class="form-group">
          <label for="categoria">Categoria:</label>
          <select id="categoria" [(ngModel)]="material.categoria" name="categoria" required>
            <option value="">Selecione uma categoria</option>
            <option value="louvor">Louvor</option>
            <option value="estudo-biblico">Estudo Bíblico</option>
            <option value="hinario">Hinário</option>
            <option value="coral">Coral</option>
            <option value="instrumental">Instrumental</option>
          </select>
        </div>

        <div class="form-group">
          <label for="tags">Tags (separadas por vírgula):</label>
          <input type="text" id="tags" [(ngModel)]="tagsString" name="tags" 
                 placeholder="ex: adoração, comunhão, alegria">
        </div>

        <div class="form-group">
          <label for="arquivo">Arquivo:</label>
          <input type="file" id="arquivo" (change)="onFileSelected($event)" 
                 accept=".pdf,.mp3,.wav,.m4a" required>
        </div>

        <div class="form-actions">
          <button type="submit" [disabled]="!uploadForm.form.valid || !selectedFile || isUploading">
            <span *ngIf="isUploading">Enviando...</span>
            <span *ngIf="!isUploading">Upload Material</span>
          </button>
        </div>
      </form>

      <div *ngIf="uploadStatus" class="status-message" [ngClass]="uploadStatus.type">
        {{ uploadStatus.message }}
      </div>
    </div>
  `,
  styles: [`
    .upload-container {
      max-width: 600px;
      margin: 20px auto;
      padding: 20px;
      border: 1px solid #ddd;
      border-radius: 8px;
    }

    .form-group {
      margin-bottom: 15px;
    }

    label {
      display: block;
      margin-bottom: 5px;
      font-weight: bold;
    }

    input, textarea, select {
      width: 100%;
      padding: 8px;
      border: 1px solid #ccc;
      border-radius: 4px;
      box-sizing: border-box;
    }

    textarea {
      height: 80px;
      resize: vertical;
    }

    .form-actions {
      margin-top: 20px;
    }

    button {
      background-color: #007bff;
      color: white;
      padding: 10px 20px;
      border: none;
      border-radius: 4px;
      cursor: pointer;
    }

    button:disabled {
      background-color: #6c757d;
      cursor: not-allowed;
    }

    button:hover:not(:disabled) {
      background-color: #0056b3;
    }

    .status-message {
      margin-top: 15px;
      padding: 10px;
      border-radius: 4px;
    }

    .status-message.success {
      background-color: #d4edda;
      color: #155724;
      border: 1px solid #c3e6cb;
    }

    .status-message.error {
      background-color: #f8d7da;
      color: #721c24;
      border: 1px solid #f5c6cb;
    }
  `]
})
export class UploadMaterialComponent implements OnInit {
  material: Partial<MaterialEstudo> = {
    titulo: '',
    descricao: '',
    categoria: '',
    tags: []
  };

  tagsString: string = '';
  selectedFile: File | null = null;
  isUploading: boolean = false;
  uploadStatus: { type: 'success' | 'error', message: string } | null = null;

  constructor(private amplifyService: AmplifyService) {}

  ngOnInit(): void {}

  onFileSelected(event: any): void {
    const file = event.target.files[0];
    if (file) {
      this.selectedFile = file;
      
      // Determinar o tipo baseado na extensão
      const extension = file.name.toLowerCase().split('.').pop();
      if (['pdf'].includes(extension)) {
        this.material.tipo = 'pdf';
      } else if (['mp3', 'wav', 'm4a'].includes(extension)) {
        this.material.tipo = 'audio';
      }
    }
  }

  async uploadMaterial(): Promise<void> {
    if (!this.selectedFile || !this.material.titulo || !this.material.categoria) {
      return;
    }

    this.isUploading = true;
    this.uploadStatus = null;

    try {
      // Preparar tags
      this.material.tags = this.tagsString.split(',').map(tag => tag.trim()).filter(tag => tag);

      // Gerar key única para o S3
      const timestamp = Date.now();
      const fileExtension = this.selectedFile.name.split('.').pop();
      const s3Key = `materiais/${this.material.categoria}/${timestamp}-${this.material.titulo.replace(/[^a-zA-Z0-9]/g, '-')}.${fileExtension}`;

      // Upload do arquivo para S3
      await this.amplifyService.uploadFile(this.selectedFile, s3Key);

      // Preparar objeto do material
      const materialCompleto: MaterialEstudo = {
        id: `material-${timestamp}`,
        titulo: this.material.titulo!,
        descricao: this.material.descricao,
        tipo: this.material.tipo!,
        arquivo: s3Key,
        categoria: this.material.categoria!,
        tags: this.material.tags!,
        dataUpload: new Date(),
        tamanho: this.selectedFile.size,
        ...(this.material.tipo === 'audio' && { duracao: 0 }), // TODO: extrair duração real
        ...(this.material.tipo === 'pdf' && { paginas: 0 }) // TODO: extrair número de páginas
      };

      // Salvar metadados no DynamoDB
      await this.amplifyService.salvarMaterial(materialCompleto);

      this.uploadStatus = {
        type: 'success',
        message: 'Material enviado com sucesso!'
      };

      // Resetar formulário
      this.resetForm();

    } catch (error) {
      console.error('Erro no upload:', error);
      this.uploadStatus = {
        type: 'error',
        message: 'Erro ao enviar material. Tente novamente.'
      };
    } finally {
      this.isUploading = false;
    }
  }

  private resetForm(): void {
    this.material = {
      titulo: '',
      descricao: '',
      categoria: '',
      tags: []
    };
    this.tagsString = '';
    this.selectedFile = null;
  }
}
